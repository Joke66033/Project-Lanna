/// ===============================
/// ประเภทการฝึกเขียน
/// ===============================
enum WritingType {
  consonant, // พยัญชนะ
  vowel,     // สระ
  tone,      // วรรณยุกต์
  number,    // ตัวเลข
}

/// ===============================
/// โมเดลข้อมูลการฝึกเขียน
/// ===============================
class WritingItem {
  final String char;        // ตัวอักษรล้านนา
  final String label;       // ชื่ออ่าน (ก, ข, สระ อา ฯลฯ)
  final WritingType type;   // ประเภท

  const WritingItem({
    required this.char,
    required this.label,
    required this.type,
  });
}


