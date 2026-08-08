import { useState, useEffect } from "react";
import { Plus, Pencil, Trash2, Search, Type, RotateCcw } from "lucide-react";
import { useSearchParams } from "react-router-dom";
import { supabase } from "../lib/supabaseClient";
import Pagination from "../components/Pagination.jsx";
import { normalizeLannaText } from "../lib/lannaNormalizer.js";
import { trackRecentActivity, sortRecentData } from "../lib/recentActivity.js";
import { getCategoryStyle } from "../lib/categoryColors.js";
import LannaText from "../components/LannaText.jsx";
import { loadLannaMap, convertThaiToLanna } from "../lib/thaiToLanna.js";
import { SuccessModal, ConfirmDeleteModal } from "../components/AlertModals.jsx";

const getApiBase = () => {
  if (typeof window !== 'undefined' && window.location.hostname === 'siripaporn.lnw.mn') {
    return 'https://siripaporn.lnw.mn';
  }
  return import.meta.env.VITE_API_BASE_URL || 'https://siripaporn.lnw.mn';
};
const BASE = getApiBase();
import { categoryColors, getCategoryBadgeStyle } from "../lib/categoryColors";

/* ===== THAI → LANNA (จาก data เดิม) =====
   $\checkmark$ รองรับ token หลายตัวอักษร เช่น "อา", "ไม้เอก"
   - จับแบบยาวที่สุดก่อน (greedy longest match)
   - ถ้าแปลงไม่ได้ → return null
 */
const thaiToLannaFromData = (text, data) => {
  if (!text) return "";

  // เตรียมรายการ token ไทย เรียงจากยาว → สั้น
  const tokens = [...data]
    .filter((d) => d.th && d.ln)
    .sort((a, b) => b.th.length - a.th.length);

  let out = "";
  let i = 0;

  while (i < text.length) {
    let matched = null;

    for (const t of tokens) {
      if (text.startsWith(t.th, i)) {
        matched = t;
        break;
      }
    }

    if (!matched) return null; // เจอตัวที่ไม่รองรับ
    out += matched.ln;
    i += matched.th.length;
  }

  return out;
};

import Modal from "../components/Modal.jsx";

