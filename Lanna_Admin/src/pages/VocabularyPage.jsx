import { useState, useEffect } from "react";
import { useSearchParams } from "react-router-dom";
import { Plus, Pencil, Trash2, Search, BookOpen, RotateCcw } from "lucide-react";
import { supabase } from "../lib/supabaseClient.js";
import Pagination from "../components/Pagination.jsx";
import { normalizeLannaText } from "../lib/lannaNormalizer.js";
import LannaText from "../components/LannaText.jsx";
import { loadLannaMap, convertThaiToLanna, toTilokFontString, tilokDirectMap } from "../lib/thaiToLanna.js";
import { translateWithAi } from "../lib/geminiAiService.js";
import { trackRecentActivity, sortRecentData } from "../lib/recentActivity.js";
import { SuccessModal, ConfirmDeleteModal, WarningModal } from "../components/AlertModals.jsx";
import Modal from "../components/Modal.jsx";
import { categoryColors, getCategoryBadgeStyle } from "../lib/categoryColors";

const getApiBase = () => {
  if (typeof window !== 'undefined' && window.location.hostname === 'siripaporn.lnw.mn') {
    return 'https://siripaporn.lnw.mn';
  }
  return import.meta.env.VITE_API_BASE_URL || 'https://siripaporn.lnw.mn';
};
const BASE = getApiBase();

/* ================= HELPERS ================= */
const mapVocabCategory = (items) => {
  // Only keep vocabulary items that have a valid category
  return items
    .filter((item) => item.category_vocab && item.category_vocab.name)
    .map((item) => ({
      ...item,
      category: item.category_vocab.name,
    }));
};

