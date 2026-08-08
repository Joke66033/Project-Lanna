import { useState, useEffect } from "react";
import { supabase } from "../lib/supabaseClient";

/**
 * LearningCategorySelect Component
 * Dropdown component สำหรับเลือกหมวดหมู่การเรียนรู้หลัก (learning_category)
 * 
 * Props:
 *   - value: string (category_code ที่เลือก)
 *   - onChange: function(category_code) (callback เมื่อเปลี่ยนค่า)
 *   - includeAllOption: boolean (แสดงตัวเลือก "ทั้งหมด" หรือไม่ - สำหรับหน้า filter)
 *   - className: string (คลาส CSS เพิ่มเติม)
 *   - disabled: boolean (เปิด/ปิดการใช้งาน)
 */
const getApiBase = () => {
  if (typeof window !== 'undefined' && window.location.hostname === 'siripaporn.lnw.mn') {
    return 'https://siripaporn.lnw.mn';
  }
  return import.meta.env.VITE_API_BASE_URL || 'https://siripaporn.lnw.mn';
};
const BASE = getApiBase();

export default function LearningCategorySelect({
  value,
  onChange,
  includeAllOption = false,
  className = "",
  disabled = false
}) {
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchCategories = async () => {
      try {
        let list = [];
        try {
          const res = await fetch(`${BASE}/endpoints/learning_category_api.php?action=getAll`);
          const json = await res.json();
          list = json.data || [];
        } catch (e) {
          console.warn("MySQL PHP API fetch error in LearningCategorySelect:", e);
        }

        if (!Array.isArray(list) || list.length === 0) {
          const { data, error } = await supabase
            .from("learning_category")
            .select("category_code, title, is_active")
            .order("category_code", { ascending: true });
          if (!error) list = data || [];
        }

        // Filter out inactive categories (is_active === false / 0 / "0") unless it matches current value
        const activeCategories = (list || []).filter(
          (c) => (c.is_active !== false && c.is_active !== "0" && c.is_active !== 0) || c.category_code === value
        );
        setCategories(activeCategories);
      } catch (err) {
        console.error("Error fetching learning categories for select dropdown:", err);
      } finally {
        setLoading(false);
      }
    };

    fetchCategories();
  }, [value]);

  return (
    <select
      value={value}
      onChange={(e) => onChange(e.target.value)}
      disabled={disabled || loading}
      className={`border rounded-xl px-4 py-2 bg-white text-gray-700 focus:outline-none focus:ring-2 focus:ring-orange-500 border-gray-300 cursor-pointer ${
        loading ? "opacity-60 cursor-not-allowed" : ""
      } ${className}`}
    >
      {includeAllOption && <option value="all">ทั้งหมด</option>}
      {!includeAllOption && <option value="">— กรุณาเลือกหมวดหมู่ —</option>}
      
      {categories.map((cat) => (
        <option key={cat.category_code} value={cat.category_code}>
          {cat.title}
        </option>
      ))}
    </select>
  );
}
