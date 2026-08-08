import { useState, useEffect } from "react";
import { useSearchParams } from "react-router-dom";
import { Plus, Pencil, Trash2, Search, BookOpen, RotateCcw } from "lucide-react";
import { supabase } from "../lib/supabaseClient.js";
import Pagination from "../components/Pagination.jsx";
import { normalizeLannaText } from "../lib/lannaNormalizer.js";
import LannaText from "../components/LannaText.jsx";
import { loadLannaMap, convertThaiToLanna } from "../lib/thaiToLanna.js";
import { trackRecentActivity, sortRecentData } from "../lib/recentActivity.js";
import { SuccessModal, ConfirmDeleteModal } from "../components/AlertModals.jsx";

const getApiBase = () => {
  if (typeof window !== 'undefined' && window.location.hostname === 'siripaporn.lnw.mn') {
    return 'https://siripaporn.lnw.mn';
  }
  return import.meta.env.VITE_API_BASE_URL || 'https://siripaporn.lnw.mn';
};
const BASE = getApiBase();

import Modal from "../components/Modal.jsx";
import { categoryColors, getCategoryBadgeStyle } from "../lib/categoryColors";

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
      } catch (e) {}

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
      } catch (e) {}

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

  const handleConvert = async () => {
    if (!form.thai_word) return;
    try {
      setLoading(true);
      const res = await fetch(
        `${BASE}/endpoints/vocabulary_api.php?action=translate&keyword=${encodeURIComponent(form.thai_word)}`
      );
      const resJson = await res.json();
      const apiData = resJson.data;
      if (apiData && apiData.lanna_word) {
        const normalized = normalizeLannaText(apiData.lanna_word);
        setForm((prev) => ({
          ...prev,
          lanna_word: normalized,
          reading: apiData.reading || prev.reading || `[${form.thai_word}]`,
          meaning: apiData.meaning && !apiData.meaning.includes("ผลถอดอักษรอัตโนมัติ") ? apiData.meaning : prev.meaning,
        }));
      } else {
        const converted = convertThaiToLanna(form.thai_word, lannaMap);
        const normalized = normalizeLannaText(converted);
        setForm((prev) => ({ ...prev, lanna_word: normalized }));
      }
    } catch (err) {
      console.error("Failed to translate using API, using fallback mapper:", err);
      const converted = convertThaiToLanna(form.thai_word, lannaMap);
      const normalized = normalizeLannaText(converted);
      setForm((prev) => ({ ...prev, lanna_word: normalized }));
    } finally {
      setLoading(false);
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
    if (!form.lanna_word.trim()) newErrors.lanna_word = "กรุณากรอกคำศัพท์ล้านนา";
    if (!form.thai_word.trim()) newErrors.thai_word = "กรุณากรอกคำศัพท์ไทย";
    if (!form.reading.trim()) newErrors.reading = "กรุณากรอกคำอ่าน";
    if (!form.meaning.trim()) newErrors.meaning = "กรุณากรอกความหมาย";
    if (!form.category_vocab_id) newErrors.category_vocab_id = "กรุณาเลือกหมวดหมู่";

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  /* ===== ADD ===== */
  const handleAdd = async (e) => {
    e.preventDefault();
    if (!validateForm()) return;

    try {
      setLoading(true);
      const res = await fetch(
        `${BASE}/endpoints/vocabulary_api.php?action=create`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(form),
        }
      );
      const resJson = await res.json();
      const { data: insertedItem, error: resError } = resJson;
      if (resError) throw resError;

      setShowAdd(false);
      setForm({ lanna_word: "", thai_word: "", reading: "", meaning: "", category_vocab_id: "" });
      setErrors({});
      setSuccessText("เพิ่มคำศัพท์เรียบร้อยแล้ว");
      setShowSuccess(true);
      
      // Update state locally (prepend)
      if (insertedItem) {
        trackRecentActivity("vocabulary", insertedItem.vocab_id);
        setData((prev) => sortRecentData([insertedItem, ...prev], "vocabulary", "vocab_id"));
      }
      fetchData();
    } catch (err) {
      alert("Error adding vocabulary: " + err.message);
    } finally {
      setLoading(false);
    }
  };

  /* ===== EDIT ===== */
  const openEdit = (item) => {
    setForm({
      lanna_word: item.lanna_word || "",
      thai_word: item.thai_word || "",
      reading: item.reading || "",
      meaning: item.meaning || "",
      category_vocab_id: item.category_vocab_id || "",
    });
    setOriginalForm(item);
    setErrors({});
    setShowEdit(true);
  };

  const handleEdit = async (e) => {
    e.preventDefault();
    if (!validateForm()) return;

    try {
      setLoading(true);
      const res = await fetch(
        `${BASE}/endpoints/vocabulary_api.php?action=update&id=${encodeURIComponent(originalForm.vocab_id)}`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(form),
        }
      );
      const resJson = await res.json();
      const { data: updatedItem, error: resError } = resJson;
      if (resError) throw resError;

      setShowEdit(false);
      setOriginalForm(null);
      setForm({ lanna_word: "", thai_word: "", reading: "", meaning: "", category_vocab_id: "" });
      setErrors({});
      setSuccessText("แก้ไขคำศัพท์เรียบร้อยแล้ว");
      setShowSuccess(true);

      // Update state locally (prepend updated item)
      if (updatedItem) {
        trackRecentActivity("vocabulary", updatedItem.vocab_id);
        setData((prev) => {
          const filtered = prev.filter((item) => (item.vocab_id || item.id) !== (updatedItem.vocab_id || updatedItem.id));
          return sortRecentData([updatedItem, ...filtered], "vocabulary", "vocab_id");
        });
      }
      fetchData();
    } catch (err) {
      alert("Error updating vocabulary: " + err.message);
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
      const res = await fetch(
        `${BASE}/endpoints/vocabulary_api.php?action=delete&id=${encodeURIComponent(deleteItem.vocab_id)}`,
        { method: "POST" }
      );
      const { error: resError } = await res.json();
      if (resError) throw resError;

      setShowDelete(false);
      setDeleteItem(null);
      setSuccessText("ลบคำศัพท์เรียบร้อยแล้ว");
      setShowSuccess(true);
      fetchData();
    } catch (err) {
      alert("Error deleting vocabulary: " + err.message);
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
            setForm({ lanna_word: "", thai_word: "", reading: "", meaning: "", category_vocab_id: "" });
            setErrors({});
            setShowEdit(false);
            setShowAdd(true);
          }}
          className="flex items-center gap-2 bg-amber-600 hover:bg-amber-700 text-white px-5 py-2.5 rounded-xl font-semibold shadow-md transition shrink-0"
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
                  <th className="th-num whitespace-nowrap">#</th>
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
                      <LannaText>{d.lanna_word}</LannaText>
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
      {(showAdd || showEdit) && (
        <Modal
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
              {/* คำศัพท์ล้านนา */}
              <div>
                <label className="text-sm font-medium">คำศัพท์ล้านนา</label>
                <div className="flex gap-2 mt-1 items-center">
                  <input
                    value={form.lanna_word}
                    placeholder="พิมพ์เอง หรือกดปุ่มแปลงด้านขวา"
                    className={`flex-1 min-w-0 border rounded-xl px-4 py-3 text-2xl lanna-text ${
                      errors.lanna_word ? "border-red-500" : ""
                    }`}
                    onChange={(e) => {
                      const normalized = normalizeLannaText(e.target.value);
                      setForm((prev) => ({ ...prev, lanna_word: normalized }));
                      setErrors((prev) => ({ ...prev, lanna_word: null }));
                    }}
                  />
                  <button
                    type="button"
                    onClick={handleConvert}
                    className="bg-orange-500 hover:bg-orange-600 text-white font-medium px-4 py-2 rounded-lg transition shrink-0 text-sm"
                  >
                    แปลงจากไทย
                  </button>
                </div>
                <p className="text-red-500 text-xs mt-1.5 font-normal leading-relaxed">
                  * ผู้ใช้ต้องกดปุ่มนี้ทุกครั้ง ที่มีการแก้ไขคำศัพท์ภาษาไทย เพื่อให้คำศัพท์ล้านนาถูกแปลงใหม่
                </p>
                {form.lanna_word && /[\u0E00-\u0E7F]/.test(form.lanna_word) && (
                  <p className="text-yellow-600 text-sm mt-1 font-medium">
                    ⚠️ กรุณาตรวจสอบผลการแปลงก่อนบันทึก
                  </p>
                )}
                {errors.lanna_word && <p className="text-red-500 text-sm mt-1">{errors.lanna_word}</p>}
              </div>

              {/* คำศัพท์ไทย */}
              <div>
                <label className="text-sm font-medium">คำศัพท์ไทย</label>
                <input
                  value={form.thai_word}
                  placeholder="ตัวอย่าง: สวัสดี"
                  className={`mt-1 w-full border rounded-xl px-4 py-3 ${
                    errors.thai_word ? "border-red-500" : ""
                  }`}
                  onChange={(e) => {
                    setForm((prev) => ({ ...prev, thai_word: e.target.value }));
                    setErrors((prev) => ({ ...prev, thai_word: null }));
                  }}
                />
                {errors.thai_word && <p className="text-red-500 text-sm mt-1">{errors.thai_word}</p>}
              </div>

              {/* คำอ่าน / ลำดับการพิมพ์ */}
              <div>
                <label className="text-sm font-medium">คำอ่าน / ลำดับการพิมพ์</label>
                <input
                  value={form.reading}
                  placeholder="ตัวอย่าง: นายฯ / น่านฯ / เน + ้ + ๋ + ๑ + ฯ"
                  className={`mt-1 w-full border rounded-xl px-4 py-3 ${
                    errors.reading ? "border-red-500" : ""
                  }`}
                  onChange={(e) => {
                    setForm((prev) => ({ ...prev, reading: e.target.value }));
                    setErrors((prev) => ({ ...prev, reading: null }));
                  }}
                />
                {errors.reading && <p className="text-red-500 text-sm mt-1">{errors.reading}</p>}
              </div>

              {/* ความหมาย */}
              <div>
                <label className="text-sm font-medium">ความหมาย</label>
                <textarea
                  value={form.meaning}
                  rows={3}
                  placeholder="ตัวอย่าง: คำทักทายทั่วไปทางภาคเหนือ"
                  className={`mt-1 w-full border rounded-xl px-4 py-3 ${
                    errors.meaning ? "border-red-500" : ""
                  }`}
                  onChange={(e) => {
                    setForm((prev) => ({ ...prev, meaning: e.target.value }));
                    setErrors((prev) => ({ ...prev, meaning: null }));
                  }}
                />
                {errors.meaning && <p className="text-red-500 text-sm mt-1">{errors.meaning}</p>}
              </div>

              {/* หมวดหมู่ */}
              <div>
                <label className="text-sm font-medium">หมวดหมู่</label>
                <select
                  value={form.category_vocab_id}
                  onChange={(e) => {
                    setForm((prev) => ({ ...prev, category_vocab_id: e.target.value }));
                    setErrors((prev) => ({ ...prev, category_vocab_id: null }));
                  }}
                  className={`w-full border rounded-xl px-4 py-3 mt-1 ${
                    errors.category_vocab_id ? "border-red-500" : ""
                  }`}
                >
                  <option value="" disabled>
                    เลือกหมวดหมู่คำศัพท์
                  </option>
                  {categories.map((c) => (
                    <option key={c.category_vocab_id} value={c.category_vocab_id}>
                      {c.name}
                    </option>
                  ))}
                </select>
                {errors.category_vocab_id && (
                  <p className="text-red-500 text-sm mt-1">{errors.category_vocab_id}</p>
                )}
              </div>
            </div>

            {/* STICKY FOOTER */}
            <div className="px-6 py-4 border-t border-gray-100 bg-gray-50 flex-shrink-0">
              <button
                disabled={
                  showAdd
                    ? !form.lanna_word || !form.thai_word || !form.reading || !form.meaning || !form.category_vocab_id
                    : showEdit && !isFormChanged
                }
                className={`w-full py-3 rounded-xl font-semibold transition-all ${(showAdd && (!form.lanna_word || !form.thai_word)) || (showEdit && !isFormChanged)
                  ? "bg-gray-300 text-gray-500 cursor-not-allowed"
                  : "bg-[#16A34A] hover:bg-[#15803D] text-white shadow"
                  }`}
              >
                บันทึกข้อมูล
              </button>
            </div>
          </form>
        </Modal>
      )}

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
    </div>
  );
}