/* ================= PAGE ================= */
export default function VocabularyPage() {
  const colors = categoryColors.vocabulary;
  const [data, setData] = useState([]);
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [lannaMap, setLannaMap] = useState([]);
  const [totalCount, setTotalCount] = useState(0);

  const [selectedCategory, setSelectedCategory] = useState("all");

  const [search, setSearch] = useState("");
  const [currentPage, setCurrentPage] = useState(1);
  const ITEMS_PER_PAGE = 10;

  const fetchData = async (page = currentPage, categoryId = selectedCategory, searchQuery = search) => {
    setLoading(true);
    setError(null);
    try {
      // 1. Fetch valid active categories
      let catData = [];
      try {
        const resCat = await fetch(`${BASE}/endpoints/category_vocab_api.php?action=getAll`);
        const jsonCat = await resCat.json();
        catData = jsonCat.data || [];
      } catch (e) {
        console.warn("Category fetch fallback:", e);
      }

      if (!Array.isArray(catData) || catData.length === 0) {
        const { data: resC } = await supabase
          .from("category_vocab")
          .select("category_vocab_id, name");
        catData = resC || [];
      }
      setCategories(catData);

      // 2. Fetch vocabulary
      let list = [];
      try {
        const resV = await fetch(`${BASE}/endpoints/vocabulary_api.php?action=getAll`);
        const jsonV = await resV.json();
        list = jsonV.data || [];
      } catch (e) {
        console.warn("Vocab fetch fallback:", e);
      }

      if (!Array.isArray(list) || list.length === 0) {
        const { data: resData } = await supabase
          .from("vocabulary")
          .select("*, category_vocab(name)");
        list = resData || [];
      }

      if (categoryId && categoryId !== "all") {
        list = list.filter((item) => String(item.category_vocab_id) === String(categoryId));
      }

      if (searchQuery.trim() !== "") {
        const q = searchQuery.trim().toLowerCase();
        list = list.filter((item) => 
          (item.thai_word && item.thai_word.toLowerCase().includes(q)) ||
          (item.lanna_word && item.lanna_word.toLowerCase().includes(q)) ||
          (item.reading && item.reading.toLowerCase().includes(q)) ||
          (item.meaning && item.meaning.toLowerCase().includes(q))
        );
      }

      // Sort recent added/edited items to top of entire dataset
      const sortedList = sortRecentData(list, "vocabulary", "vocab_id");
      setTotalCount(sortedList.length);

      const from = (page - 1) * ITEMS_PER_PAGE;
      const paginated = sortedList.slice(from, from + ITEMS_PER_PAGE);

      if (page > 1 && paginated.length === 0 && sortedList.length > 0) {
        setCurrentPage(page - 1);
      } else {
        setData(paginated);
        setError(null);
      }
    } catch (err) {
      console.error("VocabularyPage error:", err);
      setError(err.message || "เกิดข้อผิดพลาดในการโหลดข้อมูลคำศัพท์");
    } finally {
      setLoading(false);
    }
  };



  // Reset page when category changes
  useEffect(() => {
    setCurrentPage(1);
  }, [selectedCategory]);

  // Debounced search / pagination trigger
  useEffect(() => {
    const delayDebounceFn = setTimeout(() => {
      fetchData(currentPage, selectedCategory, search);
    }, 200);

    return () => clearTimeout(delayDebounceFn);
  }, [currentPage, selectedCategory, search]);

  useEffect(() => {
    const fetchLannaMap = async () => {
      const map = await loadLannaMap();
      setLannaMap(map);
    };
    fetchLannaMap();

    const channel = supabase
      .channel("vocabulary-changes")
      .on(
        "postgres_changes",
        { event: "*", schema: "public", table: "vocabulary" },
        () => fetchData(currentPage, selectedCategory, search)
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [currentPage, selectedCategory, search]);

  const [showAdd, setShowAdd] = useState(false);
  const [showEdit, setShowEdit] = useState(false);
  const [originalForm, setOriginalForm] = useState(null);

  const [showSuccess, setShowSuccess] = useState(false);
  const [successText, setSuccessText] = useState("");

  const [showWarning, setShowWarning] = useState(false);
  const [warningText, setWarningText] = useState("");

  const [showDelete, setShowDelete] = useState(false);
  const [deleteItem, setDeleteItem] = useState(null);

  const [form, setForm] = useState({
    lanna_word: "",
    thai_word: "",
    reading: "",
    meaning: "",
    category_vocab_id: "",
  });

  const [errors, setErrors] = useState({});
  const [aiLoading, setAiLoading] = useState(false);
  const [isAiConverted, setIsAiConverted] = useState(false);

  // แปลงโดยใช้ AI อัตโนมัติ (Gemini Flash & Intelligent Linguistic Engine)
  const handleAiTranslate = async () => {
    const rawThai = form.thai_word ? form.thai_word.trim() : "";
    if (!rawThai) {
      setErrors((prev) => ({
        ...prev,
        thai_word: "กรุณากรอกคำภาษาไทยก่อนทำการแปลงด้วย AI",
      }));
      return;
    }

    try {
      setAiLoading(true);
      const aiResult = await translateWithAi(rawThai, categories);
      
      // ค้นหาหมวดหมู่ที่ตรงกับที่ AI วิเคราะห์ได้
      let matchedCategoryId = null;
      if (aiResult.category && categories && categories.length > 0) {
        const catTarget = aiResult.category.trim().toLowerCase();
        let found = categories.find((c) => c.name && c.name.trim().toLowerCase() === catTarget);
        if (!found) {
          found = categories.find(
            (c) => c.name && (c.name.includes(catTarget) || catTarget.includes(c.name))
          );
        }
        if (found) {
          matchedCategoryId = found.category_vocab_id;
        }
      }

      setForm((prev) => ({
        ...prev,
        reading: aiResult.reading || prev.reading || rawThai,
        lanna_word: aiResult.lanna_word || prev.lanna_word,
        meaning: aiResult.meaning || prev.meaning || "",
        category_vocab_id: matchedCategoryId || prev.category_vocab_id || (categories[0]?.category_vocab_id || ""),
      }));
      setIsAiConverted(true);
      setErrors((prev) => ({
        ...prev,
        thai_word: null,
        reading: null,
        lanna_word: null,
        meaning: null,
        category_vocab_id: null,
      }));
    } catch (err) {
      console.error("AI Translation Error:", err);
      // Fallback ใช้วิธีตามกฎพื้นฐาน
      handleConvert();
    } finally {
      setAiLoading(false);
    }
  };

  // แปลงจากคำอ่านภาษาล้านนา (หรือคำภาษาไทย) ให้เป็นตัวอักขระล้านนา โดยใช้กฎเดียวกับในแอป 100%
  const handleConvert = () => {
    const rawReading = form.reading ? form.reading.trim() : "";
    const rawThai = form.thai_word ? form.thai_word.trim() : "";

    if (!rawReading && !rawThai) {
      setErrors((prev) => ({
        ...prev,
        thai_word: "กรุณากรอกคำภาษาไทย หรือ คำอ่านภาษาล้านนา",
        reading: "กรุณากรอกคำอ่านภาษาล้านนา",
      }));
      return;
    }

    // 1. ถ้ามีคำอ่านภาษาล้านนา ให้แปลงจากคำอ่านก่อนเสมอ
    if (rawReading) {
      const cleanReading = rawReading.replace(/[[\]-]/g, '').trim();
      const lannaConverted = convertThaiToLanna(cleanReading, lannaMap);
      setForm((prev) => ({
        ...prev,
        lanna_word: lannaConverted,
      }));
      setIsAiConverted(false);
      setErrors((prev) => ({ ...prev, reading: null, lanna_word: null }));
      return;
    }

    // 2. ถ้ายังไม่มีคำอ่าน แต่มีคำภาษาไทย ให้แปลงอักษรล้านนา
    if (rawThai) {
      const lannaConverted = convertThaiToLanna(rawThai, lannaMap);
      setForm((prev) => ({
        ...prev,
        reading: prev.reading || rawThai,
        lanna_word: lannaConverted,
      }));
      setIsAiConverted(false);
      setErrors((prev) => ({ ...prev, thai_word: null, reading: null, lanna_word: null }));
    }
  };

  /* ===== AUTO CLOSE SUCCESS ===== */
  useEffect(() => {
    if (showSuccess) {
      const timer = setTimeout(() => {
        setShowSuccess(false);
      }, 1500);
      return () => clearTimeout(timer);
    }
  }, [showSuccess]);

  const paginatedData = data;

  const validateForm = () => {
    const newErrors = {};
    const cleanThai = (form.thai_word || "").trim();
    if (!cleanThai) {
      newErrors.thai_word = "กรุณากรอกคำศัพท์ไทย";
    }

    // Auto-fill reading if empty
    let cleanReading = (form.reading || "").trim();
    if (!cleanReading && cleanThai) {
      cleanReading = cleanThai;
    }

    // Auto-fill lanna_word if empty
    let cleanLanna = (form.lanna_word || "").trim();
    if (!cleanLanna && (cleanReading || cleanThai)) {
      cleanLanna = convertThaiToLanna(cleanReading || cleanThai, lannaMap);
    }

    if (!cleanLanna) {
      newErrors.lanna_word = "กรุณากดปุ่มแปลงหรือกรอกคำศัพท์ล้านนา";
    }

    let cleanMeaning = (form.meaning || "").trim();
    if (!cleanMeaning && cleanThai) {
      cleanMeaning = cleanThai;
    }

    let catId = form.category_vocab_id;
    if (!catId && categories.length > 0) {
      catId = categories[0].category_vocab_id;
    }

    if (!catId) {
      newErrors.category_vocab_id = "กรุณาเลือกหมวดหมู่";
    }

    // Update form with auto-filled values
    setForm((prev) => ({
      ...prev,
      thai_word: cleanThai,
      reading: cleanReading,
      lanna_word: cleanLanna,
      meaning: cleanMeaning,
      category_vocab_id: catId,
    }));

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  /* ===== ADD ===== */
  const handleAdd = async (e) => {
    e.preventDefault();
    if (!validateForm()) return;

    try {
      setLoading(true);
      const payload = {
        ...form,
        reading: form.reading || form.thai_word,
        lanna_word: form.lanna_word || convertThaiToLanna(form.reading || form.thai_word, lannaMap),
        meaning: form.meaning || form.thai_word,
        category_vocab_id: form.category_vocab_id || (categories[0]?.category_vocab_id || null),
      };

      const res = await fetch(
        `${BASE}/endpoints/vocabulary_api.php?action=create`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload),
        }
      );
      const resJson = await res.json();
      const { data: insertedItem, error: resError } = resJson;
      if (resError) throw resError;

      setShowAdd(false);
      setForm({ lanna_word: "", thai_word: "", reading: "", meaning: "", category_vocab_id: "" });
      setErrors({});
      setIsAiConverted(false);
      setSuccessText("เพิ่มคำศัพท์สำเร็จ");
      setShowSuccess(true);
      
      // Update state locally (prepend)
      const newVocab = insertedItem || resJson?.data || { ...payload };
      const vocabId = newVocab?.vocab_id || newVocab?.id;
      if (vocabId) {
        trackRecentActivity("vocabulary", vocabId);
      }
      setData((prev) => [newVocab, ...prev.filter((i) => (i.vocab_id || i.id) !== vocabId)]);
      setCurrentPage(1);
      fetchData(1);
    } catch (err) {
      setWarningText(err.message || "เกิดข้อผิดพลาดในการเพิ่มคำศัพท์");
      setShowWarning(true);
    } finally {
      setLoading(false);
    }
  };

  /* ===== EDIT ===== */
  const openEdit = (item) => {
    let catId = item.category_vocab_id || item.category_vocab?.category_vocab_id || item.category_id || "";
    if (!catId && item.category && categories.length > 0) {
      const matchCat = categories.find((c) => c.name === item.category);
      if (matchCat) catId = matchCat.category_vocab_id;
    }
    if (!catId && categories.length > 0) {
      catId = categories[0].category_vocab_id;
    }

    setForm({
      lanna_word: item.lanna_word || "",
      thai_word: item.thai_word || "",
      reading: item.reading || "",
      meaning: item.meaning || "",
      category_vocab_id: catId || "",
    });
    setOriginalForm(item);
    setErrors({});
    setIsAiConverted(false);
    setShowAdd(false);
    setShowEdit(true);
  };

  const handleEdit = async (e) => {
    e.preventDefault();
    if (!validateForm()) return;

    try {
      setLoading(true);
      const targetId = originalForm.vocab_id || originalForm.id;
      const payload = {
        ...form,
        reading: form.reading || form.thai_word,
        lanna_word: form.lanna_word || convertThaiToLanna(form.reading || form.thai_word, lannaMap),
        meaning: form.meaning || form.thai_word,
        category_vocab_id: form.category_vocab_id || (categories[0]?.category_vocab_id || null),
      };

      const res = await fetch(
        `${BASE}/endpoints/vocabulary_api.php?action=update&id=${encodeURIComponent(targetId)}`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload),
        }
      );
      const resJson = await res.json();
      const { data: updatedItem, error: resError } = resJson;
      if (resError) throw resError;

      setShowEdit(false);
      setOriginalForm(null);
      setForm({ lanna_word: "", thai_word: "", reading: "", meaning: "", category_vocab_id: "" });
      setErrors({});
      setIsAiConverted(false);
      setSuccessText("แก้ไขคำศัพท์สำเร็จ");
      setShowSuccess(true);

      // Update state locally (prepend updated item)
      const updatedObj = updatedItem || { ...originalForm, ...payload, vocab_id: targetId, id: targetId };
      const editId = updatedObj?.vocab_id || targetId;
      trackRecentActivity("vocabulary", editId);
      setData((prev) => [updatedObj, ...prev.filter((i) => (i.vocab_id || i.id) !== editId)]);
      setCurrentPage(1);
      fetchData(1);
    } catch (err) {
      setWarningText(err.message || "เกิดข้อผิดพลาดในการแก้ไขคำศัพท์");
      setShowWarning(true);
    } finally {
      setLoading(false);
    }
  };

  const isFormChanged =
    showEdit &&
    originalForm &&
    (form.lanna_word !== originalForm.lanna_word ||
      form.thai_word !== originalForm.thai_word ||
      form.reading !== originalForm.reading ||
      form.meaning !== originalForm.meaning ||
      form.category_vocab_id !== originalForm.category_vocab_id);

  /* ===== DELETE ===== */
  const handleDelete = async () => {
    try {
      setLoading(true);
      const targetId = deleteItem.vocab_id || deleteItem.id;
      const res = await fetch(
        `${BASE}/endpoints/vocabulary_api.php?action=delete&id=${encodeURIComponent(targetId)}`,
        { method: "POST" }
      );
      const { error: resError } = await res.json();
      if (resError) throw resError;

      setShowDelete(false);
      setDeleteItem(null);
      setSuccessText("ลบคำศัพท์สำเร็จ");
      setShowSuccess(true);
      fetchData();
    } catch (err) {
      setShowDelete(false);
      setWarningText(err.message || "ไม่สามารถลบข้อมูลได้");
      setShowWarning(true);
    } finally {
      setLoading(false);
    }
  };

  const categoryStyle = (category) => {
    return ""; // สไตล์ครอบคลุมโดย .lanna-badge ใน index.css แล้ว
  };

  const getCategoryDotColor = (category) => {
    const text = String(category || "");
    if (!text || text === "—" || text === "ทั่วไป") return "#64748b";
    let hash = 0;
    for (let i = 0; i < text.length; i++) {
      hash = text.charCodeAt(i) + ((hash << 5) - hash);
    }
    const dotColors = [
      "#ea580c", "#d97706", "#059669", "#0d9488", "#0284c7",
      "#7c3aed", "#e11d48", "#15803d", "#7e22ce", "#14b8a6"
    ];
    return dotColors[Math.abs(hash) % dotColors.length];
  };

  return (
    <div className="p-6 bg-[#f9f7f4] min-h-screen">
      {/* HEADER CARD BANNER */}
      <div className="bg-amber-50/70 border border-amber-200 rounded-2xl p-6 mb-6 flex flex-col md:flex-row md:items-center justify-between gap-4 shadow-sm">
        <div className="flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-amber-100 flex items-center justify-center text-amber-700 shrink-0">
            <BookOpen className="w-6 h-6" />
          </div>
          <div>
            <h1 className="text-xl font-bold text-gray-900">จัดการข้อมูลคำศัพท์</h1>
            <p className="text-sm text-gray-500 mt-0.5">เพิ่ม แก้ไข และลบข้อมูลคำศัพท์ล้านนา</p>
          </div>
        </div>
        <button
          onClick={() => {
            const defaultCat = categories.length > 0 ? categories[0].category_vocab_id : "";
            setForm({ lanna_word: "", thai_word: "", reading: "", meaning: "", category_vocab_id: defaultCat });
            setErrors({});
            setIsAiConverted(false);
            setShowEdit(false);
            setShowAdd(true);
          }}
          className="flex items-center gap-2 bg-amber-600 hover:bg-amber-700 text-white px-5 py-2.5 rounded-xl font-semibold shadow-md transition shrink-0 cursor-pointer"
        >
          <Plus size={18} /> เพิ่มคำศัพท์
        </button>
      </div>

      {/* SEARCH & FILTER (Image 1 Format) */}
      <div className="bg-white p-4 rounded-2xl border border-gray-100 shadow-sm flex flex-col sm:flex-row items-center gap-3 mb-6">
        <div className="relative flex-1 w-full flex items-center">
          <Search className="w-4 h-4 text-gray-400 absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none z-10" />
          <input
            className="w-full admin-search-input pr-4 py-2.5 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-amber-500/20 focus:border-amber-500 bg-white text-sm relative z-0"
            placeholder="ค้นหาคำศัพท์ คำอ่าน หรือความหมาย..."
            value={search}
            onChange={(e) => {
              setSearch(e.target.value);
              setCurrentPage(1);
            }}
            style={{ paddingLeft: '44px' }}
          />
        </div>
        <div className="w-full sm:w-64">
          <select
            className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-amber-500/20 focus:border-amber-500 bg-white cursor-pointer text-sm"
            value={selectedCategory}
            onChange={(e) => {
              setSelectedCategory(e.target.value);
              setCurrentPage(1);
            }}
          >
            <option value="all">ทั้งหมด</option>
            {categories.map((cat) => (
              <option key={cat.category_vocab_id} value={cat.category_vocab_id}>
                {cat.name}
              </option>
            ))}
          </select>
        </div>
        <button
          onClick={() => {
            setSearch("");
            setSelectedCategory("all");
            setCurrentPage(1);
          }}
          title="รีเซ็ตการค้นหา"
          className="p-2.5 border border-gray-200 rounded-xl hover:bg-gray-50 text-gray-500 transition shrink-0"
        >
          <RotateCcw size={16} />
        </button>
      </div>

      {/* TABLE */}
      {loading ? (
        <div className="flex items-center justify-center p-12 bg-white rounded-xl shadow-sm">
          <div className="animate-spin rounded-full h-10 w-10 border-t-2 border-b-2 border-orange-500"></div>
        </div>
      ) : (
        <>
          <div className="lanna-table-card">
            <table className="lanna-table">
              <thead className={colors.theadBg}>
                <tr className={`${colors.theadText} border-b-2 ${colors.theadBorder}`} style={{ background: 'none' }}>
                  <th className="th-num whitespace-nowrap">ลำดับ</th>
                  <th className="th-left whitespace-nowrap">คำศัพท์ล้านนา</th>
                  <th className="whitespace-nowrap">คำศัพท์ไทย</th>
                  <th className="whitespace-nowrap">คำอ่าน / ลำดับการพิมพ์</th>
                  <th className="th-left whitespace-nowrap">ความหมาย</th>
                  <th className="whitespace-nowrap">หมวดหมู่</th>
                  <th className="whitespace-nowrap">จัดการ</th>
                </tr>
              </thead>
              <tbody>
                {paginatedData.map((d, i) => (
                  <tr key={d.vocab_id || i} className="hover:bg-amber-50/60 transition-colors">
                    <td className="td-num">
                      <span className={`lanna-seq ${colors.seqBg} ${colors.seqText} ${colors.seqBgHover} ${colors.seqTextHover}`}>
                        {(currentPage - 1) * ITEMS_PER_PAGE + i + 1}
                      </span>
                    </td>

                    {/* คำศัพท์ล้านนา */}
                    <td className="text-left text-lg">
                      <LannaText fallbackThai={d.thai_word}>{d.lanna_word}</LannaText>
                    </td>

                    {/* คำศัพท์ไทย */}
                    <td className="text-left lanna-cell-main">{d.thai_word}</td>

                    {/* คำอ่าน */}
                    <td className="text-left">{d.reading}</td>

                    {/* ความหมาย */}
                    <td className="lanna-cell-sub max-w-[200px] truncate" title={d.meaning}>
                      {d.meaning}
                    </td>

                    {/* หมวดหมู่ */}
                    <td className="text-left">
                      {(() => {
                        const badgeStyle = getCategoryBadgeStyle(d.category_vocab?.name || "ทั่วไป");
                        return (
                          <span className="lanna-badge" style={{ backgroundColor: badgeStyle.bg, color: badgeStyle.text, borderColor: badgeStyle.border }}>
                            <span className="lanna-badge-dot" style={{ backgroundColor: badgeStyle.dot }} />
                            {d.category_vocab?.name || "ทั่วไป"}
                          </span>
                        );
                      })()}
                    </td>

                    <td>
                      <div className="lanna-btn-actions">
                        <button onClick={() => openEdit(d)} className="lanna-btn-edit" title="แก้ไข">
                          <Pencil size={15} />
                        </button>
                        <button
                          type="button"
                          onClick={() => { setDeleteItem(d); setShowDelete(true); }}
                          className="lanna-btn-delete"
                          title="ลบ"
                        >
                          <Trash2 size={15} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
                {paginatedData.length === 0 && (
                  <tr>
                    <td colSpan={7}>
                      <div className="lanna-empty">
                        <svg className="lanna-empty-icon" fill="none" stroke="currentColor" strokeWidth="1.5" viewBox="0 0 24 24" style={{width:40,height:40}}>
                          <path strokeLinecap="round" strokeLinejoin="round" d="M12 6.042A8.967 8.967 0 006 3.75c-1.052 0-2.062.18-3 .512v14.25A8.987 8.987 0 016 18c2.305 0 4.408.867 6 2.292m0-14.25a8.966 8.966 0 016-2.292c1.052 0 2.062.18 3 .512v14.25A8.987 8.987 0 0018 18a8.967 8.967 0 00-6 2.292m0-14.25v14.25" />
                        </svg>
                        <p className="lanna-empty-title">ยังไม่มีข้อมูลคำศัพท์</p>
                      </div>
                    </td>
                  </tr>
                )}
              </tbody>
            </table>

            {/* PAGINATION */}
            <Pagination
              currentPage={currentPage}
              totalItems={totalCount}
              pageSize={ITEMS_PER_PAGE}
              onPageChange={setCurrentPage}
              colors={colors}
            />
          </div>

          {/* WARNING INLINE ERROR BELOW THE TABLE */}
          {error && (
            <p className="text-xs text-red-500 mt-3 italic text-right">
              * เกิดข้อผิดพลาดในระบบฐานข้อมูล: {error}
            </p>
          )}
        </>
      )}

      {/* ADD / EDIT MODAL */}
      <Modal
        isOpen={Boolean(showAdd || showEdit)}
        title={showAdd ? "เพิ่มคำศัพท์ใหม่" : "แก้ไขข้อมูลคำศัพท์"}
        onClose={() => {
          setShowAdd(false);
          setShowEdit(false);
          setOriginalForm(null);
          setErrors({});
          setForm({ lanna_word: "", thai_word: "", reading: "", meaning: "", category_vocab_id: "" });
        }}
      >
          <form
            onSubmit={showAdd ? handleAdd : handleEdit}
            className="flex flex-col flex-1 overflow-hidden"
          >
            {/* SCROLLABLE BODY */}
            <div className="p-6 overflow-y-auto space-y-4 flex-1">
              {/* 1. คำภาษาไทย */}
              <div>
                <label className="text-xs font-bold text-gray-700 block mb-1">
                  1. คำภาษาไทย <span className="text-red-500">*</span>
                </label>
                <input
                  value={form.thai_word}
                  placeholder="ตัวอย่าง: สวัสดี, มะม่วง, ยินดีต้อนรับ, ส้มตำ, กินข้าว"
                  className={`w-full border rounded-xl px-3.5 py-2.5 bg-white text-sm focus:outline-none focus:ring-2 focus:ring-amber-500/20 focus:border-amber-500 ${
                    errors.thai_word ? "border-red-500" : "border-gray-200"
                  }`}
                  onChange={(e) => {
                    setForm((prev) => ({ ...prev, thai_word: e.target.value }));
                    setErrors((prev) => ({ ...prev, thai_word: null }));
                  }}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter' && e.ctrlKey) {
                      e.preventDefault();
                      handleAiTranslate();
                    }
                  }}
                />
                {errors.thai_word && <p className="text-red-500 text-xs mt-1">{errors.thai_word}</p>}
                
                {/* ปุ่มแปลงด้วย AI ใต้กล่องคำภาษาไทย */}
                <div className="mt-2">
                  <button
                    type="button"
                    onClick={handleAiTranslate}
                    disabled={aiLoading}
                    className="w-full flex items-center justify-center gap-2 bg-gradient-to-r from-purple-600 via-indigo-600 to-purple-700 hover:from-purple-700 hover:to-indigo-700 text-white font-semibold py-2.5 px-4 rounded-xl shadow-md transition transform active:scale-[0.99] text-xs sm:text-sm cursor-pointer disabled:opacity-50"
                    title="กดเพื่อให้ AI ช่วยแปลงคำศัพท์ คำอ่าน และอักขระล้านนาอัตโนมัติ"
                  >
                    {aiLoading ? (
                      <>
                        <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                        <span>กำลังประมวลผลด้วย AI...</span>
                      </>
                    ) : (
                      <>
                        <span>✨</span>
                        <span>แปลงโดยใช้ AI อัตโนมัติ</span>
                      </>
                    )}
                  </button>
                </div>
              </div>

              {/* 2. คำอ่านภาษาล้านนา */}
              <div>
                <label className="text-xs font-bold text-gray-700 block mb-1">
                  2. คำอ่านภาษาล้านนา <span className="text-red-500">*</span>
                </label>
                <input
                  value={form.reading}
                  placeholder="ตัวอย่าง: สะ-หวัด-ดี, บะม่วง, ยิน-ดี-ต้อน-ฮับ, ตำ-ส้ม, กิ๋น-ข้าว"
                  className={`w-full border rounded-xl px-3.5 py-2.5 bg-white text-sm focus:outline-none focus:ring-2 focus:ring-amber-500/20 focus:border-amber-500 ${
                    errors.reading ? "border-red-500" : "border-gray-200"
                  }`}
                  onChange={(e) => {
                    setForm((prev) => ({ ...prev, reading: e.target.value }));
                    setErrors((prev) => ({ ...prev, reading: null }));
                  }}
                />
                {errors.reading && <p className="text-red-500 text-xs mt-1">{errors.reading}</p>}
                
                {/* ปุ่มแปลงจากคำอ่าน */}
                <div className="mt-2">
                  <button
                    type="button"
                    onClick={handleConvert}
                    className="w-full flex items-center justify-center gap-2 bg-gradient-to-r from-amber-600 via-orange-600 to-amber-700 hover:from-amber-700 hover:to-orange-700 text-white font-semibold py-2.5 px-4 rounded-xl shadow-md transition transform active:scale-[0.99] text-xs sm:text-sm cursor-pointer"
                    title="กดเพื่อแปลงคำอ่านเป็นตัวอักขระล้านนาตามกฎในระบบ"
                  >
                    <span>⚡</span>
                    <span>แปลงจากคำอ่าน</span>
                  </button>
                </div>
              </div>

              {/* 3. ตัวอักขระล้านนา (แสดงผลอัตโนมัติจากการกดแปลง) */}
              <div>
                <label className="text-xs font-bold text-gray-700 block mb-1">
                  3. ตัวอักขระล้านนา <span className="text-red-500">*</span>
                </label>
                <div
                  className={`w-full min-h-[64px] border rounded-xl px-4 py-3 bg-[#FFFDF9] flex items-center justify-between transition-all ${
                    errors.lanna_word
                      ? "border-red-500 bg-red-50/20"
                      : form.lanna_word
                      ? "border-[#EADBC8] shadow-sm"
                      : "border-dashed border-gray-300"
                  }`}
                >
                  {form.lanna_word ? (
                    <LannaText fallbackThai={form.thai_word} className="text-3xl text-[#924E19] leading-none tracking-wide select-all">
                      {form.lanna_word}
                    </LannaText>
                  ) : (
                    <span className="text-sm text-gray-400 italic">
                      (กดปุ่มแปลงด้านบนเพื่อแสดงตัวอักขระล้านนา)
                    </span>
                  )}
                  {form.lanna_word && (
                    <span
                      className={`px-2.5 py-1 text-xs font-medium rounded-lg shrink-0 border ${
                        isAiConverted
                          ? "bg-purple-100 text-purple-700 border-purple-200"
                          : "bg-green-100 text-green-700 border-green-200"
                      }`}
                    >
                      {isAiConverted ? "✨ AI แปลงสำเร็จ" : "✓ แปลงสำเร็จ"}
                    </span>
                  )}
                </div>
                {errors.lanna_word && <p className="text-red-500 text-xs mt-1">{errors.lanna_word}</p>}
              </div>

              {/* 4. ความหมาย */}
              <div>
                <label className="text-xs font-bold text-gray-700 block mb-1">
                  4. ความหมาย <span className="text-red-500">*</span>
                </label>
                <textarea
                  value={form.meaning}
                  rows={2}
                  placeholder="ตัวอย่าง: คำทักทายทั่วไปทางภาคเหนือ"
                  className={`w-full border rounded-xl px-3.5 py-2.5 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-amber-500/20 focus:border-amber-500 ${
                    errors.meaning ? "border-red-500" : "border-gray-200"
                  }`}
                  onChange={(e) => {
                    setForm((prev) => ({ ...prev, meaning: e.target.value }));
                    setErrors((prev) => ({ ...prev, meaning: null }));
                  }}
                />
                {errors.meaning && <p className="text-red-500 text-xs mt-1">{errors.meaning}</p>}
              </div>

              {/* 5. หมวดหมู่ */}
              <div>
                <label className="text-xs font-bold text-gray-700 block mb-1">
                  5. หมวดหมู่ <span className="text-red-500">*</span>
                </label>
                <select
                  value={form.category_vocab_id}
                  onChange={(e) => {
                    setForm((prev) => ({ ...prev, category_vocab_id: e.target.value }));
                    setErrors((prev) => ({ ...prev, category_vocab_id: null }));
                  }}
                  className={`w-full border rounded-xl px-3.5 py-2.5 text-sm bg-white cursor-pointer focus:outline-none focus:ring-2 focus:ring-amber-500/20 focus:border-amber-500 ${
                    errors.category_vocab_id ? "border-red-500" : "border-gray-200"
                  }`}
                >
                  <option value="" disabled>
                    -- กรุณาเลือกหมวดหมู่คำศัพท์ --
                  </option>
                  {categories.map((c) => (
                    <option key={c.category_vocab_id} value={c.category_vocab_id}>
                      {c.name}
                    </option>
                  ))}
                </select>
                {errors.category_vocab_id && (
                  <p className="text-red-500 text-xs mt-1">{errors.category_vocab_id}</p>
                )}
              </div>
            </div>

            {/* STICKY FOOTER */}
            <div className="px-6 py-4 border-t border-gray-100 bg-gray-50/80 flex-shrink-0">
              <button
                type="submit"
                disabled={loading || !form.thai_word.trim()}
                className={`w-full py-3 rounded-xl font-bold text-sm transition-all shadow-sm cursor-pointer ${
                  loading || !form.thai_word.trim()
                    ? "bg-gray-300 text-gray-500 cursor-not-allowed"
                    : "bg-[#16A34A] hover:bg-[#15803D] text-white shadow-md active:scale-[0.99]"
                }`}
              >
                {loading ? "กำลังดำเนินการ..." : (showAdd ? "บันทึกข้อมูลคำศัพท์ใหม่" : "บันทึกการแก้ไขข้อมูล")}
              </button>
            </div>
          </form>
        </Modal>

      {/* DELETE CONFIRM MODAL */}
      <ConfirmDeleteModal
        isOpen={showDelete}
        onClose={() => setShowDelete(false)}
        onConfirm={handleDelete}
        title="ยืนยันการลบคำศัพท์"
        itemName={deleteItem?.lanna_word || deleteItem?.thai_word || ""}
        itemSubtitle={deleteItem?.thai_word || ""}
        itemType="คำศัพท์"
        isLannaText={true}
      />

      {/* SUCCESS MODAL */}
      <SuccessModal
        isOpen={showSuccess}
        onClose={() => setShowSuccess(false)}
        message={successText}
      />

      {/* WARNING MODAL */}
      <WarningModal
        isOpen={showWarning}
        onClose={() => setShowWarning(false)}
        title="ไม่สามารถดำเนินการได้"
        message={warningText}
      />
    </div>
  );
}
