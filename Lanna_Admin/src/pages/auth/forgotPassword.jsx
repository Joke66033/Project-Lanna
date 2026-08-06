import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'

const getApiBase = () => {
  if (typeof window !== 'undefined' && window.location.hostname === 'siripaporn.lnw.mn') {
    return 'https://siripaporn.lnw.mn';
  }
  return import.meta.env.VITE_API_BASE_URL || 'https://siripaporn.lnw.mn';
};
const BASE = getApiBase();

export default function ForgotPassword() {
  const navigate = useNavigate()

  const [email, setEmail] = useState("")
  const [loading, setLoading] = useState(false)
  const [apiError, setApiError] = useState("")
  const [apiSuccess, setApiSuccess] = useState("")
  const [errors, setErrors] = useState({})

  // เคลียร์ error และรีเซ็ตค่าเริ่มต้นเมื่อเปิดหน้าครั้งแรก (Component Mount)
  useEffect(() => {
    setApiError("");
    setErrors({});
  }, []);

  // แปลงข้อความ error เป็นภาษาไทย
  const translateError = (message) => {
    if (!message) return "เกิดข้อผิดพลาดในการดำเนินการ";
    const lower = message.toLowerCase();
    if (lower.includes("user not found") || lower.includes("no user found")) {
      return "ไม่พบข้อมูลผู้ดูแลระบบ";
    }
    return "เกิดข้อผิดพลาดในการกู้คืนรหัสผ่าน กรุณาลองใหม่อีกครั้ง";
  };

  // ================= CONFIG EMAILJS =================
  const EMAILJS_SERVICE_ID = import.meta.env.VITE_EMAILJS_SERVICE_ID;
  const EMAILJS_TEMPLATE_ID = import.meta.env.VITE_EMAILJS_TEMPLATE_ID;
  const EMAILJS_PUBLIC_KEY = import.meta.env.VITE_EMAILJS_PUBLIC_KEY;

  const sendEmailViaEmailJS = async (toEmail, otp) => {
    if (!EMAILJS_SERVICE_ID || !EMAILJS_TEMPLATE_ID || !EMAILJS_PUBLIC_KEY) {
      console.log(`[Developer Debug Mode] OTP for ${toEmail} is: ${otp}`);
      alert(`[Developer Debug Mode]\nรหัส OTP สำหรับอีเมล ${toEmail} คือ: ${otp}\n\n(กรุณานำรหัสนี้ไปกรอกในหน้าถัดไป)`);
      return;
    }

    try {
      const response = await fetch("https://api.emailjs.com/api/v1.0/email/send", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          service_id: EMAILJS_SERVICE_ID,
          template_id: EMAILJS_TEMPLATE_ID,
          user_id: EMAILJS_PUBLIC_KEY,
          template_params: {
            to_email: toEmail,
            otp_code: otp,
          },
        }),
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`EmailJS Response Error: ${errorText}`);
      }
    } catch (error) {
      console.error("Failed to send email via EmailJS:", error);
      alert(`[Fallback Mode] ไม่สามารถส่งเมลได้: ${error.message}\nแต่รหัส OTP ของคุณคือ: ${otp}`);
    }
  };

  const handleSendOtp = async (e) => {
    e.preventDefault()
    setApiError("")
    setApiSuccess("")
    setErrors({})

    if (!email.trim()) {
      setErrors({ email: "กรุณากรอกอีเมล" })
      return;
    }

    setLoading(true)

    try {
      const res = await fetch(
        `${BASE}/endpoints/otp_api.php?action=send`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ email: email.trim(), type: "admin" }),
        }
      );
      const resData = await res.json();
      
      if (!res.ok || resData.error) {
        throw new Error(resData.error?.message || "เกิดข้อผิดพลาดในการส่ง OTP");
      }

      setApiSuccess("ส่งรหัส OTP เรียบร้อยแล้ว")
      const sentTime = Date.now();
      setTimeout(() => {
        setApiSuccess("")
        navigate("/otp", { state: { email: email.trim(), token: resData.data.token, otpSentAt: sentTime } })
      }, 1000)
    } catch (err) {
      console.error("Step 1 error:", err)
      setApiError(translateError(err.message))
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
                  s === 1
                    ? 'bg-orange-500 text-white ring-4 ring-orange-100'
                    : 'bg-gray-100 text-gray-400'
                }`}
              >
                {s}
              </div>
              {s < 3 && (
                <div className="h-0.5 w-10 ml-3 bg-gray-200" />
              )}
            </div>
          ))}
        </div>

        {/* HEADER */}
        <div className="mb-6 text-center">
          <h2 className="text-2xl font-bold text-gray-900">กู้คืนรหัสผ่าน</h2>
          <p className="text-gray-500 text-sm mt-1">กรุณากรอกอีเมลของท่านเพื่อรับรหัส OTP</p>
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

        <form onSubmit={handleSendOtp} className="space-y-4">
          <div>
            <label className="text-sm font-medium text-gray-700">อีเมลผู้ดูแล</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="example@gmail.com"
              className={`mt-1 w-full rounded-2xl border px-4 py-3 outline-none focus:ring-2 focus:ring-orange-200 transition ${
                errors.email ? "border-red-400" : "border-gray-200"
              }`}
            />
            {errors.email && (
              <p className="mt-1 text-xs text-red-500">{errors.email}</p>
            )}
          </div>

          <button
            disabled={loading}
            className={`w-full rounded-2xl py-3 font-semibold text-white shadow-sm transition ${
              loading ? "bg-orange-300 cursor-not-allowed" : "bg-orange-500 hover:bg-orange-600"
            }`}
          >
            {loading ? "กำลังส่ง OTP..." : "ส่ง OTP"}
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
    </div>
  )
}