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
    const key = `recent_${type}`;
    const recentIds = JSON.parse(localStorage.getItem(key) || "[]").map((x) => String(x).trim());
    if (!recentIds.length || !Array.isArray(dataList)) return dataList;

    const recentSet = new Set(recentIds);
    const recentItems = [];
    const otherItems = [];

    dataList.forEach((item) => {
      const itemId = getItemId(item, idField);
      if (itemId && recentSet.has(itemId)) {
        recentItems.push(item);
      } else {
        otherItems.push(item);
      }
    });

    recentItems.sort((a, b) => {
      const idA = getItemId(a, idField);
      const idB = getItemId(b, idField);
      return recentIds.indexOf(idA) - recentIds.indexOf(idB);
    });

    return [...recentItems, ...otherItems];
  } catch (e) {
    return dataList;
  }
}
