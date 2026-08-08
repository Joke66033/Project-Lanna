export function trackRecentActivity(type, id) {
  try {
    if (id === undefined || id === null || id === "") return;
    const strId = String(id);
    const key = `recent_${type}`;
    const existing = JSON.parse(localStorage.getItem(key) || "[]").map(String);
    const updated = [strId, ...existing.filter((item) => item !== strId)].slice(0, 50);
    localStorage.setItem(key, JSON.stringify(updated));
  } catch (e) {
    // Ignore storage errors
  }
}

export function sortRecentData(dataList, type, idField = "id") {
  try {
    const key = `recent_${type}`;
    const recentIds = JSON.parse(localStorage.getItem(key) || "[]").map(String);
    if (!recentIds.length || !Array.isArray(dataList)) return dataList;

    const recentSet = new Set(recentIds);
    const recentItems = [];
    const otherItems = [];

    dataList.forEach((item) => {
      const rawId = item[idField] !== undefined ? item[idField] : (item.id !== undefined ? item.id : (item.char_id || item.user_id || item.vocab_id || item.article_id || item.category_code || item.category_vocab_id || item.category_char_id || item.stroke_id));
      const itemId = String(rawId);
      if (recentSet.has(itemId)) {
        recentItems.push(item);
      } else {
        otherItems.push(item);
      }
    });

    recentItems.sort((a, b) => {
      const rawA = a[idField] !== undefined ? a[idField] : (a.id !== undefined ? a.id : (a.char_id || a.user_id || a.vocab_id || a.article_id || a.category_code || a.category_vocab_id || a.category_char_id || a.stroke_id));
      const rawB = b[idField] !== undefined ? b[idField] : (b.id !== undefined ? b.id : (b.char_id || b.user_id || b.vocab_id || b.article_id || b.category_code || b.category_vocab_id || b.category_char_id || b.stroke_id));
      return recentIds.indexOf(String(rawA)) - recentIds.indexOf(String(rawB));
    });

    return [...recentItems, ...otherItems];
  } catch (e) {
    return dataList;
  }
}
