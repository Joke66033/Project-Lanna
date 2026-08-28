export function getItemId(item, idField) {
  if (!item) return "";
  if (idField && item[idField] !== undefined && item[idField] !== null && String(item[idField]).trim() !== "") {
    return String(item[idField]).trim();
  }
  // Record Primary Keys first (specific entity IDs)
  if (item.char_id) return String(item.char_id).trim();
  if (item.vocab_id) return String(item.vocab_id).trim();
  if (item.article_id) return String(item.article_id).trim();
  if (item.stroke_id) return String(item.stroke_id).trim();
  if (item.user_id) return String(item.user_id).trim();

  // Category Primary Keys (for category management tables)
  if (item.category_vocab_id) return String(item.category_vocab_id).trim();
  if (item.category_char_id) return String(item.category_char_id).trim();
  if (item.category_code) return String(item.category_code).trim();
  if (item.id !== undefined && item.id !== null && String(item.id).trim() !== "") return String(item.id).trim();
  return "";
}

export function trackRecentActivity(type, id) {
  try {
    if (id === undefined || id === null || String(id).trim() === "") return;
    const strId = String(id).trim();
    const key = `recent_${type}`;
    const existing = JSON.parse(localStorage.getItem(key) || "[]").map((x) => String(x).trim());
    const updated = [strId, ...existing.filter((item) => item !== strId)].slice(0, 50);
    localStorage.setItem(key, JSON.stringify(updated));
  } catch (e) {
    // Ignore storage errors
  }
}

export function sortRecentData(dataList, type, idField = "id") {
  try {
    if (!Array.isArray(dataList)) return dataList;
    const key = `recent_${type}`;
    const recentIds = JSON.parse(localStorage.getItem(key) || "[]").map((x) => String(x).trim());
    const recentSet = new Set(recentIds);

    const parseTime = (item) => {
      const val = item?.updated_at || item?.created_at || item?.timestamp;
      if (!val) return 0;
      const t = new Date(val).getTime();
      return isNaN(t) ? 0 : t;
    };

    const parseNumId = (item, field) => {
      const idStr = getItemId(item, field);
      const match = String(idStr).match(/\d+/);
      return match ? parseInt(match[0], 10) : 0;
    };

    return [...dataList].sort((a, b) => {
      const idA = getItemId(a, idField);
      const idB = getItemId(b, idField);
      const isRecentA = Boolean(idA && recentSet.has(idA));
      const isRecentB = Boolean(idB && recentSet.has(idB));

      // 1. อันดับแรก: รายการที่เพิ่งกดเพิ่มหรือแก้ไขในหน้าผู้ดูแล (Recent Action)
      if (isRecentA && isRecentB) {
        return recentIds.indexOf(idA) - recentIds.indexOf(idB);
      }
      if (isRecentA) return -1;
      if (isRecentB) return 1;

      // 2. อันดับสอง: เรียงตามเวลาที่มีการอัปเดต/เพิ่มล่าสุด (updated_at / created_at DESC)
      const timeA = parseTime(a);
      const timeB = parseTime(b);
      if (timeA > 0 && timeB > 0 && timeA !== timeB) {
        return timeB - timeA;
      }

      // 3. อันดับสาม: เรียงตามลำดับตัวเลขของไอดีจากมากไปน้อย (เช่น AR0012, AR0011 ... AR0001)
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
