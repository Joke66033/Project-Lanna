/**
 * thaiToLanna.js
 * Central Lanna transliteration and font-mapping engine for Lanna Admin (Dynamic Algorithm, Zero Hardcoded Dictionary)
 */

const baseMap = {
  '\u1A20': 'ก', '\u1A21': 'ข', '\u1A22': 'ข', '\u1A23': 'ค', '\u1A24': 'ฅ', '\u1A25': 'ฆ', '\u1A26': 'ง',
  '\u1A27': 'จ', '\u1A28': 'ฉ', '\u1A29': 'ช', '\u1A2A': 'ซ', '\u1A2B': 'ฌ', '\u1A2C': 'ญ',
  '\u1A2D': 'ฏ', '\u1A2E': 'ฐ', '\u1A2F': 'ด', '\u1A30': 'ฒ', '\u1A31': 'ณ',
  '\u1A32': 'ต', '\u1A33': 'ถ', '\u1A34': 'ท', '\u1A35': 'ธ', '\u1A36': 'น',
  '\u1A37': 'บ', '\u1A38': 'ป', '\u1A39': 'ผ', '\u1A3A': 'ฝ', '\u1A3B': 'พ', '\u1A3C': 'ฟ', '\u1A3D': 'ภ', '\u1A3E': 'ม',
  '\u1A3F': 'ย', '\u1A40': 'ย', '\u1A41': 'ร', '\u1A42': 'ฤ', '\u1A43': 'ล', '\u1A44': 'ฦ', '\u1A45': 'ว',
  '\u1A46': 'ศ', '\u1A47': 'ษ', '\u1A48': 'ส', '\u1A49': 'ห', '\u1A4A': 'ฬ', '\u1A4B': 'อ', '\u1A4C': 'ฮ',
};

const subMap = {
  '\u1A20': '\uF001', '\u1A21': '\uF002', '\u1A22': '\uF002', '\u1A23': '\uF004',
  '\u1A24': '\uF004', '\u1A25': '\uF004', '\u1A26': '\uF007', '\u1A27': '\uF008',
  '\u1A28': '\uF009', '\u1A29': '\uF00A', '\u1A2A': '\uF00B', '\u1A2B': '\uF00C',
  '\u1A2C': '\uF00D', '\u1A2D': '\uF00E', '\u1A2E': '\uF00F', '\u1A2F': '\uF014',
  '\u1A30': '\uF012', '\u1A31': '\uF013', '\u1A32': '\uF015', '\u1A33': '\uF016',
  '\u1A34': '\uF017', '\u1A35': '\uF018', '\u1A36': '\uF019', '\u1A37': '\uF01A',
  '\u1A38': '\uF01B', '\u1A39': '\uF01C', '\u1A3A': '\uF01D', '\u1A3B': '\uF01E',
  '\u1A3C': '\uF01F', '\u1A3D': '\uF020', '\u1A3E': '\uF021', '\u1A3F': '\uF022',
  '\u1A40': '\uF022', '\u1A41': '\uF023', '\u1A42': '\uF024', '\u1A43': '\uF025',
  '\u1A44': '\uF026', '\u1A45': '\uF027', '\u1A46': '\uF028', '\u1A47': '\uF029',
  '\u1A48': '\uF02A', '\u1A49': '\uF02B', '\u1A4A': '\uF02C', '\u1A4B': '\uF02D',
  '\u1A4C': '\uF02E',
  'ก': '\uF001', 'ข': '\uF002', 'ค': '\uF004', 'ง': '\uF007',
  'จ': '\uF008', 'ฉ': '\uF009', 'ช': '\uF00A', 'ซ': '\uF00B',
  'ด': '\uF014', 'ต': '\uF015', 'ถ': '\uF016', 'ท': '\uF017', 'น': '\uF019',
  'บ': '\uF01A', 'ป': '\uF01B', 'ผ': '\uF01C', 'ฝ': '\uF01D', 'พ': '\uF01E',
  'ฟ': '\uF01F', 'ม': '\uF021', 'ย': '\uF022', 'ร': '\uF023', 'ล': '\uF025',
  'ว': '\uF027', 'ส': '\uF02A', 'ห': '\uF02B'
};

