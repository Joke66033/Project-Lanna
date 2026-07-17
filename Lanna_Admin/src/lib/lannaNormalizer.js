/**
 * lannaNormalizer.js
 * ยูทิลิตี้สำหรับจัดเรียงและปรับปรุงการป้อนข้อมูลภาษาล้านนา (Tai Tham Unicode U+1A20 - U+1AAF)
 * และภาษาลาว (Lao Unicode U+0E80 - U+0EFF) ให้มีโครงสร้าง Unicode ตามหลักภาษาศาสตร์ที่ถูกต้อง
 */

// กำหนดค่าน้ำหนักสำหรับการจัดเรียง Combining Marks หลังพยัญชนะฐาน
const LANNA_LAO_MARKS_WEIGHT = {
  // 1. ตัวห้อย / อักษรควบกล้ำ (Subjoined Consonants / Medials) -> น้ำหนัก 1
  '\u1A55': 1, // Tai Tham Medial Ra (ᩕ)
  '\u1A56': 1, // Tai Tham Medial La (ᩖ)
  '\u1A57': 1, // Tai Tham La Tang Lai (ᩗ)
  
  // 2. สระล่าง (Vowels below) -> น้ำหนัก 2
  '\u1A69': 2, // Tai Tham Vowel U (ᩩ)
  '\u1A6A': 2, // Tai Tham Vowel Uu (ᩪ)
  '\u1A6D': 2, // Tai Tham Vowel Oy (ᩭ)
  '\u0EB8': 2, // Lao Vowel U
  '\u0EB9': 2, // Lao Vowel Uu
  '\u0EBC': 2, // Lao Semivowel Ia

  // 3. สระบน / สระกลาง (Vowels above) -> น้ำหนัก 3
  '\u1A62': 3, // Tai Tham Mai Sat / Mai Kan (ᩢ)
  '\u1A65': 3, // Tai Tham Vowel I (ᩥ)
  '\u1A66': 3, // Tai Tham Vowel Ii (ᩦ)
  '\u1A67': 3, // Tai Tham Vowel Ue (ᩧ)
  '\u1A68': 3, // Tai Tham Vowel Uee (ᩨ)
  '\u1A6B': 3, // Tai Tham Vowel O (ᩫ)
  '\u1A6C': 3, // Tai Tham Vowel Oa (ᩬ)
  '\u0EB1': 3, // Lao Mai Kan
  '\u0EB4': 3, // Lao Vowel I
  '\u0EB5': 3, // Lao Vowel Ii
  '\u0EB6': 3, // Lao Vowel Ue
  '\u0EB7': 3, // Lao Vowel Uee
  '\u0EBB': 3, // Lao Vowel O

  // 3.5 สระข้างหลัง (Vowels right/post-posed) -> น้ำหนัก 3.5 (บางครั้งพิมพ์สลับมาหลังสระบน)
  '\u1A63': 3.5, // Tai Tham Vowel Aa (ᩣ)
  '\u1A64': 3.5, // Tai Tham Vowel Aaa (ᩤ)

  // 4. วรรณยุกต์ (Tone marks above) -> น้ำหนัก 4
  '\u1A75': 4, // Tai Tham Tone-1 / Mai Ek (᩵)
  '\u1A76': 4, // Tai Tham Tone-2 / Mai Tho (᩶)
  '\u1A77': 4, // Tai Tham Mai Sam (᩷)
  '\u1A78': 4, // Tai Tham Mai Si (᩸)
  '\u1A79': 4, // Tai Tham Khuen Tone-1 (᩹)
  '\u0EC8': 4, // Lao Mai Ek
  '\u0EC9': 4, // Lao Mai Tho
  '\u0ECA': 4, // Lao Mai Tri
  '\u0ECB': 4, // Lao Mai Chattawa

  // 5. เครื่องหมายบนสุด / เครื่องหมายการันต์ / เครื่องหมายอื่นๆ (Above marks & Silencers) -> น้ำหนัก 5
  '\u1A58': 5, // Tai Tham Mai Kang Lai (ᩘ)
  '\u1A7A': 5, // Tai Tham Ra Haam / Silencer (᩺)
  '\u1A7B': 5, // Tai Tham Mai Mai (᩻)
  '\u1A7C': 5, // Tai Tham Ra Haam variant (᩼)
  '\u1A7F': 5, // Tai Tham Cryptogrammic Dot (᩿)
  '\u0ECC': 5, // Lao Mai San
  '\u0ECD': 5, // Lao Nikhahit
};

