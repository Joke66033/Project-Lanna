export const trackRecentActivity = (tableName, id) => {
  try {
    if (!id) return;
    const key = `recent_${tableName}`;
    const recent = JSON.parse(localStorage.getItem(key) || "{}");
    recent[id] = Date.now();
    localStorage.setItem(key, JSON.stringify(recent));
  } catch (e) {
    console.error("Failed to track recent activity:", e);
  }
};

export const sortRecentData = (data, tableName, idField) => {
  try {
    const key = `recent_${tableName}`;
    const recent = JSON.parse(localStorage.getItem(key) || "{}");
    return [...data].sort((a, b) => {
      const idA = a[idField];
      const idB = b[idField];
      const timeA = recent[idA] || 0;
      const timeB = recent[idB] || 0;
      if (timeA !== timeB) {
        return timeB - timeA; // Newest activity first
      }
      // Fallback to standard sorting (numeric or string ID descending)
      if (typeof idA === 'number' && typeof idB === 'number') {
        return idB - idA;
      }
      return String(idB).localeCompare(String(idA), undefined, { numeric: true });
    });
  } catch (e) {
    return data;
  }
};
