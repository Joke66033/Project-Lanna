/**
 * recentActivity.js
 * Tracks recently added / edited records in localStorage
 * and places them at Rank 1 (ลำดับที่ 1) at the top of the table.
 */

export function getItemId(item, type = "", idField = "") {
  if (!item) return "";

  // 1. If an explicit idField is provided and exists directly in item
  if (idField && item[idField] !== undefined && item[idField] !== null && String(item[idField]).trim() !== "") {
    return String(item[idField]).trim();
  }

  // 2. Resolve primary key strictly by table type (Avoid mixing foreign keys!)
  const normType = String(type || "").toLowerCase().trim();

  if (normType === "vocabulary" || normType === "vocab") {
    if (item.vocab_id !== undefined && item.vocab_id !== null) return String(item.vocab_id).trim();
  } else if (normType === "lanna_char" || normType === "alphabet" || normType === "char") {
    if (item.char_id !== undefined && item.char_id !== null) return String(item.char_id).trim();
  } else if (normType === "character_strokes" || normType === "strokes") {
    if (item.stroke_id !== undefined && item.stroke_id !== null) return String(item.stroke_id).trim();
  } else if (normType === "articles" || normType === "article") {
    if (item.article_id !== undefined && item.article_id !== null) return String(item.article_id).trim();
  } else if (normType === "category_vocab") {
    if (item.category_vocab_id !== undefined && item.category_vocab_id !== null) return String(item.category_vocab_id).trim();
  } else if (normType === "category_lanna_char") {
    if (item.category_char_id !== undefined && item.category_char_id !== null) return String(item.category_char_id).trim();
  } else if (normType === "learning_category") {
    if (item.category_code !== undefined && item.category_code !== null) return String(item.category_code).trim();
  } else if (normType === "users" || normType === "user") {
    if (item.user_id !== undefined && item.user_id !== null) return String(item.user_id).trim();
  }

  // 3. Fallback: item.id
  if (item.id !== undefined && item.id !== null && String(item.id).trim() !== "") {
    return String(item.id).trim();
  }

  // 4. Default priority if type was not specified
  if (item.vocab_id) return String(item.vocab_id).trim();
  if (item.char_id) return String(item.char_id).trim();
  if (item.stroke_id) return String(item.stroke_id).trim();
  if (item.article_id) return String(item.article_id).trim();
  if (item.user_id) return String(item.user_id).trim();
  if (item.category_vocab_id) return String(item.category_vocab_id).trim();
  if (item.category_char_id) return String(item.category_char_id).trim();
  if (item.category_code) return String(item.category_code).trim();

  return "";
}

export function trackRecentActivity(type, id) {
  try {
    if (id === undefined || id === null || String(id).trim() === "") return;
    const strId = String(id).trim();
    const key = `recent_${type}`;
    const existing = JSON.parse(localStorage.getItem(key) || "[]").map((x) => String(x).trim());
    const updated = [strId, ...existing.filter((item) => item.toLowerCase() !== strId.toLowerCase())].slice(0, 50);
    localStorage.setItem(key, JSON.stringify(updated));
  } catch (e) {
    // Ignore storage errors
  }
}

export function getRecentRank(item, type, idField, recentIds) {
  if (!item || !recentIds || recentIds.length === 0) return -1;
  const targetId = getItemId(item, type, idField);
  if (!targetId) return -1;

  const targetLower = targetId.toLowerCase();

  for (let i = 0; i < recentIds.length; i++) {
    const r = recentIds[i];
    if (!r) continue;
    const rLower = r.toLowerCase();

    // 1. Direct match or case-insensitive match (e.g. "V00025" === "v00025")
    if (targetLower === rLower) return i;

    // 2. Strict prefix + numeric match (e.g. "V00025" and "V25")
    const prefixTarget = targetLower.replace(/\d+.*$/, "");
    const prefixR = rLower.replace(/\d+.*$/, "");
    if (prefixTarget === prefixR) {
      const matchTarget = targetLower.match(/\d+/);
      const matchR = rLower.match(/\d+/);
      if (matchTarget && matchR && parseInt(matchTarget[0], 10) === parseInt(matchR[0], 10)) {
        return i;
      }
    }
  }

  return -1;
}

export function sortRecentData(dataList, type, idField = "id") {
  try {
    if (!Array.isArray(dataList)) return dataList;
    const key = `recent_${type}`;
    const recentIds = JSON.parse(localStorage.getItem(key) || "[]").map((x) => String(x).trim());

    const parseNumId = (item, field) => {
      const idStr = getItemId(item, type, field);
      const match = String(idStr).match(/\d+/);
      return match ? parseInt(match[0], 10) : 0;
    };

    return [...dataList].sort((a, b) => {
      const rankA = getRecentRank(a, type, idField, recentIds);
      const rankB = getRecentRank(b, type, idField, recentIds);

      // 1. อันดับแรก: รายการที่เพิ่งกดเพิ่มหรือแก้ไขในหน้าผู้ดูแล (Recent Action) -> ลำดับที่ 1 ล่าสุดเสมอ
      if (rankA !== -1 && rankB !== -1) {
        return rankA - rankB;
      }
      if (rankA !== -1) return -1;
      if (rankB !== -1) return 1;

      // 2. สำหรับ character_strokes: เรียงลำดับตัวเลข ID ตามลำดับอักขระธรรมชาติ (S00001, S00002... ก, ข, ค, ฆ, ง)
      if (type === "character_strokes") {
        const numA = parseNumId(a, idField);
        const numB = parseNumId(b, idField);
        if (numA !== numB) {
          return numA - numB;
        }
        return 0;
      }

      // 3. เรียงตามเวลาที่มีการอัปเดตหรือสร้างล่าสุด (updated_at / created_at / timestamp)
      const parseTime = (item) => {
        const val = item?.updated_at || item?.created_at || item?.timestamp;
        if (!val) return 0;
        const t = new Date(val).getTime();
        return isNaN(t) ? 0 : t;
      };

      const timeA = parseTime(a);
      const timeB = parseTime(b);
      if (timeA > 0 && timeB > 0 && timeA !== timeB) {
        return timeB - timeA;
      }

      // 4. ลำดับ fallback: ID ล่าสุดลงมา (descending)
      const numA = parseNumId(a, idField);
      const numB = parseNumId(b, idField);
      if (numA !== numB) {
        return numB - numA;
      }

      return 0;
    });
  } catch (e) {
    return dataList;
  }
}

export function removeRecentActivity(type, id) {
  try {
    if (id === undefined || id === null || String(id).trim() === "") return;
    const strId = String(id).trim();
    const key = `recent_${type}`;
    const existing = JSON.parse(localStorage.getItem(key) || "[]").map((x) => String(x).trim());
    const updated = existing.filter((item) => item.toLowerCase() !== strId.toLowerCase());
    localStorage.setItem(key, JSON.stringify(updated));
  } catch (e) {
    // Ignore storage errors
  }
}
