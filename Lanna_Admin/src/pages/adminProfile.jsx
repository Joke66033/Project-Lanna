import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import Swal from "sweetalert2";
import logo from "../assets/image/logo.png";
import { supabase } from "../lib/supabaseClient";

const BASE = import.meta.env.VITE_API_BASE_URL;

export default function AdminProfile() {
  const [isEditing, setIsEditing] = useState(false);
  const [avatar, setAvatar] = useState(null);
  const [avatarFile, setAvatarFile] = useState(null);
  const [adminData, setAdminData] = useState(null);
  const [loading, setLoading] = useState(false);

  const [profile, setProfile] = useState({
    name: "Admin Lanna",
    email: "admin@gmail.com",
    newPassword: "",
    confirmPassword: "",
  });

  const [showNewPassword, setShowNewPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [passwordError, setPasswordError] = useState("");
  const [nameError, setNameError] = useState("");
  const [emailError, setEmailError] = useState("");
  const [showSuccessModal, setShowSuccessModal] = useState(false);

  const navigate = useNavigate();

  // กำหนดสไตล์ของปุ่มใน SweetAlert2 ให้เด่นชัดและสวยงามตามธีม Tailwind
  const swalCustomButtons = {
    confirmButton: "bg-green-500 text-white px-6 py-2.5 rounded-lg text-sm font-medium hover:bg-green-600 transition duration-150 focus:outline-none focus:ring-2 focus:ring-green-400 focus:ring-offset-2 mx-2",
    cancelButton: "bg-gray-500 text-white px-6 py-2.5 rounded-lg text-sm font-medium hover:bg-gray-600 transition duration-150 focus:outline-none focus:ring-2 focus:ring-gray-400 focus:ring-offset-2 mx-2"
  };

  const swalErrorButtons = {
    confirmButton: "bg-red-500 text-white px-6 py-2.5 rounded-lg text-sm font-medium hover:bg-red-600 transition duration-150 focus:outline-none focus:ring-2 focus:ring-red-400 focus:ring-offset-2 mx-2",
    cancelButton: "bg-gray-500 text-white px-6 py-2.5 rounded-lg text-sm font-medium hover:bg-gray-600 transition duration-150 focus:outline-none focus:ring-2 focus:ring-gray-400 focus:ring-offset-2 mx-2"
  };

  // แปลงข้อความ error เป็นภาษาไทย
  const translateError = (message) => {
    if (!message) return "เกิดข้อผิดพลาดในการดำเนินการ";
    const lower = message.toLowerCase();
    if (lower.includes("email already") || lower.includes("unique_email")) {
      return "อีเมลนี้ถูกใช้งานแล้วในระบบ";
    }
    return message || "เกิดข้อผิดพลาดในการบันทึกข้อมูล กรุณาลองใหม่อีกครั้ง";
  };

  useEffect(() => {
    const stored = localStorage.getItem("admin_user") || sessionStorage.getItem("admin_user");
    if (stored) {
      try {
        const data = JSON.parse(stored);
        setAdminData(data);
        setProfile({
          name: data.name || "",
          email: data.email || "",
          newPassword: "",
          confirmPassword: "",
        });
        setAvatar(data.avatar || null);
      } catch (e) {
        console.error("Failed to parse admin data from storage", e);
      }
    }
  }, []);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setProfile({ ...profile, [name]: value });
    if (name === "name") {
      if (value.trim() !== "") {
        setNameError("");
      }
    }
    if (name === "email") {
      if (value.trim() !== "") {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (emailRegex.test(value.trim())) {
          setEmailError("");
        } else {
          setEmailError("รูปแบบอีเมลไม่ถูกต้อง");
        }
      } else {
        setEmailError("");
      }
    }
  };

  const handleAvatarChange = (e) => {
    const file = e.target.files[0];
    if (!file) return;

    setAvatarFile(file);

    const reader = new FileReader();
    reader.onloadend = () => setAvatar(reader.result);
    reader.readAsDataURL(file);
  };

  const uploadProfileImage = async (file) => {
    if (!adminData?.admin_id) return null;

    const formData = new FormData();
    formData.append("id", adminData.admin_id);
    formData.append("type", "admin");
    formData.append("file", file);

    const res = await fetch(`${BASE}/endpoints/upload_profile_api.php`, {
      method: "POST",
      body: formData,
    });
    const resJson = await res.json();
    if (resJson.error) {
      throw new Error(resJson.error.message || "อัปโหลดรูปภาพล้มเหลว");
    }
    return resJson.data.avatar;
  };

  const handleSave = async () => {
    if (!adminData?.admin_id) {
      Swal.fire({
        icon: "error",
        title: "ไม่พบข้อมูลผู้ใช้",
        confirmButtonText: "ตกลง",
        customClass: swalErrorButtons,
        buttonsStyling: false
      });
      return;
    }

    const nameTrimmed = profile.name?.trim() || "";
    const emailTrimmed = profile.email?.trim() || "";
    let hasError = false;

    if (nameTrimmed === "") {
      setNameError("กรุณากรอกชื่อผู้ดูแลระบบ");
      hasError = true;
    } else {
      setNameError("");
    }

    if (emailTrimmed === "") {
      setEmailError("กรุณากรอกอีเมล");
      hasError = true;
    } else {
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(emailTrimmed)) {
        setEmailError("รูปแบบอีเมลไม่ถูกต้อง");
        hasError = true;
      } else {
        setEmailError("");
      }
    }

    if (hasError) {
      Swal.fire({
        icon: "error",
        title: "ข้อมูลไม่ถูกต้อง",
        text: "กรุณาตรวจสอบชื่อผู้ดูแลและอีเมลให้ถูกต้องก่อนบันทึก",
        confirmButtonText: "ตกลง",
        customClass: swalErrorButtons,
        buttonsStyling: false
      });
      return;
    }

    const newPass = profile.newPassword?.trim() || "";
    const confirmPass = profile.confirmPassword?.trim() || "";

    if (newPass === "" && confirmPass === "") {
      // Both empty -> no password change
      setPasswordError("");
    } else if (newPass === "" || confirmPass === "") {
      Swal.fire({
        icon: "error",
        title: "ข้อมูลไม่ครบถ้วน",
        text: "ต้องกรอกทั้งรหัสผ่านใหม่และยืนยันรหัสผ่านให้ครบทั้งสองช่อง",
        confirmButtonText: "ตกลง",
        customClass: swalErrorButtons,
        buttonsStyling: false
      });
      return;
    } else {
      if (newPass !== confirmPass) {
        setPasswordError("รหัสผ่านใหม่และยืนยันรหัสผ่านไม่ตรงกัน");
        return;
      }
      if (newPass.length < 6) {
        setPasswordError("รหัสผ่านใหม่ต้องมีความยาวอย่างน้อย 6 ตัวอักษร");
        return;
      }
      setPasswordError("");
    }

    // ── สร้างสรุปการเปลี่ยนแปลงเพื่อแสดงใน Swal ──────────────────────────
    const changes = [];

    if ((profile.name?.trim() || "") !== (adminData?.name?.trim() || "")) {
      changes.push(
        `<tr>
          <td style="padding:4px 10px 4px 0;color:#6b7280;white-space:nowrap">ชื่อ</td>
          <td style="padding:4px 6px;color:#ef4444;text-decoration:line-through">${adminData?.name || "—"}</td>
          <td style="padding:4px 0 4px 6px;color:#22c55e;font-weight:600">${profile.name || "—"}</td>
        </tr>`
      );
    }

    if ((profile.email?.trim().toLowerCase() || "") !== (adminData?.email?.trim().toLowerCase() || "")) {
      changes.push(
        `<tr>
          <td style="padding:4px 10px 4px 0;color:#6b7280;white-space:nowrap">อีเมล</td>
          <td style="padding:4px 6px;color:#ef4444;text-decoration:line-through">${adminData?.email || "—"}</td>
          <td style="padding:4px 0 4px 6px;color:#22c55e;font-weight:600">${profile.email || "—"}</td>
        </tr>`
      );
    }

    if (avatarFile) {
      changes.push(
        `<tr>
          <td style="padding:4px 10px 4px 0;color:#6b7280;white-space:nowrap">รูปโปรไฟล์</td>
          <td colspan="2" style="padding:4px 0;color:#22c55e;font-weight:600">เปลี่ยนรูปใหม่</td>
        </tr>`
      );
    }

    if (newPass !== "") {
      changes.push(
        `<tr>
          <td style="padding:4px 10px 4px 0;color:#6b7280;white-space:nowrap">รหัสผ่าน</td>
          <td colspan="2" style="padding:4px 0;color:#22c55e;font-weight:600">เปลี่ยนรหัสผ่านใหม่</td>
        </tr>`
      );
    }

    const changeHtml =
      changes.length > 0
        ? `<p style="margin-bottom:10px;color:#374151;font-size:0.9rem">รายการที่เปลี่ยนแปลง:</p>
           <table style="width:100%;font-size:0.85rem;border-collapse:collapse">
             ${changes.join("")}
           </table>`
        : `<p style="color:#6b7280;font-size:0.9rem">ไม่มีการเปลี่ยนแปลงข้อมูล</p>`;

    // ── Swal ยืนยันก่อนบันทึก ──────────────────────────────────────────────
    const { isConfirmed } = await Swal.fire({
      icon: "question",
      title: "ยืนยันการแก้ไขข้อมูล?",
      html: changeHtml,
      showCancelButton: true,
      confirmButtonText: "ตกลง",
      cancelButtonText: "ยกเลิก",
      timer: 8000,
      timerProgressBar: true,
      reverseButtons: true,
      customClass: {
        confirmButton:
          "bg-orange-500 text-white px-6 py-2.5 rounded-lg text-sm font-medium hover:bg-orange-600 transition duration-150 focus:outline-none focus:ring-2 focus:ring-orange-400 focus:ring-offset-2 mx-2",
        cancelButton:
          "bg-gray-200 text-gray-700 px-6 py-2.5 rounded-lg text-sm font-medium hover:bg-gray-300 transition duration-150 focus:outline-none focus:ring-2 focus:ring-gray-300 focus:ring-offset-2 mx-2",
      },
      buttonsStyling: false,
      didOpen: (popup) => {
        // ปรับสีแถบ progress bar เป็นสีส้ม (primary color ของโปรเจกต์)
        const bar = popup.querySelector(".swal2-timer-progress-bar");
        if (bar) bar.style.background = "#f27f0d";
      },
    });

    if (!isConfirmed) return; // ผู้ใช้กด "ยกเลิก" หรือ timer หมด → หยุดทันที

    // ── เรียก API บันทึกจริง ───────────────────────────────────────────────
    setLoading(true);

    try {
      let currentAvatarUrl = avatar;

      // 1. อัปโหลดรูปไปที่ PHP endpoint (PHP จัดการลบเก่า/บันทึกใหม่/อัปเดต DB ให้ครบ)
      if (avatarFile) {
        currentAvatarUrl = await uploadProfileImage(avatarFile);
        if (!currentAvatarUrl) throw new Error('ไม่ได้รับ URL รูปโปรไฟล์จาก server');
      }

      // 2. อัปเดตข้อมูลผู้ดูแลระบบ
      const updatePayload = {
        name: profile.name,
        email: profile.email,
        avatar: currentAvatarUrl || '',
      };
      if (newPass !== "") {
        updatePayload.newPassword = newPass;
      }

      console.log("Payload to update admin profile:", updatePayload);

      const res = await fetch(
        `${BASE}/endpoints/admin_user_api.php?action=update&id=${encodeURIComponent(adminData.admin_id)}`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(updatePayload),
        }
      );
      const { data, error } = await res.json();
      if (error) throw error;

      // Remove password_hash from data to keep local storage clean
      if (data && data.password_hash) {
        delete data.password_hash;
      }

      const baseUser = data || { ...adminData, ...updatePayload };
      if (baseUser.newPassword) {
        delete baseUser.newPassword;
      }

      // ใส่ cache buster ใน URL รูปภาพเพื่อบังคับเบราว์เซอร์ดาวน์โหลดภาพใหม่แทนการใช้ cache เดิม
      const cacheBustedAvatar = baseUser.avatar ? `${baseUser.avatar.split('?')[0]}?t=${Date.now()}` : null;

      const updatedUser = {
        ...baseUser,
        avatar: cacheBustedAvatar
      };

      // อัปเดตข้อมูลลงใน storage ของเบราว์เซอร์
      if (localStorage.getItem("admin_user")) {
        localStorage.setItem("admin_user", JSON.stringify(updatedUser));
      } else {
        sessionStorage.setItem("admin_user", JSON.stringify(updatedUser));
      }

      setAdminData(updatedUser);
      setAvatar(updatedUser.avatar || null);
      setAvatarFile(null);

      // เคลียร์ช่องรหัสผ่านและค่าความปลอดภัยทั้งหมด
      setProfile({
        name: updatedUser.name || "",
        email: updatedUser.email || "",
        newPassword: "",
        confirmPassword: "",
      });
      setPasswordError("");
      setNameError("");
      setEmailError("");
      setShowNewPassword(false);
      setShowConfirmPassword(false);
      setIsEditing(false);

      // ส่งสัญญาณอัปเดตไปทั่วหน้าเว็บเพื่อให้ Topbar อัปเดตรูปใหม่ทันที
      window.dispatchEvent(new Event("admin_profile_updated"));

      // 3. แสดง Success Modal
      setShowSuccessModal(true);

    } catch (err) {
      console.error("Error saving admin profile:", err);
      Swal.fire({
        icon: "error",
        title: "เกิดข้อผิดพลาดในการบันทึก",
        text: translateError(err.message || err.error_description || "กรุณาลองใหม่อีกครั้ง"),
        confirmButtonText: "ตกลง",
        cancelButtonText: "ยกเลิก",
        customClass: swalErrorButtons,
        buttonsStyling: false
      });
    } finally {
      setLoading(false);
    }
  };


  return (
    <div className="min-h-screen bg-[#f9f7f4] relative px-4 sm:px-6 py-6 md:py-10">

      {/* ===== SUCCESS MODAL ===== */}
      {showSuccessModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center">
          {/* Backdrop */}
          <div className="absolute inset-0 bg-black/50 backdrop-blur-sm" />

          {/* Card */}
          <div className="relative z-10 w-80 bg-white rounded-2xl shadow-2xl p-8 flex flex-col items-center gap-5 animate-fadeInScale">

            {/* ไอคอนวงกลมสีเขียวอ่อน + เครื่องหมายถูก */}
            <div className="w-20 h-20 rounded-full bg-green-50 flex items-center justify-center">
              <svg
                className="w-10 h-10 text-green-500"
                fill="none"
                stroke="currentColor"
                strokeWidth="2.5"
                viewBox="0 0 24 24"
              >
                <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
              </svg>
            </div>

            {/* หัวข้อ */}
            <h2 className="text-xl font-bold text-gray-800 text-center">
              บันทึกข้อมูลสำเร็จ
            </h2>

            {/* ปุ่ม ตกลง — ปิด modal เท่านั้น ไม่ navigate */}
            <button
              onClick={() => setShowSuccessModal(false)}
              className="w-full py-3 rounded-xl bg-green-500 hover:bg-green-600 active:bg-green-700 text-white font-semibold text-sm tracking-wide shadow transition-colors duration-150"
            >
              ตกลง
            </button>
          </div>
        </div>
      )}


      {/* container กลางหน้า */}
      <div className="mx-auto w-full max-w-2xl pt-16 md:pt-10 relative">
        {/* BACK */}
        <button
          onClick={() => navigate("/dashboard")}
          className="mb-6 md:absolute md:left-0 md:top-2 px-3.5 py-2 rounded-lg text-gray-600 hover:bg-gray-50 border bg-white/80 shadow-sm transition flex items-center gap-1.5"
        >
          <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" d="M15 19l-7-7 7-7" />
          </svg>
          <span>กลับ</span>
        </button>

        {/* TITLE */}
        <div className="text-center -mt-6 mb-8">
          <h1 className="text-[26px] font-bold text-[#8B4513]/85 transition-colors">
            จัดการข้อมูลผู้ดูแลระบบ
          </h1>
          <p className="text-gray-500 mt-3">
            แก้ไขข้อมูลส่วนตัวของผู้ดูแลระบบ
          </p>
        </div>

        {/* CARD */}
        <div className="bg-white rounded-3xl shadow-xl border p-6 sm:p-8 md:p-10 relative overflow-hidden">
          {/* LOADING BLOCKER */}
          {loading && (
            <div className="absolute inset-0 bg-white/70 flex items-center justify-center z-50">
              <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-orange-500"></div>
            </div>
          )}

          {/* AVATAR */}
          <div className="flex flex-col items-center mb-10">
            <div className="relative group">
              <div className="w-24 h-24 md:w-28 md:h-28 rounded-full overflow-hidden bg-orange-500 flex items-center justify-center text-4xl font-bold text-white shadow-lg ring-4 ring-orange-100 transition-all duration-200 group-hover:ring-orange-200">
                {/* แสดงรูปโปรไฟล์: ถ้ามี URL ใช้ URL นั้น (รูปจาก PHP upload), ถ้าไม่มีใช้ logo.png */}
                {avatar ? (
                  <img
                    src={avatar}
                    alt="avatar"
                    className="w-full h-full object-cover"
                    onError={(e) => {
                      // ถ้าโหลดรูปไม่ได้ (ไฟล์หาย ฯลฯ) fallback ไปใช้ logo
                      e.currentTarget.src = logo;
                    }}
                  />
                ) : (
                  <img src={logo} alt="default avatar" className="w-full h-full object-cover p-1" />
                )}
              </div>

              {/* ปุ่มเปลี่ยนรูปโปรไฟล์ (แสดงเฉพาะในโหมดแก้ไข) */}
              {isEditing && (
                <label className="absolute bottom-1 right-1 bg-white border border-gray-200 rounded-full p-2.5 cursor-pointer shadow-md hover:bg-orange-50 hover:border-orange-200 hover:text-orange-500 transition-all duration-150 z-10 flex items-center justify-center animate-fadeIn">
                  <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5 text-gray-500 hover:text-orange-500 transition-colors" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2">
                    <path strokeLinecap="round" strokeLinejoin="round" d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z" />
                    <path strokeLinecap="round" strokeLinejoin="round" d="M15 13a3 3 0 11-6 0 3 3 0 016 0z" />
                  </svg>
                  <input
                    type="file"
                    accept="image/*"
                    onChange={handleAvatarChange}
                    className="hidden"
                  />
                </label>
              )}
            </div>

            {isEditing && (
              <p className="text-sm text-gray-500 mt-3 text-center animate-fadeIn">
                กดรูปกล้องหรือปุ่มด้านล่างเพื่อแก้ไขข้อมูล
              </p>
            )}
          </div>

          {/* FORM */}
          <div className="space-y-6">
            {/* NAME */}
            <div>
              <label className="block mb-1.5 text-sm font-medium text-gray-700">
                ชื่อผู้ดูแล <span className="text-red-500">*</span>
              </label>
              <input
                name="name"
                value={profile.name}
                disabled={!isEditing}
                onChange={handleChange}
                className={`w-full rounded-xl border px-4 py-3 focus:ring-2 focus:ring-orange-400 outline-none transition-colors ${
                  isEditing 
                    ? (nameError ? "border-red-500 bg-white focus:ring-red-400" : "border-gray-300 bg-white") 
                    : "border-gray-200 bg-gray-50 text-gray-600 cursor-not-allowed"
                }`}
              />
              {nameError && (
                <p className="text-red-500 text-sm mt-1.5 flex items-center gap-1 animate-fadeIn">
                  <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
                  </svg>
                  <span>{nameError}</span>
                </p>
              )}
            </div>

            {/* EMAIL */}
            <div>
              <label className="block mb-1.5 text-sm font-medium text-gray-700">
                อีเมล <span className="text-red-500">*</span>
              </label>
              <input
                name="email"
                value={profile.email}
                disabled={!isEditing}
                onChange={handleChange}
                className={`w-full rounded-xl border px-4 py-3 focus:ring-2 focus:ring-orange-400 outline-none transition-colors ${
                  isEditing 
                    ? (emailError ? "border-red-500 bg-white focus:ring-red-400" : "border-gray-300 bg-white") 
                    : "border-gray-200 bg-gray-50 text-gray-600 cursor-not-allowed"
                }`}
              />
              {emailError && (
                <p className="text-red-500 text-sm mt-1.5 flex items-center gap-1 animate-fadeIn">
                  <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
                  </svg>
                  <span>{emailError}</span>
                </p>
              )}
            </div>

            {/* NEW PASSWORD & CONFIRM NEW PASSWORD (ONLY SHOWN IN EDIT MODE) */}
            {isEditing && (
              <>
                {/* NEW PASSWORD */}
                <div>
                  <label className="block mb-1 text-sm font-medium text-gray-700">
                    รหัสผ่านใหม่
                  </label>
                  <div className="relative">
                    <input
                      type={showNewPassword ? "text" : "password"}
                      name="newPassword"
                      value={profile.newPassword || ""}
                      disabled={!isEditing}
                      onChange={handleChange}
                      placeholder={isEditing ? "เว้นว่างไว้หากไม่ต้องการเปลี่ยนรหัสผ่าน" : "••••••••"}
                      className={`w-full rounded-xl border pl-4 pr-10 py-3 focus:ring-2 focus:ring-orange-400 outline-none transition-colors ${
                        isEditing ? "bg-white border-gray-300" : "bg-gray-50 border-gray-200 text-gray-600"
                      }`}
                    />
                    <button
                      type="button"
                      disabled={!isEditing}
                      onClick={() => setShowNewPassword(!showNewPassword)}
                      className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-orange-600 focus:outline-none disabled:opacity-50 transition"
                    >
                      {showNewPassword ? (
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
                </div>

                {/* CONFIRM NEW PASSWORD */}
                <div>
                  <label className="block mb-1 text-sm font-medium text-gray-700">
                    ยืนยันรหัสผ่านใหม่
                  </label>
                  <div className="relative">
                    <input
                      type={showConfirmPassword ? "text" : "password"}
                      name="confirmPassword"
                      value={profile.confirmPassword || ""}
                      disabled={!isEditing}
                      onChange={handleChange}
                      placeholder={isEditing ? "เว้นว่างไว้หากไม่ต้องการเปลี่ยนรหัสผ่าน" : "••••••••"}
                      className={`w-full rounded-xl border pl-4 pr-10 py-3 focus:ring-2 focus:ring-orange-400 outline-none transition-colors ${
                        isEditing ? "bg-white border-gray-300" : "bg-gray-50 border-gray-200 text-gray-600"
                      }`}
                    />
                    <button
                      type="button"
                      disabled={!isEditing}
                      onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                      className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-orange-600 focus:outline-none disabled:opacity-50 transition"
                    >
                      {showConfirmPassword ? (
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
                  {passwordError && (
                    <p className="text-red-500 text-sm mt-1">{passwordError}</p>
                  )}
                </div>
              </>
            )}
          </div>

          {/* ACTION */}
          <div className="flex justify-center mt-10">
            {isEditing ? (
              <div className="flex flex-col sm:flex-row gap-3 w-full sm:w-auto">
                <button
                  type="button"
                  onClick={() => {
                    setIsEditing(false);
                    // รีเซ็ตข้อมูลกลับเป็นข้อมูลเดิมที่ดึงมาจากฐานข้อมูล
                    if (adminData) {
                      setProfile({
                        name: adminData.name || "",
                        email: adminData.email || "",
                        newPassword: "",
                        confirmPassword: "",
                      });
                      setAvatar(adminData.avatar || null);
                      setAvatarFile(null);
                      setPasswordError("");
                      setNameError("");
                      setEmailError("");
                      setShowNewPassword(false);
                      setShowConfirmPassword(false);
                    }
                  }}
                  className="w-full sm:w-auto px-6 py-3 rounded-xl border border-gray-300 text-gray-700 bg-white hover:bg-gray-50 active:bg-gray-100 font-semibold transition text-center"
                >
                  ยกเลิก
                </button>
                <button
                  type="button"
                  onClick={handleSave}
                  disabled={loading}
                  className="w-full sm:w-auto min-w-[140px] px-6 py-3 rounded-xl bg-[#16A34A] hover:bg-[#15803D] active:bg-[#15803D] text-white shadow-lg font-semibold flex items-center justify-center gap-2 disabled:opacity-75 disabled:cursor-not-allowed transition"
                >
                  {loading ? (
                    <>
                      <svg className="animate-spin h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                        <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                        <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                      </svg>
                      <span>กำลังบันทึกข้อมูล...</span>
                    </>
                  ) : (
                    "บันทึกข้อมูล"
                  )}
                </button>
              </div>
            ) : (
              <button
                type="button"
                onClick={() => setIsEditing(true)}
                className="w-full sm:w-auto px-10 py-3 rounded-xl bg-orange-500 text-white hover:bg-orange-600 active:bg-orange-700 shadow-lg font-semibold transition text-center"
              >
                แก้ไขข้อมูล
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
