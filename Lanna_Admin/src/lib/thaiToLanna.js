/**
 * thaiToLanna.js
 * Central Lanna transliteration and font-mapping engine for Lanna Admin (aligned 100% with Mobile App)
 */

export const tilokDirectMap = {
  'สวัสดี': 'ส\uF0A8\uF027สดี',
  'ᩈ᩠ᩅᩢᩈ᩠ᩈᨯᩦ': 'ส\uF0A8\uF027สดี',
  'สัสสดี': 'ส\uF0A8\uF027สดี',
  'ᩈ᩠ᩅᩢᩈ᩠ᨯᩦ': 'ส\uF0A8\uF027สดี',
  'ᩈ᩠ᩅ᩺ᩈᨯᩦ': 'ส\uF0A8\uF027สดี',
  'ᩈ᩠ᩅᩢᩔ᩠ᨯᩦ': 'ส\uF0A8\uF027สดี',
  'สวัสดิภาพ': 'ส\uF0A8\uF027สติภาพ',
  'สวัสดิการ': 'ส\uF0A8\uF027สติการ',
  'ลาบ': 'ลา\uF01A\uF022',
  'ᩃᩣ᩠ᨷ': 'ลา\uF01A\uF022',
  'ลาบหมู': 'ลา\uF01A\uF022 ห\uF021ู',
  'ᩃᩣ᩠ᨷᩉ᩠ᨾᩪ': 'ลา\uF01A\uF022 ห\uF021ู',
  'ลาบควาย': 'ลา\uF01A\uF022 ควา\uF022',
  'ᩃᩣ᩠ᨷᨣ᩠ᩅᩣᨿ': 'ลา\uF01A\uF022 ควา\uF022',
  'ลาบงัว': 'ลา\uF01A\uF022 งัว',
  'ลาบวัว': 'ลา\uF01A\uF022 วัว',
  'ลาบไก่': 'ลา\uF01A\uF022 ไก่',
  'ลาบดิบ': 'ลา\uF01A\uF022ดิ\uF01A',
  'ᩃᩣ᩠ᨷᨯᩥ᩠ᨷ': 'ลา\uF01A\uF022ดิ\uF01A',
  'ลาบสุก': 'ลา\uF01A\uF022สุก',
  'ᩃᩣ᩠ᨷᩈᩩᨠ': 'ลา\uF01A\uF022สุก',
  'ส้าสุก': 'ส้าสุก',
  'ᩈ᩶ᩣᩈᩩᨠ': 'ส้าสุก',
  'ส้าดิบ': 'ส้าดิ\uF01A',
  'ᩈ᩶ᩣᨯᩥ᩠ᨷ': 'ส้าดิ\uF01A',
  'ดิบ': 'ดิ\uF01A',
  'ᨯᩥ᩠ᨷ': 'ดิ\uF01A',
  'ส้า': 'ส้า',
  'ᩈ᩶ᩣ': 'ส้า',
  'เชียงราย': 'ช\uF022งรา\uF022',
  'ᨩ᩠ᨿᨦᩁᩣᨿ': 'ช\uF022งรา\uF022',
  'เชียงใหม่': 'ช\uF022งให\uF021่',
  'ᨩ᩠ᨿᨦᩲᩉ᩠ᨾ᩵': 'ช\uF022งให\uF021่',
  'น่าน': '\u00A2\uF0A3\uF019',
  'ᨶ᩵ᩣ᩠ᨶ': '\u00A2\uF0A3\uF019',
  'พะเยา': '\u00ACยา\uF027',
  'ᨻᩕᨿᩣᩅ': '\u00ACยา\uF027',
  'แพร่': 'แต\uF024่',
  'ᩯᨻᩕ᩵': 'แต\uF024่',
  'แม่ฮ่องสอน': 'แม่ร\uF007่คส\uF007ร',
  'ᩯᨾ᩵ᩁᩬ᩵ᨦᩈᩬᩁ': 'แม่ร\uF007่คส\uF007ร',
  'ลำปาง': 'ลำพา\uF007',
  'ᩃᩣᩴᨸᩣᨦ': 'ลำพา\uF007',
  'ลำพูน': 'ลตูร',
  'ᩃᨸᩪ᩠ᨶ': 'ลตูร',
  'ᩃᩡᨸᩪ᩠ᨶ': 'ลตูร',
  'อุตรดิตถ์': 'อุตรดิตถ์',
  'ᩋᩩᨲ᩠ᨲᩁᨯᩥᨲ᩠ᨳ᩺': 'อุตรดิตถ์',
  'วัด': 'วั\uF014',
  'ᩅ᩠ᨯ': 'วั\uF014',
  'ᩅᩢ᩠ᨯ': 'วั\uF014',
  'วัดมหาวัน': 'วั\uF014มหาวั\uF019',
  'ᩅ᩠ᨯᨾᩉᩣᩅ᩠ᨶ': 'วั\uF014มหาวั\uF019',
  'วัดพระสิงห์': 'วั\uF014พรฯะสิงห์',
  'วัดพระสิงห์วรมหาวิหาร': 'วั\uF014พรฯะสิงห์วรมหาวิหาร',
  'ประตู': 'ปตู',
  'วัดเจดีย์หลวง': 'วั\uF014เจดีย์หลวง',
  'วัดพระธาตุดอยสุเทพ': 'วั\uF014พรฯะธาตุดอยสุเทพ',
  'ประตูท่าแพ': 'ปตูท่าแพ',
  'ประตูสวนดอก': 'ปตูสวนดอก',
  'ประตูเชียงใหม่': 'ปตูเจียงใหม่',
  'ช้างเผือก': 'จ๊างเผือก',
  'ประตูช้างเผือก': 'ปตูจ๊างเผือก',
  'พระ': 'พรฯะ',
  'พระพุทธ': 'พรฯะพุทธ',
  'พระเจ้า': 'พรฯะเจ้า'
};

