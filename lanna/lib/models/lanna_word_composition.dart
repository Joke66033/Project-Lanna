/// โมเดลโครงสร้างข้อมูลอักขระล้านนาสำหรับแต่ละพยางค์ (Lanna Syllable Composition Model)
/// รองรับการแยกองค์ประกอบ พยัญชนะต้น, สระ, วรรณยุกต์, ตัวสะกด และตัวห้อย (Sakot)
/// ตามหลักการอักขรวิธีล้านนาที่แท้จริงแทนการจัดเก็บเป็นข้อความดิบเพียงอย่างเดียว
class LannaSyllable {
  /// พยัญชนะต้น (เช่น ก -> \u1A20, ข -> \u1A21)
  final String consonant;

  /// พยัญชนะควบกล้ำหรือตัวสะกดห้อยด้านล่าง (Tua Hom / Tua Sakot เช่น \u1A60 + ร)
  final String? subjoinedConsonant;

  /// สระที่ผสม (เช่น สระอา -> \u1A63, สระอู -> \u1A6A)
  final String? vowel;

  /// เครื่องหมายวรรณยุกต์ล้านนา (เช่น ไม้เอก -> \u1A75, ไม้โท -> \u1A76)
  final String? tone;

  /// ตัวสะกดด้านหลัง (ถ้ามี)
  final String? finalConsonant;

  /// เครื่องหมายพิเศษอื่นๆ (เช่น ไม้ซัด -> \u1A7B, ไม้แก๋งไหล)
  final String? specialSign;

  LannaSyllable({
    required this.consonant,
    this.subjoinedConsonant,
    this.vowel,
    this.tone,
    this.finalConsonant,
    this.specialSign,
  });

  /// แปลงข้อมูล JSON กลับมาเป็นโมเดล LannaSyllable
  factory LannaSyllable.fromJson(Map<String, dynamic> json) {
    return LannaSyllable(
      consonant: json['consonant']?.toString() ?? '',
      subjoinedConsonant: json['subjoined_consonant']?.toString(),
      vowel: json['vowel']?.toString(),
      tone: json['tone']?.toString(),
      finalConsonant: json['final_consonant']?.toString(),
      specialSign: json['special_sign']?.toString(),
    );
  }

  /// แปลงโมเดล LannaSyllable ไปเป็น Map/JSON
  Map<String, dynamic> toJson() {
    return {
      'consonant': consonant,
      if (subjoinedConsonant != null) 'subjoined_consonant': subjoinedConsonant,
      if (vowel != null) 'vowel': vowel,
      if (tone != null) 'tone': tone,
      if (finalConsonant != null) 'final_consonant': finalConsonant,
      if (specialSign != null) 'special_sign': specialSign,
    };
  }

  /// ทำการสร้างชุดอักขระล้านนา (Unicode Tai Tham) ที่ถูกต้องสมบูรณ์แบบตามลำดับอักขรวิธีล้านนา
  /// ลำดับการเรียงอักษรล้านนาทาง Unicode:
  /// 1. สระหน้า (ถ้ามี เช่น สระเอ \u1A6E, สระแอ \u1A6F)
  /// 2. พยัญชนะต้น (consonant)
  /// 3. ตัวสะกด/ตัวห้อยด้านล่าง (Sakot \u1A60 + subjoinedConsonant)
  /// 4. สระล่าง/สระบน/สระหลัง (vowel)
  /// 5. ตัวสะกดท้าย (Sakot \u1A60 + finalConsonant)
  /// 6. วรรณยุกต์ (tone) และ เครื่องหมายพิเศษ (specialSign)
  String toLannaString() {
    final buffer = StringBuffer();

    // 1. สระหน้าล้านนา
    final isPreVowel = vowel == '\u1A6E' || // สระเอ
                       vowel == '\u1A6F' || // สระแอ
                       vowel == '\u1A70' || // สระโอ
                       vowel == '\u1A71' || // สระไอ (อย)
                       vowel == '\u1A72';   // สระใอ
    if (isPreVowel && vowel != null) {
      buffer.write(vowel);
    }

    // 2. พยัญชนะต้น
    buffer.write(consonant);

    // 3. ตัวสะกดห้อย/ควบกล้ำด้านล่าง (Sakot + consonant)
    if (subjoinedConsonant != null && subjoinedConsonant!.isNotEmpty) {
      buffer.write('\u1A60'); // SAKOT CONTROLLER
      buffer.write(subjoinedConsonant);
    }

    // 4. สระ (ถ้าไม่ใช่สระหน้า)
    if (vowel != null && !isPreVowel) {
      buffer.write(vowel);
    }

    // 5. ตัวสะกดท้าย (ถ้าเขียนเป็นตัวสะกดห้อย)
    if (finalConsonant != null && finalConsonant!.isNotEmpty) {
      buffer.write('\u1A60'); // SAKOT CONTROLLER
      buffer.write(finalConsonant);
    }

    // 6. วรรณยุกต์ และ เครื่องหมายพิเศษ
    if (specialSign != null) {
      buffer.write(specialSign);
    }

    if (tone != null) {
      buffer.write(tone);
    }

    return buffer.toString();
  }
}
