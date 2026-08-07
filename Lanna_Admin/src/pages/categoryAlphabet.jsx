import { useState, useEffect } from "react";
import { Plus, Pencil, Trash2 } from "lucide-react";
import { supabase } from "../lib/supabaseClient";
import Pagination from "../components/Pagination.jsx";

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
export default function CategoryAlphabet() {
  const colors = categoryColors.categoryVocab;
  const ITEMS_PER_PAGE = 10;

  /* ===== STATES ===== */
  const [data, setData] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [totalCount, setTotalCount] = useState(0)

  const [search, setSearch] = useState("");
  const [currentPage, setCurrentPage] = useState(1);

  const [showAdd, setShowAdd] = useState(false);
  const [showEdit, setShowEdit] = useState(false);
  const [originalForm, setOriginalForm] = useState(null);

  const [showDelete, setShowDelete] = useState(false);
  const [deleteItem, setDeleteItem] = useState(null);

  const [form, setForm] = useState({ name: "" });
  const [errors, setErrors] = useState({});

  const [showSuccess, setShowSuccess] = useState(false);
  const [successText, setSuccessText] = useState("");

  const fetchData = async (page = currentPage, searchQuery = search) => {
    setLoading(true)
    try {
      let query = supabase
        .from("category_vocab")
        .select("category_vocab_id, name", { count: "exact" });

      if (searchQuery.trim() !== "") {
        query = query.ilike("name", `%${searchQuery}%`);
      }

      query = query.order("category_vocab_id", { ascending: false });

      const from = (page - 1) * ITEMS_PER_PAGE;
      const to = from + ITEMS_PER_PAGE - 1;
      query = query.range(from, to);

      const { data: resData, error: resError, count } = await query;
      if (resError) throw resError;

      if (page > 1 && (!resData || resData.length === 0)) {
        setCurrentPage(page - 1);
      } else {
        const sorted = sortRecentData(resData || [], "category_vocab", "category_vocab_id");
        setData(sorted);
        setTotalCount(count || 0);
        setError(null);
      }
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    const delayDebounceFn = setTimeout(() => {
      fetchData(currentPage, search);
    }, 200);

    return () => clearTimeout(delayDebounceFn);
  }, [currentPage, search]);

  useEffect(() => {
    // Real-time subscription
    const channel = supabase
      .channel('category_vocab')
      .on('postgres_changes', 
        { event: '*', schema: 'public', table: 'category_vocab' },
        () => fetchData(currentPage, search)
      )
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  }, [currentPage, search])

  const displayData = (data || []).map((item) => ({
    id: item.category_vocab_id,
    name: item.name || "",
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
        `${BASE}/endpoints/category_vocab_api.php?action=create`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ name: form.name }),
        }
      );
      const resJson = await res.json();
      const { data: insertedItem, error: resError } = resJson;
      if (resError) throw resError;

      setShowAdd(false);
      setForm({ name: "" });
      setErrors({});
      setSuccessText("เพิ่มหมวดหมู่เรียบร้อยแล้ว");
      setShowSuccess(true);

      // Prepend to state
      if (insertedItem) {
        trackRecentActivity("category_vocab", insertedItem.category_vocab_id);
        setData((prev) => sortRecentData([insertedItem, ...prev], "category_vocab", "category_vocab_id"));
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
    setForm(item);
    setOriginalForm(item);
    setShowEdit(true);
  };

  const handleEdit = async (e) => {
    e.preventDefault();
    if (!validateForm()) return;

    try {
      setLoading(true);
      const res = await fetch(
        `${BASE}/endpoints/category_vocab_api.php?action=update&id=${encodeURIComponent(originalForm.id)}`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ name: form.name }),
        }
      );
      const resJson = await res.json();
      const { data: updatedItem, error: resError } = resJson;
      if (resError) throw resError;

      setShowEdit(false);
      setOriginalForm(null);
      setSuccessText("แก้ไขหมวดหมู่เรียบร้อยแล้ว");
      setShowSuccess(true);

      // Prepend to state
      if (updatedItem) {
        trackRecentActivity("category_vocab", updatedItem.category_vocab_id);
        setData((prev) => {
          const filtered = prev.filter((item) => (item.category_vocab_id || item.id) !== (updatedItem.category_vocab_id || updatedItem.id));
          return sortRecentData([updatedItem, ...filtered], "category_vocab", "category_vocab_id");
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
    showEdit && originalForm && form.name !== originalForm.name;

  /* ===== DELETE (SQL API) ===== */
  const handleDelete = async () => {
    try {
      setLoading(true);
      const categoryId = deleteItem.category_vocab_id || deleteItem.id;

      const res = await fetch(
        `${BASE}/endpoints/category_vocab_api.php?action=delete&id=${encodeURIComponent(categoryId)}`,
        { method: "POST" }
      );
      const resJson = await res.json();
      if (resJson.error) {
        const errMsg = typeof resJson.error === 'string' ? resJson.error : (resJson.error.message || 'ไม่สามารถลบข้อมูลได้');
        throw new Error(errMsg);
      }

      setShowDelete(false);
      setDeleteItem(null);
      setSuccessText("ลบหมวดหมู่คำศัพท์เรียบร้อยแล้ว");
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
      {/* HEADER */}
      <div className="flex justify-between items-center mb-4">
          <div>
            <h1 className={`text-[26px] font-bold ${colors.title}`}>จัดการหมวดหมู่คำศัพท์</h1>
            <p className="text-sm text-gray-500 mt-1">
              สร้างและดูแลหมวดหมู่สำหรับจัดกลุ่มคำศัพท์ล้านนา
            </p>
          </div>
          <button
            onClick={() => {
              setForm({ name: "" });
              setErrors({});
              setShowEdit(false);
              setShowAdd(true);
            }}
            className={`flex items-center gap-2 ${colors.button} text-white px-4 py-2.5 rounded-lg font-semibold shadow-md transition`}
          >
            <Plus size={18} />
            เพิ่มหมวดหมู่
          </button>
        </div>

      {/* SEARCH */}
      <input
        className="w-full mb-4 px-4 py-2 border rounded-lg"
        placeholder="ค้นหาหมวดหมู่คำศัพท์..."
        value={search}
        onChange={(e) => {
          setSearch(e.target.value);
          setCurrentPage(1);
        }}
      />

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
                <th className="th-num">#</th>
                <th className="th-left">ชื่อหมวดหมู่</th>
                <th>จัดการ</th>
              </tr>
            </thead>

            <tbody>
              {paginatedData.map((d, i) => (
                <tr key={d.id || i}>
                  <td className="td-num">
                    <span className={`lanna-seq ${colors.seqBg} ${colors.seqText} ${colors.seqBgHover} ${colors.seqTextHover}`}>
                      {(currentPage - 1) * ITEMS_PER_PAGE + i + 1}
                    </span>
                  </td>
                  <td className="lanna-cell-main">{d.name}</td>
                  <td>
                    <div className="lanna-btn-actions">
                      <button onClick={() => openEdit(d)} className="lanna-btn-edit" title="แก้ไข">
                        <Pencil size={15} />
                      </button>
                      <button
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
                  <td colSpan={3}>
                    <div className="lanna-empty">
                      <svg className="lanna-empty-icon" fill="none" stroke="currentColor" strokeWidth="1.5" viewBox="0 0 24 24" style={{width:40,height:40}}>
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
              <input
                placeholder="ชื่อหมวดหมู่"
                value={form.name}
                onChange={(e) => setForm({ name: e.target.value })}
                className={`w-full border rounded-xl px-4 py-3 ${
                  errors.name ? "border-red-500" : ""
                }`}
              />

              {errors.name && (
                <p className="text-red-500 text-sm">{errors.name}</p>
              )}
            </div>

            {/* STICKY FOOTER */}
            <div className="px-6 py-4 border-t border-gray-100 bg-gray-50 flex-shrink-0">
              <button
                disabled={showAdd ? !form.name : !isFormChanged}
                className={`w-full py-3 rounded-xl font-semibold transition-all ${
                  (showAdd && !form.name) || (showEdit && !isFormChanged)
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
