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

//////////////////////////////////////////////////
/// พยัญชนะล้านนา (10 ตัว)
//////////////////////////////////////////////////

const consonants = [
  WritingItem(char: 'ᨠ', label: 'ก', type: WritingType.consonant),
  WritingItem(char: 'ᨡ', label: 'ข', type: WritingType.consonant),
  WritingItem(char: 'ᨢ', label: 'ค', type: WritingType.consonant),
  WritingItem(char: 'ᨣ', label: 'ฆ', type: WritingType.consonant),
  WritingItem(char: 'ᨤ', label: 'ง', type: WritingType.consonant),
  WritingItem(char: 'ᨥ', label: 'จ', type: WritingType.consonant),
  WritingItem(char: 'ᨦ', label: 'ฉ', type: WritingType.consonant),
  WritingItem(char: 'ᨧ', label: 'ช', type: WritingType.consonant),
  WritingItem(char: 'ᨨ', label: 'ซ', type: WritingType.consonant),
  WritingItem(char: 'ᨩ', label: 'ญ', type: WritingType.consonant),
];

//////////////////////////////////////////////////
/// สระล้านนา (10 ตัว)
//////////////////////////////////////////////////

const vowels = [
  WritingItem(char: 'ᩣ', label: 'สระ อา', type: WritingType.vowel),
  WritingItem(char: 'ᩤ', label: 'สระ อิ', type: WritingType.vowel),
  WritingItem(char: 'ᩥ', label: 'สระ อี', type: WritingType.vowel),
  WritingItem(char: 'ᩦ', label: 'สระ อึ', type: WritingType.vowel),
  WritingItem(char: 'ᩧ', label: 'สระ อื', type: WritingType.vowel),
  WritingItem(char: 'ᩨ', label: 'สระ อุ', type: WritingType.vowel),
  WritingItem(char: 'ᩩ', label: 'สระ อู', type: WritingType.vowel),
  WritingItem(char: 'ᩪ', label: 'สระ เอ', type: WritingType.vowel),
  WritingItem(char: 'ᩫ', label: 'สระ แอ', type: WritingType.vowel),
  WritingItem(char: 'ᩬ', label: 'สระ โอ', type: WritingType.vowel),
];

//////////////////////////////////////////////////
/// วรรณยุกต์ล้านนา (ประมาณ 10)
//////////////////////////////////////////////////

const tones = [
  WritingItem(char: '\u1a75', label: 'ไม้เอก', type: WritingType.tone),
  WritingItem(char: '\u1a76', label: 'ไม้โท', type: WritingType.tone),
  WritingItem(char: '\u1a77', label: 'ไม้ตรี', type: WritingType.tone),
  WritingItem(char: '\u1a78', label: 'ไม้จัตวา', type: WritingType.tone),
  WritingItem(char: '\u1a62', label: 'ไม้หันอากาศ', type: WritingType.tone),
  WritingItem(char: '\u1a7a', label: 'เครื่องหมายเสียงสูง', type: WritingType.tone),
  WritingItem(char: '\u1a7f', label: 'เครื่องหมายเสียงต่ำ', type: WritingType.tone),
  WritingItem(char: '\u1a7b', label: 'ไม้พัด/ไม้ระเบิด', type: WritingType.tone),
  WritingItem(char: '\u1a7c', label: 'ไม้ซัด', type: WritingType.tone),
  WritingItem(char: '\u1a74', label: 'ไม้สัญญประกาศ', type: WritingType.tone),
  WritingItem(char: '\u1a53', label: 'เครื่องหมายย่อคำ', type: WritingType.tone),
];

//////////////////////////////////////////////////
/// ตัวเลขล้านนา (10 ตัว)
//////////////////////////////////////////////////

const numbers = [
  WritingItem(char: '᪑', label: '๑', type: WritingType.number),
  WritingItem(char: '᪒', label: '๒', type: WritingType.number),
  WritingItem(char: '᪓', label: '๓', type: WritingType.number),
  WritingItem(char: '᪔', label: '๔', type: WritingType.number),
  WritingItem(char: '᪕', label: '๕', type: WritingType.number),
  WritingItem(char: '᪖', label: '๖', type: WritingType.number),
  WritingItem(char: '᪗', label: '๗', type: WritingType.number),
  WritingItem(char: '᪘', label: '๘', type: WritingType.number),
  WritingItem(char: '᪙', label: '๙', type: WritingType.number),
  WritingItem(char: '᪐', label: '๐', type: WritingType.number),
];
