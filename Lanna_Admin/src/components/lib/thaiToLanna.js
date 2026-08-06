import { supabase } from './supabaseClient.js';

let lannaMapCache = null;

/**
 * ดึงแผนที่การจับคู่ตัวอักษรไทยกับล้านนาจาก Supabase ตาราง lanna_char
 * @returns {Promise<Array<{thai: string, lanna: string}>>} รายการแม็ปปิ้งเรียงตามความยาวคำไทยจากยาวไปสั้น
 */
export async function loadLannaMap() {
  if (lannaMapCache) return lannaMapCache;

  try {
    const { data, error } = await supabase
      .from('lanna_char')
      .select('lanna_char, thai_equivalent');

    if (error) throw error;

    const mapping = (data || [])
      .map(item => {
        const thaiRaw = item.thai_equivalent || '';
        // สกัดตัวอักษรไทยส่วนแรกก่อนวงเล็บ เช่น "ก (ก๋ะ)" -> "ก"
        const match = thaiRaw.match(/^([^\s(]+)/);
        const thai = match ? match[1].trim() : thaiRaw.trim();
        return {
          thai,
          lanna: item.lanna_char || ''
        };
      })
      .filter(item => item.thai && item.lanna)
      // เรียงลำดับจากความยาวอักษรไทยมากไปน้อย (Greedy Match)
      .sort((a, b) => b.thai.length - a.thai.length);

    lannaMapCache = mapping;
    return lannaMapCache;
  } catch (err) {
    console.error("Failed to load Lanna character mapping:", err);
    return [];
  }
}

/**
 * แปลงตัวอักษรไทยเป็นอักษรล้านนายูนิโค้ดแท้ (Greedy Match)
 * @param {string} thaiText - ข้อความไทยที่ต้องการแปลง
 * @param {Array<{thai: string, lanna: string}>} mapping - แผนที่การแปล
 * @returns {string} ข้อความที่แปลงเป็นอักษรล้านนาแล้ว (ตัวอักษรที่ไม่พบในแผนที่จะคงเดิมไว้)
 */
export function convertThaiToLanna(thaiText, mapping) {
  if (!thaiText) return '';
  if (!mapping || mapping.length === 0) return thaiText;

  let result = '';
  let i = 0;

  while (i < thaiText.length) {
    let matched = false;

    for (const item of mapping) {
      if (thaiText.startsWith(item.thai, i)) {
        result += item.lanna;
        i += item.thai.length;
        matched = true;
        break;
      }
    }

    if (!matched) {
      result += thaiText[i];
      i++;
    }
  }

  return result;
}
