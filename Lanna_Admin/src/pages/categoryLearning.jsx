import { useState, useEffect } from "react";
import { Plus, Pencil, Trash2, Search, RotateCcw } from "lucide-react";
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
  const [selectedStatus, setSelectedStatus] = useState("all");
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

  const fetchData = async (page = currentPage, searchQuery = search, statusFilter = selectedStatus) => {
    setLoading(true);
    try {
      let list = [];
      try {
        const res = await fetch(`${BASE}/endpoints/learning_category_api.php?action=getAll`);
        const json = await res.json();
        list = json.data || [];
      } catch (e) {
        console.warn("MySQL PHP API fetch error, falling back to Supabase:", e);
      }

      if (!Array.isArray(list) || list.length === 0) {
        const { data: resData } = await supabase
          .from("learning_category")
          .select("*");
        list = resData || [];
      }

      if (searchQuery.trim() !== "") {
        const q = searchQuery.trim().toLowerCase();
        list = list.filter((item) => item.title && item.title.toLowerCase().includes(q));
      }

      if (statusFilter === "1" || statusFilter === "active") {
        list = list.filter((item) => Number(item.is_active) === 1 || String(item.status) === "1" || String(item.status).toLowerCase() === "active");
      } else if (statusFilter === "0" || statusFilter === "inactive") {
        list = list.filter((item) => Number(item.is_active) === 0 || String(item.status) === "0" || String(item.status).toLowerCase() === "inactive");
      }

      setTotalCount(list.length);

      const from = (page - 1) * ITEMS_PER_PAGE;
      const paginated = list.slice(from, from + ITEMS_PER_PAGE);

      if (page > 1 && paginated.length === 0 && list.length > 0) {
        setCurrentPage(page - 1);
      } else {
        const sorted = sortRecentData(paginated, "learning_category", "category_code");
        setData(sorted);
        setError(null);
      }
    } catch (err) {
      console.error("categoryLearning error:", err);
      setError(err.message || "เกิดข้อผิดพลาดในการโหลดข้อมูลหมวดหมู่การเรียนรู้");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    const delayDebounceFn = setTimeout(() => {
      fetchData(currentPage, search, selectedStatus);
    }, 200);

    return () => clearTimeout(delayDebounceFn);
  }, [currentPage, search, selectedStatus]);

  useEffect(() => {
    const channel = supabase
      .channel("learning_category")
      .on("postgres_changes", 
        { event: "*", schema: "public", table: "learning_category" },
        () => fetchData(currentPage, search, selectedStatus)
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [currentPage, search, selectedStatus]);

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

  const [usageInfo, setUsageInfo] = useState(null);

  const openDeleteConfirm = async (item) => {
    setDeleteItem(item);
    setUsageInfo(null);
    try {
      const code = item.category_code;
      const res = await fetch(`${BASE}/endpoints/learning_category_api.php?action=checkUsage&id=${encodeURIComponent(code)}`);
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
      const code = deleteItem.category_code;
      const isCascade = usageInfo && usageInfo.inUse;

      const res = await fetch(
        `${BASE}/endpoints/learning_category_api.php?action=delete&id=${encodeURIComponent(code)}${isCascade ? '&cascade=true' : ''}`,
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
      setSuccessText("ลบหมวดหมู่การเรียนรู้เรียบร้อยแล้ว");
      setShowSuccess(true);

      setData((prev) => prev.filter((item) => item.category_code !== code));
      fetchData();
    } catch (err) {
      alert(err.message || err);
    } finally {
      setLoading(false);
      setDeleteItem(null);
    }
  };

  return (
    <div className="p-6 bg-[#f9f7f4] min-h-screen">
      {/* HEADER CARD BANNER */}
      <div className="bg-sky-50/70 border border-sky-200 rounded-2xl p-6 mb-6 flex flex-col md:flex-row md:items-center justify-between gap-4 shadow-sm">
        <div className="flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-sky-100 flex items-center justify-center text-sky-700 shrink-0">
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
            </svg>
          </div>
          <div>
            <h1 className="text-xl font-bold text-gray-900">จัดการหมวดหมู่การเรียนรู้</h1>
            <p className="text-sm text-gray-500 mt-0.5">สร้างและดูแลหมวดหมู่การเรียนรู้หลักสำหรับจัดกลุ่มอักขระล้านนา</p>
          </div>
        </div>
        <button
          onClick={() => {
            setForm({ category_code: "", title: "", description: "", is_active: 1, total_items: 0 });
            setErrors({});
            setShowAdd(true);
          }}
          className="flex items-center gap-2 bg-sky-600 hover:bg-sky-700 text-white px-5 py-2.5 rounded-xl font-semibold shadow-md transition shrink-0"
        >
          <Plus size={18} />
          <span>เพิ่มหมวดหมู่การเรียนรู้</span>
        </button>
      </div>

      {/* SEARCH & FILTER (Image 1 Format) */}
      <div className="bg-white p-4 rounded-2xl border border-gray-100 shadow-sm flex flex-col sm:flex-row items-center gap-3 mb-6">
        <div className="relative flex-1 w-full">
          <Search className="w-4 h-4 text-gray-400 absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
          <input
            className="w-full pl-10 pr-4 py-2.5 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-sky-500/20 focus:border-sky-500 bg-white text-sm"
            placeholder="ค้นหาตามชื่อหมวดหมู่การเรียนรู้..."
            value={search}
            onChange={(e) => {
              setSearch(e.target.value);
              setCurrentPage(1);
            }}
          />
        </div>
        <div className="w-full sm:w-64">
          <select
            className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-sky-500/20 focus:border-sky-500 bg-white cursor-pointer text-sm"
            value={selectedStatus}
            onChange={(e) => {
              setSelectedStatus(e.target.value);
              setCurrentPage(1);
            }}
          >
            <option value="all">ทั้งหมด</option>
            <option value="1">กำลังใช้งาน</option>
            <option value="0">ปิดใช้งาน</option>
          </select>
        </div>
        <button
          onClick={() => {
            setSearch("");
            setSelectedStatus("all");
            setCurrentPage(1);
          }}
          title="รีเซ็ตการค้นหา"
          className="p-2.5 border border-gray-200 rounded-xl hover:bg-gray-50 text-gray-500 transition shrink-0"
        >
          <RotateCcw size={16} />
        </button>
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
                        onClick={() => openDeleteConfirm(item)}
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
                  <td colSpan={5}>
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
