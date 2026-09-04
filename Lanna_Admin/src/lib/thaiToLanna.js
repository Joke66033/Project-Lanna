/**
 * thaiToLanna.js
 * Central Lanna transliteration engine matching the mobile app
 */

// 1. Direct Consonant Mapping (Thai -> Tai Tham Unicode)
const consonantMap = {
  'ก': '\u1A20', 'ข': '\u1A21', 'ฃ': '\u1A22', 'ค': '\u1A23', 'ฅ': '\u1A24', 'ฆ': '\u1A25', 'ง': '\u1A26',
  'จ': '\u1A27', 'ฉ': '\u1A28', 'ช': '\u1A29', 'ซ': '\u1A2A', 'ฌ': '\u1A2B', 'ญ': '\u1A2C',
  'ฎ': '\u1A2D', 'ฏ': '\u1A2D', 'ฐ': '\u1A2E', 'ฑ': '\u1A2F', 'ฒ': '\u1A30', 'ณ': '\u1A31',
  'ด': '\u1A2F', 'ต': '\u1A32', 'ถ': '\u1A33', 'ท': '\u1A34', 'ธ': '\u1A35', 'น': '\u1A36',
  'บ': '\u1A37', 'ป': '\u1A38', 'ผ': '\u1A39', 'ฝ': '\u1A3A', 'พ': '\u1A3B', 'ฟ': '\u1A3C', 'ภ': '\u1A3D', 'ม': '\u1A3E',
  'ย': '\u1A3F', 'ร': '\u1A41', 'ฤ': '\u1A42', 'ล': '\u1A43', 'ฦ': '\u1A44', 'ว': '\u1A45',
  'ศ': '\u1A46', 'ษ': '\u1A47', 'ส': '\u1A48', 'ห': '\u1A49', 'ฬ': '\u1A4A', 'อ': '\u1A4B', 'ฮ': '\u1A4C',
};

// 2. Direct Vowel Mapping
const vowelMap = {
  'ะ': '\u1A61', 'า': '\u1A63', 'ิ': '\u1A65', 'ี': '\u1A66', 'ึ': '\u1A67', 'ื': '\u1A68',
  'ุ': '\u1A69', 'ู': '\u1A6A', 'เ': '\u1A6E', 'แ': '\u1A6F', 'โ': '\u1A70', 'ใ': '\u1A72', 'ไ': '\u1A71',
  'ั': '\u1A62', '็': '\u1A7B', 'ำ': '\u1A63\u1A74',
};

// 3. Direct Tone Mapping
const toneMap = {
  '่': '\u1A75', '้': '\u1A76', '๊': '\u1A77', '๋': '\u1A78', '์': '\u1A7A',
};

// 4. Digits
const numberMap = {
  '๐': '\u1A80', '๑': '\u1A81', '๒': '\u1A82', '๓': '\u1A83', '๔': '\u1A84',
  '๕': '\u1A85', '๖': '\u1A86', '๗': '\u1A87', '๘': '\u1A88', '๙': '\u1A89',
  '0': '\u1A80', '1': '\u1A81', '2': '\u1A82', '3': '\u1A83', '4': '\u1A84',
  '5': '\u1A85', '6': '\u1A86', '7': '\u1A87', '8': '\u1A88', '9': '\u1A89',
};

const sakot = '\u1A60';
const clusterFollowers = new Set(['ร', 'ล', 'ว', 'ย']);