/* ================= PAGE ================= */
export default function AlphabetPage() {
  const colors = categoryColors.alphabet;
  /* ===== DATA ===== */
  const [data, setData] = useState([])
  const [categories, setCategories] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [lannaMap, setLannaMap] = useState([])
  const [totalCount, setTotalCount] = useState(0)

  const [selectedCategory, setSelectedCategory] = useState("all");
  const [search, setSearch] = useState("");
  const [currentPage, setCurrentPage] = useState(1);
  const ITEMS_PER_PAGE = 10;

  const fetchData = async (page = currentPage, categoryId = selectedCategory, searchQuery = search) => {
    setLoading(true);
    try {
      let list = [];
      try {
        const res = await fetch(`${BASE}/endpoints/lanna_char_api.php?action=getAll`);
        const json = await res.json();
        list = json.data || [];
      } catch (e) {
        console.warn("MySQL PHP API fetch error, falling back to Supabase:", e);
      }

      if (!Array.isArray(list) || list.length === 0) {
        const { data: resData } = await supabase
          .from("lanna_char")
          .select(`
            char_id, lanna_char, thai_equivalent, category_char_id,
            category_lanna_char ( category_char_id, name, learning_category_code )
          `);
        list = resData || [];
      }

      // Filter by category
      if (categoryId && categoryId !== "all") {
        list = list.filter((item) => String(item.category_char_id) === String(categoryId));
      }

      // Filter by search query
      if (searchQuery.trim() !== "") {
        const q = searchQuery.trim().toLowerCase();
        list = list.filter((item) => 
          (item.lanna_char && item.lanna_char.toLowerCase().includes(q)) ||
          (item.thai_equivalent && item.thai_equivalent.toLowerCase().includes(q)) ||
          (item.char_id && item.char_id.toLowerCase().includes(q))
        );
      }

      // Sort recent added/edited items to top of entire dataset
      const sortedList = sortRecentData(list, "lanna_char", "char_id");
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
      console.error("fetchData error:", err);
      setError(err.message || "เกิดข้อผิดพลาดในการโหลดข้อมูลอักขระ");
    } finally {
      setLoading(false);
    }
  };

  const fetchCharCategories = async () => {
    try {
      const res = await fetch(`${BASE}/endpoints/category_lanna_char_api.php?action=getAll`);
      const json = await res.json();
      if (json.data && Array.isArray(json.data) && json.data.length > 0) {
        setCategories(json.data);
      } else {
        const { data: catData } = await supabase
          .from("category_lanna_char")
          .select("category_char_id, name, learning_category_code");
        setCategories(catData || []);
      }
    } catch (err) {
      console.error("Error fetching categories:", err);
    }
  };

  // Reset page when category changes
  useEffect(() => {
    setCurrentPage(1);
  }, [selectedCategory]);

  // Fetch data on dependency changes (debounced search input)
  useEffect(() => {
    const delayDebounceFn = setTimeout(() => {
      fetchData(currentPage, selectedCategory, search);
    }, 200);

    return () => clearTimeout(delayDebounceFn);
  }, [currentPage, selectedCategory, search]);

  useEffect(() => {
    fetchCharCategories();
    
    const fetchLannaMap = async () => {
      const map = await loadLannaMap();
      setLannaMap(map);
    };
    fetchLannaMap();
    
    // Real-time subscription for Lanna characters
    const channel = supabase
      .channel('lanna_char')
      .on('postgres_changes', 
        { event: '*', schema: 'public', table: 'lanna_char' },
        () => fetchData(currentPage, selectedCategory, search)
      )
      .subscribe()

    // Real-time subscription for Lanna character categories
    const catChannel = supabase
      .channel('category_lanna_char')
      .on('postgres_changes', 
        { event: '*', schema: 'public', table: 'category_lanna_char' },
        () => fetchCategories()
      )
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
      supabase.removeChannel(catChannel)
    }
  }, [currentPage, selectedCategory, search])


  const displayData = (data || []).map((item, idx) => ({
    id: item.char_id || item.id || idx,
    ln: item.lanna_char || item.lanna_word || item.ln || "",
    th: item.thai_equivalent || item.thai_word || item.thai_char || item.th || "",
    category: item.category_lanna_char?.name || "ไม่ระบุหมวดหมู่",
    category_char_id: item.category_char_id || "",
    ...item
  }));

  const [showAdd, setShowAdd] = useState(false);
  const [showEdit, setShowEdit] = useState(false);
  const [originalForm, setOriginalForm] = useState(null);

  const [showSuccess, setShowSuccess] = useState(false);
  const [successText, setSuccessText] = useState("");

  const [showDelete, setShowDelete] = useState(false);
  const [deleteItem, setDeleteItem] = useState(null);

  const [form, setForm] = useState({
    ln: "",
    th: "",
    category_char_id: "",
  });

  // ✅ เพิ่ม state ช่องพิมพ์ไทย (ช่องบน)
  const [thaiDraft, setThaiDraft] = useState("");

  const [errors, setErrors] = useState({});

  const handleConvert = () => {
    if (!form.th) return;
    const converted = convertThaiToLanna(form.th, lannaMap);
    const normalized = normalizeLannaText(converted);
    setForm((prev) => ({
      ...prev,
      ln: normalized
    }));
  };

  /* ===== PAGINATION ===== */
  const totalPages = Math.ceil(totalCount / ITEMS_PER_PAGE);
  const paginatedData = displayData;

  const validateForm = () => {
    const newErrors = {};
    if (!form.ln.trim()) newErrors.ln = "กรุณากรอกอักขระล้านนา";
    if (!form.th.trim()) newErrors.th = "กรุณากรอกอักขระไทย";
    if (!form.category_char_id) newErrors.category_char_id = "กรุณาเลือกหมวดหมู่";

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  /* ===== ADD ===== */
  const handleAdd = async (e) => {
    e.preventDefault();

    if (!validateForm()) {
      setSuccessText("กรอกข้อมูลให้ครบ");
      setShowSuccess(true);
      return;
    }

    try {
      setLoading(true);
      const res = await fetch(
        `${BASE}/endpoints/lanna_char_api.php?action=create`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            lanna_char: form.ln,
            thai_equivalent: form.th,
            category_char_id: form.category_char_id
          }),
        }
      );
      const resJson = await res.json();
      const { data: insertedChar, error: resError } = resJson;
      if (resError) throw resError;

      setShowAdd(false);
      setErrors({});
      setThaiDraft("");
      setSuccessText("เพิ่มอักขระเรียบร้อยแล้ว");
      setShowSuccess(true);

      // Prepend to state
      const charId = insertedChar?.char_id || resJson?.data?.char_id;
      if (charId) {
        trackRecentActivity("lanna_char", charId);
      }
      setCurrentPage(1);
      fetchData(1);
    } catch (err) {
      alert("Error adding Lanna char: " + err.message);
    } finally {
      setLoading(false);
    }
  };

  /* ===== EDIT ===== */
  const openEdit = (item) => {
    setForm({
      ln: item.lanna_char || item.lanna_word || item.ln || "",
      th: item.thai_equivalent || item.thai_word || item.th || "",
      category_char_id: item.category_char_id || "",
    });
    setOriginalForm(item);
    setThaiDraft(item.thai_equivalent || item.thai_word || item.th || ""); // ✅ เติมไทยกลับในช่องบน
    setErrors({});
    setShowEdit(true);
  };

  const handleEdit = async (e) => {
    e.preventDefault();
    if (!validateForm()) return;

    try {
      const targetId = originalForm.char_id || originalForm.id;
      const res = await fetch(
        `${BASE}/endpoints/lanna_char_api.php?action=update&id=${encodeURIComponent(targetId)}`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            lanna_char: form.ln,
            thai_equivalent: form.th,
            category_char_id: form.category_char_id
          }),
        }
      );
      const resJson = await res.json();
      const { data: updatedChar, error: resError } = resJson;
      if (resError) throw resError;

      setShowEdit(false);
      setOriginalForm(null);
      setThaiDraft("");
      setErrors({});
      setSuccessText("แก้ไขอักขระเรียบร้อยแล้ว");
      setShowSuccess(true);

      // Update state locally (prepend)
      const editCharId = updatedChar?.char_id || targetId;
      trackRecentActivity("lanna_char", editCharId);
      setCurrentPage(1);
      fetchData(1);
    } catch (err) {
      alert("Error updating Lanna char: " + err.message);
    } finally {
      setLoading(false);
    }
  };

  const isFormChanged =
    showEdit &&
    originalForm &&
    (form.th !== (originalForm.thai_equivalent || originalForm.thai_word || originalForm.th || "") ||
      form.ln !== (originalForm.lanna_char || originalForm.lanna_word || originalForm.ln || "") ||
      form.category_char_id !== (originalForm.category_char_id || ""));

  /* ===== DELETE ===== */
  const handleDelete = async () => {
    try {
      setLoading(true);
      const res = await fetch(
        `${BASE}/endpoints/lanna_char_api.php?action=delete&id=${encodeURIComponent(deleteItem.id)}`,
        { method: "POST" }
      );
      const { error: resError } = await res.json();
      if (resError) throw resError;

      setShowDelete(false);
      setDeleteItem(null);
      setSuccessText("ลบอักขระเรียบร้อยแล้ว");
      setShowSuccess(true);
      fetchData();
    } catch (err) {
      alert("Error deleting Lanna char: " + err.message);
    } finally {
      setLoading(false);
    }
  };

  const currentCategoryName = selectedCategory === "all" 
    ? "ทั้งหมด" 
    : (categories.find(c => c.category_char_id === selectedCategory)?.name || "กำลังโหลด...");

  return (
    <div className="p-6 bg-[#f9f7f4] min-h-screen">
      {/* HEADER CARD BANNER */}
      <div className="bg-emerald-50/70 border border-emerald-200 rounded-2xl p-6 mb-6 flex flex-col md:flex-row md:items-center justify-between gap-4 shadow-sm">
        <div className="flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-emerald-100 flex items-center justify-center text-emerald-700 shrink-0">
            <Type className="w-6 h-6" />
          </div>
          <div>
            <h1 className="text-xl font-bold text-gray-900">จัดการข้อมูลอักขระ</h1>
            <p className="text-sm text-gray-500 mt-0.5">เพิ่ม แก้ไข และจัดการข้อมูลอักขระล้านนา</p>
          </div>
        </div>
        <button
          onClick={() => {
            setForm({ ln: "", th: "", category_char_id: "" });
            setThaiDraft("");
            setErrors({});
            setShowEdit(false);
            setShowAdd(true);
          }}
          className="flex items-center gap-2 bg-emerald-600 hover:bg-emerald-700 text-white px-5 py-2.5 rounded-xl font-semibold shadow-md transition shrink-0"
        >
          <Plus size={18} /> เพิ่มอักขระ
        </button>
      </div>

      {/* SEARCH & FILTER (Image 1 Format) */}
      <div className="bg-white p-4 rounded-2xl border border-gray-100 shadow-sm flex flex-col sm:flex-row items-center gap-3 mb-6">
        <div className="relative flex-1 w-full flex items-center">
          <Search className="w-4 h-4 text-gray-400 absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none z-10" />
          <input
            className="w-full admin-search-input pr-4 py-2.5 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 bg-white text-sm relative z-0"
            placeholder="ค้นหาอักขระ หรือชื่อ..."
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
            className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 bg-white cursor-pointer text-sm"
            value={selectedCategory}
            onChange={(e) => {
              setSelectedCategory(e.target.value);
              setCurrentPage(1);
            }}
          >
            <option value="all">ทั้งหมด</option>
            {categories.map((cat) => (
              <option key={cat.category_char_id} value={cat.category_char_id}>
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
          <div className={`animate-spin rounded-full h-10 w-10 border-t-2 border-b-2 ${colors.borderCol}`}></div>
        </div>
      ) : error ? (
        <div className="p-12 text-center text-red-600 bg-white rounded-xl shadow-sm border border-red-200">
          <p className="font-bold text-lg">เกิดข้อผิดพลาดในการโหลดข้อมูล</p>
          <p className="text-sm mt-1">{error}</p>
          <button
            onClick={fetchData}
            className={`mt-4 px-4 py-2 ${colors.primaryBg} ${colors.primaryBgHover} text-white rounded-lg transition`}
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
                <th className="whitespace-nowrap">อักขระล้านนา</th>
                <th className="whitespace-nowrap">อักขระไทย</th>
                <th className="whitespace-nowrap">หมวดหมู่</th>
                <th className="whitespace-nowrap">จัดการ</th>
              </tr>
            </thead>
            <tbody>
              {paginatedData.map((d, i) => (
                <tr key={d.id || i} className="hover:bg-emerald-50/60 transition-colors">
                  <td className="td-num">
                    <span className={`lanna-seq ${colors.seqBg} ${colors.seqText} ${colors.seqBgHover} ${colors.seqTextHover}`}>
                      {(currentPage - 1) * ITEMS_PER_PAGE + i + 1}
                    </span>
                  </td>

                  {/* ✅ ใส่ฟอนต์ล้านนาให้แน่นอน */}
                  <td className="text-2xl text-left">
                    <LannaText>{d.ln}</LannaText>
                  </td>

                  <td className="text-left lanna-cell-main">{d.th}</td>

                  <td className="text-left">
                    {(() => {
                      const categoryName = d.category || "ไม่ระบุหมวดหมู่";
                      const badgeStyle = getCategoryBadgeStyle(categoryName);
                      return (
                        <span className="lanna-badge" style={{ backgroundColor: badgeStyle.bg, color: badgeStyle.text, borderColor: badgeStyle.border }}>
                          <span className="lanna-badge-dot" style={{ backgroundColor: badgeStyle.dot }} />
                          {categoryName}
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
                  <td colSpan={5}>
                    <div className="lanna-empty">
                      <svg className="lanna-empty-icon" fill="none" stroke="currentColor" strokeWidth="1.5" viewBox="0 0 24 24" style={{width:40,height:40}}>
                        <path strokeLinecap="round" strokeLinejoin="round" d="M4.5 12.75l6 6 9-13.5" />
                      </svg>
                      <p className="lanna-empty-title">ยังไม่มีข้อมูลอักขระ</p>
                      <p className="lanna-empty-sub">เลือกหมวดหมู่แล้วกด "เพิ่มอักขระ" เพื่อเริ่มต้น</p>
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
      )}

      {/* ADD / EDIT MODAL */}
      {(showAdd || showEdit) && (
        <Modal
          title={showAdd ? "เพิ่มอักขระล้านนา" : "แก้ไขอักขระล้านนา"}
          onClose={() => {
            setShowAdd(false);
            setShowEdit(false);
            setOriginalForm(null);
            setErrors({});
            setThaiDraft("");
            setForm({ ln: "", th: "", category_char_id: "" });
          }}
        >
          <form
            onSubmit={showAdd ? handleAdd : handleEdit}
            className="flex flex-col flex-1 overflow-hidden"
          >
            {/* SCROLLABLE BODY */}
            <div className="p-6 overflow-y-auto space-y-6 flex-1">
              {/* ✅ อักขระไทย */}
              <div>
                <label className="text-sm font-medium">อักขระไทย</label>
                <input
                  value={form.th}
                  placeholder="ตัวอย่าง: ก (ก๋ะ)"
                  onChange={(e) => {
                    const thai = e.target.value;
                    setForm((prev) => ({ ...prev, th: thai }));
                    setErrors((prev) => ({ ...prev, th: null }));
                  }}
                  className={`mt-1 w-full border rounded-xl px-4 py-3 ${
                    errors.th ? "border-red-500" : ""
                  }`}
                />
                {errors.th && <p className="text-red-500 text-sm mt-1">{errors.th}</p>}
              </div>

              {/* ✅ อักขระล้านนา (แสดงด้วยฟอนต์ LannaAkkhara) พร้อมปุ่มแปลงจากไทย */}
              <div>
                <label className="text-sm font-medium">อักขระล้านนา</label>
                <div className="flex gap-2 mt-1 items-center">
                  <input
                    value={form.ln}
                    placeholder="พิมพ์เอง หรือกดปุ่มแปลงด้านขวา"
                    className={`flex-1 min-w-0 border rounded-xl px-4 py-3 text-2xl lanna-text ${
                      errors.ln ? "border-red-500" : ""
                    }`}
                    onChange={(e) => {
                      const lannaText = e.target.value;
                      const normalized = normalizeLannaText(lannaText);
                      setForm((prev) => ({ ...prev, ln: normalized }));
                      setErrors((prev) => ({ ...prev, ln: null }));
                    }}
                  />
                  <button
                    type="button"
                    onClick={handleConvert}
                    className={`${colors.primaryBg} ${colors.primaryBgHover} text-white font-medium px-4 py-2 rounded-lg transition shrink-0 text-sm`}
                  >
                    แปลงจากไทย
                  </button>
                </div>
                <p className="text-red-500 text-xs mt-1.5 font-normal leading-relaxed">
                  * ผู้ใช้ต้องกดปุ่มนี้ทุกครั้ง ที่มีการแก้ไขอักขระไทย เพื่อให้อักขระล้านนาถูกแปลงใหม่
                </p>
                {form.ln && /[\u0E00-\u0E7F]/.test(form.ln) && (
                  <p className="text-yellow-600 text-sm mt-1 font-medium">
                    ⚠️ กรุณาตรวจสอบผลการแปลงก่อนบันทึก
                  </p>
                )}
                {errors.ln && <p className="text-red-500 text-sm mt-1">{errors.ln}</p>}
              </div>

              <div>
                <select
                  value={form.category_char_id}
                  onChange={(e) => {
                    setForm({ ...form, category_char_id: e.target.value });
                    setErrors((prev) => ({ ...prev, category_char_id: null }));
                  }}
                  className={`w-full border rounded-xl px-4 py-3
            ${errors.category_char_id ? "border-red-500" : ""}`}
                >
                  <option value="" disabled>
                    เลือกหมวดหมู่
                  </option>
                  {categories.map((c) => (
                    <option key={c.category_char_id} value={c.category_char_id}>
                      {c.name}
                    </option>
                  ))}
                </select>
                {errors.category_char_id && (
                  <p className="text-red-500 text-sm">{errors.category_char_id}</p>
                )}
              </div>
            </div>

            {/* STICKY FOOTER */}
            <div className="px-6 py-4 border-t border-gray-100 bg-gray-50 flex-shrink-0">
              <button
                disabled={
                  showAdd
                    ? !form.th || !form.ln || !form.category_char_id
                    : showEdit && !isFormChanged
                }
                className={`w-full py-3 rounded-xl font-semibold transition-all ${
                  (showAdd && (!form.th || !form.ln || !form.category_char_id)) ||
                  (showEdit && !isFormChanged)
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
        title="ยืนยันการลบอักขระ"
        itemName={deleteItem?.ln || deleteItem?.lanna_char || ""}
        itemSubtitle={deleteItem?.th || deleteItem?.thai_equivalent || ""}
        itemType="ข้อมูลอักขระ"
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
