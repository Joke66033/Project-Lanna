import { useState, useEffect } from "react";
import { Plus, Pencil, Trash2, Search, RotateCcw } from "lucide-react";
import { supabase } from "../lib/supabaseClient";
import Pagination from "../components/Pagination.jsx";
import LearningCategorySelect from "../components/LearningCategorySelect.jsx";

const getApiBase = () => {
  if (typeof window !== 'undefined' && window.location.hostname === 'siripaporn.lnw.mn') {
    return 'https://siripaporn.lnw.mn';
  }
  return import.meta.env.VITE_API_BASE_URL || 'https://siripaporn.lnw.mn';
};
const BASE = getApiBase();
import { trackRecentActivity, sortRecentData } from "../lib/recentActivity.js";
import { SuccessModal, ConfirmDeleteModal } from "../components/AlertModals.jsx";

import Modal from "../components/Modal.jsx";
import { categoryColors, getCategoryBadgeStyle } from "../lib/categoryColors";

/* ================= PAGE ================= */
export default function CategoryLannaChar() {
  const colors = categoryColors.categoryAlphabet;
  const ITEMS_PER_PAGE = 10;

  /* ===== STATES ===== */
  const [data, setData] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [totalCount, setTotalCount] = useState(0)

  const [search, setSearch] = useState("");
  const [currentPage, setCurrentPage] = useState(1);

  const [deleteIndex, setDeleteIndex] = useState(null);

  const [showAdd, setShowAdd] = useState(false);
  const [showEdit, setShowEdit] = useState(false);
  const [originalForm, setOriginalForm] = useState(null);

  const [showDelete, setShowDelete] = useState(false);
  const [deleteItem, setDeleteItem] = useState(null);

  const [selectedLearningCategory, setSelectedLearningCategory] = useState("all");
  const [form, setForm] = useState({ name: "", learning_category_code: "" });
  const [errors, setErrors] = useState({});

  const [showSuccess, setShowSuccess] = useState(false);
  const [successText, setSuccessText] = useState("");

  const fetchData = async (page = currentPage, searchQuery = search, learningCat = selectedLearningCategory) => {
    setLoading(true);
    try {
      let list = [];
      try {
        const res = await fetch(`${BASE}/endpoints/category_lanna_char_api.php?action=getAll`);
        const json = await res.json();
        list = json.data || [];
      } catch (e) {
        console.warn("MySQL PHP API fetch error, falling back to Supabase:", e);
      }

      if (!Array.isArray(list) || list.length === 0) {
        const { data: resData } = await supabase
          .from("category_lanna_char")
          .select("category_char_id, name, learning_category_code, learning_category(title)");
        list = resData || [];
      }

      if (searchQuery.trim() !== "") {
        const q = searchQuery.trim().toLowerCase();
        list = list.filter((item) => item.name && item.name.toLowerCase().includes(q));
      }

      if (learningCat !== "all") {
        list = list.filter((item) => String(item.learning_category_code) === String(learningCat));
      }

      // Sort recent added/edited items to top of entire dataset
      const sortedList = sortRecentData(list, "category_lanna_char", "category_char_id");
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
      console.error("categoryLannaChar error:", err);
      setError(err.message || "เกิดข้อผิดพลาดในการโหลดข้อมูลหมวดหมู่อักขระ");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    const delayDebounceFn = setTimeout(() => {
      fetchData(currentPage, search, selectedLearningCategory);
    }, 200);

    return () => clearTimeout(delayDebounceFn);
  }, [currentPage, search, selectedLearningCategory]);

  useEffect(() => {
    // Real-time subscription
    const channel = supabase
      .channel('category_lanna_char')
      .on('postgres_changes',
        { event: '*', schema: 'public', table: 'category_lanna_char' },
        () => fetchData(currentPage, search, selectedLearningCategory)
      )
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  }, [currentPage, search, selectedLearningCategory])

  const displayData = (data || []).map((item) => ({
    id: item.category_char_id,
    name: item.name || "",
    learning_category_code: item.learning_category_code || "",
    learning_category_title: item.learning_category?.title || "—",
  }));

  /* ===== AUTO CLOSE SUCCESS ===== */
  useEffect(() => {
    if (showSuccess) {
      const timer = setTimeout(() => {
        setShowSuccess(false);
      }, 1500);
      return () => clearTimeout(timer);
    }
  }, [showSuccess]);

  const paginatedData = displayData;

  /* ===== VALIDATE ===== */
  const validateForm = () => {
    const newErrors = {};
    if (!form.name.trim()) newErrors.name = "กรุณากรอกชื่อหมวดหมู่";
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
        `${BASE}/endpoints/category_lanna_char_api.php?action=create`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            name: form.name,
            learning_category_code: form.learning_category_code || null,
          }),
        }
      );
      const resJson = await res.json();
      const { data: insertedItem, error: resError } = resJson;
      if (resError) throw resError;

      setShowAdd(false);
      setForm({ name: "", learning_category_code: "" });
      setErrors({});
      setSuccessText("เพิ่มหมวดหมู่เรียบร้อยแล้ว");
      setShowSuccess(true);

      // Prepend to state
      if (insertedItem) {
        trackRecentActivity("category_lanna_char", insertedItem.category_char_id);
        setData((prev) => sortRecentData([insertedItem, ...prev], "category_lanna_char", "category_char_id"));
      }
      fetchData();
    } catch (err) {
      alert("Error adding category: " + err.message);
    } finally {
      setLoading(false);
    }
  };

  /* ===== EDIT ===== */
  const openEdit = (item) => {
    setForm({
      name: item.name || "",
      learning_category_code: item.learning_category_code || "",
    });
    setOriginalForm(item);
    setShowEdit(true);
  };

  const handleEdit = async (e) => {
    e.preventDefault();
    if (!validateForm()) return;

    try {
      setLoading(true);
      const res = await fetch(
        `${BASE}/endpoints/category_lanna_char_api.php?action=update&id=${encodeURIComponent(originalForm.id)}`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            name: form.name,
            learning_category_code: form.learning_category_code || null,
          }),
        }
      );
      const resJson = await res.json();
      const { data: updatedItem, error: resError } = resJson;
      if (resError) throw resError;

      setShowEdit(false);
      setOriginalForm(null);
      setForm({ name: "", learning_category_code: "" });
      setSuccessText("แก้ไขหมวดหมู่เรียบร้อยแล้ว");
      setShowSuccess(true);

      // Prepend to state
      if (updatedItem) {
        trackRecentActivity("category_lanna_char", updatedItem.category_char_id);
        setData((prev) => {
          const filtered = prev.filter((item) => (item.category_char_id || item.id) !== (updatedItem.category_char_id || updatedItem.id));
          return sortRecentData([updatedItem, ...filtered], "category_lanna_char", "category_char_id");
        });
      }
      fetchData();
    } catch (err) {
      alert("Error updating category: " + err.message);
    } finally {
      setLoading(false);
    }
  };

  const isFormChanged =
    showEdit &&
    originalForm &&
    (form.name !== originalForm.name || form.learning_category_code !== originalForm.learning_category_code);

  const [usageInfo, setUsageInfo] = useState(null);

  const openDeleteConfirm = async (item) => {
    setDeleteItem(item);
    setUsageInfo(null);
    try {
      const categoryId = item.category_char_id || item.id;
      const res = await fetch(`${BASE}/endpoints/category_lanna_char_api.php?action=checkUsage&id=${encodeURIComponent(categoryId)}`);
      const json = await res.json();
      if (json.data && json.data.inUse) {
        setUsageInfo(json.data);
      }
    } catch (e) {}
    setShowDelete(true);
  };

  /* ===== DELETE (SQL API) ===== */
  const handleDelete = async () => {
    try {
      setLoading(true);
      const categoryId = deleteItem.category_char_id || deleteItem.id;
      const isCascade = usageInfo && usageInfo.inUse;

      const res = await fetch(
        `${BASE}/endpoints/category_lanna_char_api.php?action=delete&id=${encodeURIComponent(categoryId)}${isCascade ? '&cascade=true' : ''}`,
        { method: "POST" }
      );
      const resJson = await res.json();
      if (resJson.error) {
        const errMsg = typeof resJson.error === 'string' ? resJson.error : (resJson.error.message || 'ไม่สามารถลบข้อมูลได้');
        throw new Error(errMsg);
      }

      setShowDelete(false);
      setDeleteItem(null);
      setUsageInfo(null);
      setDeleteIndex(null);
      setSuccessText("ลบหมวดหมู่อักขระเรียบร้อยแล้ว");
      setShowSuccess(true);
      fetchData();
    } catch (err) {
      alert(err.message || err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="p-6 bg-[#f9f7f4] min-h-screen">
      {/* HEADER CARD BANNER */}
      <div className="bg-cyan-50/70 border border-cyan-200 rounded-2xl p-6 mb-6 flex flex-col md:flex-row md:items-center justify-between gap-4 shadow-sm">
        <div className="flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-cyan-100 flex items-center justify-center text-cyan-700 shrink-0">
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
            </svg>
          </div>
          <div>
            <h1 className="text-xl font-bold text-gray-900">จัดการหมวดหมู่อักขระ</h1>
            <p className="text-sm text-gray-500 mt-0.5">สร้างและดูแลหมวดหมู่สำหรับจัดกลุ่มอักขระล้านนา</p>
          </div>
        </div>
        <button
          onClick={() => {
            setForm({ name: "", learning_category_code: "" });
            setErrors({});
            setShowEdit(false);
            setShowAdd(true);
          }}
          className="flex items-center gap-2 bg-cyan-600 hover:bg-cyan-700 text-white px-5 py-2.5 rounded-xl font-semibold shadow-md transition shrink-0"
        >
          <Plus size={18} />
          เพิ่มหมวดหมู่
        </button>
      </div>

      {/* SEARCH & FILTER (Image 1 Format) */}
      <div className="bg-white p-4 rounded-2xl border border-gray-100 shadow-sm flex flex-col sm:flex-row items-center gap-3 mb-6">
        <div className="relative flex-1 w-full flex items-center">
          <Search className="w-4 h-4 text-gray-400 absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none z-10" />
          <input
            className="w-full admin-search-input pr-4 py-2.5 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-cyan-500/20 focus:border-cyan-500 bg-white text-sm relative z-0"
            placeholder="ค้นหาหมวดหมู่อักขระ..."
            value={search}
            onChange={(e) => {
              setSearch(e.target.value);
              setCurrentPage(1);
            }}
          />
        </div>
        <div className="w-full sm:w-72">
          <LearningCategorySelect
            includeAllOption={true}
            value={selectedLearningCategory}
            onChange={(code) => {
              setSelectedLearningCategory(code);
              setCurrentPage(1);
            }}
            className="w-full text-sm rounded-xl"
          />
        </div>
        <button
          onClick={() => {
            setSearch("");
            setSelectedLearningCategory("all");
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
                <th className="th-num whitespace-nowrap">#</th>
                <th className="th-left whitespace-nowrap">ชื่อหมวดหมู่อักขระ</th>
                <th className="th-left whitespace-nowrap">หมวดหมู่การเรียนรู้</th>
                <th className="whitespace-nowrap">จัดการ</th>
              </tr>
            </thead>

            <tbody>
              {paginatedData.map((d, i) => (
                <tr key={d.id || i} className="hover:bg-amber-50/60 transition-colors">
                  <td className="td-num">
                    <span className={`lanna-seq ${colors.seqBg} ${colors.seqText} ${colors.seqBgHover} ${colors.seqTextHover}`}>
                      {(currentPage - 1) * ITEMS_PER_PAGE + i + 1}
                    </span>
                  </td>
                  <td className="lanna-cell-main">{d.name}</td>
                  <td className="text-left">
                    {(() => {
                      if (!d.learning_category_title) return <span className="text-gray-400 text-sm">—</span>;
                      const badgeStyle = getCategoryBadgeStyle(d.learning_category_title);
                      return (
                        <span className="lanna-badge" style={{ backgroundColor: badgeStyle.bg, color: badgeStyle.text, borderColor: badgeStyle.border }}>
                          <span className="lanna-badge-dot" style={{ backgroundColor: badgeStyle.dot }} />
                          {d.learning_category_title}
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
                        onClick={() => openDeleteConfirm(d)}
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
                  <td colSpan={4}>
                    <div className="lanna-empty">
                      <svg className="lanna-empty-icon" fill="none" stroke="currentColor" strokeWidth="1.5" viewBox="0 0 24 24" style={{ width: 40, height: 40 }}>
                        <path strokeLinecap="round" strokeLinejoin="round" d="M3.75 9.776c.112-.017.227-.026.344-.026h15.812c.117 0 .232.009.344.026m-16.5 0a2.25 2.25 0 00-1.883 2.542l.857 6a2.25 2.25 0 002.227 1.932H19.05a2.25 2.25 0 002.227-1.932l.857-6a2.25 2.25 0 00-1.883-2.542m-16.5 0V6A2.25 2.25 0 016 3.75h3.879a1.5 1.5 0 011.06.44l2.122 2.12a1.5 1.5 0 001.06.44H18A2.25 2.25 0 0120.25 9v.776" />
                      </svg>
                      <p className="lanna-empty-title">ยังไม่มีหมวดหมู่</p>
                      <p className="lanna-empty-sub">กดปุ่ม "เพิ่มหมวดหมู่" เพื่อเริ่มต้น</p>
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
          title={showAdd ? "เพิ่มหมวดหมู่" : "แก้ไขหมวดหมู่"}
          onClose={() => {
            setShowAdd(false);
            setShowEdit(false);
            setOriginalForm(null);
          }}
        >
          <form
            onSubmit={showAdd ? handleAdd : handleEdit}
            className="flex flex-col flex-1 overflow-hidden"
          >
            {/* SCROLLABLE BODY */}
            <div className="p-6 overflow-y-auto space-y-5 flex-1">
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-1.5">ชื่อหมวดหมู่อักขระ *</label>
                <input
                  placeholder="ชื่อหมวดหมู่อักขระ"
                  value={form.name}
                  onChange={(e) => setForm({ ...form, name: e.target.value })}
                  className={`w-full border rounded-xl px-4 py-3 focus:ring-2 ${colors.ringFocus} ${errors.name ? "border-red-500" : "border-gray-300"}`}
                />
                {errors.name && (
                  <p className="text-red-500 text-sm mt-1">{errors.name}</p>
                )}
              </div>

              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-1.5">หมวดหมู่การเรียนรู้</label>
                <LearningCategorySelect
                  value={form.learning_category_code}
                  onChange={(code) => setForm({ ...form, learning_category_code: code })}
                  className="w-full py-3"
                />
              </div>
            </div>

            {/* STICKY FOOTER */}
            <div className="px-6 py-4 border-t border-gray-100 bg-gray-50 flex-shrink-0">
              <button
                disabled={showAdd ? !form.name : !isFormChanged}
                className={`w-full py-3 rounded-xl font-semibold transition-all ${(showAdd && !form.name) || (showEdit && !isFormChanged)
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

      {/* DELETE MODAL */}
      <ConfirmDeleteModal
        isOpen={showDelete}
        onClose={() => setShowDelete(false)}
        onConfirm={handleDelete}
        title="ยืนยันการลบหมวดหมู่"
        itemName={deleteItem?.name || ""}
        usageWarningText={usageInfo?.usedInText || ""}
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