// 5. High-Frequency Authentic Dictionary Mapping
const dialectDictionary = {
  'สวัสดี': 'ᩈᩅᩢᩔᨯᩦ',
  'สะ-หวัด-ดี': 'ᩈᩅᩢᩔᨯᩦ',
  'สะหวัดดี': 'ᩈᩅᩢᩔᨯᩦ',
  'สะ-บาย-ดี': 'ᩈᩅᩢ᩠ᨯᩈᨯᩦ',
  'สะบายดี': 'ᩈᩅᩢ᩠ᨯᩈᨯᩦ',
  'สะ-หวัด-สะ-ดี': 'ᩈᩅᩢᩔᨯᩦ',
  'สะหวัดสะดี': 'ᩈᩅᩢᩔᨯᩦ',
  'ยินดีต้อนรับ': 'ᨿᩥ᩠ᨶᨯᩦᨲᩬ᩶ᩁᩁᩢ᩠ᨷ',
  'ยินดีต้อนฮับ': 'ᨿᩥ᩠ᨶᨯᩦᨲᩬ᩶ᩁᩁᩢ᩠ᨷ',
  'ยินดี': 'ᨿᩥ᩠ᨶᨯᩦ',
  'ขอบคุณ': 'ᨿᩥ᩠ᨶᨯᩦ',
  'ขอโทษ': 'ᩈᩩᨾᩣ',
  'สุมา': 'ᩈᩩᨾᩣ',
  'มะม่วง': 'ᨷᩡᨾ᩠ᩅ᩵ᨦ',
  'บะม่วง': 'ᨷᩡᨾ᩠ᩅ᩵ᨦ',
  'มะนาว': 'ᨷᩡᨶᩣᩅ',
  'บะนาว': 'ᨷᩡᨶᩣᩅ',
  'มะพร้าว': 'ᨷᩡᨸ᩶ᩣᩅ',
  'บะป๊าว': 'ᨷᩡᨸ᩶ᩣᩅ',
  'มะเขือ': 'ᨷᩡᨡᩮᩬᩥ',
  'บะเขือ': 'ᨷᩡᨡᩮᩬᩥ',
  'มะขาม': 'ᨷᩡᨡᩣ᩠ᨾ',
  'บะขาม': 'ᨷᩡᨡᩣ᩠ᨾ',
  'ส้มตำ': 'ᨲᩣᩴᩈᩫ᩠ᨾ',
  'ตำส้ม': 'ᨲᩣᩴᩈᩫ᩠ᨾ',
  'เชียงใหม่': 'ᨩ᩠ᨿᨦᩲᩉ᩠ᨾ᩵',
  'เจียงใหม่': 'ᨩ᩠ᨿᨦᩲᩉ᩠ᨾ᩵',
  'เชียงราย': 'ᨩ᩠ᨿᨦᩁᩣ᩠ᨿ',
  'เจียงฮาย': 'ᨩ᩠ᨿᨦᩁᩣ᩠ᨿ',
  'ลำพูน': 'ᩃᩣᩴᨻᩪ᩠ᨶ',
  'ละปูน': 'ᩃᩣᩴᨻᩪ᩠ᨶ',
  'ลำปาง': 'ᩃᩣᩴᨸᩣ᩠ᨦ',
  'ละปาง': 'ᩃᩣᩴᨸᩣ᩠ᨦ',
  'พะเยา': 'ᨻ᩠ᨿᩣᩅ',
  'พยาว': 'ᨻ᩠ᨿᩣᩅ',
  'น่าน': 'ᨶ᩵ᩣ᩠ᨶ',
  'แพร่': 'ᩯᨻᩕ᩵',
  'แม่ฮ่องสอน': 'ᩯᨾ᩵ᩁᩬ᩵ᨦᩈᩬᩁ',
  'ผ้าคลุม': 'ᨹ᩶ᩣᨲᩩ᩠ᨾ',
  'เสริมงาม': 'ᩈᩮᩁᩥ᩠ᨾᨦᩣ᩠ᨾ',
  'สันติสุข': 'ᩈᩢ᩠ᨶติᩈᩩᨡ',
  'สันทราย': 'ᩈᩢ᩠ᨶᨴᩕᩣ᩠ᨿ',
  'กิน': 'ᨠᩥ᩠᩵ᨶ',
  'กิ๋น': 'ᨠᩥ᩠᩵ᨶ',
  'กินข้าว': 'ᨠᩥ᩠᩵ᨶᨡ᩶ᩣᩅ',
  'กิ๋นข้าว': 'ᨠᩥ᩠᩵ᨶᨡ᩶ᩣᩅ',
  'อร่อย': 'ᩃᩣᩴ',
  'ลำ': 'ᩃᩣᩴ',
  'สวย': 'ᨦᩣ᩠ᨾ',
  'งาม': 'ᨦᩣ᩠ᨾ',
  'พูด': 'ᩋᩪ᩶',
  'อู้': 'ᩋᩪ᩶',
  'รัก': 'ᩁᩢ᩠ᨠ',
  'ฮัก': 'ᩁᩢ᩠ᨠ',
};

function isFinalConsonant(text, index) {
  if (index === 0 || !consonantMap[text[index]]) return false;
  const next = index + 1 < text.length ? text[index + 1] : '';
  if (next && next.trim() && !consonantMap[next]) return false;
  const prev = text[index - 1];
  return vowelMap[prev] || toneMap[prev] || prev === 'ะ' || prev === 'ั';
}

/**
 * Transliterates Thai/Reading text into Tai Tham (Lanna) script matching Flutter engine
 */
export function convertThaiToLanna(input) {
  if (!input) return '';
  const text = String(input).trim().replace(/[\[\]\-]/g, '');
  if (!text) return '';

  // 1. Direct dictionary match
  if (dialectDictionary[text]) {
    return dialectDictionary[text];
  }

  // Check with original input
  const origTrimmed = String(input).trim();
  if (dialectDictionary[origTrimmed]) {
    return dialectDictionary[origTrimmed];
  }

  // 2. Rule-based Transliteration matching LannaTransliterator
  let result = '';
  let offset = 0;

  while (offset < text.length) {
    // Check if substring matches dictionary entry
    let matched = null;
    for (const [key, val] of Object.entries(dialectDictionary)) {
      if (text.startsWith(key, offset)) {
        matched = { key, val };
        break;
      }
    }
    if (matched) {
      result += matched.val;
      offset += matched.key.length;
      continue;
    }

    const char = text[offset];
    if (consonantMap[char]) {
      result += consonantMap[char];
      const next = offset + 1 < text.length ? text[offset + 1] : '';
      const afterNext = offset + 2 < text.length ? text[offset + 2] : '';

      if (clusterFollowers.has(next) && consonantMap[next] && afterNext) {
        result += sakot + consonantMap[next];
        offset++;
      } else if (isFinalConsonant(text, offset)) {
        const prev = offset > 0 ? text[offset - 1] : '';
        if (prev !== '์') {
          const written = consonantMap[char];
          if (result.endsWith(written)) {
            result = result.slice(0, -written.length);
            if (result.endsWith('\u1A62')) {
              result = result.slice(0, -1);
            }
            result += sakot + written;
          }
        }
      }
    } else if (vowelMap[char]) {
      result += vowelMap[char];
    } else if (toneMap[char]) {
      result += toneMap[char];
    } else if (numberMap[char]) {
      result += numberMap[char];
    } else {
      result += char;
    }
    offset++;
  }

  return result;
}

export function toTilokFontString(text) {
  return convertThaiToLanna(text);
}

export function thaiToLanna(text) {
  return convertThaiToLanna(text);
}

export async function loadLannaMap() {
  return {};
}

export const tilokDirectMap = {};