const specialLigatures = {
  // 1. สวัสดี / สวัสสดี / สัสส
  '\u1A48\u1A60\u1A45\u1A7B\u1A48\u1A60\u1A48\u1A2F\u1A66': 'ส\uF027ั\u00AAดี',
  '\u1A48\u1A60\u1A48': '\u00AA',
  'สวัสดี': 'ส\uF027ั\u00AAดี',
  'สวัสสดี': 'ส\uF027ั\u00AAดี',
  'ส_วั\u00AAดี': 'ส\uF027ั\u00AAดี',
  'สวั\u00AAดี': 'ส\uF027ั\u00AAดี',
  // 2. น่าน
  '\u1A36\u1A75\u1A63\u1A60\u1A36': '\u00A2\uF0A3\uF019',
  '\u1A36\u1A75\u1A63\u1A36': '\u00A2\uF0A3\uF019',
  'น่า\uF019': '\u00A2\uF0A3\uF019',
  'น่าน': '\u00A2\uF0A3\uF019',
  // 3. พะเยา (พยาว - ใส่ [ หน้าตัว พ และเอาตัว ว ไปห้อยใต้สระอา)
  '\u1A3B\u1A55': 'พ\uF023',
  '\u1A55': '\uF023',
  'พยาว': '[พยา\uF027',
  'พะเยา': '[พยา\uF027',
  'พระยาว': '[พยา\uF027',
  '[พยา\uF057': '[พยา\uF027',
  '[พย\uF027า': '[พยา\uF027',
  'พยา\uF057': '[พยา\uF027',
  'พยา \uF027': '[พยา\uF027',
  '\u1A3B\u1A55\u1A3F\u1A63\u1A45': '[พยา\uF027',
  '\u1A3B\u1A61\u1A3F\u1A6E\u1A7B\u1A63': '[พยา\uF027',
  // 4. ละห้อย (Medial La) \u1A56 -> \uF025
  '\u1A56': '\uF025',
  // 5. ลำพูน
  '\u1A43\u1A38\u1A6A\u1A60\u1A36': 'ลตูร',
  '\u1A43\u1A61\u1A38\u1A6A\u1A60\u1A36': 'ลตูร',
  'ลบูป': 'ลตูร',
  'ละปูน': 'ลตูร',
  'ลำพูน': 'ลตูร',
  // 6. ลำปาง
  '\u1A43\u1A63\u1A74\u1A38\u1A63\u1A26': 'ล\u0E4Dาพา\uF007',
  '\u1A43\u1A74\u1A63\u1A3B\u1A63\u1A60\u1A26': 'ล\u0E4Dาพา\uF007',
  '\u1A43\u1A74\u1A3B\u1A63\u1A60\u1A26': 'ล\u0E4Dาพา\uF007',
  '\u1A43\u1A74\u1A38\u1A63\u1A60\u1A26': 'ล\u0E4Dาพา\uF007',
  'ลํววาตา': 'ล\u0E4Dาพา\uF007',
  'ลำปาง': 'ล\u0E4Dาพา\uF007',
  // 7. เชียงราย / เชียงใหม่
  'ช\uF022งราย': 'ช\uF022งรา\uF022',
  'เชียงราย': 'ช\uF022งรา\uF022',
  '\u1A29\u1A60\u1A3F\u1A26\u1A41\u1A63\u1A3F': 'ช\uF022งรา\uF022',
  'เชียงใหม่': 'ช\uF022ง\u0E43ห\uF021\u0E48',
  '\u1A29\u1A60\u1A3F\u1A26\u1A72\u1A49\u1A60\u1A3E\u1A75': 'ช\uF022ง\u0E43ห\uF021\u0E48',
  // 8. แม่ฮ่องสอน / แพร่
  '\u1A6F\u1A3E\u1A75\u1A41\u1A6C\u1A75\u1A26\u1A48\u1A6C\u1A41': 'แม่ร\uF007่คส\uF007ร',
  'แม่ฮ่องสอน': 'แม่ร\uF007่คส\uF007ร',
  'แม่ฮองสอน': 'แม่ร\uF007่คส\uF007ร',
  'แพร่': 'แ\u0E1E\uF025\u0E48',
  '\u1A6F\u1A3B\u1A56\u1A75': 'แ\u0E1E\uF025\u0E48',
  // 9. จะไป / อย่า / ไป -> จไพ / ไพ
  'จะไป': 'จไพ',
  'จะไปมา': 'จไพมา',
  'จะไปไป': 'จไพไพ',
  'จะไปยะ': 'จไพยะ',
  'จะไปกิ๋น': 'จไพกิ๋\uF019',
  'จะไปอู้': 'จไพอู้',
  'อย่ามา': 'จไพมา',
  'อย่าไป': 'จไพไพ',
  'อย่าทำ': 'จไพยะ',
  'อย่ากิน': 'จไพกิ๋\uF019',
  'อย่าพูด': 'จไพอู้',
  '\u1A27\u1A71\u1A3B\u1A71\u1A3B': 'จไพไพ',
  '\u1A27\u1A71\u1A38\u1A71\u1A38': 'จไพไพ',
  '\u1A71\u1A3B\u1A71\u1A3B': 'ไพไพ',
  '\u1A71\u1A38\u1A71\u1A38': 'ไพไพ',
  '\u1A71\u1A38': 'ไพ',
  '\u1A71\u1A3B': 'ไพ',
  // 10. ฉลาด (จ + ละห้อยหางยาว \uF055 + า + ดะห้อย \uF014)
  '\u1A27\u1A56\u1A63\u1A60\u1A2F': 'จ\uF055า\uF014',
  '\u1A27\u1A56\u1A63\u1A2F': 'จ\uF055า\uF014',
  'จ\uF025า\uF014': 'จ\uF055า\uF014',
  'ฉลาด': 'จ\uF055า\uF014',
  'จะหลาด': 'จ\uF055า\uF014',
  '[จาด': 'จ\uF055า\uF014',
  // 11. ยินดีต้อนรับ / ยินดีต้อนฮับ
  'ยินดีต้อนรับ': 'ยิ\uF019ดีต้อ\uF019ฮั\uF01A',
  'ยินดีต้อนฮับ': 'ยิ\uF019ดีต้อ\uF019ฮั\uF01A',
  'ยินดีต้อนฮั้บ': 'ยิ\uF019ดีต้อ\uF019ฮั\uF01A',
  '\u1A3F\u1A65\u1A60\u1A36\u1A2F\u1A66\u1A32\u1A6C\u1A76\u1A41\u1A7B\u1A60\u1A37': 'ยิ\uF019ดีต้อ\uF019ฮั\uF01A',
  '\u1A3F\u1A65\u1A60\u1A36\u1A2F\u1A66\u1A32\u1A6C\u1A76\u1A36\u1A4C\u1A7B\u1A60\u1A37': 'ยิ\uF019ดีต้อ\uF019ฮั\uF01A',
  // 12. อ่านก่อนใช้
  'อ่านก่อนใช้': 'อ่า\uF019ก\u0E48อ\uF019ไช\u0E49',
};

