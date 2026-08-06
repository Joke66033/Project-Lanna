import { useState, useEffect } from "react";
import { Plus, Pencil, Trash2 } from "lucide-react";
import { supabase } from "../lib/supabaseClient";
import Pagination from "../components/Pagination.jsx";
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
import { categoryColors } from "../lib/categoryColors";

/* ================= PAGE ================= */
export default function CategoryLearning() {
  const colors = categoryColors.categoryLearning;
  const ITEMS_PER_PAGE = 10;

  /* ===== STATES ===== */
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [totalCount, setTotalCount] = useState(0);

  const [search, setSearch] = useState("");
  const [currentPage, setCurrentPage] = useState(1);

  const [showAdd, setShowAdd] = useState(false);
  const [showEdit, setShowEdit] = useState(false);
  const [originalForm, setOriginalForm] = useState(null);

  const [showDelete, setShowDelete] = useState(false);
  const [deleteItem, setDeleteItem] = useState(null);

  const [form, setForm] = useState({
    category_code: "",
    title: "",
    description: "",
    is_active: 1,
    total_items: 0,
  });
  const [errors, setErrors] = useState({});

  const [showSuccess, setShowSuccess] = useState(false);
  const [successText, setSuccessText] = useState("");

  const fetchData = async (page = currentPage, searchQuery = search) => {
    setLoading(true);
    try {
      let query = supabase
        .from("learning_category")
        .select("*", { count: "exact" });

      if (searchQuery.trim() !== "") {
        query = query.ilike("title", `%${searchQuery}%`);
      }

      query = query.order("category_code", { ascending: true });

      const from = (page - 1) * ITEMS_PER_PAGE;
      const to = from + ITEMS_PER_PAGE - 1;
      query = query.range(from, to);

      const { data: resData, error: resError, count } = await query;
      if (resError) throw resError;

      if (page > 1 && (!resData || resData.length === 0)) {
        setCurrentPage(page - 1);
      } else {
        const sorted = sortRecentData(resData || [], "learning_category", "category_code");
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
    const channel = supabase
      .channel("learning_category")
      .on("postgres_changes", 
        { event: "*", schema: "public", table: "learning_category" },
        () => fetchData(currentPage, search)
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [currentPage, search]);

  /* ===== AUTO CLOSE SUCCESS ===== */
  useEffect(() => {
    if (showSuccess) {
      const timer = setTimeout(() => {
        setShowSuccess(false);
      }, 1500);
      return () => clearTimeout(timer);
    }
  }, [showSuccess]);

  /* ===== VALIDATE ===== */
  const validateForm = () => {
    const newErrors = {};
    if (!form.title.trim()) newErrors.title = "กรุณากรอกชื่อหมวดหมู่การเรียนรู้";
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  /* ===== ADD ===== */
  const handleAdd = async (e) => {
    e.preventDefault();
    if (!validateForm()) return;

    try {
      setLoading(true);
      const submitData = {
        ...form,
        total_items: parseInt(form.total_items || '0', 10)
      };
      const res = await fetch(
        `${BASE}/endpoints/learning_category_api.php?action=create`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(submitData),
        }
      );
      const resJson = await res.json();
      const { data: insertedItem, error: resError } = resJson;
      if (resError) throw resError;

      setShowAdd(false);
      setForm({ category_code: "", title: "", description: "", is_active: 1, total_items: 0 });
      setErrors({});
      setSuccessText("เพิ่มหมวดหมู่การเรียนรู้เรียบร้อยแล้ว");
      setShowSuccess(true);

      if (insertedItem) {
        trackRecentActivity("learning_category", insertedItem.category_code);
        setData((prev) => sortRecentData([insertedItem, ...prev], "learning_category", "category_code"));
      }
      fetchData();
    } catch (err) {
      alert("เกิดข้อผิดพลาดในการเพิ่มหมวดหมู่: " + err.message);
    } finally {
      setLoading(false);
    }
  };

  /* ===== EDIT ===== */
  const openEdit = (item) => {
    setForm({
      category_code: item.category_code || "",
      title: item.title || "",
      description: item.description || "",
      is_active: item.is_active ? 1 : 0,
      total_items: item.total_items || 0,
    });
    setOriginalForm(item);
    setShowEdit(true);
  };

  const handleEdit = async (e) => {
    e.preventDefault();
    if (!validateForm()) return;

    try {
      setLoading(true);
      const submitData = {
        ...form,
        total_items: parseInt(form.total_items || '0', 10)
      };
      const res = await fetch(
        `${BASE}/endpoints/learning_category_api.php?action=update&id=${encodeURIComponent(originalForm.category_code)}`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(submitData),
        }
      );
      const resJson = await res.json();
      const { data: updatedItem, error: resError } = resJson;
      if (resError) throw resError;

      setShowEdit(false);
      setOriginalForm(null);
      setSuccessText("แก้ไขข้อมูลหมวดหมู่เรียบร้อยแล้ว");
      setShowSuccess(true);

      if (updatedItem) {
        trackRecentActivity("learning_category", updatedItem.category_code);
        setData((prev) => {
          const filtered = prev.filter((item) => item.category_code !== updatedItem.category_code);
          return sortRecentData([updatedItem, ...filtered], "learning_category", "category_code");
        });
      }
      fetchData();
    } catch (err) {
      alert("เกิดข้อผิดพลาดในการแก้ไขหมวดหมู่: " + err.message);
    } finally {
      setLoading(false);
    }
  };

  const isFormChanged =
    showEdit &&
    originalForm &&
    (form.title !== originalForm.title ||
      form.description !== originalForm.description ||
      form.is_active !== (originalForm.is_active ? 1 : 0) ||
      (parseInt(form.total_items) || 0) !== (parseInt(originalForm.total_items) || 0));

  /* ===== DELETE (SQL API) ===== */
  const handleDelete = async () => {
    try {
      setLoading(true);
      const code = deleteItem.category_code;

      // Call PHP SQL API endpoint to perform cascade delete on MySQL DB
      const res = await fetch(
        `${BASE}/endpoints/learning_category_api.php?action=delete&id=${encodeURIComponent(code)}`,
        { method: "POST" }
      );
      const resJson = await res.json();
      if (resJson.error) throw new Error(resJson.error.message || resJson.error);

      setShowDelete(false);
      setSuccessText("ลบหมวดหมู่การเรียนรู้และข้อมูลย่อยทั้งหมดเรียบร้อยแล้ว");
      setShowSuccess(true);

      setData((prev) => prev.filter((item) => item.category_code !== code));
      fetchData();
    } catch (err) {
      alert("ไม่สามารถลบข้อมูลได้: " + (err.message || err));
    } finally {
      setLoading(false);
      setDeleteItem(null);
    }
  };

  return (
    <div className="p-6 bg-[#f9f7f4] min-h-screen">
      {/* HEADER */}
      <div className="flex justify-between items-center mb-4">
        <div>
          <h1 className={`text-[26px] font-bold ${colors.title}`}>จัดการหมวดหมู่การเรียนรู้</h1>
          <p className="text-sm text-gray-500 mt-1">
            สร้างและดูแลหมวดหมู่การเรียนรู้หลักสำหรับจัดกลุ่มอักขระล้านนา
          </p>
        </div>
        <button
          onClick={() => {
            setForm({ category_code: "", title: "", description: "", is_active: 1, total_items: 0 });
            setErrors({});
            setShowAdd(true);
          }}
          className={`flex items-center gap-2 ${colors.button} text-white px-4 py-2.5 rounded-lg font-semibold shadow-md transition`}
        >
          <Plus size={18} />
          <span>เพิ่มหมวดหมู่การเรียนรู้</span>
        </button>
      </div>

      {/* SEARCH */}
      <div className="flex gap-4 mb-4">
        <div className="flex-1">
          <input
            className={`w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 ${colors.ringFocus} bg-white`}
            placeholder="ค้นหาตามชื่อหมวดหมู่การเรียนรู้..."
            value={search}
            onChange={(e) => {
              setSearch(e.target.value);
              setCurrentPage(1);
            }}
          />
        </div>
      </div>

      {/* LOADING / ERROR / TABLE */}
      {loading && data.length === 0 ? (
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
                <th className="th-left">หัวข้อหลัก</th>
                <th className="th-left">คำอธิบาย</th>
                <th className="!text-center">จำนวนรายการ</th>
                <th className="!text-center">สถานะ</th>
                <th>จัดการ</th>
              </tr>
            </thead>
            <tbody>
              {data.map((item, index) => (
                <tr key={item.category_code || index}>
                  <td className="td-num">
                    <span className={`lanna-seq ${colors.seqBg} ${colors.seqText} ${colors.seqBgHover} ${colors.seqTextHover}`}>
                      {(currentPage - 1) * ITEMS_PER_PAGE + index + 1}
                    </span>
                  </td>
                  <td className="lanna-cell-main">{item.title}</td>
                  <td className="text-gray-500 text-left">{item.description || "—"}</td>
                  <td className="text-center text-gray-600 font-medium">{item.total_items}</td>
                  <td className="text-center">
                    <span
                      className={`px-3 py-1.5 rounded-full text-xs font-semibold ${
                        item.is_active
                          ? "bg-green-100 text-green-700"
                          : "bg-red-100 text-red-700"
                      }`}
                    >
                      {item.is_active ? "กำลังใช้งาน" : "ปิดใช้งาน"}
                    </span>
                  </td>
                  <td>
                    <div className="lanna-btn-actions">
                      <button onClick={() => openEdit(item)} className="lanna-btn-edit" title="แก้ไข">
                        <Pencil size={15} />
                      </button>
                      <button
                        onClick={() => {
                          setDeleteItem(item);
                          setShowDelete(true);
                        }}
                        className="lanna-btn-delete"
                        title="ลบ"
                      >
                        <Trash2 size={15} />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
              {data.length === 0 && (
                <tr>
                  <td colSpan={6}>
                    <div className="lanna-empty">
                      <p>ยังไม่มีข้อมูลหมวดหมู่การเรียนรู้</p>
                    </div>
                  </td>
                </tr>
              )}
            </tbody>
          </table>

          <Pagination
            currentPage={currentPage}
            totalItems={totalCount}
            pageSize={ITEMS_PER_PAGE}
            onPageChange={setCurrentPage}
            colors={colors}
          />
        </div>
      )}

      {/* ADD MODAL */}
      {showAdd && (
        <Modal title="เพิ่มหมวดหมู่การเรียนรู้" onClose={() => setShowAdd(false)}>
          <form
            onSubmit={handleAdd}
            className="flex flex-col flex-1 overflow-hidden"
          >
            {/* SCROLLABLE BODY */}
            <div className="p-6 overflow-y-auto space-y-4 flex-1">
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-1">หัวข้อหลัก *</label>
                <input
                  value={form.title}
                  onChange={(e) => setForm({ ...form, title: e.target.value })}
                  className={`w-full border rounded-xl px-4 py-2.5 focus:ring-2 focus:ring-orange-500 bg-white ${
                    errors.title ? "border-red-500" : "border-gray-300"
                  }`}
                  placeholder="ชื่อหมวดหมู่การเรียนรู้"
                />
                {errors.title && <p className="text-red-500 text-xs mt-1">{errors.title}</p>}
              </div>
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-1">คำอธิบาย</label>
                <textarea
                  value={form.description}
                  onChange={(e) => setForm({ ...form, description: e.target.value })}
                  className="w-full border rounded-xl px-4 py-2.5 border-gray-300 focus:ring-2 focus:ring-orange-500 h-24 bg-white"
                  placeholder="รายละเอียดคำอธิบายหมวดหมู่"
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-1">จำนวนรายการเริ่มต้น</label>
                  <input
                    type="text"
                    inputMode="numeric"
                    pattern="[0-9]*"
                    value={form.total_items}
                    onFocus={(e) => {
                      if (String(form.total_items) === '0') {
                        setForm({ ...form, total_items: '' });
                      }
                    }}
                    onBlur={(e) => {
                      if (e.target.value === '') {
                        setForm({ ...form, total_items: '0' });
                      }
                    }}
                    onChange={(e) => {
                      let val = e.target.value.replace(/[^0-9]/g, "");
                      val = val.replace(/^0+(?=\d)/, "");
                      setForm({ ...form, total_items: val });
                    }}
                    className="w-full border rounded-xl px-4 py-2.5 border-gray-300 focus:ring-2 focus:ring-orange-500 bg-white"
                  />
                </div>
                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-1">สถานะใช้งาน</label>
                  <select
                    value={form.is_active}
                    onChange={(e) => setForm({ ...form, is_active: parseInt(e.target.value) })}
                    className="w-full border rounded-xl px-4 py-2.5 border-gray-300 focus:ring-2 focus:ring-orange-500 bg-white"
                  >
                    <option value={1}>เปิดใช้งาน</option>
                    <option value={0}>ปิดใช้งาน</option>
                  </select>
                </div>
              </div>
            </div>

            {/* STICKY FOOTER */}
            <div className="px-6 py-4 border-t border-gray-100 bg-gray-50 flex-shrink-0">
              <button
                type="submit"
                disabled={!form.title.trim()}
                className={`w-full py-3 rounded-xl font-bold transition-all ${
                  !form.title.trim()
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

      {/* EDIT MODAL */}
      {showEdit && (
        <Modal title="แก้ไขหมวดหมู่การเรียนรู้" onClose={() => setShowEdit(false)}>
          <form
            onSubmit={handleEdit}
            className="flex flex-col flex-1 overflow-hidden"
          >
            {/* SCROLLABLE BODY */}
            <div className="p-6 overflow-y-auto space-y-4 flex-1">
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-1">หัวข้อหลัก *</label>
                <input
                  value={form.title}
                  onChange={(e) => setForm({ ...form, title: e.target.value })}
                  className={`w-full border rounded-xl px-4 py-2.5 focus:ring-2 ${colors.ringFocus} bg-white ${
                    errors.title ? "border-red-500" : "border-gray-300"
                  }`}
                  placeholder="ชื่อหมวดหมู่การเรียนรู้"
                />
                {errors.title && <p className="text-red-500 text-xs mt-1">{errors.title}</p>}
              </div>
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-1">คำอธิบาย</label>
                <textarea
                  value={form.description}
                  onChange={(e) => setForm({ ...form, description: e.target.value })}
                  className={`w-full border rounded-xl px-4 py-2.5 border-gray-300 focus:ring-2 ${colors.ringFocus} h-24 bg-white`}
                  placeholder="รายละเอียดคำอธิบายหมวดหมู่"
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-1">จำนวนรายการ</label>
                  <input
                    type="text"
                    inputMode="numeric"
                    pattern="[0-9]*"
                    value={form.total_items}
                    onFocus={(e) => {
                      if (String(form.total_items) === '0') {
                        setForm({ ...form, total_items: '' });
                      }
                    }}
                    onBlur={(e) => {
                      if (e.target.value === '') {
                        setForm({ ...form, total_items: '0' });
                      }
                    }}
                    onChange={(e) => {
                      let val = e.target.value.replace(/[^0-9]/g, "");
                      val = val.replace(/^0+(?=\d)/, "");
                      setForm({ ...form, total_items: val });
                    }}
                    className={`w-full border rounded-xl px-4 py-2.5 border-gray-300 focus:ring-2 ${colors.ringFocus} bg-white`}
                  />
                </div>
                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-1">สถานะใช้งาน</label>
                  <select
                    value={form.is_active}
                    onChange={(e) => setForm({ ...form, is_active: parseInt(e.target.value) })}
                    className={`w-full border rounded-xl px-4 py-2.5 border-gray-300 focus:ring-2 ${colors.ringFocus} bg-white`}
                  >
                    <option value={1}>เปิดใช้งาน</option>
                    <option value={0}>ปิดใช้งาน</option>
                  </select>
                </div>
              </div>
            </div>

            {/* STICKY FOOTER */}
            <div className="px-6 py-4 border-t border-gray-100 bg-gray-50 flex-shrink-0">
              <button
                type="submit"
                disabled={!isFormChanged}
                className={`w-full py-3 rounded-xl font-bold transition-all ${
                  !isFormChanged
                    ? "bg-gray-200 text-gray-400 cursor-not-allowed"
                    : "bg-[#16A34A] hover:bg-[#15803D] text-white shadow"
                }`}
              >
                บันทึกการแก้ไข
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
        title="ยืนยันการลบหมวดหมู่การเรียนรู้"
        itemName={deleteItem?.title || ""}
        itemSubtitle={deleteItem?.category_code || ""}
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
