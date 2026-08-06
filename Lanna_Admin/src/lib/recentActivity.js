export function trackRecentActivity(type, id) {
  try {
    const key = `recent_${type}`;
    const existing = JSON.parse(localStorage.getItem(key) || "[]");
    const updated = [id, ...existing.filter((item) => item !== id)].slice(0, 20);
    localStorage.setItem(key, JSON.stringify(updated));
  } catch (e) {
    // Ignore storage errors
  }
}

export function sortRecentData(dataList, type, idField = "id") {
  try {
    const key = `recent_${type}`;
    const recentIds = JSON.parse(localStorage.getItem(key) || "[]");
    if (!recentIds.length) return dataList;

    const recentSet = new Set(recentIds);
    const recentItems = [];
    const otherItems = [];

    dataList.forEach((item) => {
      const itemId = item[idField] || item.id;
      if (recentSet.has(itemId)) {
        recentItems.push(item);
      } else {
        otherItems.push(item);
      }
    });

    recentItems.sort((a, b) => {
      const idA = a[idField] || a.id;
      const idB = b[idField] || b.id;
      return recentIds.indexOf(idA) - recentIds.indexOf(idB);
    });

    return [...recentItems, ...otherItems];
  } catch (e) {
    return dataList;
  }
}