/**
 * ฟังก์ชันจัดระเบียบและจัดเรียงลำดับ Unicode อักษรล้านนาและอักษรลาว (Real-time Normalizer)
 * @param {string} text - ข้อความล้านนาหรือข้อความลาวที่มีการพิมพ์เข้ามา
 * @returns {string} ข้อความที่จัดเรียง Unicode ถูกต้องตามหลักภาษาศาสตร์
 */
export function normalizeLannaText(text) {
  if (!text) return "";

  const segments = [];
  let currentSegment = null;

  for (let i = 0; i < text.length; i++) {
    const char = text[i];

    // กรณีเจอ Sakot (U+1A60: ᩠) ตัวเชื่อมตัวห้อย
    if (char === '\u1A60') {
      const nextChar = (i + 1 < text.length) ? text[i + 1] : '';
      const subjoinedSeq = char + nextChar;

      if (currentSegment) {
        // นำตัวห้อยไปเกาะกับพยัญชนะต้นก่อนหน้า มีค่าน้ำหนักเป็น 1
        currentSegment.marks.push({ char: subjoinedSeq, weight: 1 });
      } else {
        // หากไม่มีพยัญชนะฐานก่อนหน้า ให้ถือว่าตัวห้อยนี้เป็นฐานชั่วคราว
        segments.push({ base: subjoinedSeq, marks: [] });
      }

      if (nextChar) {
        i++; // ข้ามตัวอักขระที่ถูกรวมเป็นตัวห้อยไป
      }
    }
    // กรณีตัวอักษรเป็น Combining mark อื่นๆ ที่มีน้ำหนักที่กำหนดไว้
    else if (LANNA_LAO_MARKS_WEIGHT[char] !== undefined) {
      if (currentSegment) {
        currentSegment.marks.push({ char, weight: LANNA_LAO_MARKS_WEIGHT[char] });
      } else {
        // หากไม่มีพยัญชนะฐานขึ้นก่อนหน้า
        segments.push({ base: char, marks: [] });
      }
    }
    // กรณีเป็นพยัญชนะฐานหรือสระหลักทั่วไป (Base characters)
    else {
      if (currentSegment) {
        segments.push(currentSegment);
      }
      currentSegment = { base: char, marks: [] };
    }
  }

  // เก็บบล็อกสุดท้าย
  if (currentSegment) {
    segments.push(currentSegment);
  }

  // จัดเรียง Combining Marks ในแต่ละ Segment
  let result = "";
  for (const seg of segments) {
    // จัดเรียงตามค่าน้ำหนัก (weight) จากน้อยไปหามาก
    seg.marks.sort((a, b) => a.weight - b.weight);

    result += seg.base;
    for (const m of seg.marks) {
      result += m.char;
    }
  }

  // รองรับการแทนที่กลุ่มคำศัพท์เฉพาะล้านนาที่มีรูปแบบการเขียนพิเศษ/สลับแบบพิเศษเพิ่มเติม (ถ้ามี)
  // ตัวอย่างเช่น การพิมพ์สระขวาหลังสระล่างที่เป็นกรณีเฉพาะ
  // (ณ จุดนี้ โครงสร้าง segments ครอบคลุมการพิมพ์สลับวรรณยุกต์-สระส่วนใหญ่แล้วอย่างถูกต้อง)

  return result;
}
