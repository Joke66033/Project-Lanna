export const categoryColors = {
  users: {
    seqBg: "bg-purple-100",
    seqText: "text-purple-600",
    seqBgHover: "hover:bg-purple-200",
    seqTextHover: "hover:text-purple-700",
    theadBg: "bg-purple-50",
    theadText: "text-purple-700",
    theadBorder: "border-purple-200",
    primaryBg: "bg-purple-600",
    primaryBgHover: "hover:bg-purple-700",
    ringFocus: "focus:ring-purple-500",
    borderCol: "border-purple-600",
  },
  categoryLearning: {
    seqBg: "bg-sky-100",
    seqText: "text-sky-600",
    seqBgHover: "hover:bg-sky-200",
    seqTextHover: "hover:text-sky-700",
    theadBg: "bg-sky-50",
    theadText: "text-sky-700",
    theadBorder: "border-sky-200",
    primaryBg: "bg-sky-600",
    primaryBgHover: "hover:bg-sky-700",
    ringFocus: "focus:ring-sky-500",
    borderCol: "border-sky-600",
  },
  articles: {
    seqBg: "bg-violet-100",
    seqText: "text-violet-600",
    seqBgHover: "hover:bg-violet-200",
    seqTextHover: "hover:text-violet-700",
    theadBg: "bg-violet-50",
    theadText: "text-violet-700",
    theadBorder: "border-violet-200",
    primaryBg: "bg-violet-600",
    primaryBgHover: "hover:bg-violet-700",
    ringFocus: "focus:ring-violet-500",
    borderCol: "border-violet-600",
  },
  alphabet: {
    seqBg: "bg-emerald-100",
    seqText: "text-emerald-600",
    seqBgHover: "hover:bg-emerald-200",
    seqTextHover: "hover:text-emerald-700",
    theadBg: "bg-emerald-50",
    theadText: "text-emerald-700",
    theadBorder: "border-emerald-200",
    primaryBg: "bg-emerald-600",
    primaryBgHover: "hover:bg-emerald-700",
    ringFocus: "focus:ring-emerald-500",
    borderCol: "border-emerald-600",
  },
};

export function getCategoryBadgeStyle(category) {
  const text = String(category || "");
  if (!text || text === "—" || text === "ทั่วไป") {
    return { bg: "#f1f5f9", text: "#475569", border: "#cbd5e1", dot: "#64748b" };
  }
  let hash = 0;
  for (let i = 0; i < text.length; i++) {
    hash = text.charCodeAt(i) + ((hash << 5) - hash);
  }
  const hue = Math.abs(hash) % 360;
  return {
    bg: `hsl(${hue}, 85%, 96%)`,
    text: `hsl(${hue}, 75%, 35%)`,
    border: `hsl(${hue}, 70%, 82%)`,
    dot: `hsl(${hue}, 80%, 45%)`,
  };
}