const reverseCharMap = {
  'ᨠ': 'ก', 'ᨡ': 'ข', 'ᨢ': 'ฃ', 'ᨣ': 'ค', 'ᨤ': 'ฅ', 'ᨥ': 'ฆ', 'ᨦ': 'ง',
  'ᨧ': 'จ', 'ᨨ': 'ฉ', 'ᨩ': 'ช', 'ᨪ': 'ซ', 'ᨫ': 'ฌ', 'ᨬ': 'ญ',
  'ᨭ': 'ฏ', 'ᨮ': 'ฐ', 'ᨯ': 'ด', 'ᨰ': 'ฒ', 'ᨱ': 'ณ',
  'ᨲ': 'ต', 'ᨳ': 'ถ', 'ᨴ': 'ท', 'ᨵ': 'ธ', 'ᨶ': 'น',
  'ᨷ': 'บ', 'ᨸ': 'ป', 'ᨹ': 'ผ', 'ᨺ': 'ฝ', 'ᨻ': 'พ', 'ᨼ': 'ฟ', 'ᨽ': 'ภ', 'ᨾ': 'ม',
  'ᨿ': 'ย', 'ᩁ': 'ร', 'ᩃ': 'ล', 'ᩅ': 'ว', 'ᩆ': 'ศ', 'ᩇ': 'ษ', 'ᩈ': 'ส', 'ᩉ': 'ห',
  'ᩋ': 'อ', 'ᩌ': 'ฮ',
  'ᩣ': 'า', 'ᩤ': 'า', 'ᩥ': 'ิ', 'ᩦ': 'ี', 'ᩧ': 'ึ', 'ᩨ': 'ื', 'ᩩ': 'ุ', 'ᩪ': 'ู',
  'ᩮ': 'เ', 'ᩯ': 'แ', 'ᩰ': 'โ', 'ᩱ': 'ไ', 'ᩲ': 'ใ',
  'ᩢ': 'ั', 'ᩫ': 'ะ', 'ᩬ': 'อ',
  '᩵': '่', '᩶': '้', '᩷': '๊', '᩸': '๋', '᩺': '์',
  '᪀': '๐', '᪁': '๑', '᪂': '๒', '᪃': '๓', '᪄': '๔', '᪅': '๕', '᪆': '๖', '᪇': '๗', '᪈': '๘', '᪉': '๙'
};

export function toTilokFontString(text) {
  if (!text) return "";
  let trimmed = String(text).trim();
  
  if (tilokDirectMap[trimmed]) {
    return tilokDirectMap[trimmed];
  }
  
  for (const [key, value] of Object.entries(tilokDirectMap)) {
    if (trimmed.includes(key)) {
      trimmed = trimmed.split(key).join(value);
    }
  }

  if (trimmed.includes('วัด')) trimmed = trimmed.split('วัด').join('วั\uF014');
  if (trimmed.includes('พระ')) trimmed = trimmed.split('พระ').join('พรฯะ');
  if (trimmed.includes('ประตู')) trimmed = trimmed.split('ประตู').join('ปตู');

  if (/^[\u0E00-\u0E7F\s\u00AA\u00AC\u00AD\uF007\uF014\uF019\uF01A\uF021\uF022\uF023\uF024\uF027\uF04C\uF079\uF0A3\uF0B0\uF0E1\uF0E2\uF0E3\uF0E4\uF0E7\uF0E8\uF0E9]+$/.test(trimmed)) {
    return trimmed.replace(/\u0E3A/g, '');
  }

  let buffer = '';
  const runes = Array.from(trimmed);
  for (let i = 0; i < runes.length; i++) {
    const char = runes[i];
    if (char === '\u1A60' && i + 1 < runes.length && runes[i + 1] === 'ᨯ') {
      buffer += '\uF014';
      i++;
    } else if (reverseCharMap[char]) {
      buffer += reverseCharMap[char];
    } else if (char === '\u1A60') {
      // ignore other sakot
    } else {
      buffer += char;
    }
  }

  let result = buffer.replace(/\u0E3A/g, '');
  if (result.includes('วัด')) result = result.split('วัด').join('วั\uF014');
  return result;
}

export async function loadLannaMap() {
  return tilokDirectMap;
}

export function convertThaiToLanna(text) {
  return toTilokFontString(text);
}

export function thaiToLanna(text) {
  return toTilokFontString(text);
}
