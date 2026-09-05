import { useState, useEffect } from 'react'
import { useNavigate, useLocation } from 'react-router-dom'

const getApiBase = () => {
  if (typeof window !== 'undefined' && window.location.hostname === 'siripaporn.lnw.mn') {
    return 'https://siripaporn.lnw.mn';
  }
  return import.meta.env.VITE_API_BASE_URL || 'https://siripaporn.lnw.mn';
};
const BASE = getApiBase();

export default function Otp() {
  const navigate = useNavigate()
  const location = useLocation()
  const email = location.state?.email || ""
  const initialToken = location.state?.token || ""
  const [currentToken, setCurrentToken] = useState(initialToken)
  const initialOtpSentAt = location.state?.otpSentAt || null

  const [otpArray, setOtpArray] = useState(["", "", "", "", "", ""])
  const [loading, setLoading] = useState(false)
  const [apiError, setApiError] = useState("")
  const [apiSuccess, setApiSuccess] = useState("")
  
  const [otpSentAt, setOtpSentAt] = useState(initialOtpSentAt)
  const [timeLeft, setTimeLeft] = useState(180)

  // Redirect back to forgot-password if email is missing
  useEffect(() => {
    if (!email) {
      navigate('/forgot-password', { replace: true })
    }
  }, [email, navigate])

  // Clear errors on load
  useEffect(() => {
    setApiError("")
    setApiSuccess("")
  }, [])

  // Calculate countdown time based on otpSentAt timestamp
  useEffect(() => {
    if (!otpSentAt) return;

    const calculateTimeLeft = () => {
      const diffSeconds = Math.floor((Date.now() - otpSentAt) / 1000);
      const remaining = 180 - diffSeconds;
      return remaining > 0 ? remaining : 0;
    };

    setTimeLeft(calculateTimeLeft());

    const interval = setInterval(() => {
      const remaining = calculateTimeLeft();
      setTimeLeft(remaining);
      if (remaining <= 0) {
        clearInterval(interval);
      }
    }, 1000);

    return () => clearInterval(interval);
  }, [otpSentAt]);

  const formatTime = (seconds) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  // EmailJS configurations
  const EMAILJS_SERVICE_ID = import.meta.env.VITE_EMAILJS_SERVICE_ID;
  const EMAILJS_TEMPLATE_ID = import.meta.env.VITE_EMAILJS_TEMPLATE_ID;
  const EMAILJS_PUBLIC_KEY = import.meta.env.VITE_EMAILJS_PUBLIC_KEY;

  const sendEmailViaEmailJS = async (toEmail, otp) => {
    if (!EMAILJS_SERVICE_ID || !EMAILJS_TEMPLATE_ID || !EMAILJS_PUBLIC_KEY) {
      console.log(`[Developer Debug Mode] OTP for ${toEmail} is: ${otp}`);
      alert(`[Developer Debug Mode]\nรหัส OTP สำหรับอีเมล ${toEmail} คือ: ${otp}\n\n(กรุณานำรหัสนี้ไปกรอกในช่อง OTP)`);
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

  const handleResendOtp = async () => {
    setApiError("")
    setApiSuccess("")
    setLoading(true)
    setOtpArray(["", "", "", "", "", ""])

    try {
      const res = await fetch(
        `${BASE}/endpoints/otp_api.php?action=send`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ email, type: "admin" }),
        }
      );
      const resData = await res.json();
      if (!res.ok || resData.error) {
        throw new Error(resData.error?.message || "ไม่สามารถส่งรหัส OTP ใหม่ได้");
      }

      if (resData.data && resData.data.token) {
        setCurrentToken(resData.data.token);
      }

      setOtpSentAt(Date.now())
      setApiSuccess("ส่งรหัส OTP ใหม่ไปยังอีเมลของท่านเรียบร้อยแล้ว")
      setTimeout(() => {
        setApiSuccess("")
      }, 5000)
    } catch (err) {
      console.error("Resend OTP error:", err)
      setApiError("ไม่สามารถส่งรหัส OTP ใหม่ได้ กรุณาลองอีกครั้ง")
    } finally {
      setLoading(false)
    }
  }

  const handleOtpChange = (value, index) => {
    const val = value.replace(/\D/g, "");
    const newOtp = [...otpArray];
    newOtp[index] = val ? val.slice(-1) : "";
    setOtpArray(newOtp);

    if (val && index < 5) {
      const nextInput = document.getElementById(`otp-${index + 1}`);
      if (nextInput) nextInput.focus();
    }
  };

  const handleOtpKeyDown = (e, index) => {
    if (e.key === "Backspace") {
      if (!otpArray[index] && index > 0) {
        const prevInput = document.getElementById(`otp-${index - 1}`);
        if (prevInput) {
          prevInput.focus();
          const newOtp = [...otpArray];
          newOtp[index - 1] = "";
          setOtpArray(newOtp);
        }
      } else {
        const newOtp = [...otpArray];
        newOtp[index] = "";
        setOtpArray(newOtp);
      }
    }
  };

  const handleOtpPaste = (e) => {
    e.preventDefault();
    const pasteData = e.clipboardData.getData("text").replace(/\D/g, "").slice(0, 6);
    if (pasteData.length === 6) {
      const newOtp = pasteData.split("");
      setOtpArray(newOtp);
      const lastInput = document.getElementById("otp-5");
      if (lastInput) lastInput.focus();
    }
  };

  const handleSubmitOtp = async (e) => {
    e.preventDefault()
    setApiError("")
    setApiSuccess("")

    const otpCode = otpArray.join('')
    if (otpCode.length !== 6) {
      setApiError("กรุณากรอกรหัส OTP ให้ครบ 6 หลัก")
      return;
    }

    setLoading(true)

    try {
      const res = await fetch(
        `${BASE}/endpoints/otp_api.php?action=verify`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ email, otp: otpCode, type: "admin", token: currentToken }),
        }
      );
      const resData = await res.json();
      
      if (!res.ok || resData.error) {
        throw new Error(resData.error?.message || "รหัส OTP ไม่ถูกต้องหรือหมดอายุ");
      }

      setApiSuccess("ยืนยันรหัส OTP สำเร็จ")
      setTimeout(() => {
        setApiSuccess("")
        navigate("/reset-password", { state: { email, resetToken: resData.data.resetToken } })
      }, 1000)
    } catch (err) {
      console.error("OTP verification error:", err)
      setApiError(err.message || "รหัส OTP ไม่ถูกต้องหรือหมดอายุ")
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
                  s === 2
                    ? 'bg-orange-500 text-white ring-4 ring-orange-100'
                    : s === 1
                    ? 'bg-green-500 text-white'
                    : 'bg-gray-100 text-black font-bold'
                }`}
              >
                {s === 1 ? '✓' : s}
              </div>
              {s < 3 && (
                <div
                  className={`h-0.5 w-10 ml-3 transition-colors duration-300 ${
                    s === 1 ? 'bg-green-500' : 'bg-gray-200'
                  }`}
                />
              )}
            </div>
          ))}
        </div>

        {/* HEADER */}
        <div className="mb-6 text-center">
          <h2 className="text-2xl font-bold text-black">ยืนยันรหัส OTP</h2>
          <p className="text-black font-medium text-sm mt-1">กรอกรหัส OTP 6 หลักที่ส่งไปยัง {email}</p>
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

        {/* TIME CONTROLS */}
        {timeLeft > 0 ? (
          <form onSubmit={handleSubmitOtp} className="space-y-6">
            <div>
              <label className="block text-sm font-semibold text-black mb-3 text-center">
                รหัสยืนยัน OTP (6 หลัก)
              </label>
              
              <div className="flex justify-center gap-2 mb-4" onPaste={handleOtpPaste}>
                {otpArray.map((digit, idx) => (
                  <input
                    key={idx}
                    id={`otp-${idx}`}
                    type="text"
                    inputMode="numeric"
                    maxLength={1}
                    value={digit}
                    onChange={(e) => handleOtpChange(e.target.value, idx)}
                    onKeyDown={(e) => handleOtpKeyDown(e, idx)}
                    className="w-12 h-12 border-2 border-gray-200 text-center text-2xl font-bold text-black rounded-xl focus:border-[#f97316] focus:outline-none focus:ring-2 focus:ring-orange-200 transition"
                  />
                ))}
              </div>

              <p className={`text-center text-sm font-semibold transition-colors duration-300 ${
                timeLeft < 60 ? 'text-red-600 font-bold' : 'text-orange-500'
              }`}>
                รหัสหมดอายุใน {formatTime(timeLeft)}
              </p>
            </div>

            <button
              type="submit"
              disabled={loading || otpArray.some(d => !d)}
              className={`w-full rounded-2xl py-3 font-semibold text-white shadow-sm transition ${
                loading || otpArray.some(d => !d)
                  ? "bg-orange-300 cursor-not-allowed"
                  : "bg-orange-500 hover:bg-orange-600"
              }`}
            >
              {loading ? "กำลังตรวจสอบ..." : "ยืนยัน OTP"}
            </button>
          </form>
        ) : (
          <div className="space-y-6 text-center animate-[fadeIn_0.3s_ease-out]">
            <div className="rounded-2xl border border-red-200 bg-red-50 px-4 py-4 text-sm text-red-600 font-semibold">
              รหัส OTP หมดอายุแล้ว กรุณาขอรหัสใหม่
            </div>
            <button
              type="button"
              onClick={handleResendOtp}
              disabled={loading}
              className={`w-full rounded-2xl py-3 font-semibold text-white shadow-sm transition ${
                loading ? "bg-orange-300 cursor-not-allowed" : "bg-orange-500 hover:bg-orange-600"
              }`}
            >
              {loading ? "กำลังส่งรหัสใหม่..." : "ส่งรหัสใหม่"}
            </button>
          </div>
        )}

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
