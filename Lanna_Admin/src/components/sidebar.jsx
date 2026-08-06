import { useState, useEffect } from "react";
import { NavLink, useNavigate, useLocation } from "react-router-dom";
import logo from '../assets/image/logo.png';
import { supabase } from "../lib/supabaseClient";
import { ChevronDown, ChevronUp } from "lucide-react";
import { categoryColors } from "../lib/categoryColors";

export default function Sidebar() {
  const navigate = useNavigate();
  const location = useLocation();
  const [categories, setCategories] = useState([]);
  const [vocabCategories, setVocabCategories] = useState([]);
  
  const isAlphabetPage = location.pathname === "/alphabet";
  const [isOpen, setIsOpen] = useState(isAlphabetPage);

  const isVocabPage = location.pathname === "/vocabulary";
  const [isVocabOpen, setIsVocabOpen] = useState(isVocabPage);

  // Auto-expand the dropdown when navigating to the alphabet page
  useEffect(() => {
    if (isAlphabetPage) {
      setIsOpen(true);
    }
  }, [isAlphabetPage]);

  // Auto-expand the dropdown when navigating to the vocabulary page
  useEffect(() => {
    if (isVocabPage) {
      setIsVocabOpen(true);
    }
  }, [isVocabPage]);

  // Fetch categories from category_lanna_char dynamically
  useEffect(() => {
    const fetchCategories = async () => {
      try {
        const { data, error } = await supabase
          .from("category_lanna_char")
          .select("category_char_id, name")
          .order("category_char_id", { ascending: true });
        if (!error && data) {
          setCategories(data);
        }
      } catch (err) {
        console.error("Error fetching sidebar categories:", err);
      }
    };
    
    fetchCategories();

    // Subscribe to database changes to keep sidebar categories sync in real-time
    const catChannel = supabase
      .channel('sidebar_categories_sync')
      .on('postgres_changes', 
        { event: '*', schema: 'public', table: 'category_lanna_char' },
        () => fetchCategories()
      )
      .subscribe();

    return () => {
      supabase.removeChannel(catChannel);
    };
  }, []);

  // Fetch categories from category_vocab dynamically
  useEffect(() => {
    const fetchVocabCategories = async () => {
      try {
        const { data, error } = await supabase
          .from("category_vocab")
          .select("category_vocab_id, name")
          .order("category_vocab_id", { ascending: true });
        if (!error && data) {
          setVocabCategories(data);
        }
      } catch (err) {
        console.error("Error fetching sidebar vocab categories:", err);
      }
    };
    
    fetchVocabCategories();

    // Subscribe to database changes to keep sidebar vocab categories sync in real-time
    const vocabCatChannel = supabase
      .channel('sidebar_vocab_categories_sync')
      .on('postgres_changes', 
        { event: '*', schema: 'public', table: 'category_vocab' },
        () => fetchVocabCategories()
      )
      .subscribe();

    return () => {
      supabase.removeChannel(vocabCatChannel);
    };
  }, []);

  return (
    <aside className="w-64 bg-gray-50 border-r border-gray-200 text-gray-700 min-h-screen flex flex-col shrink-0 select-none">

      {/* ===== HEADER (Gradient Orange Accented) ===== */}
      <div className="flex items-center gap-3 px-5 py-4 border-b border-orange-100 bg-gradient-to-r from-orange-50/70 to-orange-100/30">
        <div className="w-12 h-12 rounded-full overflow-hidden bg-white flex items-center justify-center border border-orange-100 shadow-sm">
          <img src={logo} alt="Lanna Logo" className="w-full h-full object-cover" style={{ borderRadius: '50%' }} />
        </div>

        <div className="leading-tight">
          <div className="text-[17px] font-bold text-gray-900">
            Lanna translation
          </div>
          <div className="text-[13px] text-orange-600 font-medium">
            ระบบของผู้ดูแล
          </div>
        </div>
      </div>

      {/* ===== MENU ===== */}
      <nav className="flex-1 p-4 space-y-1.5 overflow-y-auto">
        
        {/* รายงานสถิติ */}
        <NavLink
          to="/dashboard"
          className={({ isActive }) =>
            `block px-4 py-2 rounded-lg text-base font-medium transition ${
              isActive
                ? `${categoryColors.dashboard.sidebarActive} font-bold pl-3 shadow-sm`
                : `${categoryColors.dashboard.sidebarNormal}`
            }`
          }
        >
          รายงานสถิติ
        </NavLink>

        {/* จัดการข้อมูลคำศัพท์ */}
        <NavLink
          to="/vocabulary"
          className={({ isActive }) =>
            `block px-4 py-2 rounded-lg text-base font-medium transition ${
              isActive || isVocabPage
                ? `${categoryColors.vocabulary.sidebarActive} font-bold pl-3 shadow-sm`
                : `${categoryColors.vocabulary.sidebarNormal}`
            }`
          }
        >
          จัดการข้อมูลคำศัพท์
        </NavLink>

        {/* จัดการข้อมูลอักขระ */}
        <NavLink
          to="/alphabet"
          className={({ isActive }) =>
            `block px-4 py-2 rounded-lg text-base font-medium transition ${
              isActive || isAlphabetPage
                ? `${categoryColors.alphabet.sidebarActive} font-bold pl-3 shadow-sm`
                : `${categoryColors.alphabet.sidebarNormal}`
            }`
          }
        >
          จัดการข้อมูลอักขระ
        </NavLink>

        {/* จัดการเส้นทางการวาดอักขระ */}
        <NavLink
          to="/characterStrokes"
          className={({ isActive }) =>
            `block px-4 py-2 rounded-lg text-base font-medium transition ${
              isActive
                ? `${categoryColors.alphabet.sidebarActive} font-bold pl-3 shadow-sm`
                : `${categoryColors.alphabet.sidebarNormal}`
            }`
          }
        >
          จัดการเส้นทางการวาดอักขระ
        </NavLink>

        {/* จัดการหมวดหมู่คำศัพท์ */}
        <NavLink
          to="/categoryAlphabet"
          className={({ isActive }) =>
            `block px-4 py-2 rounded-lg text-base font-medium transition ${
              isActive
                ? `${categoryColors.categoryVocab.sidebarActive} font-bold pl-3 shadow-sm`
                : `${categoryColors.categoryVocab.sidebarNormal}`
            }`
          }
        >
          จัดการหมวดหมู่คำศัพท์
        </NavLink>

        {/* จัดการหมวดหมู่อักขระ */}
        <NavLink
          to="/categoryLannaChar"
          className={({ isActive }) =>
            `block px-4 py-2 rounded-lg text-base font-medium transition ${
              isActive
                ? `${categoryColors.categoryAlphabet.sidebarActive} font-bold pl-3 shadow-sm`
                : `${categoryColors.categoryAlphabet.sidebarNormal}`
            }`
          }
        >
          จัดการหมวดหมู่อักขระ
        </NavLink>

        {/* จัดการหมวดหมู่การเรียนรู้ */}
        <NavLink
          to="/categoryLearning"
          className={({ isActive }) =>
            `block px-4 py-2 rounded-lg text-base font-medium transition ${
              isActive
                ? `${categoryColors.categoryLearning.sidebarActive} font-bold pl-3 shadow-sm`
                : `${categoryColors.categoryLearning.sidebarNormal}`
            }`
          }
        >
          จัดการหมวดหมู่การเรียนรู้
        </NavLink>

        {/* จัดการเนื้อหาการเรียนรู้อักขระล้านนา */}
        <NavLink
          to="/articles"
          className={({ isActive }) =>
            `block px-4 py-2 rounded-lg text-base font-medium transition ${
              isActive
                ? `${categoryColors.articles.sidebarActive} font-bold pl-3 shadow-sm`
                : `${categoryColors.articles.sidebarNormal}`
            }`
          }
        >
          จัดการเนื้อหาการเรียนรู้อักขระล้านนา
        </NavLink>

        {/* จัดการสมาชิก */}
        <NavLink
          to="/users"
          className={({ isActive }) =>
            `block px-4 py-2 rounded-lg text-base font-medium transition ${
              isActive
                ? `${categoryColors.users.sidebarActive} font-bold pl-3 shadow-sm`
                : `${categoryColors.users.sidebarNormal}`
            }`
          }
        >
          จัดการสมาชิก
        </NavLink>
      </nav>
    </aside>
  );
}