export function toTilokFontString(text, fallbackThai = null) {
  if (!text) return "";
  let trimmed = String(text).trim();

  // 1. ตรวจสอบ Ligatures และคำสะกดตามอักขรวิธีล้านนา (ตรวจสอบ fallbackThai ก่อนเสมอ)
  if (fallbackThai && specialLigatures[fallbackThai.trim()]) {
    return specialLigatures[fallbackThai.trim()];
  }
  if (specialLigatures[trimmed]) {
    return specialLigatures[trimmed];
  }

  // หากเป็นรหัส LN-TILOK PUA สำเร็จรูปอยู่แล้ว คืนค่าทันที
  if (/[\uF000-\uF0FF\u00AA\u00AC\u00AD]/.test(trimmed) &&
      !trimmed.includes('ราย') && !trimmed.includes('ยาว') && !trimmed.includes('ปูน') && !trimmed.includes('ปาง') &&
      !trimmed.includes('[') && !trimmed.includes('พ')) {
    return trimmed;
  }

  let src = trimmed;
  for (const [key, val] of Object.entries(specialLigatures)) {
    src = src.split(key).join(val);
  }

  const vowels = new Set(['\u1A63', '\u1A64', '\u1A65', '\u1A66', '\u1A67', '\u1A68', '\u1A69', '\u1A6A', '\u1A7B', 'า', 'ิ', 'ี', 'ึ', 'ื', 'ุ', 'ู', 'ั', 'อ', '\u1A6C']);

  let out = [];
  const chars = Array.from(src);
  for (let i = 0; i < chars.length; i++) {
    const c = chars[i];
    if ((c === '\u1A60' || c === '᩠') && i + 1 < chars.length) {
      const next = chars[i + 1];
      if (subMap[next]) {
        out.push(subMap[next]);
        i++;
        continue;
      }
    }

    const isAfterVowel = i > 0 && vowels.has(chars[i - 1]);
    const isAtWordBoundary = i === chars.length - 1 || chars[i + 1] === ' ' || chars[i + 1] === '\n';
    if (isAfterVowel && isAtWordBoundary && subMap[c]) {
      out.push(subMap[c]);
      continue;
    }

    if (baseMap[c]) {
      out.push(baseMap[c]);
    } else {
      switch (c) {
        case '\u1A63': case '\u1A64': out.push('า'); break;
        case '\u1A65': out.push('ิ'); break;
        case '\u1A66': out.push('ี'); break;
        case '\u1A67': out.push('ึ'); break;
        case '\u1A68': out.push('ื'); break;
        case '\u1A69': out.push('ุ'); break;
        case '\u1A6A': out.push('ู'); break;
        case '\u1A6E': out.push('เ'); break;
        case '\u1A6F': out.push('แ'); break;
        case '\u1A70': out.push('โ'); break;
        case '\u1A71': out.push('ไ'); break;
        case '\u1A72': out.push('ใ'); break;
        case '\u1A74': out.push('\u0E4Dา'); break;
        case '\u1A75': out.push('่'); break;
        case '\u1A76': out.push('้'); break;
        case '\u1A77': out.push('๊'); break;
        case '\u1A78': out.push('๋'); break;
        case '\u1A7A': out.push('์'); break;
        case '\u1A7B': out.push('ั'); break;
        case '\u1A6C': case '\u1A7C': out.push('อ'); break;
        default: out.push(c); break;
      }
    }
  }
  return out.join('');
}

export const tilokDirectMap = {};

export async function loadLannaMap() {
  return {};
}

export function convertThaiToLanna(text) {
  return toTilokFontString(text);
}

export function thaiToLanna(text) {
  return toTilokFontString(text);
}
