/**
 * recentActivity.js
 * Tracks recently added / edited records in localStorage
 * and places them at Rank 1 (ลำดับที่ 1) at the top of the table.
 * Default database items remain sorted in natural ascending (ASC) order (จากน้อยไปมาก).
 */

export function getItemPrimaryIds(item, type = "", idField = "") {
  if (!item) return [];
  const set = new Set();

  if (idField && item[idField] !== undefined && item[idField] !== null) {
    const val = String(item[idField]).trim();
    if (val) set.add(val);
  }

  const normType = String(type || "").toLowerCase().trim();

  if (normType === "vocabulary" || normType === "vocab") {
    if (item.vocab_id) set.add(String(item.vocab_id).trim());
  } else if (normType === "lanna_char" || normType === "alphabet" || normType === "char") {
    if (item.char_id) set.add(String(item.char_id).trim());
  } else if (normType === "character_strokes" || normType === "strokes") {
    if (item.stroke_id) set.add(String(item.stroke_id).trim());
  } else if (normType === "articles" || normType === "article") {
    if (item.article_id) set.add(String(item.article_id).trim());
  } else if (normType === "category_vocab") {
    if (item.category_vocab_id) set.add(String(item.category_vocab_id).trim());
  } else if (normType === "category_lanna_char") {
    if (item.category_char_id) set.add(String(item.category_char_id).trim());
  } else if (normType === "learning_category") {
    if (item.category_code) set.add(String(item.category_code).trim());
  } else if (normType === "users" || normType === "user") {
    if (item.user_id) set.add(String(item.user_id).trim());
  }

  if (item.id !== undefined && item.id !== null) {
    const val = String(item.id).trim();
    if (val) set.add(val);
  }

  return Array.from(set);
}

export function getItemId(item, type = "", idField = "") {
  const ids = getItemPrimaryIds(item, type, idField);
  return ids.length > 0 ? ids[0] : "";
}

export function trackRecentActivity(type, id) {
  try {
    if (id === undefined || id === null || String(id).trim() === "") return;
    const strId = String(id).trim();
    const key = `recent_${type}`;
    const existing = JSON.parse(localStorage.getItem(key) || "[]").map((x) => String(x).trim());

    const strNum = strId.match(/\d+/) ? parseInt(strId.match(/\d+/)[0], 10) : null;
    const filtered = existing.filter((item) => {
      if (item.toLowerCase() === strId.toLowerCase()) return false;
      const itemNum = item.match(/\d+/) ? parseInt(item.match(/\d+/)[0], 10) : null;
      if (strNum !== null && itemNum !== null && strNum === itemNum) return false;
      return true;
    });

    const updated = [strId, ...filtered].slice(0, 50);
    localStorage.setItem(key, JSON.stringify(updated));
  } catch (e) {
    // Ignore storage errors
  }
}

export function getRecentRank(item, type, idField, recentIds) {
  if (!item || !recentIds || recentIds.length === 0) return -1;
  const ids = getItemPrimaryIds(item, type, idField);
  if (ids.length === 0) return -1;

  const idsLower = ids.map((x) => x.toLowerCase());
  const idsNums = ids
    .map((x) => {
      const m = x.match(/\d+/);
      return m ? parseInt(m[0], 10) : null;
    })
    .filter((n) => n !== null);

  for (let i = 0; i < recentIds.length; i++) {
    const r = recentIds[i];
    if (!r) continue;
    const rLower = r.toLowerCase();
    const rMatch = r.match(/\d+/);
    const rNum = rMatch ? parseInt(rMatch[0], 10) : null;

    // 1. Direct or case-insensitive string match
    if (ids.includes(r) || idsLower.includes(rLower)) return i;

    // 2. Numeric match (e.g. "V00018" and 18 or "18")
    if (rNum !== null && idsNums.includes(rNum)) return i;
  }

  return -1;
}

export function sortRecentData(dataList, type, idField = "id") {
  try {
    if (!Array.isArray(dataList)) return dataList;
    const key = `recent_${type}`;
    const recentIds = JSON.parse(localStorage.getItem(key) || "[]").map((x) => String(x).trim());

    const parseNumId = (item, field) => {
      const ids = getItemPrimaryIds(item, type, field);
      for (const idStr of ids) {
        const match = String(idStr).match(/\d+/);
        if (match) return parseInt(match[0], 10);
      }
      return 0;
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

      // 2. ข้อมูลปกติในฐานข้อมูล: เรียงจากน้อยไปมากตาม ID (ASC) เช่น V00001 -> V00002 -> V00003
      const numA = parseNumId(a, idField);
      const numB = parseNumId(b, idField);
      if (numA !== numB) {
        return numA - numB;
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
    const strNum = strId.match(/\d+/) ? parseInt(strId.match(/\d+/)[0], 10) : null;
    const updated = existing.filter((item) => {
      if (item.toLowerCase() === strId.toLowerCase()) return false;
      const itemNum = item.match(/\d+/) ? parseInt(item.match(/\d+/)[0], 10) : null;
      if (strNum !== null && itemNum !== null && strNum === itemNum) return false;
      return true;
    });
    localStorage.setItem(key, JSON.stringify(updated));
  } catch (e) {
    // Ignore storage errors
  }
}
