import { useState, useEffect } from "react";
import { Plus, Pencil, Trash2, Search, Activity, RotateCcw } from "lucide-react";
import { supabase } from "../lib/supabaseClient";
import Pagination from "../components/Pagination.jsx";
import { SuccessModal, ConfirmDeleteModal, WarningModal } from "../components/AlertModals.jsx";
import Modal from "../components/Modal.jsx";
import { trackRecentActivity, removeRecentActivity, sortRecentData } from "../lib/recentActivity.js";
import { categoryColors, getCategoryBadgeStyle } from "../lib/categoryColors.js";
import LannaText from "../components/LannaText.jsx";
import StrokePreviewCanvas from "../components/StrokePreviewCanvas.jsx";
import { convertThaiToLanna } from "../lib/thaiToLanna.js";
import { normalizeLannaText } from "../lib/lannaNormalizer.js";

const getApiBase = () => {
  if (typeof window !== 'undefined' && window.location.hostname === 'siripaporn.lnw.mn') {
    return 'https://siripaporn.lnw.mn';
  }
  return import.meta.env.VITE_API_BASE_URL || 'https://siripaporn.lnw.mn';
};
const BASE = getApiBase();

export default function CharacterStrokesPage() {
  const colors = categoryColors.characterStrokes;
  const ITEMS_PER_PAGE = 10;

  const [data, setData] = useState([]);
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const [search, setSearch] = useState("");
  const [categoryFilter, setCategoryFilter] = useState("all");
  const [currentPage, setCurrentPage] = useState(1);
  const [totalCount, setTotalCount] = useState(0);

  const [showAdd, setShowAdd] = useState(false);
  const [showEdit, setShowEdit] = useState(false);
  const [showDelete, setShowDelete] = useState(false);

  const [editItem, setEditItem] = useState(null);
  const [deleteItem, setDeleteItem] = useState(null);

  const [form, setForm] = useState({
    char_symbol: "",
    char_name: "",
    category_char_id: "CL0001",
    category: "CL0001",
    stroke_count: 1,
    stroke_data: "[]"
  });

  const [showSuccess, setShowSuccess] = useState(false);
  const [successText, setSuccessText] = useState("");
  const [showWarning, setShowWarning] = useState(false);
  const [warningText, setWarningText] = useState("");

  const fetchCategories = async () => {
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

  const fetchData = async (cat = categoryFilter, s = search) => {
    setLoading(true);
    setError(null);
    try {
      let url = `${BASE}/endpoints/character_strokes_api.php?action=getAll`;
      const params = new URLSearchParams();
      if (cat && cat !== "all") params.append("category", cat);
      if (s && s.trim() !== "") params.append("search", s.trim());
      const queryStr = params.toString();
      if (queryStr) url += `&${queryStr}`;

      const res = await fetch(url);
      const result = await res.json();
      if (result.error) {
        setError(result.error.message);
        setData([]);
        setTotalCount(0);
      } else {
        const list = result.data || [];
        const sortedList = sortRecentData(list, "character_strokes", "stroke_id");
        setData(sortedList);
        setTotalCount(sortedList.length);
      }
    } catch (err) {
      console.error("Error fetching character strokes:", err);
      setError("ไม่สามารถดึงข้อมูลเส้นทางการวาดอักขระได้");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchCategories();
  }, []);

  useEffect(() => {
    const handler = setTimeout(() => {
      fetchData(categoryFilter, search);
    }, 200);
    return () => clearTimeout(handler);
  }, [categoryFilter, search]);

  const paginatedData = data.slice((currentPage - 1) * ITEMS_PER_PAGE, currentPage * ITEMS_PER_PAGE);

  // Helper to find category name from categories list
  const getDisplayCategoryName = (item) => {
    if (item.category_name) {
      const match = categories.find(c => c.category_char_id === item.category_name || c.name === item.category_name);
      if (match) return match.name;
    }
    const catId = item.category_char_id || item.category;
    const match = categories.find(c => c.category_char_id === catId || c.name === catId);
    if (match) return match.name;
    
    // Legacy fallback mapping
    const legacyMap = {
      consonant: "พยัญชนะในวรรค",
      vowel: "สระจม (สระหน้อย)",
      tone: "วรรณยุกต์",
      tone_mark: "วรรณยุกต์",
      number: "เลขในธัมม์",
      sequence: "เครื่องหมายแทนอักษร (ตัวสะกด/ตัวห้อย)",
      other: "เครื่องหมายพิเศษอื่นๆ"
    };
    return legacyMap[catId?.toLowerCase()] || item.category_name || item.category || "ไม่ระบุหมวดหมู่";
  };

  // Convert Thai character name (เช่น "ก", "กะ", "ข", "ขะ") to Lanna character
  const handleConvertThaiToLanna = (thaiInput = form.char_name) => {
    if (!thaiInput) return;
    const cleanInput = thaiInput.trim();
    if (!cleanInput) return;

    // 1. Direct single Thai consonant lookup
    const THAI_CONSONANT_MAP = {
      'ก': 'ᨠ', 'กะ': 'ᨠ', 'ก๋ะ': 'ᨠ', 'ข': 'ᨡ', 'ขะ': 'ᨡ', 'ข๋ะ': 'ᨡ',
      'ฃ': 'ᨢ', 'ฃะ': 'ᨢ', 'ค': 'ᨣ', 'คะ': 'ᨣ', 'ค (กะ)': 'ᨣ', 'ฅ': 'ᨤ', 'ฅะ': 'ᨤ',
      'ฆ': 'ᨥ', 'ฆะ': 'ᨥ', 'ง': 'ᨦ', 'งะ': 'ᨦ', 'จ': 'ᨧ', 'จะ': 'ᨧ', 'จ๋ะ': 'ᨧ',
      'ฉ': 'ᨨ', 'ฉะ': 'ᨨ', 'ช': 'ᨩ', 'ชะ': 'ᨩ', 'ซ': 'ᨪ', 'ซะ': 'ᨪ',
      'ฌ': 'ᨫ', 'ฌะ': 'ᨫ', 'ญ': 'ᨬ', 'ญะ': 'ᨬ', 'ยนะ': 'ᨬ', 'ฏ': 'ᨭ', 'ฏะ': 'ᨭ', 'ต๊า': 'ᨭ',
      'ฐ': 'ᨮ', 'ฐะ': 'ᨮ', 'ฑ': 'ᨯ', 'ฑะ': 'ᨯ', 'ด': 'ᨯ', 'ดะ': 'ᨯ',
      'ฒ': 'ᨰ', 'ฒะ': 'ᨰ', 'ณ': 'ᨱ', 'ณะ': 'ᨱ', 'ต': 'ᨲ', 'ตะ': 'ᨲ', 'ต๋ะ': 'ᨲ',
      'ถ': 'ᨳ', 'ถะ': 'ᨳ', 'ท': 'ᨴ', 'ทะ': 'ᨴ', 'ธ': 'ᨵ', 'ธะ': 'ᨵ',
      'น': 'ᨶ', 'นะ': 'ᨶ', 'บ': 'ᨷ', 'บะ': 'ᨷ', 'ป': 'ᨸ', 'ปะ': 'ᨸ', 'ป๋ะ': 'ᨸ',
      'ผ': 'ᨹ', 'ผะ': 'ᨹ', 'ฝ': 'ᨺ', 'ฝะ': 'ᨺ', 'พ': 'ᨻ', 'พะ': 'ᨻ',
      'ฟ': 'ᨼ', 'ฟะ': 'ᨼ', 'ภ': 'ᨽ', 'ภะ': 'ᨽ', 'ม': 'ᨾ', 'มะ': 'ᨾ',
      'ย': 'ᨿ', 'ยะ': 'ᨿ', 'ย่า': 'ᨿ', 'ร': 'ᩁ', 'ระ': 'ᩁ', 'รา': 'ᩁ', 'ล': 'ᩃ', 'ละ': 'ᩃ',
      'ว': 'ᩅ', 'วะ': 'ᩅ', 'ศ': 'ᩆ', 'ศะ': 'ᩆ', 'ษ': 'ᩇ', 'ษะ': 'ᩇ',
      'ส': 'ᩈ', 'สะ': 'ᩈ', 'ส๋ะ': 'ᩈ', 'ห': 'ᩉ', 'หะ': 'ᩉ', 'ฬ': 'ᩊ', 'ฬะ': 'ᩊ',
      'อ': 'ᩋ', 'อะ': 'ᩋ', 'ฮ': 'ᩌ', 'ฮะ': 'ᩌ'
    };

    let converted = "";
    // If input is purely a known key
    if (THAI_CONSONANT_MAP[cleanInput]) {
      converted = THAI_CONSONANT_MAP[cleanInput];
    } else {
      // Extract main token in case of parentheses like "ฆะ (คะ)" or "ก (กะ)"
      const parts = cleanInput.split(/[\s\(\)\/]+/).filter(Boolean);
      for (const p of parts) {
        if (THAI_CONSONANT_MAP[p]) {
          converted = THAI_CONSONANT_MAP[p];
          break;
        }
      }
    }

    // Fallback to engine
    if (!converted) {
      converted = convertThaiToLanna(cleanInput);
    }

    if (converted) {
      const normalized = normalizeLannaText(converted);
      setForm((prev) => ({
        ...prev,
        char_symbol: normalized
      }));
    }
  };

  const handleOpenAdd = () => {
    const defaultCat = categories[0]?.category_char_id || "CL0001";
    setForm({
      char_symbol: "",
      char_name: "",
      category_char_id: defaultCat,
      category: defaultCat,
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
    
    // Pick the matching category_char_id
    let selectedCat = item.category_char_id || item.category || "CL0001";
    const matchCat = categories.find(c => c.category_char_id === selectedCat || c.name === item.category || c.name === item.category_name);
    if (matchCat) {
      selectedCat = matchCat.category_char_id;
    }

    setForm({
      char_symbol: item.char_symbol || "",
      char_name: item.char_name || "",
      category_char_id: selectedCat,
      category: selectedCat,
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
        setWarningText("ข้อมูลพิกัดจุดลากเส้น (stroke_data) ต้องเป็นรูปแบบ JSON ที่ถูกต้อง");
        setShowWarning(true);
        return;
      }

      const res = await fetch(`${BASE}/endpoints/character_strokes_api.php?action=create`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          ...form,
          category_char_id: form.category_char_id || form.category,
          category: form.category_char_id || form.category,
          stroke_data: parsedStrokes
        })
      });
      const result = await res.json();
      if (result.error) {
        setWarningText(result.error.message || result.error || "เกิดข้อผิดพลาดในการบันทึกข้อมูล");
        setShowWarning(true);
        return;
      }
      const newStroke = result.data || { ...form };
      const strokeId = newStroke.stroke_id || result.data?.stroke_id;
      if (strokeId) {
        trackRecentActivity("character_strokes", strokeId);
        setData((prev) => [newStroke, ...prev.filter((i) => (i.stroke_id || i.id) !== strokeId)]);
      }
      setShowAdd(false);
      setSuccessText("เพิ่มข้อมูลสำเร็จ");
      setShowSuccess(true);
      setCurrentPage(1);
      fetchData(categoryFilter, search);
    } catch (err) {
      setWarningText(err.message || "เกิดข้อผิดพลาดในการบันทึกข้อมูล");
      setShowWarning(true);
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
        setWarningText("ข้อมูลพิกัดจุดลากเส้น (stroke_data) ต้องเป็นรูปแบบ JSON ที่ถูกต้อง");
        setShowWarning(true);
        return;
      }

      const targetId = editItem.stroke_id || editItem.id;
      const res = await fetch(
        `${BASE}/endpoints/character_strokes_api.php?action=update&id=${encodeURIComponent(targetId)}`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            ...form,
            category_char_id: form.category_char_id || form.category,
            category: form.category_char_id || form.category,
            stroke_data: parsedStrokes
          })
        }
      );
      const result = await res.json();
      if (result.error) {
        setWarningText(result.error.message || result.error || "เกิดข้อผิดพลาดในการอัปเดตข้อมูล");
        setShowWarning(true);
        return;
      }
      const updatedStroke = result.data || { ...editItem, ...form, stroke_id: targetId };
      const strokeId = updatedStroke.stroke_id || targetId;
      if (strokeId) {
        trackRecentActivity("character_strokes", strokeId);
        setData((prev) => [updatedStroke, ...prev.filter((i) => (i.stroke_id || i.id) !== strokeId)]);
      }
      setShowEdit(false);
      setSuccessText("แก้ไขข้อมูลสำเร็จ");
      setShowSuccess(true);
      setCurrentPage(1);
      fetchData(categoryFilter, search);
    } catch (err) {
      setWarningText(err.message || "เกิดข้อผิดพลาดในการอัปเดตข้อมูล");
      setShowWarning(true);
    }
  };

  const handleDelete = async () => {
    if (!deleteItem) return;
    try {
      const targetId = deleteItem.stroke_id || deleteItem.id;
      if (targetId) {
        removeRecentActivity("character_strokes", targetId);
      }
      const res = await fetch(
        `${BASE}/endpoints/character_strokes_api.php?action=delete&id=${encodeURIComponent(targetId)}`,
        { method: "POST" }
      );
      const result = await res.json();
      if (result.error) {
        setWarningText(result.error.message || result.error || "เกิดข้อผิดพลาดในการลบข้อมูล");
        setShowWarning(true);
        return;
      }
      setData((prev) => prev.filter((i) => (i.stroke_id || i.id) !== targetId));
      setShowDelete(false);
      setSuccessText("ลบข้อมูลสำเร็จ");
      setShowSuccess(true);
      fetchData(categoryFilter, search);
    } catch (err) {
      setWarningText(err.message || "เกิดข้อผิดพลาดในการลบข้อมูล");
      setShowWarning(true);
    }
  };

  return (
    <div className="p-6 bg-[#f9f7f4] min-h-screen">
      {/* HEADER CARD BANNER */}
      <div className="bg-indigo-50/70 border border-indigo-200 rounded-2xl p-6 mb-6 flex flex-col md:flex-row md:items-center justify-between gap-4 shadow-sm">
        <div className="flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-indigo-100 flex items-center justify-center text-indigo-700 shrink-0">
            <Activity className="w-6 h-6" />
          </div>
          <div>
            <h1 className="text-xl font-bold text-gray-900">จัดการเส้นทางการวาดอักขระ</h1>
            <p className="text-sm text-gray-800 mt-0.5 font-medium">เพิ่ม แก้ไข และจัดการเส้นทางการลากเส้นอักขระล้านนา (100x100 Grid)</p>
          </div>
        </div>
        <button
          onClick={handleOpenAdd}
          className="flex items-center gap-2 bg-indigo-600 hover:bg-indigo-700 text-white px-5 py-2.5 rounded-xl font-semibold shadow-md transition shrink-0"
        >
          <Plus size={18} /> เพิ่มเส้นทางการวาด
        </button>
      </div>

      {/* SEARCH & FILTER (Format matched with alphabet.jsx) */}
      <div className="bg-white p-4 rounded-2xl border border-gray-100 shadow-sm flex flex-col sm:flex-row items-center gap-3 mb-6">
        <div className="relative flex-1 w-full flex items-center">
          <Search className="w-4 h-4 text-gray-500 absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none z-10" />
          <input
            className="w-full admin-search-input pr-4 py-2.5 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 bg-white text-sm text-gray-900 font-medium relative z-0"
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
            className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 bg-white cursor-pointer text-sm text-gray-900 font-medium"
            value={categoryFilter}
            onChange={(e) => {
              setCategoryFilter(e.target.value);
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
            setCategoryFilter("all");
            setCurrentPage(1);
            fetchData("all", "");
          }}
          title="รีเซ็ตการค้นหา"
          className="p-2.5 border border-gray-200 rounded-xl hover:bg-gray-50 text-gray-700 transition shrink-0 cursor-pointer"
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
            onClick={() => fetchData()}
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
                <th className="whitespace-nowrap text-center">จำนวนเส้น</th>
                <th className="whitespace-nowrap">จัดการ</th>
              </tr>
            </thead>
            <tbody>
              {paginatedData.map((d, i) => {
                const categoryName = getDisplayCategoryName(d);
                const badgeStyle = getCategoryBadgeStyle(categoryName);
                return (
                  <tr key={d.stroke_id || i} className="hover:bg-indigo-50/60 transition-colors">
                    <td className="td-num">
                      <span className={`lanna-seq ${colors.seqBg} ${colors.seqText} ${colors.seqBgHover} ${colors.seqTextHover}`}>
                        {(currentPage - 1) * ITEMS_PER_PAGE + i + 1}
                      </span>
                    </td>

                    {/* ✅ ฟอนต์ล้านนา LN-TILOK-6.10 */}
                    <td className="text-2xl text-left">
                      <LannaText fallbackThai={d.char_name}>{d.char_symbol}</LannaText>
                    </td>

                    <td className="text-left lanna-cell-main">{d.char_name || "-"}</td>

                    <td className="text-left">
                      <span className="lanna-badge" style={{ backgroundColor: badgeStyle.bg, color: badgeStyle.text, borderColor: badgeStyle.border }}>
                        <span className="lanna-badge-dot" style={{ backgroundColor: badgeStyle.dot }} />
                        {categoryName}
                      </span>
                    </td>

                    <td className="text-center font-bold text-gray-900">
                      {d.stroke_count || 1} เส้น
                    </td>

                    <td>
                      <div className="lanna-btn-actions">
                        <button onClick={() => handleOpenEdit(d)} className="lanna-btn-edit" title="แก้ไข">
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
                );
              })}
              {paginatedData.length === 0 && (
                <tr>
                  <td colSpan={6}>
                    <div className="lanna-empty">
                      <svg className="lanna-empty-icon" fill="none" stroke="currentColor" strokeWidth="1.5" viewBox="0 0 24 24" style={{ width: 40, height: 40 }}>
                        <path strokeLinecap="round" strokeLinejoin="round" d="M4.5 12.75l6 6 9-13.5" />
                      </svg>
                      <p className="lanna-empty-title">ยังไม่มีข้อมูลเส้นทางการวาด</p>
                      <p className="lanna-empty-sub">กดปุ่ม "เพิ่มเส้นทางการวาด" เพื่อเริ่มต้นสร้างข้อมูล</p>
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

      {/* Modal Add / Edit with Live Stroke Preview */}
      {(showAdd || showEdit) && (
        <Modal
          title={showAdd ? "เพิ่มข้อมูลเส้นทางการวาดอักขระ" : "แก้ไขข้อมูลเส้นทางการวาดอักขระ"}
          maxWidthClass="max-w-4xl"
          onClose={() => {
            setShowAdd(false);
            setShowEdit(false);
          }}
        >
          <form onSubmit={showAdd ? handleSaveAdd : handleSaveEdit} className="flex flex-col flex-1 overflow-hidden">
            <div className="p-6 overflow-y-auto space-y-4 flex-1">
              <div className="grid grid-cols-1 md:grid-cols-12 gap-6">
                
                {/* Left Form Inputs (7 cols) */}
                <div className="md:col-span-7 space-y-4">
                  {/* 1. ชื่ออักขระ (เช่น กะ, ขะ, ฆะ (คะ)) */}
                  <div>
                    <label style={{ color: '#000000' }} className="block mb-1.5 text-sm font-normal text-black">
                      ชื่ออักขระ (ภาษาไทย)
                    </label>
                    <input
                      type="text"
                      value={form.char_name}
                      onChange={(e) => {
                        const val = e.target.value;
                        setForm((prev) => ({ ...prev, char_name: val }));
                        handleConvertThaiToLanna(val);
                      }}
                      style={{ color: '#000000' }}
                      className="w-full border border-gray-300 rounded-xl px-4 py-2.5 text-sm font-medium focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 bg-white shadow-sm placeholder:text-gray-400"
                      placeholder="เช่น ก (กะ), ข (ขะ), ฆะ (คะ)"
                    />
                    <p style={{ color: '#dc2626' }} className="text-xs font-medium mt-1">
                      * พิมพ์ชื่ออักขระ เช่น กะ, ขะ, คะ ระบบจะแปลงตัวอักขระล้านนาให้โดยอัตโนมัติ
                    </p>
                  </div>

                  {/* 2. ตัวอักขระล้านนา */}
                  <div>
                    <label style={{ color: '#000000' }} className="block mb-1 text-sm font-normal text-black">
                      ตัวอักขระล้านนา <span style={{ color: '#dc2626' }}>*</span>
                    </label>
                    <div className="flex items-center gap-2">
                      <input
                        type="text"
                        required
                        value={form.char_symbol}
                        onChange={(e) => {
                          const normalized = normalizeLannaText(e.target.value);
                          setForm({ ...form, char_symbol: normalized });
                        }}
                        style={{ color: '#000000' }}
                        className="w-full border border-gray-300 rounded-xl px-4 py-2.5 text-2xl font-bold focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 bg-white shadow-sm font-lanna placeholder:text-gray-400"
                        placeholder="เช่น ᨠ"
                      />
                    </div>
                  </div>

                  {/* 3. หมวดหมู่อักขระ และ จำนวนเส้น */}
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div>
                      <label style={{ color: '#000000' }} className="block mb-1 text-sm font-normal text-black">
                        หมวดหมู่อักขระ
                      </label>
                      <select
                        value={form.category_char_id || form.category}
                        onChange={(e) => setForm({ ...form, category_char_id: e.target.value, category: e.target.value })}
                        style={{ color: '#000000' }}
                        className="w-full border border-gray-300 rounded-xl px-3 py-2.5 text-sm font-medium focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 bg-white cursor-pointer shadow-sm"
                      >
                        {categories.map((cat) => (
                          <option key={cat.category_char_id} value={cat.category_char_id} style={{ color: '#000000' }}>
                            {cat.name}
                          </option>
                        ))}
                      </select>
                    </div>

                    <div>
                      <label style={{ color: '#000000' }} className="block mb-1 text-sm font-normal text-black">
                        จำนวนเส้น
                      </label>
                      <div className="flex items-center border border-gray-300 rounded-xl bg-white shadow-sm overflow-hidden focus-within:ring-2 focus-within:ring-indigo-500/20 focus-within:border-indigo-500">
                        <button
                          type="button"
                          onClick={() => {
                            const current = parseInt(form.stroke_count) || 1;
                            setForm((prev) => ({ ...prev, stroke_count: Math.max(1, current - 1) }));
                          }}
                          style={{ color: '#000000', fontWeight: '700' }}
                          className="px-3 py-2.5 bg-gray-50 hover:bg-gray-100 border-r border-gray-200 transition active:bg-gray-200 cursor-pointer select-none"
                          title="ลดจำนวนเส้น"
                        >
                          -
                        </button>
                        <input
                          type="number"
                          min="1"
                          value={form.stroke_count ?? 1}
                          onChange={(e) => {
                            const val = e.target.value;
                            setForm((prev) => ({
                              ...prev,
                              stroke_count: val === '' ? '' : Math.max(1, parseInt(val) || 1)
                            }));
                          }}
                          onBlur={() => {
                            setForm((prev) => ({
                              ...prev,
                              stroke_count: Math.max(1, parseInt(prev.stroke_count) || 1)
                            }));
                          }}
                          style={{ color: '#000000', fontWeight: '700' }}
                          className="w-full text-center py-2.5 text-sm focus:outline-none bg-transparent"
                        />
                        <button
                          type="button"
                          onClick={() => {
                            const current = parseInt(form.stroke_count) || 1;
                            setForm((prev) => ({ ...prev, stroke_count: current + 1 }));
                          }}
                          style={{ color: '#000000', fontWeight: '700' }}
                          className="px-3 py-2.5 bg-gray-50 hover:bg-gray-100 border-l border-gray-200 transition active:bg-gray-200 cursor-pointer select-none"
                          title="เพิ่มจำนวนเส้น"
                        >
                          +
                        </button>
                      </div>
                    </div>
                  </div>

                  {/* 4. พิกัดจุดลากเส้น (JSON Array) */}
                  <div>
                    <label style={{ color: '#000000' }} className="block mb-1 text-sm font-normal text-black">
                      พิกัดจุดลากเส้น (JSON Array) <span style={{ color: '#dc2626' }}>*</span>
                    </label>
                    <textarea
                      rows={7}
                      required
                      value={form.stroke_data}
                      onChange={(e) => {
                        const val = e.target.value;
                        let count = form.stroke_count;
                        try {
                          const parsed = JSON.parse(val);
                          if (Array.isArray(parsed) && parsed.length > 0) {
                            count = Array.isArray(parsed[0]) ? parsed.length : 1;
                          }
                        } catch (err) {}
                        setForm({ ...form, stroke_data: val, stroke_count: count });
                      }}
                      style={{ color: '#000000' }}
                      className="w-full border border-gray-300 rounded-xl p-3 font-mono text-xs font-medium focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 bg-white shadow-sm leading-relaxed placeholder:text-gray-400"
                      placeholder='[ [ {"x": 20, "y": 50}, {"x": 80, "y": 50} ] ]'
                    />
                  </div>
                </div>

                {/* Right Stroke Live Preview (5 cols) */}
                <div className="md:col-span-5 flex flex-col justify-start">
                  <StrokePreviewCanvas
                    strokeDataStr={form.stroke_data}
                    charSymbol={form.char_symbol}
                    size={280}
                  />
                </div>

              </div>
            </div>

            <div className="flex justify-end gap-3 p-4 bg-gray-50 border-t border-gray-100 rounded-b-2xl">
              <button
                type="button"
                onClick={() => {
                  setShowAdd(false);
                  setShowEdit(false);
                }}
                style={{ color: '#000000' }}
                className="px-5 py-2.5 text-sm font-semibold border border-gray-300 rounded-xl hover:bg-gray-100 transition shadow-sm cursor-pointer"
              >
                ยกเลิก
              </button>
              <button
                type="submit"
                className="px-5 py-2.5 text-sm font-semibold text-white bg-indigo-600 rounded-xl hover:bg-indigo-700 transition shadow-sm cursor-pointer"
              >
                บันทึกข้อมูล
              </button>
            </div>
          </form>
        </Modal>
      )}

      <ConfirmDeleteModal
        isOpen={showDelete}
        onClose={() => setShowDelete(false)}
        onConfirm={handleDelete}
        title="ยืนยันการลบข้อมูลเส้นทางการวาด"
        itemName={deleteItem?.char_symbol || deleteItem?.char_name || ""}
        itemSubtitle={deleteItem?.char_name || ""}
        itemType="ข้อมูลเส้นทางการวาด"
      />

      {/* Success Notification */}
      <SuccessModal
        isOpen={showSuccess}
        onClose={() => setShowSuccess(false)}
        message={successText}
      />

      {/* Warning / Error Notification */}
      <WarningModal
        isOpen={showWarning}
        onClose={() => setShowWarning(false)}
        title="แจ้งเตือนข้อมูลซ้ำ"
        message={warningText}
      />
    </div>
  );
}

