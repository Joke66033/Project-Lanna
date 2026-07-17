# API Documentation - รายการเส้นทาง API (API Endpoints) ทั้งหมดในโปรเจกต์ LANNA

เอกสารนี้ระบุรายละเอียดเส้นทางเชื่อมต่อ API ทั้งหมดของโปรเจกต์ ทั้งฝั่ง PHP Backend API และส่วนที่ดึงข้อมูลจาก Supabase โดยตรงผ่าน Client ใน React Frontend (`Lanna_Admin`)

---

## 📌 ภาพรวมสถาปัตยกรรมระบบ (System Architecture Overview)

โปรเจกต์นี้ใช้งาน Backend ร่วมกัน 2ระบบหลัก:
1. **PHP API (Lanna_API)**: รันบน XAMPP (Apache) ทำหน้าที่เป็น Gateway หลักในฝั่ง Admin เพื่อรับ Request จาก React App (`Lanna_Admin`) แล้วประมวลผลคำสั่งส่งต่อไปยัง Supabase Rest API (PostgREST) ผ่าน cURL
2. **Supabase Direct**: React Frontend เรียกใช้ `supabaseClient` โดยตรงสำหรับการดึงข้อมูลหมวดหมู่พยัญชนะล้านนา, การซิงก์ข้อมูลแผนที่ตัวอักษรไทย-ล้านนาแบบออฟไลน์ และรับข้อมูลแจ้งเตือนอัปเดตแบบเรียลไทม์ (Real-time postgres changes subscription)
3. **EmailJS (External API)**: ใช้สำหรับจัดการส่งอีเมล OTP ในระบบลืมรหัสผ่านโดยตรงจาก Frontend

---

## 🛠️ รายการ API Endpoints แบ่งตามกลุ่มฟีเจอร์

### 1. ระบบยืนยันตัวตนและจัดการผู้ดูแลระบบ (Authentication & Admin Profiles)

จัดการข้อมูลเกี่ยวกับตาราง `admin_user` และการอัปโหลดไฟล์รูปภาพแอดมิน

