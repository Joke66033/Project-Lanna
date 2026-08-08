import { useState, useEffect } from "react";
import { Plus, Pencil, Trash2, Search, Activity, RefreshCw } from "lucide-react";
import Pagination from "../components/Pagination.jsx";
import { SuccessModal, ConfirmDeleteModal } from "../components/AlertModals.jsx";
import Modal from "../components/Modal.jsx";

const getApiBase = () => {
  if (typeof window !== 'undefined' && window.location.hostname === 'siripaporn.lnw.mn') {
    return 'https://siripaporn.lnw.mn';
  }
  return import.meta.env.VITE_API_BASE_URL || 'https://siripaporn.lnw.mn';
};
const BASE = getApiBase();

export default function CharacterStrokesPage() {
  const ITEMS_PER_PAGE = 10;

  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const [search, setSearch] = useState("");
  const [categoryFilter, setCategoryFilter] = useState("all");
  const [currentPage, setCurrentPage] = useState(1);

  const [showAdd, setShowAdd] = useState(false);
  const [showEdit, setShowEdit] = useState(false);
  const [showDelete, setShowDelete] = useState(false);

  const [editItem, setEditItem] = useState(null);
  const [deleteItem, setDeleteItem] = useState(null);

  const [form, setForm] = useState({
    char_symbol: "",
    char_name: "",
    category: "consonant",
    stroke_count: 1,
    stroke_data: "[]"
  });

  const [showSuccess, setShowSuccess] = useState(false);
  const [successText, setSuccessText] = useState("");

  const fetchData = async () => {
    setLoading(true);
    setError(null);
    try {
      let url = `${BASE}/endpoints/character_strokes_api.php?action=getAll`;
      if (categoryFilter !== "all") {
        url += `&category=${categoryFilter}`;
      }
      const res = await fetch(url);
      const result = await res.json();
      if (result.error) {
        setError(result.error.message);
        setData([]);
      } else {
        setData(result.data || []);
      }
    } catch (err) {
      console.error("Error fetching character strokes:", err);
      setError("ไม่สามารถดึงข้อมูลเส้นทางการวาดอักขระได้");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, [categoryFilter]);

  // Search & Pagination filtering
  const filteredData = data.filter((item) => {
    const matchSearch =
      (item.char_symbol || "").toLowerCase().includes(search.toLowerCase()) ||
      (item.char_name || "").toLowerCase().includes(search.toLowerCase());
    return matchSearch;
  });

  const totalPages = Math.ceil(filteredData.length / ITEMS_PER_PAGE) || 1;
  const paginatedData = filteredData.slice(
    (currentPage - 1) * ITEMS_PER_PAGE,
    currentPage * ITEMS_PER_PAGE
  );

  const handleOpenAdd = () => {
    setForm({
      char_symbol: "",
      char_name: "",
      category: "consonant",
      stroke_count: 1,
      stroke_data: "[\n  [\n    {\"x\": 20, \"y\": 50},\n    {\"x\": 80, \"y\": 50}\n  ]\n]"
    });
    setShowAdd(true);
  };

  const handleOpenEdit = (item) => {
    setEditItem(item);
    let strData = item.stroke_data;
    if (typeof strData !== "string") {
      strData = JSON.stringify(strData, null, 2);
    }
    setForm({
      char_symbol: item.char_symbol || "",
      char_name: item.char_name || "",
      category: item.category || "consonant",
      stroke_count: item.stroke_count || 1,
      stroke_data: strData
    });
    setShowEdit(true);
  };

  const handleSaveAdd = async (e) => {
    e.preventDefault();
    try {
      let parsedStrokes;
      try {
        parsedStrokes = JSON.parse(form.stroke_data);
      } catch (err) {
        alert("ข้อมูล stroke_data ต้องเป็น JSON ที่ถูกต้อง");
        return;
      }

      const res = await fetch(`${BASE}/endpoints/character_strokes_api.php?action=create`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          ...form,
          stroke_data: parsedStrokes
        })
      });
      const result = await res.json();
      if (result.error) {
        alert(result.error.message);
        return;
      }
      setShowAdd(false);
      setSuccessText("เพิ่มข้อมูลเส้นทางการวาดเรียบร้อยแล้ว");
      setShowSuccess(true);
      fetchData();
    } catch (err) {
      alert("เกิดข้อผิดพลาดในการบันทึกข้อมูล");
    }
  };

  const handleSaveEdit = async (e) => {
    e.preventDefault();
    if (!editItem) return;
    try {
      let parsedStrokes;
      try {
        parsedStrokes = JSON.parse(form.stroke_data);
      } catch (err) {
        alert("ข้อมูล stroke_data ต้องเป็น JSON ที่ถูกต้อง");
        return;
      }

      const res = await fetch(
        `${BASE}/endpoints/character_strokes_api.php?action=update&id=${editItem.stroke_id}`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            ...form,
            stroke_data: parsedStrokes
          })
        }
      );
      const result = await res.json();
      if (result.error) {
        alert(result.error.message);
        return;
      }
      setShowEdit(false);
      setSuccessText("แก้ไขข้อมูลเส้นทางการวาดเรียบร้อยแล้ว");
      setShowSuccess(true);
      fetchData();
    } catch (err) {
      alert("เกิดข้อผิดพลาดในการอัปเดตข้อมูล");
    }
  };

  const handleDelete = async () => {
    if (!deleteItem) return;
    try {
      const res = await fetch(
        `${BASE}/endpoints/character_strokes_api.php?action=delete&id=${deleteItem.stroke_id}`,
        { method: "POST" }
      );
      const result = await res.json();
      if (result.error) {
        alert(result.error.message);
        return;
      }
      setShowDelete(false);
      setSuccessText("ลบข้อมูลเส้นทางการวาดเรียบร้อยแล้ว");
      setShowSuccess(true);
      fetchData();
    } catch (err) {
      alert("เกิดข้อผิดพลาดในการลบข้อมูล");
    }
  };

  return (
    <div className="p-6 max-w-7xl mx-auto space-y-6">
      {/* Header Banner (Indigo Theme) */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 bg-indigo-50/70 p-6 rounded-2xl border border-indigo-200 shadow-sm">
        <div>
          <h1 className="text-xl font-bold text-gray-900 flex items-center gap-2">
            <Activity className="w-7 h-7 text-indigo-600" />
            จัดการเส้นทางการวาดอักขระล้านนา
          </h1>
          <p className="text-sm text-gray-500 mt-1">
            จัดเก็บและปรับแต่งพิกัดจุดลากเส้นของแต่ละตัวอักขระสำหรับระบบฝึกเขียน (100x100 Grid)
          </p>
        </div>
        <button
          onClick={handleOpenAdd}
          className="flex items-center gap-2 bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2.5 rounded-xl font-semibold shadow-md transition shrink-0"
        >
          <Plus className="w-5 h-5" />
          เพิ่มข้อมูลเส้นการวาด
        </button>
      </div>

      {/* Filters & Search (Image 1 Format) */}
      <div className="bg-white p-4 rounded-2xl border border-gray-100 shadow-sm flex flex-col sm:flex-row items-center gap-3 mb-6">
        <div className="relative flex-1 w-full">
          <Search className="w-4 h-4 text-gray-400 absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
          <input
            type="text"
            placeholder="ค้นหาอักขระ หรือชื่อ..."
            value={search}
            onChange={(e) => {
              setSearch(e.target.value);
              setCurrentPage(1);
            }}
            className="w-full pl-10 pr-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 focus:outline-none bg-white"
          />
        </div>

        <div className="w-full sm:w-64">
          <select
            value={categoryFilter}
            onChange={(e) => {
              setCategoryFilter(e.target.value);
              setCurrentPage(1);
            }}
            className="w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 focus:outline-none cursor-pointer bg-white"
          >
            <option value="all">ทุกประเภท</option>
            <option value="consonant">พยัญชนะ</option>
            <option value="vowel">สระ</option>
            <option value="tone">วรรณยุกต์</option>
            <option value="number">ตัวเลข</option>
            <option value="sequence">ตัวซ้อน/ลำดับ</option>
            <option value="other">อื่นๆ</option>
          </select>
        </div>

        <button
          onClick={() => {
            setSearch("");
            setCategoryFilter("all");
            setCurrentPage(1);
            fetchData();
          }}
          title="รีเซ็ตการค้นหา"
          className="p-2.5 border border-gray-200 rounded-xl hover:bg-gray-50 text-gray-500 transition shrink-0"
        >
          <RefreshCw className="w-4 h-4" />
        </button>
      </div>

      {/* Table */}
      <div className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
        {loading ? (
          <div className="p-12 text-center text-gray-500">กำลังโหลดข้อมูลเส้นทางการวาด...</div>
        ) : error ? (
          <div className="p-8 text-center text-red-500">{error}</div>
        ) : paginatedData.length === 0 ? (
          <div className="p-12 text-center text-gray-400">ไม่พบข้อมูลเส้นทางการวาด</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-indigo-50 border-b-2 border-indigo-200 text-xs font-bold text-indigo-900">
                  <th className="p-4 whitespace-nowrap text-center w-16">#</th>
                  <th className="p-4 whitespace-nowrap">ตัวอักขระ</th>
                  <th className="p-4 whitespace-nowrap">ชื่ออักขระ</th>
                  <th className="p-4 whitespace-nowrap">ประเภท</th>
                  <th className="p-4 text-center whitespace-nowrap">จำนวนเส้น (STROKES)</th>
                  <th className="p-4 text-center whitespace-nowrap">จัดการ</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100 text-sm">
                {paginatedData.map((item, index) => {
                  const cat = (item.category || "").toLowerCase();
                  let badge = <span className="px-2.5 py-1 rounded-full text-xs font-semibold bg-teal-50 text-teal-700 border border-teal-200">{item.category || "อื่นๆ"}</span>;
                  if (cat === "consonant") {
                    badge = <span className="px-2.5 py-1 rounded-full text-xs font-semibold bg-amber-50 text-amber-700 border border-amber-200">พยัญชนะ</span>;
                  } else if (cat === "vowel") {
                    badge = <span className="px-2.5 py-1 rounded-full text-xs font-semibold bg-sky-50 text-sky-700 border border-sky-200">สระ</span>;
                  } else if (cat === "tone" || cat === "tone_mark") {
                    badge = <span className="px-2.5 py-1 rounded-full text-xs font-semibold bg-emerald-50 text-emerald-700 border border-emerald-200">วรรณยุกต์</span>;
                  } else if (cat === "number") {
                    badge = <span className="px-2.5 py-1 rounded-full text-xs font-semibold bg-purple-50 text-purple-700 border border-purple-200">ตัวเลข</span>;
                  } else if (cat === "sequence") {
                    badge = <span className="px-2.5 py-1 rounded-full text-xs font-semibold bg-indigo-50 text-indigo-700 border border-indigo-200">ตัวซ้อน/ลำดับ</span>;
                  }
                  return (
                    <tr key={item.stroke_id} className="hover:bg-indigo-50/60 transition">
                      <td className="p-4 text-center">
                        <span className="lanna-seq bg-indigo-100 text-indigo-700 hover:bg-indigo-200 hover:text-indigo-800">
                          {(currentPage - 1) * ITEMS_PER_PAGE + index + 1}
                        </span>
                      </td>
                      <td className="p-4 text-2xl font-bold text-amber-900 font-serif">
                        {item.char_symbol}
                      </td>
                      <td className="p-4 font-medium text-gray-800">
                        {item.char_name || "-"}
                      </td>
                      <td className="p-4">
                        {badge}
                      </td>
                      <td className="p-4 text-center font-semibold text-gray-700">
                        {item.stroke_count} เส้น
                      </td>
                    <td className="p-4 text-center space-x-2">
                      <button
                        onClick={() => handleOpenEdit(item)}
                        className="p-1.5 text-blue-600 hover:bg-blue-50 rounded-lg"
                        title="แก้ไข"
                      >
                        <Pencil className="w-4 h-4" />
                      </button>
                      <button
                        onClick={() => {
                          setDeleteItem(item);
                          setShowDelete(true);
                        }}
                        className="p-1.5 text-red-600 hover:bg-red-50 rounded-lg"
                        title="ลบ"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </td>
                  </tr>
                );
              })}
              </tbody>
            </table>
          </div>
        )}

        {/* Pagination */}
        <div className="p-4 border-t border-gray-100">
          <Pagination
            currentPage={currentPage}
            totalPages={totalPages}
            onPageChange={(page) => setCurrentPage(page)}
          />
        </div>
      </div>

      {/* Modal Add / Edit */}
      {(showAdd || showEdit) && (
        <Modal
          title={showAdd ? "เพิ่มข้อมูลเส้นทางการวาดอักขระ" : "แก้ไขข้อมูลเส้นทางการวาดอักขระ"}
          onClose={() => {
            setShowAdd(false);
            setShowEdit(false);
          }}
        >
          <form onSubmit={showAdd ? handleSaveAdd : handleSaveEdit} className="space-y-4">
            <div>
              <label className="block text-xs font-bold text-gray-700 uppercase mb-1">
                ตัวอักขระ (Character Symbol) *
              </label>
              <input
                type="text"
                required
                value={form.char_symbol}
                onChange={(e) => setForm({ ...form, char_symbol: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg text-lg font-serif"
                placeholder="เช่น ᨠ"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-gray-700 uppercase mb-1">
                ชื่ออักขระ (Character Name)
              </label>
              <input
                type="text"
                value={form.char_name}
                onChange={(e) => setForm({ ...form, char_name: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg"
                placeholder="เช่น พยัญชนะ กะ"
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-bold text-gray-700 uppercase mb-1">
                  ประเภท (Category)
                </label>
                <select
                  value={form.category}
                  onChange={(e) => setForm({ ...form, category: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg"
                >
                  <option value="consonant">consonant (พยัญชนะ)</option>
                  <option value="vowel">vowel (สระ)</option>
                  <option value="tone">tone (วรรณยุกต์)</option>
                  <option value="number">number (ตัวเลข)</option>
                  <option value="sequence">sequence (ตัวซ้อน/ลำดับ)</option>
                  <option value="other">other (อื่นๆ)</option>
                </select>
              </div>

              <div>
                <label className="block text-xs font-bold text-gray-700 uppercase mb-1">
                  จำนวนเส้น (Stroke Count)
                </label>
                <input
                  type="number"
                  min="1"
                  value={form.stroke_count}
                  onChange={(e) => setForm({ ...form, stroke_count: parseInt(e.target.value) || 1 })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg"
                />
              </div>
            </div>

            <div>
              <label className="block text-xs font-bold text-gray-700 uppercase mb-1">
                พิกัดจุดลากเส้น (Stroke Data JSON Array) *
              </label>
              <textarea
                rows={8}
                required
                value={form.stroke_data}
                onChange={(e) => setForm({ ...form, stroke_data: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg font-mono text-xs"
                placeholder='[ [ {"x": 20, "y": 50}, {"x": 80, "y": 50} ] ]'
              />
            </div>

            <div className="flex justify-end gap-3 pt-4 border-t">
              <button
                type="button"
                onClick={() => {
                  setShowAdd(false);
                  setShowEdit(false);
                }}
                className="px-4 py-2 text-sm text-gray-600 border border-gray-300 rounded-lg hover:bg-gray-50"
              >
                ยกเลิก
              </button>
              <button
                type="submit"
                className="px-4 py-2 text-sm text-white bg-amber-600 rounded-lg hover:bg-amber-700 font-semibold"
              >
                บันทึกข้อมูล
              </button>
            </div>
          </form>
        </Modal>
      )}

      {/* Delete Confirmation Modal */}
      {showDelete && (
        <ConfirmDeleteModal
          title="ยืนยันการลบข้อมูลเส้นทางการวาด"
          message={`คุณต้องการลบข้อมูลเส้นทางการวาดของ "${deleteItem?.char_symbol}" (${deleteItem?.char_name}) ใช่หรือไม่?`}
          onConfirm={handleDelete}
          onCancel={() => setShowDelete(false)}
        />
      )}

      {/* Success Notification */}
      {showSuccess && (
        <SuccessModal
          text={successText}
          onClose={() => setShowSuccess(false)}
        />
      )}
    </div>
  );
}
