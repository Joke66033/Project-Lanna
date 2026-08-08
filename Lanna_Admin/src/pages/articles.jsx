import { useState, useEffect } from "react";
import { useSearchParams } from "react-router-dom";
import {
  Plus,
  Pencil,
  Trash2,
  ChevronDown,
  Search,
  BookOpen,
} from "lucide-react";
import { supabase } from "../lib/supabaseClient";
import Pagination from "../components/Pagination.jsx";
import { trackRecentActivity, sortRecentData } from "../lib/recentActivity";
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
  const [selectedCategory, setSelectedCategory] = useState("all");

  const [showAdd, setShowAdd] = useState(false);
  const [showEdit, setShowEdit] = useState(false);
  const [editIndex, setEditIndex] = useState(null);

  const [showDelete, setShowDelete] = useState(false);
  const [deleteIndex, setDeleteIndex] = useState(null);

  const [showSuccess, setShowSuccess] = useState(false);
  const [successText, setSuccessText] = useState("");

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
        const { data: learnData } = await supabase
          .from("learning_category")
          .select("category_code, title, is_active")
          .order("category_code", { ascending: true });

        const activeLearnCats = (learnData || []).filter(
          (c) => c.is_active !== false && c.is_active !== "0" && c.is_active !== 0
        );
        setLearningCategories(activeLearnCats);
        const activeCodes = new Set(activeLearnCats.map((c) => c.category_code));

        // 2. Fetch char categories belonging only to active learning categories
        const { data: cats } = await supabase
          .from("category_lanna_char")
          .select("category_char_id, name, learning_category_code")
          .order("category_char_id", { ascending: true });

        if (cats) {
          const activeCharCats = cats.filter(
            (c) => !c.learning_category_code || activeCodes.has(c.learning_category_code)
          );
          setCharCategories(activeCharCats);
        }
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
  const fetchData = async (page = currentPage, searchQuery = search, categoryId = selectedCategory) => {
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
        let selectStr = "*, category_lanna_char(name, learning_category_code, learning_category(title, category_code))";
        if (categoryId && categoryId !== "all") {
          selectStr = "*, category_lanna_char!inner(name, learning_category_code, learning_category(title, category_code))";
        }
        const { data: resData } = await supabase
          .from("articles")
          .select(selectStr);
        list = resData || [];
      }

      if (categoryId && categoryId !== "all") {
        list = list.filter((item) => {
          const lCode = item.learning_category_code || item.category_lanna_char?.learning_category_code;
          return String(lCode) === String(categoryId);
        });
      }

      if (searchQuery.trim() !== "") {
        const q = searchQuery.trim().toLowerCase();
        list = list.filter((item) => 
          (item.title && item.title.toLowerCase().includes(q)) ||
          (item.content && item.content.toLowerCase().includes(q))
        );
      }

      setTotalCount(list.length);

      const from = (page - 1) * itemsPerPage;
      const paginated = list.slice(from, from + itemsPerPage);

      if (page > 1 && paginated.length === 0 && list.length > 0) {
        setCurrentPage(page - 1);
      } else {
        const sorted = sortRecentData(paginated, "articles", "article_id");
        setData(sorted);
        setError(null);
      }
    } catch (err) {
      console.error("articles fetchData error:", err);
      setError(err.message || "เกิดข้อผิดพลาดในการโหลดข้อมูลบทเรียน");
    } finally {
      setLoading(false);
    }
  };

  // Reset page when category changes
  useEffect(() => {
    setCurrentPage(1);
  }, [selectedCategory]);

  useEffect(() => {
    const delayDebounceFn = setTimeout(() => {
      fetchData(currentPage, search, selectedCategory);
    }, 200);

    return () => clearTimeout(delayDebounceFn);
  }, [currentPage, search, selectedCategory]);

  useEffect(() => {
    // Real-time subscription
    const channel = supabase
      .channel("articles")
      .on("postgres_changes",
        { event: "*", schema: "public", table: "articles" },
        () => fetchData(currentPage, search, selectedCategory)
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [currentPage, search, selectedCategory]);

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
      setSuccessText("เพิ่มเนื้อหาการเรียนรู้เรียบร้อยแล้ว");
      setShowSuccess(true);

      // Update state locally (prepend)
      if (insertedItem) {
        trackRecentActivity("articles", insertedItem.article_id);
        setData((prev) => sortRecentData([insertedItem, ...prev], "articles", "article_id"));
      }
      fetchData();
    } catch (err) {
      alert("Error adding article: " + err.message);
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
      const res = await fetch(
        `${BASE}/endpoints/articles_api.php?action=update&id=${form.id}`,
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
      setSuccessText("แก้ไขข้อมูลเรียบร้อยแล้ว");
      setShowSuccess(true);

      // Update state locally (prepend updated item)
      if (updatedItem) {
        trackRecentActivity("articles", updatedItem.article_id);
        setData((prev) => {
          const filtered = prev.filter((item) => (item.article_id || item.id) !== (updatedItem.article_id || updatedItem.id));
          return sortRecentData([updatedItem, ...filtered], "articles", "article_id");
        });
      }
      fetchData();
    } catch (err) {
      alert("Error updating article: " + err.message);
    } finally {
      setSubmitting(false);
    }
  };

  /* ===== DELETE ===== */
  const handleDelete = async () => {
    try {
      setLoading(true);
      const res = await fetch(
        `${BASE}/endpoints/articles_api.php?action=delete&id=${articles[deleteIndex].id}`,
        { method: "POST" }
      );
      const { error: resError } = await res.json();
      if (resError) throw resError;

      setShowDelete(false);
      setDeleteIndex(null);
      setSuccessText("ลบข้อมูลเรียบร้อยแล้ว");
      setShowSuccess(true);
      fetchData();
    } catch (err) {
      alert("Error deleting article: " + err.message);


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

  const filteredCharCategories = form.learning_category_code
    ? charCategories.filter((c) => c.learning_category_code === form.learning_category_code)
    : charCategories;

  return (
    <div className="p-6 bg-[#f9f7f4] min-h-screen">
      {/* HEADER CARD BANNER */}
      <div className="bg-orange-50/70 border border-orange-100 rounded-2xl p-6 mb-6 flex flex-col md:flex-row md:items-center justify-between gap-4 shadow-sm">
        <div className="flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-orange-100 flex items-center justify-center text-orange-600 shrink-0">
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
          className={`flex items-center gap-2 ${colors.button} text-white px-5 py-2.5 rounded-xl shadow transition font-semibold shrink-0`}
        >
          <Plus size={18} /> เพิ่มเนื้อหาการเรียนรู้
        </button>
      </div>

      {/* SEARCH & FILTER */}
      <div className="flex flex-col sm:flex-row gap-4 mb-6">
        <div className="relative flex-1">
          <Search className="w-4 h-4 text-gray-400 absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
          <input
            className={`w-full pl-10 pr-4 py-2 border rounded-xl focus:outline-none focus:ring-2 ${colors.ringFocus} bg-white text-sm`}
            placeholder="ค้นหาหัวข้อเนื้อหา..."
            value={search}
            onChange={(e) => {
              setSearch(e.target.value);
              setCurrentPage(1);
            }}
          />
        </div>
        <div className="w-full sm:w-64">
          <select
            className={`w-full px-4 py-2 border rounded-xl focus:outline-none focus:ring-2 ${colors.ringFocus} bg-white cursor-pointer text-sm`}
            value={selectedCategory}
            onChange={(e) => {
              setSelectedCategory(e.target.value);
              setCurrentPage(1);
            }}
          >
            <option value="all">ทั้งหมด</option>
            {learningCategories.map((cat) => (
              <option key={cat.category_code} value={cat.category_code}>
                {cat.title}
              </option>
            ))}
          </select>
        </div>
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
                <th className="th-num">#</th>
                <th className="th-left w-[25%]">หัวข้อเนื้อหา</th>
                <th className="w-[15%]">หมวดหมู่การเรียนรู้</th>
                <th className="th-left w-[45%]">รายละเอียดเนื้อหา</th>
                <th className="w-[15%]">หมวดหมู่อักขระ</th>
                <th>จัดการ</th>
              </tr>
            </thead>
            <tbody>
              {paginatedArticles.map((a, i) => (
                <tr key={a.id || i}>
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
