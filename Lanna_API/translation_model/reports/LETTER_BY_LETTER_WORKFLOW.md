# ขั้นตอนตรวจคำศัพท์ทีละพยัญชนะ

ระบบนี้แยก “ผ่านการตรวจทางเทคนิค” ออกจาก “ถูกต้องทางภาษา” อย่างชัดเจน
เพื่อไม่ให้ผล OCR หรือการแปลงรูปฟอนต์ถูกนำไปใช้เป็นคำแปลจริงโดยอัตโนมัติ

## สถานะข้อมูล

- `owner_verified`: เจ้าของโครงการหรือผู้เชี่ยวชาญยืนยันรูปคำแล้ว
- `auto_checked_needs_expert`: ผ่านการตรวจ Unicode แหล่งที่มา คำอ่าน และความหมาย แต่ยังต้องตรวจภาษา
- `source_image_verified`: ตรวจว่าคำ รูปอักษร คำอ่าน และความหมายตรงกับภาพหน้าต้นฉบับแล้ว แต่ยังไม่ใช่การรับรองโดยผู้เชี่ยวชาญ
- รายการที่ไม่ผ่านจะอยู่ในไฟล์ `*_rejected.jsonl` และห้ามนำเข้าฐานข้อมูล

## ทำงานทีละพยัญชนะ

ตัวอย่างหมวด ก:

```powershell
python scripts/build_letter_review.py `
  --letter ก `
  --approved data/raw/external/approved_records.jsonl `
  --overrides data/raw/verified_overrides.json `
  --output-dir data/review/by_initial
```

ตรวจ `ก_review.jsonl` ทีละรายการโดยเทียบภาพหน้าพจนานุกรม แล้วเปลี่ยนสถานะ
เฉพาะรายการที่ยืนยันได้เป็น `expert_verified` ก่อนนำเข้าฐานข้อมูล เมื่อหมวด ก
ไม่มีรายการค้างหรือข้อขัดแย้งจึงเริ่มหมวด ข

หลัง OCR ไฟล์สแกนเพื่อค้นหาเลขหน้าแล้ว ให้แนบหน้าที่อาจตรงกันโดยไม่ยกระดับ
สถานะการยืนยัน:

```powershell
python scripts/attach_pdf_evidence.py `
  --review-file data/review/by_initial/ก_review.jsonl `
  --ocr-dir data/review/dictionary_ocr `
  --output data/review/by_initial/ก_evidence.jsonl
```

`candidate_pages` เป็นเพียงตำแหน่งช่วยค้น ต้องเปิดภาพหน้านั้นและตรวจรูปอักษรล้านนา
ด้วยสายตาก่อนตั้ง `visually_verified=true`

## ฐานข้อมูล

รัน `migrations/20260810_create_vocabulary_review.sql` หนึ่งครั้งเพื่อสร้างตารางพักตรวจ
จากนั้นตรวจไฟล์ก่อนนำเข้าทุกครั้ง:

```powershell
php scripts/import_vocabulary_review.php `
  --letter=ก `
  --file=translation_model/data/review/by_initial/ก_evidence.jsonl
```

เพิ่ม `--apply` เมื่อต้องการเขียนลง `vocabulary_review` เท่านั้น สคริปต์นี้ไม่เขียนลง
`vocabulary` และจะไม่ลดสถานะคำที่เจ้าของหรือผู้เชี่ยวชาญยืนยันแล้ว

## หลักการจัดหมวดความหมาย

สคริปต์เสนอหมวดจากความหมายเท่านั้น เช่น อาหารและเครื่องดื่ม พืชและเกษตร
สัตว์ บุคคลและเครือญาติ สถานที่ ศาสนา ร่างกาย ธรรมชาติ สิ่งของ การกระทำ
และลักษณะ หมวดที่ระบบเสนอไม่ถือว่ายืนยันจนกว่าจะมีผู้ตรวจ

## ข้อห้าม

- ห้ามใช้ผลโมเดลหรือกฎแทนข้อมูลพจนานุกรมโดยไม่ติดสถานะ `needs_review`
- ห้ามถือว่าการมีอักขระ Tai Tham Unicode แปลว่ารูปคำนั้นถูกต้อง
- ห้ามนำเข้าหลายพยัญชนะพร้อมกัน
- ห้ามเขียนทับคำที่ `owner_verified` หรือ `expert_verified` ด้วยผลอัตโนมัติ
