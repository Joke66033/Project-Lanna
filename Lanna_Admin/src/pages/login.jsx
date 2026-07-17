import { useState } from "react";
import { useNavigate, useLocation } from "react-router-dom";
import logo from "../assets/image/logo.png";

const BASE = import.meta.env.VITE_API_BASE_URL;

export default function Login() {
  const navigate = useNavigate();
  const location = useLocation();

  const [form, setForm] = useState({ email: "", password: "" });
  const [errors, setErrors] = useState({});
  const [apiError, setApiError] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [remember, setRemember] = useState(true);
  const [loading, setLoading] = useState(false);

  const validate = () => {
    const newErrors = {};
    if (!form.email.trim()) newErrors.email = "กรุณากรอกอีเมล";
    if (!form.password.trim()) newErrors.password = "กรุณากรอกรหัสผ่าน";
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e) => {
    e.preventDefault()
    setApiError("")
    if (!validate()) return
    setLoading(true)

    try {
      const res = await fetch(
        `${BASE}/endpoints/admin_user_api.php?action=login`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            email: form.email,
            password: form.password
          })
        }
      );
      const resData = await res.json();

      if (!res.ok || resData.error) {
        setApiError(resData.error?.message || 'อีเมลหรือรหัสผ่านไม่ถูกต้อง');
        return;
      }

      const adminData = resData.data;

      if (remember) {
        localStorage.setItem('admin_user', JSON.stringify(adminData))
      } else {
        sessionStorage.setItem('admin_user', JSON.stringify(adminData))
      }

      navigate('/dashboard', { replace: true })
    } catch (err) {
      setApiError('เกิดข้อผิดพลาด กรุณาลองใหม่')
    } finally {
      setLoading(false)
    }
  };

  const goForgotPassword = () => {
    navigate("/forgot-password", { state: { email: form.email } });
  };

  return (
    <div className="min-h-screen bg-[#f9f7f4] flex items-center justify-center p-6">
      <div className="w-full max-w-4xl bg-white rounded-3xl shadow-sm overflow-hidden border">
        <div className="grid grid-cols-1 md:grid-cols-2">

          {/* LEFT */}
          <div className="relative bg-gradient-to-b from-orange-50 to-[#fff7ed] p-10 flex items-center justify-center">
            <div className="absolute -top-14 -left-14 w-44 h-44 rounded-full bg-orange-200/40 blur-2xl" />
            <div className="absolute -bottom-14 -right-14 w-52 h-52 rounded-full bg-orange-300/30 blur-2xl" />

            <div className="relative text-center">
              <div className="mx-auto w-28 h-28 md:w-36 md:h-36 rounded-full overflow-hidden bg-white shadow-sm flex items-center justify-center">
                <img src={logo} alt="Lanna Logo" className="w-full h-full object-cover" style={{ borderRadius: '50%' }} />
              </div>

              <h1 className="mt-6 text-2xl md:text-3xl font-extrabold text-gray-900">
                ระบบแปลภาษาล้านนา
              </h1>
              <p className="mt-2 text-gray-500 text-sm md:text-base">
                เข้าสู่ระบบผู้ดูแลเพื่อจัดการข้อมูลในระบบ
              </p>

              <div className="mt-6 inline-flex items-center gap-2 px-4 py-2 rounded-full bg-white/70 border text-sm text-gray-600">
                <span className="w-2.5 h-2.5 rounded-full bg-orange-500" />
                Admin Panel
              </div>
            </div>
          </div>

          {/* RIGHT */}
          <div className="p-8 md:p-10">
            <div className="mb-6">
              <h2 className="text-2xl font-bold text-gray-900">
                เข้าสู่ระบบผู้ดูแล
              </h2>
              <p className="text-gray-500 text-sm mt-1">
                กรุณากรอกข้อมูลเพื่อเข้าสู่ระบบ
              </p>
            </div>

            {apiError && (
              <div className="mb-4 rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-600">
                {apiError}
              </div>
            )}

            <form onSubmit={handleSubmit} className="space-y-4">

              {/* EMAIL */}
              <div>
                <label className="text-sm font-medium text-gray-700">
                  อีเมล
                </label>
                <input
                  type="email"
                  value={form.email}
                  onChange={(e) => setForm({ ...form, email: e.target.value })}
                  placeholder="admin@gmail.com"
                  className={`mt-1 w-full rounded-2xl border px-4 py-3 outline-none focus:ring-2 focus:ring-orange-200 ${
                    errors.email ? "border-red-400" : "border-gray-200"
                  }`}
                />
                {errors.email && (
                  <p className="mt-1 text-xs text-red-500">{errors.email}</p>
                )}
              </div>

              {/* PASSWORD + EYE ICON */}
              <div>
                <label className="text-sm font-medium text-gray-700">
                  รหัสผ่าน
                </label>

                <div
                  className={`mt-1 input-group ${
                    errors.password ? "border-red-400" : ""
                  }`}
                >
                  <input
                    type={showPassword ? "text" : "password"}
                    value={form.password}
                    onChange={(e) =>
                      setForm({ ...form, password: e.target.value })
                    }
                    placeholder="123456"
                    className="flex-1 outline-none bg-transparent"
                  />

                  <button
                    type="button"
                    onClick={() => setShowPassword((prev) => !prev)}
                    className="text-gray-400 hover:text-orange-600 ml-2"
                    aria-label="toggle password"
                  >
                    {showPassword ? (
                      // ตาปิด
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        className="h-5 w-5"
                        fill="none"
                        stroke="currentColor"
                        strokeWidth="2"
                        viewBox="0 0 24 24"
                      >
                        <path d="M3 3l18 18" />
                        <path d="M10.5 10.5a3 3 0 104.243 4.243" />
                        <path d="M9.88 4.24A9.97 9.97 0 0112 4c5 0 9 8 9 8a16.22 16.22 0 01-4.62 5.27M6.53 6.53A16.14 16.14 0 003 12s4 8 9 8a9.77 9.77 0 004.24-.97" />
                      </svg>
                    ) : (
                      // ตาเปิด
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        className="h-5 w-5"
                        fill="none"
                        stroke="currentColor"
                        strokeWidth="2"
                        viewBox="0 0 24 24"
                      >
                        <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8S1 12 1 12z" />
                        <circle cx="12" cy="12" r="3" />
                      </svg>
                    )}
                  </button>
                </div>

                {errors.password && (
                  <p className="mt-1 text-xs text-red-500">
                    {errors.password}
                  </p>
                )}
              </div>

              {/* FORGOT */}
              <div className="flex items-center justify-end">
                <button
                  type="button"
                  onClick={goForgotPassword}
                  className="text-sm text-orange-600 hover:underline"
                >
                  ลืมรหัสผ่าน?
                </button>
              </div>

              {/* LOGIN BUTTON */}
              <button
                disabled={loading}
                className={`w-full rounded-2xl py-3 font-semibold text-white shadow-sm transition ${
                  loading
                    ? "bg-orange-300"
                    : "bg-orange-500 hover:bg-orange-600"
                }`}
              >
                {loading ? "กำลังเข้าสู่ระบบ..." : "เข้าสู่ระบบ"}
              </button>

            </form>
          </div>
        </div>
      </div>
    </div>
  );
}
