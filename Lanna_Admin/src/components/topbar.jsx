import { useState, useEffect } from "react";
import { useNavigate, useLocation } from "react-router-dom";
import { categoryColors } from "../lib/categoryColors";

export default function Topbar() {
  const [open, setOpen] = useState(false);
  const [adminData, setAdminData] = useState(null);
  const navigate = useNavigate();
  const location = useLocation();

  // ดึงข้อมูลแอดมินล่าสุดจาก storage ของเบราว์เซอร์ทุกครั้งที่เปลี่ยนหน้า
  useEffect(() => {
    const loadAdminData = () => {
      const stored = localStorage.getItem("admin_user") || sessionStorage.getItem("admin_user");
      if (stored) {
        try {
          setAdminData(JSON.parse(stored));
        } catch (e) {
          console.error("Failed to parse admin data from storage", e);
        }
      }
    };

    loadAdminData();

    // ฟังเหตุการณ์อัปเดตโปรไฟล์เพื่อเปลี่ยนภาพ/ข้อมูลทันทีโดยไม่ต้องเปลี่ยนหน้าหรือรีโหลด
    window.addEventListener("admin_profile_updated", loadAdminData);
    return () => {
      window.removeEventListener("admin_profile_updated", loadAdminData);
    };
  }, [location]);

  const adminName = adminData?.name || "Admin Lanna";
  const avatar = adminData?.avatar || null;
  const initial = adminName.charAt(0).toUpperCase();

  const handleLogout = () => {
    localStorage.removeItem("admin_user");
    sessionStorage.removeItem("admin_user");
    localStorage.removeItem("admin_token");
    sessionStorage.removeItem("admin_token");
    navigate("/login", { replace: true });
  };

  const getBorderClass = () => {
    const path = location.pathname;
    if (path.startsWith("/vocabulary")) return "border-orange-600";
    if (path.startsWith("/alphabet")) return "border-amber-600";
    if (path.startsWith("/categoryAlphabet")) return "border-emerald-600";
    if (path.startsWith("/categoryLannaChar")) return "border-teal-600";
    if (path.startsWith("/categoryLearning")) return "border-sky-600";
    if (path.startsWith("/articles")) return "border-violet-600";
    if (path.startsWith("/users")) return "border-rose-600";
    return "border-gray-200";
  };

  return (
    <div className={`h-14 bg-white border-b-2 ${getBorderClass()} px-6 flex items-center justify-end relative`}>
      {/* ===== ADMIN PROFILE ===== */}
      <div
        className="flex items-center gap-3 cursor-pointer select-none"
        onClick={() => setOpen(!open)}
      >
        {/* Name */}
        <span className="text-base text-gray-700 font-medium">{adminName}</span>

        {/* Avatar */}
        <div className="w-9 h-9 rounded-full overflow-hidden bg-orange-500 text-white flex items-center justify-center font-semibold text-base">
          {avatar ? (
            <img
              src={avatar}
              alt="admin-avatar"
              className="w-full h-full object-cover"
            />
          ) : (
            initial
          )}
        </div>
      </div>

      {/* ===== DROPDOWN ===== */}
      {open && (
        <div className="absolute right-6 top-14 mt-2 w-56 bg-white border rounded-xl shadow-lg overflow-hidden z-50">
          <button
            onClick={() => {
              setOpen(false);
              navigate("/admin-profile"); // หน้าแก้ไขข้อมูล admin
            }}
            className="w-full text-left px-4 py-3 text-base hover:bg-gray-100"
          >
            จัดการข้อมูลผู้ดูแล
          </button>

          <button
            onClick={handleLogout}
            className="w-full text-left px-4 py-3 text-base text-red-500 hover:bg-red-50"
          >
            ออกจากระบบ
          </button>
        </div>
      )}
    </div>
  );
}
