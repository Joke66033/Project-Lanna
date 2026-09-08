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

export function isIdMatch(idA, idB) {
  if (idA === undefined || idA === null || idB === undefined || idB === null) return false;
  const sA = String(idA).trim();
  const sB = String(idB).trim();
  if (sA === "" || sB === "") return false;
  if (sA.toLowerCase() === sB.toLowerCase()) return true;

  // Only consider numeric match if at least one side is a pure number (no alphabetic prefix)
  const isPureNumA = /^\d+$/.test(sA);
  const isPureNumB = /^\d+$/.test(sB);
  if (isPureNumA || isPureNumB) {
    const numA = parseInt(sA.replace(/\D/g, ""), 10);
    const numB = parseInt(sB.replace(/\D/g, ""), 10);
    if (!isNaN(numA) && !isNaN(numB) && numA === numB) {
      return true;
    }
  }
  return false;
}

export function trackRecentActivity(type, id) {
  try {
    if (id === undefined || id === null || String(id).trim() === "") return;
    const strId = String(id).trim();
    const key = `recent_${type}`;
    const existing = JSON.parse(localStorage.getItem(key) || "[]").map((x) => String(x).trim());

    const filtered = existing.filter((item) => !isIdMatch(item, strId));
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

  for (let i = 0; i < recentIds.length; i++) {
    const r = recentIds[i];
    if (!r) continue;
    if (ids.some((id) => isIdMatch(id, r))) {
      return i;
    }
  }

  return -1;
}

export function sortRecentData(dataList, type, idField = "id") {
  try {
    if (!Array.isArray(dataList)) return dataList;
    const key = `recent_${type}`;
    const recentIds = JSON.parse(localStorage.getItem(key) || "[]").map((x) => String(x).trim());

    return [...dataList].sort((a, b) => {
      const rankA = getRecentRank(a, type, idField, recentIds);
      const rankB = getRecentRank(b, type, idField, recentIds);

      // 1. Recent action items go to Rank 1 (top of table)
      if (rankA !== -1 && rankB !== -1) {
        return rankA - rankB;
      }
      if (rankA !== -1) return -1;
      if (rankB !== -1) return 1;

      // 2. Default items: natural ascending (ASC) order (e.g. CS0001, CS0002... S00001, S00002... V00001, V00002...)
      const idA = getItemId(a, type, idField);
      const idB = getItemId(b, type, idField);
      if (idA && idB) {
        return idA.localeCompare(idB, undefined, { numeric: true, sensitivity: "base" });
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
    const updated = existing.filter((item) => !isIdMatch(item, strId));
    localStorage.setItem(key, JSON.stringify(updated));
  } catch (e) {
    // Ignore storage errors
  }
}