| Method | Path / Endpoint | คำอธิบาย | Parameters | Response | ไฟล์เรียกใช้งานใน Frontend |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **GET** | `/endpoints/admin_user_api.php?action=getAll` | ดึงข้อมูลบัญชีผู้ดูแลระบบทั้งหมด | None | `{"data": [admin, ...], "error": null}` | None |
| **GET** | `/endpoints/admin_user_api.php?action=getById&id={id}` | ดึงข้อมูลผู้ดูแลระบบรายตัวตาม ID | `id` (string in query) | `{"data": admin, "error": null}` | None |
| **GET** | `/endpoints/admin_user_api.php?action=getByEmail&email={email}` | ค้นหาข้อมูลผู้ดูแลระบบด้วยอีเมล | `email` (string in query) | `{"data": admin, "error": null}` | [login.jsx](file:///c:/xampp/htdocs/LANNA/Lanna_Admin/src/pages/login.jsx)<br>[forgotPassword.jsx](file:///c:/xampp/htdocs/LANNA/Lanna_Admin/src/pages/auth/forgotPassword.jsx) |
| **GET** | `/endpoints/admin_user_api.php?action=getOtpByEmail&email={email}` | ดึงข้อมูลรหัส OTP ตัวล่าสุดเพื่อใช้อ้างอิงการลืมรหัสผ่าน | `email` (string in query) | `{"data": {"otp_code", "otp_expires_at"}, "error": null}` | [forgotPassword.jsx](file:///c:/xampp/htdocs/LANNA/Lanna_Admin/src/pages/auth/forgotPassword.jsx)<br>[otp.jsx](file:///c:/xampp/htdocs/LANNA/Lanna_Admin/src/pages/auth/otp.jsx) |
| **POST** | `/endpoints/admin_user_api.php?action=create` | สร้างบัญชีผู้ดูแลระบบใหม่ | Body JSON: `email`, `password_hash`, `password_plain`, `name`, `avatar`, `role` | `{"data": admin, "error": null}` | None |
| **POST** | `/endpoints/admin_user_api.php?action=update&id={id}` | อัปเดตข้อมูลผู้ดูแลระบบตาม ID (เช่น เปลี่ยนรหัสผ่าน, ชื่อ, รูปโปรไฟล์) | `id` (string in query)<br>Body JSON: fields ที่ต้องการอัปเดต | `{"data": admin, "error": null}` | [login.jsx](file:///c:/xampp/htdocs/LANNA/Lanna_Admin/src/pages/login.jsx)<br>[adminProfile.jsx](file:///c:/xampp/htdocs/LANNA/Lanna_Admin/src/pages/adminProfile.jsx) |
| **POST** | `/endpoints/admin_user_api.php?action=updateByEmail&email={email}` | อัปเดตข้อมูลผู้ดูแลระบบด้วยอีเมล (เช่น อัปเดต OTP หรือ Reset รหัสผ่านใหม่) | `email` (string in query)<br>Body JSON: fields ที่ต้องการอัปเดต | `{"data": admin, "error": null}` | [forgotPassword.jsx](file:///c:/xampp/htdocs/LANNA/Lanna_Admin/src/pages/auth/forgotPassword.jsx)<br>[otp.jsx](file:///c:/xampp/htdocs/LANNA/Lanna_Admin/src/pages/auth/otp.jsx)<br>[reset_password.jsx](file:///c:/xampp/htdocs/LANNA/Lanna_Admin/src/pages/auth/reset_password.jsx) |
| **POST** | `/endpoints/admin_user_api.php?action=delete&id={id}` | ลบบัญชีผู้ดูแลระบบ | `id` (string in query) | `{"data": admin, "error": null}` | None |
| **POST** | `/endpoints/upload_profile_api.php` | อัปโหลดรูปภาพโปรไฟล์แอดมินลง Apache Disk และอัปเดต URL ไปยังฐานข้อมูล | Content-Type: `multipart/form-data`<br>- `admin_id` (string in POST)<br>- `file` (file upload: JPG/PNG/WEBP <= 2MB) | `{"data": {"avatar", "filename"}, "error": null}` | [adminProfile.jsx](file:///c:/xampp/htdocs/LANNA/Lanna_Admin/src/pages/adminProfile.jsx) |

---

### 2. ระบบจัดการอักขระล้านนา (Lanna Characters & Categories)

จัดการข้อมูลเกี่ยวกับตาราง `lanna_char` และตาราง `category_lanna_char`

| Method | Path / Endpoint | คำอธิบาย | Parameters | Response | ไฟล์เรียกใช้งานใน Frontend |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **GET** | `/endpoints/lanna_char_api.php?action=getAll` | ดึงข้อมูลพยัญชนะ/อักขระล้านนาทั้งหมดพร้อมชื่อหมวดหมู่ที่ JOIN | None | `{"data": [char_with_cat_name, ...], "error": null}` | [alphabet.jsx](file:///c:/xampp/htdocs/LANNA/Lanna_Admin/src/pages/alphabet.jsx) |
| **GET** | `/endpoints/lanna_char_api.php?action=getById&id={id}` | ดึงข้อมูลอักขระเดี่ยวตาม ID | `id` (string in query) | `{"data": char_item, "error": null}` | None |
| **POST** | `/endpoints/lanna_char_api.php?action=create` | เพิ่มข้อมูลอักขระล้านนาใหม่ | Body JSON: `lanna_char`, `thai_equivalent`, `category_char_id` | `{"data": char_item, "error": null}` | [alphabet.jsx](file:///c:/xampp/htdocs/LANNA/Lanna_Admin/src/pages/alphabet.jsx) |
| **POST** | `/endpoints/lanna_char_api.php?action=update&id={id}` | แก้ไขข้อมูลอักขระล้านนาตาม ID | `id` (string in query)<br>Body JSON: `lanna_char`, `thai_equivalent`, `category_char_id` | `{"data": char_item, "error": null}` | [alphabet.jsx](file:///c:/xampp/htdocs/LANNA/Lanna_Admin/src/pages/alphabet.jsx) |
| **POST** | `/endpoints/lanna_char_api.php?action=delete&id={id}` | ลบข้อมูลอักขระล้านนาออก | `id` (string in query) | `{"data": char_item, "error": null}` | [alphabet.jsx](file:///c:/xampp/htdocs/LANNA/Lanna_Admin/src/pages/alphabet.jsx) |
| **GET** | `/endpoints/category_lanna_char_api.php?action=getAll` | ดึงหมวดหมู่อักขระล้านนาทั้งหมด | None | `{"data": [category, ...], "error": null}` | [categoryLannaChar.jsx](file:///c:/xampp/htdocs/LANNA/Lanna_Admin/src/pages/categoryLannaChar.jsx) |
| **GET** | `/endpoints/category_lanna_char_api.php?action=getById&id={id}` | ดึงหมวดหมู่อักขระตาม ID | `id` (string in query) | `{"data": category, "error": null}` | None |
| **POST** | `/endpoints/category_lanna_char_api.php?action=create` | เพิ่มหมวดหมู่อักขระ (ระบบรัน ID: CC#### อัตโนมัติ) | Body JSON: `name` | `{"data": category, "error": null}` | [categoryLannaChar.jsx](file:///c:/xampp/htdocs/LANNA/Lanna_Admin/src/pages/categoryLannaChar.jsx) |
| **POST** | `/endpoints/category_lanna_char_api.php?action=update&id={id}` | แก้ไขชื่อหมวดหมู่อักขระ | `id` (string in query)<br>Body JSON: `name` | `{"data": category, "error": null}` | [categoryLannaChar.jsx](file:///c:/xampp/htdocs/LANNA/Lanna_Admin/src/pages/categoryLannaChar.jsx) |
| **POST** | `/endpoints/category_lanna_char_api.php?action=delete&id={id}` | ลบหมวดหมู่อักขระออก | `id` (string in query) | `{"data": category, "error": null}` | [categoryLannaChar.jsx](file:///c:/xampp/htdocs/LANNA/Lanna_Admin/src/pages/categoryLannaChar.jsx) |
| **Supabase** | Direct: `category_lanna_char` | ดึงรายชื่อหมวดหมู่ไปแสดงผลใน Dropdown ของ Modal ตัวอักขระ | `select("category_char_id, name")` | Array of `{category_char_id, name}` | [alphabet.jsx](file:///c:/xampp/htdocs/LANNA/Lanna_Admin/src/pages/alphabet.jsx) |
| **Supabase** | Direct: `lanna_char` | ดึงคู่ความสัมพันธ์ภาษาไทย-อักขระล้านนามาเก็บเป็นข้อมูลสำหรับแปลงออฟไลน์ | `select("lanna_char, thai_equivalent")` | Array of `{lanna_char, thai_equivalent}` | [thaiToLanna.js](file:///c:/xampp/htdocs/LANNA/Lanna_Admin/src/lib/thaiToLanna.js) |

---

### 3. ระบบจัดการข้อมูลคำศัพท์ (Vocabulary & Categories)

จัดการข้อมูลเกี่ยวกับตาราง `vocabulary` และตาราง `category_vocab`

| Method | Path / Endpoint | คำอธิบาย | Parameters | Response | ไฟล์เรียกใช้งานใน Frontend |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **GET** | `/endpoints/vocabulary_api.php?action=getAll` | ดึงข้อมูลคำศัพท์ทั้งหมดพร้อมหมวดหมู่ที่ JOIN (ถูก Map ให้อยู่ในฟิลด์ category) | None | `{"data": [vocab_with_cat_name, ...], "error": null}` | [VocabularyPage.jsx](file:///c:/xampp/htdocs/LANNA/Lanna_Admin/src/pages/VocabularyPage.jsx)<br>[dashboard.jsx](file:///c:/xampp/htdocs/LANNA/Lanna_Admin/src/pages/dashboard.jsx) |
| **GET** | `/endpoints/vocabulary_api.php?action=getById&id={id}` | ดึงคำศัพท์แบบเดี่ยวตาม ID | `id` (string in query) | `{"data": vocab_item, "error": null}` | None |
| **GET** | `/endpoints/vocabulary_api.php?action=search&keyword={keyword}` | ค้นหาคำศัพท์ด้วยคีย์เวิร์ด (แบบ ilike คลุม lanna_word, reading, thai_word, meaning) | `keyword` (string in query) | `{"data": [vocab_item, ...], "error": null}` | None (เรียกจาก App ฝั่งผู้ใช้ทั่วไป) |
| **POST** | `/endpoints/vocabulary_api.php?action=create` | เพิ่มคำศัพท์ใหม่ (ระบบรัน ID: V##### อัตโนมัติ) | Body JSON: `lanna_word`, `thai_word`, `reading`, `meaning`, `category_vocab_id` | `{"data": vocab_item, "error": null}` | [VocabularyPage.jsx](file:///c:/xampp/htdocs/LANNA/Lanna_Admin/src/pages/VocabularyPage.jsx) |
| **POST** | `/endpoints/vocabulary_api.php?action=update&id={id}` | แก้ไขข้อมูลคำศัพท์ตาม ID | `id` (string in query)<br>Body JSON: `lanna_word`, `thai_word`, `reading`, `meaning`, `category_vocab_id` | `{"data": vocab_item, "error": null}` | [VocabularyPage.jsx](file:///c:/xampp/htdocs/LANNA/Lanna_Admin/src/pages/VocabularyPage.jsx) |
| **POST** | `/endpoints/vocabulary_api.php?action=delete&id={id}` | ลบข้อมูลคำศัพท์ออก | `id` (string in query) | `{"data": vocab_item, "error": null}` | [VocabularyPage.jsx](file:///c:/xampp/htdocs/LANNA/Lanna_Admin/src/pages/VocabularyPage.jsx) |
| **GET** | `/endpoints/category_vocab_api.php?action=getAll` | ดึงข้อมูลหมวดหมู่คำศัพท์ล้านนาทั้งหมด | None | `{"data": [category, ...], "error": null}` | [categoryAlphabet.jsx](file:///c:/xampp/htdocs/LANNA/Lanna_Admin/src/pages/categoryAlphabet.jsx)<br>[dashboard.jsx](file:///c:/xampp/htdocs/LANNA/Lanna_Admin/src/pages/dashboard.jsx)<br>[VocabularyPage.jsx](file:///c:/xampp/htdocs/LANNA/Lanna_Admin/src/pages/VocabularyPage.jsx) |
| **GET** | `/endpoints/category_vocab_api.php?action=getById&id={id}` | ดึงหมวดหมู่คำศัพท์ล้านนาตาม ID | `id` (string in query) | `{"data": category, "error": null}` | None |
| **POST** | `/endpoints/category_vocab_api.php?action=create` | เพิ่มข้อมูลหมวดหมู่คำศัพท์ใหม่ (รัน ID: CV#### อัตโนมัติ) | Body JSON: `name` | `{"data": category, "error": null}` | [categoryAlphabet.jsx](file:///c:/xampp/htdocs/LANNA/Lanna_Admin/src/pages/categoryAlphabet.jsx) |
| **POST** | `/endpoints/category_vocab_api.php?action=update&id={id}` | อัปเดตข้อมูลหมวดหมู่คำศัพท์ตาม ID | `id` (string in query)<br>Body JSON: `name` | `{"data": category, "error": null}` | [categoryAlphabet.jsx](file:///c:/xampp/htdocs/LANNA/Lanna_Admin/src/pages/categoryAlphabet.jsx) |
| **POST** | `/endpoints/category_vocab_api.php?action=delete&id={id}` | ลบข้อมูลหมวดหมู่คำศัพท์ออก | `id` (string in query) | `{"data": category, "error": null}` | [categoryAlphabet.jsx](file:///c:/xampp/htdocs/LANNA/Lanna_Admin/src/pages/categoryAlphabet.jsx) |

*หมายเหตุ: หน้าเพจ `categoryAlphabet.jsx` ทำหน้าที่แสดงผลและจัดการข้อมูลของตาราง `category_vocab` (หมวดหมู่คำศัพท์)*

---

### 4. ระบบจัดการข้อมูลบทความ (Articles)

จัดการข้อมูลข่าวสารหรือบทความในตาราง `articles`

| Method | Path / Endpoint | คำอธิบาย | Parameters | Response | ไฟล์เรียกใช้งานใน Frontend |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **GET** | `/endpoints/articles_api.php?action=getAll` | ดึงข้อมูลบทความทั้งหมด | None | `{"data": [article, ...], "error": null}` | [articles.jsx](file:///c:/xampp/htdocs/LANNA/Lanna_Admin/src/pages/articles.jsx)<br>[dashboard.jsx](file:///c:/xampp/htdocs/LANNA/Lanna_Admin/src/pages/dashboard.jsx) |
| **GET** | `/endpoints/articles_api.php?action=getById&id={id}` | ดึงข้อมูลบทความเดี่ยวตาม ID | `id` (string in query) | `{"data": article, "error": null}` | None |
| **POST** | `/endpoints/articles_api.php?action=create` | เพิ่มบทความใหม่ในระบบ | Body JSON: `title`, `content`, `cover_image`, `author_id`, `created_at` | `{"data": article, "error": null}` | [articles.jsx](file:///c:/xampp/htdocs/LANNA/Lanna_Admin/src/pages/articles.jsx) |
| **POST** | `/endpoints/articles_api.php?action=update&id={id}` | แก้ไขรายละเอียดบทความตาม ID | `id` (string in query)<br>Body JSON: fields ที่ต้องการอัปเดต | `{"data": article, "error": null}` | [articles.jsx](file:///c:/xampp/htdocs/LANNA/Lanna_Admin/src/pages/articles.jsx) |
| **POST** | `/endpoints/articles_api.php?action=delete&id={id}` | ลบบทความออกจากระบบ | `id` (string in query) | `{"data": article, "error": null}` | [articles.jsx](file:///c:/xampp/htdocs/LANNA/Lanna_Admin/src/pages/articles.jsx) |

---

### 5. ระบบจัดการผู้ใช้ทั่วไป (Users Management)

ควบคุมและจัดการสถานะการใช้งานของบัญชีผู้ใช้ฝั่ง Application ในตาราง `users`

| Method | Path / Endpoint | คำอธิบาย | Parameters | Response | ไฟล์เรียกใช้งานใน Frontend |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **GET** | `/endpoints/users_api.php?action=getAll` | ดึงข้อมูลรายชื่อผู้ใช้งานทั้งหมดในระบบ | None | `{"data": [user, ...], "error": null}` | [users.jsx](file:///c:/xampp/htdocs/LANNA/Lanna_Admin/src/pages/users.jsx)<br>[dashboard.jsx](file:///c:/xampp/htdocs/LANNA/Lanna_Admin/src/pages/dashboard.jsx) |
| **GET** | `/endpoints/users_api.php?action=getById&id={id}` | ค้นหาข้อมูลผู้ใช้งานตาม ID | `id` (string in query) | `{"data": user, "error": null}` | None |
| **POST** | `/endpoints/users_api.php?action=create` | ลงทะเบียนสร้างสมาชิกใหม่ | Body JSON: `name`, `email`, `status` | `{"data": user, "error": null}` | None |
| **POST** | `/endpoints/users_api.php?action=update&id={id}` | อัปเดตข้อมูลผู้ใช้งาน/เปลี่ยนสถานะการแบนบัญชี | `id` (string in query)<br>Body JSON: `status` (เช่น `"active"` หรือ `"banned"`) | `{"data": user, "error": null}` | [users.jsx](file:///c:/xampp/htdocs/LANNA/Lanna_Admin/src/pages/users.jsx) |
| **POST** | `/endpoints/users_api.php?action=delete&id={id}` | ลบข้อมูลผู้ใช้งานออกจากฐานข้อมูล | `id` (string in query) | `{"data": user, "error": null}` | None |

---

### 6. ระบบบันทึกประวัติการแปลและเก็บรายการโปรด (Translation Logs & Favorites)

จัดการประวัติการแปลงภาษาและการบันทึกรายการที่ชอบของผู้ใช้ทั่วไป

| Method | Path / Endpoint | คำอธิบาย | Parameters | Response | ไฟล์เรียกใช้งานใน Frontend |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **GET** | `/endpoints/translate_logs_api.php?action=getAll` | ดึงสถิติ/ประวัติการกดแปลภาษาของระบบทั้งหมด | None | `{"data": [log, ...], "error": null}` | [dashboard.jsx](file:///c:/xampp/htdocs/LANNA/Lanna_Admin/src/pages/dashboard.jsx) |
| **GET** | `/endpoints/translate_logs_api.php?action=getById&id={id}` | ดึงข้อมูลประวัติแปลตาม Log ID | `id` (string in query) | `{"data": log, "error": null}` | None |
| **POST** | `/endpoints/translate_logs_api.php?action=create` | บันทึก Log การกดแปลภาษาใหม่ลงระบบ | Body JSON: `user_id`, `input_text`, `output_text` | `{"data": log, "error": null}` | None (เรียกจาก App ฝั่งผู้ใช้ทั่วไป) |
| **POST** | `/endpoints/translate_logs_api.php?action=update&id={id}` | อัปเดตข้อมูลประวัติ Log แปลภาษา | `id` (string in query)<br>Body JSON: fields ที่ต้องการอัปเดต | `{"data": log, "error": null}` | None |
| **POST** | `/endpoints/translate_logs_api.php?action=delete&id={id}` | ลบ Log การแปลออกจากระบบ | `id` (string in query) | `{"data": log, "error": null}` | None |
| **GET** | `/endpoints/favorites_api.php?action=getAll` | ดึงรายการคำศัพท์โปรดของผู้ใช้งานทั้งหมด | None | `{"data": [favorite, ...], "error": null}` | None |
| **GET** | `/endpoints/favorites_api.php?action=getById&id={id}` | ค้นหาข้อมูลรายการโปรดตาม Favorite ID | `id` (string in query) | `{"data": favorite, "error": null}` | None |
| **GET** | `/endpoints/favorites_api.php?action=getByUserId&userId={userId}` | ดึงรายการคำศัพท์โปรดทั้งหมดของสมาชิกรายนั้นๆ | `userId` (string in query) | `{"data": [favorite, ...], "error": null}` | None (เรียกจาก App ฝั่งผู้ใช้ทั่วไป) |
| **POST** | `/endpoints/favorites_api.php?action=create` | เพิ่มคำศัพท์เข้าสู่รายการคำศัพท์โปรดของผู้ใช้ | Body JSON: `user_id`, `vocab_id` | `{"data": favorite, "error": null}` | None (เรียกจาก App ฝั่งผู้ใช้ทั่วไป) |
| **POST** | `/endpoints/favorites_api.php?action=update&id={id}` | แก้ไขรายการโปรด | `id` (string in query)<br>Body JSON: fields ที่ต้องการอัปเดต | `{"data": favorite, "error": null}` | None |
| **POST** | `/endpoints/favorites_api.php?action=delete&id={id}` | ลบคำศัพท์ออกจากรายการโปรด | `id` (string in query) | `{"data": favorite, "error": null}` | None (เรียกจาก App ฝั่งผู้ใช้ทั่วไป) |

---

### 7. ระบบส่งรหัสผ่านทางอีเมล (External EmailJS API)

ติดต่อระบบอีเมลส่ง OTP โดยตรงจาก Browser

| Method | Path / Endpoint | คำอธิบาย | Parameters | Response | ไฟล์เรียกใช้งานใน Frontend |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **POST** | `https://api.emailjs.com/api/v1.0/email/send` | ส่งข้อความอีเมลรหัสยืนยัน OTP (6 หลัก) ไปยังอีเมลแอดมินปลายทาง | Body JSON:<br>- `service_id` (string)<br>- `template_id` (string)<br>- `user_id` (public key)<br>- `template_params`: `{to_email, otp_code}` | HTML/Text Status (200 OK) | [forgotPassword.jsx](file:///c:/xampp/htdocs/LANNA/Lanna_Admin/src/pages/auth/forgotPassword.jsx)<br>[otp.jsx](file:///c:/xampp/htdocs/LANNA/Lanna_Admin/src/pages/auth/otp.jsx) |

---

## 🔍 รายการตรวจสอบความสมบูรณ์และจุดเตือนในโปรเจกต์ (Audit & Health Check)

1. **การเทียบจับคู่ไฟล์ Backend**:
   - $\checkmark$ **ผ่านการตรวจสอบ 100%**: ไม่พบการเรียกใช้งาน endpoint ท้องถิ่นใดๆ ใน React Frontend ที่ไม่มีไฟล์ `.php` ตัวจริงในฝั่ง `Lanna_API`
   - $\checkmark$ มีไฟล์ Backend รองรับทุก endpoint ของตัวแอปพลิเคชันอย่างสมบูรณ์
2. **การทำงานของตาราง Category**:
   - *หมายเหตุระบบ*: ในหน้า `alphabet.jsx` (จัดการตัวอักษร) มีการดึงข้อมูลรายชื่อหมวดหมู่ตัวอักษรเพื่อใส่ลงใน Dropdown โดยใช้ `supabase.from("category_lanna_char")` แทนที่จะเรียกผ่าน `/endpoints/category_lanna_char_api.php?action=getAll` ซึ่งระบบเขียนไว้ทั้งสองส่วนและทำงานสอดประสานกันได้อย่างไร้ข้อผิดพลาด
3. **Endpoints ที่ไม่ได้เรียกในระบบ Admin**:
   - `favorites_api.php` ทั้งหมด (สร้างขึ้นเพื่อให้รองรับการเก็บคำศัพท์ที่ชอบบน Application ฝั่งโมบายล์หรือผู้ใช้นอกเหนือบอร์ดแอดมิน)
   - `translate_logs_api.php?action=create/update/delete` (เขียนรองรับให้ Client แปลภาษาภายนอกบันทึก Log ลง Supabase ในขณะที่ Admin เรียกใช้เฉพาะ `action=getAll` บนหน้า Dashboard เพื่อดึงสรุปจำนวนประวัติมาสร้างกราฟสถิติ)

---

## 📊 สรุปภาพรวมสถาปัตยกรรมฐานข้อมูล

- **ฐานข้อมูลหลัก**: Supabase (PostgreSQL) 
- **การเชื่อมต่อ**:
  - **ฝั่งเขียน/แก้ไข/ลบข้อมูลหลัก (CUD)**: React Frontend -> PHP API (Lanna_API) -> Supabase Rest API (ป้องกันการเปิดเผยคีย์หลักและทำสิทธิ์เข้าถึงของแอดมินได้อย่างปลอดภัย)
  - **ฝั่งเรียลไทม์ (Real-time updates)**: React Frontend -> Supabase Realtime Channels (ซิงค์ภาพรวมตารางแสดงผลทันทีแบบเรียลไทม์เมื่อมีการเปลี่ยนแปลงข้อมูลใดๆ)
