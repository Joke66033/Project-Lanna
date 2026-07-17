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
        const { data, error } = await supabase
          .from("learning_category")
          .select("category_code, title")
          .order("category_code", { ascending: true });

        if (error) throw error;
        setCategories(data || []);
      } catch (err) {
        console.error("Error fetching learning categories for select dropdown:", err);
      } finally {
        setLoading(false);
      }
    };

    fetchCategories();
  }, []);

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
