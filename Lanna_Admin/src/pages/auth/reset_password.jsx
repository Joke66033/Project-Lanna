import { useState, useEffect } from 'react'
import { useNavigate, useLocation } from 'react-router-dom'

const getApiBase = () => {
  if (typeof window !== 'undefined' && window.location.hostname === 'siripaporn.lnw.mn') {
    return 'https://siripaporn.lnw.mn';
  }
  return import.meta.env.VITE_API_BASE_URL || 'https://siripaporn.lnw.mn';
};
const BASE = getApiBase();

export default function ResetPassword() {
  const navigate = useNavigate()
  const location = useLocation()
  const email = location.state?.email || ""
  const resetToken = location.state?.resetToken || ""

  const [password, setPassword] = useState("")
  const [confirmPassword, setConfirmPassword] = useState("")
  const [loading, setLoading] = useState(false)
  const [apiError, setApiError] = useState("")
  const [apiSuccess, setApiSuccess] = useState("")
  const [errors, setErrors] = useState({})
  const [showPassword, setShowPassword] = useState(false)
  const [showConfirmPassword, setShowConfirmPassword] = useState(false)
  const [toast, setToast] = useState({ show: false, message: "" })

  // Redirect back to forgot-password if email or resetToken is missing
  useEffect(() => {
    if (!email || !resetToken) {
      navigate('/forgot-password', { replace: true })
    }
  }, [email, resetToken, navigate])

  // Clear errors on load
  useEffect(() => {
    setApiError("")
    setApiSuccess("")
    setErrors({})
  }, [])

  const handleSubmitReset = async (e) => {
    e.preventDefault()
    setApiError("")
    setApiSuccess("")
    setErrors({})

    const newErrors = {}
    if (!password) {
      newErrors.password = "กรุณากรอกรหัสผ่านใหม่"
    } else if (password.length < 6) {
      newErrors.password = "รหัสผ่านต้องยาวอย่างน้อย 6 ตัวอักษร"
    }

    if (!confirmPassword) {
      newErrors.confirmPassword = "กรุณายืนยันรหัสผ่าน"
    } else if (password !== confirmPassword) {
      newErrors.confirmPassword = "รหัสผ่านไม่ตรงกัน"
    }

    if (Object.keys(newErrors).length > 0) {
      setErrors(newErrors)
      return;
    }

    setLoading(true)

    try {
      const resetRes = await fetch(
        `${BASE}/endpoints/otp_api.php?action=resetPassword`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            newPassword: password,
            resetToken: resetToken
          }),
        }
      );
      const resData = await resetRes.json();
      if (!resetRes.ok || resData.error) {
        throw new Error(resData.error?.message || "ไม่สามารถตั้งรหัสผ่านใหม่ได้");
      }

      setToast({ show: true, message: "เปลี่ยนรหัสผ่านสำเร็จ" })
      setTimeout(() => {
        setToast({ show: false, message: "" })
        navigate('/login', { replace: true })
      }, 3000)
    } catch (err) {
      console.error("Reset password error:", err)
      setApiError(err.message || "เกิดข้อผิดพลาดในการตั้งรหัสผ่านใหม่ กรุณาลองใหม่อีกครั้ง")
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-[#f9f7f4] flex items-center justify-center p-6 animate-[fadeIn_0.3s_ease-out]">
      <div className="w-full max-w-md bg-white rounded-3xl shadow-sm overflow-hidden border p-8 md:p-10">
        
        {/* STEP INDICATOR */}
        <div className="flex items-center justify-center mb-8 gap-3">
          {[1, 2, 3].map((s) => (
            <div key={s} className="flex items-center">
              <div
                className={`w-9 h-9 rounded-full flex items-center justify-center font-bold text-sm transition-all duration-300 ${
                  s === 3
                    ? 'bg-orange-500 text-white ring-4 ring-orange-100'
                    : 'bg-green-500 text-white'
                }`}
              >
                {s < 3 ? '✓' : s}
              </div>
              {s < 3 && (
                <div className="h-0.5 w-10 ml-3 bg-green-500" />
              )}
            </div>
          ))}
        </div>

        {/* HEADER */}
        <div className="mb-6 text-center">
          <h2 className="text-2xl font-bold text-black">ตั้งรหัสผ่านใหม่</h2>
          <p className="text-black font-medium text-sm mt-1">กรุณากรอกรหัสผ่านใหม่ที่ต้องการใช้งาน</p>
        </div>

        {/* MESSAGES */}
        {apiError && (
          <div className="mb-4 rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-600">
            {apiError}
          </div>
        )}
        {apiSuccess && (
          <div className="mb-4 rounded-2xl border border-green-200 bg-green-50 px-4 py-3 text-sm text-green-600">
            {apiSuccess}
          </div>
        )}

        <form onSubmit={handleSubmitReset} className="space-y-4">
          <div>
            <label className="text-sm font-semibold text-black">รหัสผ่านใหม่</label>
            <div
              className={`mt-1 input-group ${
                errors.password ? "border-red-400" : ""
              }`}
            >
              <input
                type={showPassword ? "text" : "password"}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="กรอกรหัสผ่านอย่างน้อย 6 ตัวอักษร"
                className="flex-1 outline-none bg-transparent text-black"
              />
              <button
                type="button"
                onClick={() => setShowPassword((prev) => !prev)}
                className="text-gray-500 hover:text-black ml-2"
                aria-label="toggle password"
              >
                {showPassword ? (
                  <svg className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                    <path d="M3 3l18 18" />
                    <path d="M10.5 10.5a3 3 0 104.243 4.243" />
                    <path d="M9.88 4.24A9.97 9.97 0 0112 4c5 0 9 8 9 8a16.22 16.22 0 01-4.62 5.27M6.53 6.53A16.14 16.14 0 003 12s4 8 9 8a9.77 9.77 0 004.24-.97" />
                  </svg>
                ) : (
                  <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                    <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8S1 12 1 12z" />
                    <circle cx="12" cy="12" r="3" />
                  </svg>
                )}
              </button>
            </div>
            {errors.password && (
              <p className="mt-1 text-xs text-red-500">{errors.password}</p>
            )}
          </div>

          <div>
            <label className="text-sm font-semibold text-black">ยืนยันรหัสผ่านใหม่</label>
            <div
              className={`mt-1 input-group ${
                errors.confirmPassword ? "border-red-400" : ""
              }`}
            >
              <input
                type={showConfirmPassword ? "text" : "password"}
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                placeholder="กรอกรหัสผ่านใหม่อีกครั้ง"
                className="flex-1 outline-none bg-transparent text-black"
              />
              <button
                type="button"
                onClick={() => setShowConfirmPassword((prev) => !prev)}
                className="text-gray-500 hover:text-black ml-2"
                aria-label="toggle confirm password"
              >
                {showConfirmPassword ? (
                  <svg className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                    <path d="M3 3l18 18" />
                    <path d="M10.5 10.5a3 3 0 104.243 4.243" />
                    <path d="M9.88 4.24A9.97 9.97 0 0112 4c5 0 9 8 9 8a16.22 16.22 0 01-4.62 5.27M6.53 6.53A16.14 16.14 0 003 12s4 8 9 8a9.77 9.77 0 004.24-.97" />
                  </svg>
                ) : (
                  <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                    <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8S1 12 1 12z" />
                    <circle cx="12" cy="12" r="3" />
                  </svg>
                )}
              </button>
            </div>
            {errors.confirmPassword && (
              <p className="mt-1 text-xs text-red-500">{errors.confirmPassword}</p>
            )}
          </div>
          
          {/* PASSWORD CHECKLIST */}
          <div className="mt-4 space-y-2">
            <div className="flex items-center gap-2 text-sm font-medium">
              {password.length >= 6 ? (
                <span className="text-green-600 flex items-center gap-1.5">
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
                  </svg>
                  ตั้งรหัสผ่าน 6 ตัวขึ้นไป
                </span>
              ) : (
                <span className="text-red-500 flex items-center gap-1.5">
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
                  </svg>
                  ตั้งรหัสผ่าน 6 ตัวขึ้นไป
                </span>
              )}
            </div>
            <div className="flex items-center gap-2 text-sm font-medium">
              {/[a-zA-Z]/.test(password) ? (
                <span className="text-green-600 flex items-center gap-1.5">
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
                  </svg>
                  มีตัวอักษรอย่างน้อย 1 ตัว
                </span>
              ) : (
                <span className="text-red-500 flex items-center gap-1.5">
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
                  </svg>
                  มีตัวอักษรอย่างน้อย 1 ตัว
                </span>
              )}
            </div>
          </div>

          <button
            disabled={loading || password.length < 6 || !/[a-zA-Z]/.test(password)}
            className={`w-full rounded-2xl py-3 font-semibold text-white shadow-sm transition ${
              (loading || password.length < 6 || !/[a-zA-Z]/.test(password))
                ? "bg-orange-300 cursor-not-allowed"
                : "bg-orange-500 hover:bg-orange-600"
            }`}
          >
            {loading ? "กำลังบันทึก..." : "บันทึกรหัสผ่านใหม่"}
          </button>
        </form>

        {/* BACK TO LOGIN */}
        <div className="mt-6 text-center">
          <button
            type="button"
            onClick={() => navigate('/login')}
            className="text-sm font-semibold text-orange-500 hover:underline hover:text-orange-600"
          >
            ย้อนกลับไปหน้าเข้าสู่ระบบ
          </button>
        </div>

      </div>

      {/* Toast Notification */}
      {toast.show && (
        <div className="fixed top-5 right-5 z-50 flex items-center gap-3 bg-green-600 text-white px-6 py-4 rounded-2xl shadow-xl border border-green-500/30 transform transition-all duration-300 animate-[fadeIn_0.3s_ease-out]">
          <svg className="h-6 w-6" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
          </svg>
          <span className="font-semibold">{toast.message}</span>
        </div>
      )}

    </div>
  )
}
