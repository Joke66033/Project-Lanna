import { useState, useEffect } from "react";
import { useSearchParams } from "react-router-dom";
import {
  Plus,
  Pencil,
  Trash2,
  ChevronDown,
  Search,
  BookOpen,
  RotateCcw,
} from "lucide-react";
import { supabase } from "../lib/supabaseClient";
import Pagination from "../components/Pagination.jsx";
import { trackRecentActivity, sortRecentData } from "../lib/recentActivity";
import { SuccessModal, ConfirmDeleteModal, WarningModal } from "../components/AlertModals.jsx";

const getApiBase = () => {
  if (typeof window !== 'undefined' && window.location.hostname === 'siripaporn.lnw.mn') {
    return 'https://siripaporn.lnw.mn';
  }
  return import.meta.env.VITE_API_BASE_URL || 'https://siripaporn.lnw.mn';
};
const BASE = getApiBase();

import Modal from "../components/Modal.jsx";
import { categoryColors, getCategoryBadgeStyle } from "../lib/categoryColors";

/* ================= PAGE ================= */
export default function Articles() {
  const colors = categoryColors.articles;
  const articleCategories = ["พยัญชนะ", "สระ", "วรรณยุกต์", "ตัวเลข", "ตัวสะกด"];
  const itemsPerPage = 10;

  /* ===== STATES ===== */
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [totalCount, setTotalCount] = useState(0);

  const [search, setSearch] = useState("");
  const [currentPage, setCurrentPage] = useState(1);
  const [selectedLearningCategory, setSelectedLearningCategory] = useState("all");
  const [selectedCharCategory, setSelectedCharCategory] = useState("all");

  const [showAdd, setShowAdd] = useState(false);
  const [showEdit, setShowEdit] = useState(false);
  const [editIndex, setEditIndex] = useState(null);

  const [showDelete, setShowDelete] = useState(false);
  const [deleteIndex, setDeleteIndex] = useState(null);

  const [showSuccess, setShowSuccess] = useState(false);
  const [successText, setSuccessText] = useState("");

  const [showWarning, setShowWarning] = useState(false);
  const [warningText, setWarningText] = useState("");

  // หมวดหมู่อักขระจาก category_lanna_char
  const [charCategories, setCharCategories] = useState([]);
  const [lannaChars, setLannaChars] = useState([]);
  const [learningCategories, setLearningCategories] = useState([]);

  const [form, setForm] = useState({
    category: "",
    title: "",
    content: "",
    category_char_id: "",
    image_path: null,
    learning_category_code: "",
  });

  const [errors, setErrors] = useState({});
  const [submitting, setSubmitting] = useState(false);

  /* ===== FETCH CHAR CATEGORIES, LANNA CHARS & LEARNING CATEGORIES ===== */
  useEffect(() => {
    const fetchAllCategories = async () => {
      try {
        // 1. Fetch active learning categories
        let learnData = [];
        try {
          const res = await fetch(`${BASE}/endpoints/learning_category_api.php?action=getAll`);
          const json = await res.json();
          learnData = json.data || [];
        } catch (e) {}

        if (!Array.isArray(learnData) || learnData.length === 0) {
          const { data } = await supabase
            .from("learning_category")
            .select("category_code, title, is_active")
            .order("category_code", { ascending: true });
          learnData = data || [];
        }

        const activeLearnCats = learnData.filter(
          (c) => c.is_active !== false && c.is_active !== "0" && c.is_active !== 0
        );
        setLearningCategories(activeLearnCats);
        const activeCodes = new Set(activeLearnCats.map((c) => c.category_code));

        // 2. Fetch char categories
        let charCats = [];
        try {
          const res = await fetch(`${BASE}/endpoints/category_lanna_char_api.php?action=getAll`);
          const json = await res.json();
          charCats = json.data || [];
        } catch (e) {}

        if (!Array.isArray(charCats) || charCats.length === 0) {
          const { data } = await supabase
            .from("category_lanna_char")
            .select("category_char_id, name, learning_category_code")
            .order("category_char_id", { ascending: true });
          charCats = data || [];
        }

        const activeCharCats = charCats.filter(
          (c) => !c.learning_category_code || activeCodes.has(c.learning_category_code)
        );
        setCharCategories(activeCharCats);
      } catch (err) {
        console.error("Error fetching categories in articles:", err);
      }
    };
    fetchAllCategories();
  }, []);

  useEffect(() => {
    const fetchLannaChars = async () => {
      const { data, error } = await supabase
        .from("lanna_char")
        .select("char_id, lanna_char, thai_equivalent, category_char_id");
      if (!error && data) setLannaChars(data);
    };
    fetchLannaChars();
  }, []);

  /* ===== FETCH ARTICLES ===== */
  const fetchData = async (
    page = currentPage,
    searchQuery = search,
    learnCat = selectedLearningCategory,
    charCat = selectedCharCategory
  ) => {
    setLoading(true);
    try {
      let list = [];
      try {
        const res = await fetch(`${BASE}/endpoints/articles_api.php?action=getAll`);
        const json = await res.json();
        list = json.data || [];
      } catch (e) {
        console.warn("MySQL PHP API fetch error, falling back to Supabase:", e);
      }

      if (!Array.isArray(list) || list.length === 0) {
        const { data: resData } = await supabase
          .from("articles")
          .select("*, category_lanna_char(name, learning_category_code, learning_category(title, category_code))");
        list = resData || [];
      }

      // Dropdown 1 filter: หมวดหมู่การเรียนรู้
      if (learnCat && learnCat !== "all") {
        list = list.filter((item) => {
          const lCode = item.learning_category_code || item.category_lanna_char?.learning_category_code;
          return String(lCode) === String(learnCat);
        });
      }

      // Dropdown 2 filter: หมวดหมู่อักขระ
      if (charCat && charCat !== "all") {
        list = list.filter((item) => {
          const cId = item.category_char_id || item.category_lanna_char?.category_char_id;
          return String(cId) === String(charCat);
        });
      }

      if (searchQuery.trim() !== "") {
        const q = searchQuery.trim().toLowerCase();
        list = list.filter((item) => 
          (item.title && item.title.toLowerCase().includes(q)) ||
          (item.content && item.content.toLowerCase().includes(q))
        );
      }

      // Sort recent added/edited items to top of entire dataset
      const sortedList = sortRecentData(list, "articles", "article_id");
      setTotalCount(sortedList.length);

      const from = (page - 1) * itemsPerPage;
      const paginated = sortedList.slice(from, from + itemsPerPage);

      if (page > 1 && paginated.length === 0 && sortedList.length > 0) {
        setCurrentPage(page - 1);
      } else {
        setData(paginated);
        setError(null);
      }
    } catch (err) {
      console.error("articles fetchData error:", err);
      setError(err.message || "เกิดข้อผิดพลาดในการโหลดข้อมูลบทเรียน");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    const delayDebounceFn = setTimeout(() => {
      fetchData(currentPage, search, selectedLearningCategory, selectedCharCategory);
    }, 200);

    return () => clearTimeout(delayDebounceFn);
  }, [currentPage, search, selectedLearningCategory, selectedCharCategory]);

  useEffect(() => {
    const channel = supabase
      .channel("articles")
      .on("postgres_changes",
        { event: "*", schema: "public", table: "articles" },
        () => fetchData(currentPage, search, selectedLearningCategory, selectedCharCategory)
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [currentPage, search, selectedLearningCategory, selectedCharCategory]);

  const getCharCategoryName = (item) => {
    if (item.category_lanna_char?.name) return item.category_lanna_char.name;
    const cat = charCategories.find((c) => c.category_char_id === item.category_char_id);
    return cat ? cat.name : "—";
  };

  const getLearningCategoryTitle = (item) => {
    if (item.category_lanna_char?.learning_category?.title) {
      return item.category_lanna_char.learning_category.title;
    }
    const charCat = charCategories.find((c) => c.category_char_id === item.category_char_id);
    if (charCat) {
      const learnCat = learningCategories.find((l) => l.category_code === charCat.learning_category_code);
      return learnCat ? learnCat.title : "ทั่วไป";
    }
    return "ทั่วไป";
  };

  // Auto-fill using debounce and matched keywords for both dropdowns
  const [debouncedTitle, setDebouncedTitle] = useState("");

  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedTitle(form.title || "");
    }, 400); // Debounce 400ms after typing stops

    return () => clearTimeout(timer);
  }, [form.title]);

  useEffect(() => {
    if (!debouncedTitle || !debouncedTitle.trim()) return;

    let guessedCharCatId = "";
    let guessedLearningCode = "";

    // 1. ลองเดาจากหมวดหมู่อักขระ (charCategories)
    const matchedCharCat = charCategories.find((cat) => {
      const catName = (cat.name || "").trim();
      return catName !== "" && debouncedTitle.includes(catName);
    });

    if (matchedCharCat) {
      guessedCharCatId = String(matchedCharCat.category_char_id);
      guessedLearningCode = matchedCharCat.learning_category_code || "";
    } else {
      // 2. ลองเดาจากตัวอักษรล้านนา/ไทย (lannaChars)
      if (lannaChars.length > 0) {
        const matchedChar = lannaChars.find((c) => {
          const lnChar = (c.lanna_char || "").trim();
          const thEq = (c.thai_equivalent || "").trim();
          return (lnChar !== "" && debouncedTitle.includes(lnChar)) || (thEq !== "" && debouncedTitle.includes(thEq));
        });
        if (matchedChar && matchedChar.category_char_id) {
          guessedCharCatId = String(matchedChar.category_char_id);
          const parentCat = charCategories.find((cat) => cat.category_char_id === matchedChar.category_char_id);
          if (parentCat) {
            guessedLearningCode = parentCat.learning_category_code || "";
          }
        }
      }
    }

    // 3. ลองเดาจากหมวดหมู่การเรียนรู้ (learningCategories)
    const matchedLearning = learningCategories.find((cat) => {
      const catTitle = (cat.title || "").trim();
      return catTitle !== "" && debouncedTitle.includes(catTitle);
    });

    if (matchedLearning) {
      guessedLearningCode = String(matchedLearning.category_code);
    }

    // อัปเดต form state
    setForm((prev) => {
      const updates = {};
      if (guessedCharCatId) updates.category_char_id = guessedCharCatId;
      if (guessedLearningCode) updates.learning_category_code = guessedLearningCode;
      return { ...prev, ...updates };
    });
  }, [debouncedTitle, charCategories, lannaChars, learningCategories]);

  const articles = (data || []).map((item, idx) => {
    const charCat = charCategories.find((c) => c.category_char_id === item.category_char_id);
    const learningCode = item.category_lanna_char?.learning_category_code || charCat?.learning_category_code || "";
    return {
      id: item.id || item.article_id || idx,
      order: item.order || item.sort_order || idx + 1,
      title: item.title || "",
      learning_category_title: getLearningCategoryTitle(item),
      learning_category_code: learningCode,
      content: item.content || "",
      category_char_id: item.category_char_id || "",
      char_category_name: getCharCategoryName(item),
      date: item.date || (item.created_at ? new Date(item.created_at).toLocaleDateString("th-TH") : "—"),
      ...item,
    };
  });

  const paginatedArticles = articles;

  /* ===== VALIDATE ===== */
  const validateForm = () => {
    const e = {};
    if (!form.title || !form.title.trim()) e.title = "กรุณากรอกหัวข้อเนื้อหา";
    if (!form.learning_category_code) e.learning_category_code = "กรุณาเลือกหมวดหมู่การเรียนรู้";
    if (!form.category_char_id) e.category_char_id = "กรุณาเลือกหมวดหมู่อักขระ";
    if (!form.content || !form.content.trim()) e.content = "กรุณากรอกรายละเอียดเนื้อหา";
    setErrors(e);
    return Object.keys(e).length === 0;
  };



  const resetForm = () => {
    setForm({
      category: "",
      title: "",
      content: "",
      category_char_id: "",
      image_path: null,
      learning_category_code: "",
    });
  };

  /* ===== ADD ===== */
  const handleAdd = async (e) => {
    e.preventDefault();
    if (!validateForm()) return;

    try {
      setSubmitting(true);
      const res = await fetch(
        `${BASE}/endpoints/articles_api.php?action=create`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            title: form.title,
            content: form.content,
            category_char_id: form.category_char_id || null,
            image_path: form.image_path || null,
          }),
        }
      );
      const resJson = await res.json();
      const { data: insertedItem, error: resError } = resJson;
      if (resError) throw resError;

      resetForm();
      setShowAdd(false);
      setSuccessText("เพิ่มข้อมูลสำเร็จ");
      setShowSuccess(true);

      // Update state locally (prepend)
      const newArticle = insertedItem || resJson?.data || { ...form };
      const articleId = newArticle?.article_id || newArticle?.id;
      if (articleId) {
        trackRecentActivity("articles", articleId);
      }
      setData((prev) => [newArticle, ...prev.filter((i) => (i.article_id || i.id) !== articleId)]);
      setSearch("");
      setSelectedLearningCategory("all");
      setSelectedCharCategory("all");
      setCurrentPage(1);
      fetchData(1, "", "all", "all");
    } catch (err) {
      setWarningText(err.message || "เกิดข้อผิดพลาดในการเพิ่มเนื้อหา");
      setShowWarning(true);
    } finally {
      setSubmitting(false);
    }
  };

  /* ===== EDIT ===== */
  const openEdit = (index) => {
    const a = articles[index];
    setEditIndex(index);
    setForm({
      id: a.id,
      category: a.category || "",
      title: a.title || "",
      content: a.content || "",
      category_char_id: a.category_char_id ? String(a.category_char_id) : "",
      image_path: a.image_path || null,
      learning_category_code: a.learning_category_code || "",
    });
    setShowEdit(true);
  };

  const handleEditSave = async (e) => {
    e.preventDefault();
    if (!validateForm()) return;

    try {
      setSubmitting(true);
      const targetId = form.id;
      const res = await fetch(
        `${BASE}/endpoints/articles_api.php?action=update&id=${encodeURIComponent(targetId)}`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            title: form.title,
            content: form.content,
            category_char_id: form.category_char_id || null,
            image_path: form.image_path || null,
          }),
        }
      );
      const resJson = await res.json();
      const { data: updatedItem, error: resError } = resJson;
      if (resError) throw resError;

      setShowEdit(false);
      setEditIndex(null);
      setSuccessText("แก้ไขข้อมูลสำเร็จ");
      setShowSuccess(true);

      // Update state locally (prepend updated item)
      const updatedArticle = updatedItem || { ...form, article_id: targetId, id: targetId };
      const editId = updatedArticle?.article_id || targetId;
      trackRecentActivity("articles", editId);
      setData((prev) => [updatedArticle, ...prev.filter((i) => (i.article_id || i.id) !== editId)]);
      setSearch("");
      setSelectedLearningCategory("all");
      setSelectedCharCategory("all");
      setCurrentPage(1);
      fetchData(1, "", "all", "all");
    } catch (err) {
      setWarningText(err.message || "เกิดข้อผิดพลาดในการแก้ไขเนื้อหา");
      setShowWarning(true);
    } finally {
      setSubmitting(false);
    }
  };

  /* ===== DELETE ===== */
  const handleDelete = async () => {
    try {
      setLoading(true);
      const targetItem = articles[deleteIndex];
      const targetId = targetItem?.article_id || targetItem?.id;
      const res = await fetch(
        `${BASE}/endpoints/articles_api.php?action=delete&id=${encodeURIComponent(targetId)}`,
        { method: "POST" }
      );
      const { error: resError } = await res.json();
      if (resError) throw resError;

      setShowDelete(false);
      setDeleteIndex(null);
      setSuccessText("ลบข้อมูลสำเร็จ");
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

  const matchedCharCategories = form.learning_category_code
    ? charCategories.filter((c) => String(c.learning_category_code) === String(form.learning_category_code))
    : charCategories;
  const filteredCharCategories = matchedCharCategories.length > 0 ? matchedCharCategories : charCategories;

  return (
    <div className="p-6 bg-[#f9f7f4] min-h-screen">
      {/* HEADER CARD BANNER */}
      <div className="bg-violet-50/70 border border-violet-200 rounded-2xl p-6 mb-6 flex flex-col md:flex-row md:items-center justify-between gap-4 shadow-sm">
        <div className="flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-violet-100 flex items-center justify-center text-violet-700 shrink-0">
            <BookOpen className="w-6 h-6" />
          </div>
          <div>
            <h1 className="text-xl font-bold text-gray-900">จัดการเนื้อหาการเรียนรู้อักขระล้านนา</h1>
            <p className="text-sm text-gray-500 mt-0.5">เพิ่ม แก้ไข และลบเนื้อหาการเรียนรู้อักขระล้านนา</p>
          </div>
        </div>
        <button
          onClick={() => {
            resetForm();
            setErrors({});
            setShowAdd(true);
          }}
          className="flex items-center gap-2 bg-violet-600 hover:bg-violet-700 text-white px-5 py-2.5 rounded-xl font-semibold shadow-md transition shrink-0"
        >
          <Plus size={18} /> เพิ่มเนื้อหาการเรียนรู้
        </button>
      </div>

      {/* SEARCH & FILTER BAR (Image 1 Format) */}
      <div className="bg-white p-4 rounded-2xl border border-gray-100 shadow-sm flex flex-col md:flex-row items-center gap-3 mb-6">
        {/* SEARCH INPUT */}
        <div className="relative flex-1 w-full flex items-center">
          <Search className="w-4 h-4 text-gray-400 absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none z-10" />
          <input
            className="w-full admin-search-input pr-4 py-2.5 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-violet-500/20 focus:border-violet-500 bg-white text-sm relative z-0"
            placeholder="ค้นหาหัวข้อเนื้อหา..."
            value={search}
            onChange={(e) => {
              setSearch(e.target.value);
              setCurrentPage(1);
            }}
          />
        </div>

        {/* DROPDOWN 1: หมวดหมู่การเรียนรู้ (Wider, no top label) */}
        <div className="w-full md:w-72">
          <select
            className="w-full px-3.5 py-2.5 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-violet-500/20 focus:border-violet-500 bg-white cursor-pointer text-sm text-gray-700 font-medium"
            value={selectedLearningCategory}
            onChange={(e) => {
              setSelectedLearningCategory(e.target.value);
              setSelectedCharCategory("all");
              setCurrentPage(1);
            }}
          >
            <option value="all">หมวดหมู่การเรียนรู้: ทั้งหมด</option>
            {learningCategories.map((cat) => (
              <option key={cat.category_code} value={cat.category_code}>
                {cat.title}
              </option>
            ))}
          </select>
        </div>

        {/* DROPDOWN 2: หมวดหมู่อักขระ (Wider, no top label) */}
        <div className="w-full md:w-72">
          <select
            className="w-full px-3.5 py-2.5 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-violet-500/20 focus:border-violet-500 bg-white cursor-pointer text-sm text-gray-700 font-medium"
            value={selectedCharCategory}
            onChange={(e) => {
              setSelectedCharCategory(e.target.value);
              setCurrentPage(1);
            }}
          >
            <option value="all">หมวดหมู่อักขระ: ทั้งหมด</option>
            {charCategories
              .filter((c) => selectedLearningCategory === "all" || c.learning_category_code === selectedLearningCategory)
              .map((cat) => (
                <option key={cat.category_char_id} value={cat.category_char_id}>
                  {cat.name}
                </option>
              ))}
          </select>
        </div>

        {/* REFRESH / RESET BUTTON */}
        <button
          onClick={() => {
            setSearch("");
            setSelectedLearningCategory("all");
            setSelectedCharCategory("all");
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
        <div className="flex items-center justify-center p-12 bg-white rounded-xl shadow-sm border border-gray-100">
          <div className={`animate-spin rounded-full h-10 w-10 border-t-2 border-b-2 ${colors.borderCol}`}></div>
        </div>
      ) : error ? (
        <div className="p-12 text-center text-red-600 bg-white rounded-xl shadow-sm border border-red-200">
          <p className="font-bold text-lg">เกิดข้อผิดพลาดในการโหลดข้อมูล</p>
          <p className="text-sm mt-1">{error}</p>
          <button
            onClick={fetchData}
            className={`mt-4 px-4 py-2 ${colors.primaryBg} text-white rounded-lg ${colors.primaryBgHover} transition`}
          >
            โหลดใหม่
          </button>
        </div>
      ) : (
        <div className="lanna-table-card">
          <table className="lanna-table">
            <thead className={colors.theadBg}>
              <tr className={`${colors.theadText} border-b-2 ${colors.theadBorder}`} style={{ background: 'none' }}>
                <th className="th-num whitespace-nowrap">ลำดับ</th>
                <th className="th-left whitespace-nowrap min-w-[200px]">หัวข้อเนื้อหา</th>
                <th className="th-left whitespace-nowrap min-w-[180px]">หมวดหมู่การเรียนรู้</th>
                <th className="th-left whitespace-nowrap min-w-[280px]">รายละเอียดเนื้อหา</th>
                <th className="th-left whitespace-nowrap min-w-[180px]">หมวดหมู่อักขระ</th>
                <th className="whitespace-nowrap">จัดการ</th>
              </tr>
            </thead>
            <tbody>
              {paginatedArticles.map((a, i) => (
                <tr key={a.id || i} className="hover:bg-violet-50/60 transition-colors">
                  <td className="td-num">
                    <span className={`lanna-seq ${colors.seqBg} ${colors.seqText} ${colors.seqBgHover} ${colors.seqTextHover}`}>
                      {(currentPage - 1) * itemsPerPage + i + 1}
                    </span>
                  </td>
                  <td className="w-[25%]">
                    <p className="lanna-cell-main">{a.title}</p>
                  </td>
                  <td className="text-left">
                    {(() => {
                      const badgeStyle = getCategoryBadgeStyle(a.learning_category_title);
                      return (
                        <span className="lanna-badge" style={{ backgroundColor: badgeStyle.bg, color: badgeStyle.text, borderColor: badgeStyle.border }}>
                          <span className="lanna-badge-dot" style={{ backgroundColor: badgeStyle.dot }} />
                          {a.learning_category_title}
                        </span>
                      );
                    })()}
                  </td>
                  <td className="lanna-cell-sub text-left w-[45%]">
                    <p className="line-clamp-2 text-sm leading-relaxed">{a.content}</p>
                  </td>
                  <td className="text-left w-[15%]">
                    {a.char_category_name && a.char_category_name !== "—" ? (
                      (() => {
                        const badgeStyle = getCategoryBadgeStyle(a.char_category_name);
                        return (
                          <span className="lanna-badge" style={{ backgroundColor: badgeStyle.bg, color: badgeStyle.text, borderColor: badgeStyle.border }}>
                            <span className="lanna-badge-dot" style={{ backgroundColor: badgeStyle.dot }} />
                            {a.char_category_name}
                          </span>
                        );
                      })()
                    ) : (
                      <span className="lanna-cell-sub text-xs">—</span>
                    )}
                  </td>
                  <td>
                    <div className="lanna-btn-actions">
                      <button onClick={() => openEdit(i)} className="lanna-btn-edit" title="แก้ไข">
                        <Pencil size={15} />
                      </button>
                      <button
                        onClick={() => { setDeleteIndex(i); setShowDelete(true); }}
                        className="lanna-btn-delete"
                        title="ลบ"
                      >
                        <Trash2 size={15} />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
              {paginatedArticles.length === 0 && (
                <tr>
                  <td colSpan={6}>
                    <div className="lanna-empty">
                      <svg className="lanna-empty-icon" fill="none" stroke="currentColor" strokeWidth="1.5" viewBox="0 0 24 24" style={{ width: 40, height: 40 }}>
                        <path strokeLinecap="round" strokeLinejoin="round" d="M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m0 12.75h7.5m-7.5 3H12M10.5 2.25H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9z" />
                      </svg>
                      <p className="lanna-empty-title">ยังไม่มีเนื้อหาการเรียนรู้</p>
                    </div>
                  </td>
                </tr>
              )}
            </tbody>
          </table>

          <Pagination
            currentPage={currentPage}
            totalItems={totalCount}
            pageSize={itemsPerPage}
            onPageChange={setCurrentPage}
            colors={colors}
          />
        </div>
      )}

      {/* ADD / EDIT MODAL */}
      {(showAdd || showEdit) && (
        <Modal
          title={showAdd ? "เพิ่มเนื้อหาการเรียนรู้" : "แก้ไขเนื้อหาการเรียนรู้"}
          onClose={() => {
            setShowAdd(false);
            setShowEdit(false);
            setErrors({});
          }}
        >
          <form
            onSubmit={showAdd ? handleAdd : handleEditSave}
            className="flex flex-col flex-1 overflow-hidden"
          >
            <div className="p-6 overflow-y-auto space-y-4 flex-1">
              <div>
                <label className="block mb-1 font-medium text-gray-700">หัวข้อเนื้อหา <span className="text-red-500">*</span></label>
                <input
                  type="text"
                  value={form.title}
                  onChange={(e) => {
                    setForm((prev) => ({ ...prev, title: e.target.value }));
                    setErrors((prev) => ({ ...prev, title: null }));
                  }}
                  className={`w-full border rounded-xl px-4 py-3 focus:outline-none focus:ring-2 ${colors.ringFocus} bg-white ${errors.title ? "border-red-500" : "border-gray-300"}`}
                  placeholder="กรอกหัวข้อเนื้อหา"
                />
                {errors.title && <p className="text-red-500 text-xs mt-1">{errors.title}</p>}
              </div>

              <div>
                <label className="block mb-1 font-medium text-gray-700">หมวดหมู่การเรียนรู้ <span className="text-red-500">*</span></label>
                <div className="relative">
                  <select
                    value={form.learning_category_code}
                    onChange={(e) => {
                      const code = e.target.value;
                      setForm((prev) => {
                        const nextCharCatId = charCategories.find(
                          (c) => c.category_char_id === prev.category_char_id && c.learning_category_code === code
                        )
                          ? prev.category_char_id
                          : "";
                        return { ...prev, learning_category_code: code, category_char_id: nextCharCatId };
                      });
                    }}
                    className={`w-full border rounded-xl px-4 py-3 pr-12 appearance-none focus:outline-none focus:ring-2 ${colors.ringFocus} bg-white ${errors.learning_category_code ? "border-red-500" : "border-gray-300"}`}
                  >
                    <option value="">— กรุณาเลือกหมวดหมู่การเรียนรู้ —</option>
                    {learningCategories.map((l) => (
                      <option key={l.category_code} value={l.category_code}>{l.title}</option>
                    ))}
                  </select>
                  <ChevronDown size={20} className="pointer-events-none absolute right-4 top-1/2 -translate-y-1/2 text-gray-400" />
                </div>
                {errors.learning_category_code && <p className="text-red-500 text-xs mt-1">{errors.learning_category_code}</p>}
              </div>

              <div>
                <label className="block mb-1 font-medium text-gray-700">หมวดหมู่อักขระที่เกี่ยวข้อง <span className="text-red-500">*</span></label>
                <div className="relative">
                  <select
                    value={form.category_char_id}
                    onChange={(e) => {
                      const charCatId = e.target.value;
                      const charCat = charCategories.find((c) => c.category_char_id === charCatId);
                      setForm((prev) => ({
                        ...prev,
                        category_char_id: charCatId,
                        learning_category_code: charCat ? charCat.learning_category_code : prev.learning_category_code,
                      }));
                    }}
                    className={`w-full border rounded-xl px-4 py-3 pr-12 appearance-none focus:outline-none focus:ring-2 ${colors.ringFocus} bg-white ${errors.category_char_id ? "border-red-500" : "border-gray-300"}`}
                  >
                    <option value="">— กรุณาเลือกหมวดหมู่อักขระ —</option>
                    {filteredCharCategories.map((c) => (
                      <option key={c.category_char_id} value={String(c.category_char_id)}>{c.name}</option>
                    ))}
                  </select>
                  <ChevronDown size={20} className="pointer-events-none absolute right-4 top-1/2 -translate-y-1/2 text-gray-400" />
                </div>
                {errors.category_char_id && <p className="text-red-500 text-xs mt-1">{errors.category_char_id}</p>}
              </div>

              <div>
                <label className="block mb-1 font-medium text-gray-700">รายละเอียดเนื้อหา <span className="text-red-500">*</span></label>
                <textarea
                  value={form.content}
                  onChange={(e) => {
                    setForm((prev) => ({ ...prev, content: e.target.value }));
                    setErrors((prev) => ({ ...prev, content: null }));
                  }}
                  className={`w-full border rounded-xl px-4 py-3 h-32 focus:outline-none focus:ring-2 ${colors.ringFocus} bg-white ${errors.content ? "border-red-500" : "border-gray-300"}`}
                  placeholder="กรอกรายละเอียดเนื้อหา"
                />
                {errors.content && <p className="text-red-500 text-xs mt-1">{errors.content}</p>}
              </div>
            </div>

            <div className="px-6 py-4 border-t border-gray-100 bg-gray-50 flex-shrink-0">
              <button
                type="submit"
                disabled={submitting}
                className={`w-full py-3 rounded-xl font-semibold transition-all ${submitting
                  ? "bg-gray-300 text-gray-500 cursor-not-allowed"
                  : "bg-[#16A34A] hover:bg-[#15803D] text-white shadow"
                  }`}
              >
                {submitting ? (
                  <div className="flex items-center justify-center gap-2">
                    <div className="animate-spin rounded-full h-5 w-5 border-t-2 border-b-2 border-white"></div>
                    กำลังบันทึกข้อมูล...
                  </div>
                ) : (
                  "บันทึกข้อมูล"
                )}
              </button>
            </div>
          </form>
        </Modal>
      )}

      {/* DELETE */}
      <ConfirmDeleteModal
        isOpen={showDelete}
        onClose={() => { setShowDelete(false); setDeleteIndex(null); }}
        onConfirm={handleDelete}
        title="ยืนยันการลบเนื้อหาการเรียนรู้"
        itemName={deleteIndex !== null && articles[deleteIndex] ? articles[deleteIndex].title : ""}
        itemType="เนื้อหาการเรียนรู้"
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
