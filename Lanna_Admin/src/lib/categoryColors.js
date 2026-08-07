export const categoryColors = {
  dashboard: {
    sidebarActive: "bg-orange-50 text-orange-700 border-l-4 border-orange-600",
    sidebarNormal: "text-gray-600 hover:bg-gray-50 hover:text-gray-900",
    seqBg: "bg-orange-100",
    seqText: "text-orange-600",
    seqBgHover: "hover:bg-orange-200",
    seqTextHover: "hover:text-orange-700",
    theadBg: "bg-orange-50",
    theadText: "text-orange-700",
    theadBorder: "border-orange-200",
    primaryBg: "bg-orange-600",
    primaryBgHover: "hover:bg-orange-700",
    ringFocus: "focus:ring-orange-500",
    borderCol: "border-orange-600",
  },
  vocabulary: {
    sidebarActive: "bg-amber-50 text-amber-900 border-l-4 border-amber-800",
    sidebarNormal: "text-gray-600 hover:bg-gray-50 hover:text-gray-900",
    seqBg: "bg-amber-100",
    seqText: "text-amber-600",
    seqBgHover: "hover:bg-amber-200",
    seqTextHover: "hover:text-amber-700",
    theadBg: "bg-amber-50",
    theadText: "text-amber-900",
    theadBorder: "border-amber-200",
    primaryBg: "bg-amber-600",
    primaryBgHover: "hover:bg-amber-700",
    ringFocus: "focus:ring-amber-500",
    borderCol: "border-amber-600",
  },
  alphabet: {
    sidebarActive: "bg-[#F7FBEA] text-[#3F6212] border-l-4 border-[#4D7C0F]",
    sidebarNormal: "text-gray-600 hover:bg-gray-50 hover:text-gray-900",
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
  categoryVocab: {
    sidebarActive: "bg-[#F0FDFA] text-[#115E59] border-l-4 border-[#0F766E]",
    sidebarNormal: "text-gray-600 hover:bg-gray-50 hover:text-gray-900",
    seqBg: "bg-teal-100",
    seqText: "text-teal-600",
    seqBgHover: "hover:bg-teal-200",
    seqTextHover: "hover:text-teal-700",
    theadBg: "bg-teal-50",
    theadText: "text-teal-700",
    theadBorder: "border-teal-200",
    primaryBg: "bg-teal-600",
    primaryBgHover: "hover:bg-teal-700",
    ringFocus: "focus:ring-teal-500",
    borderCol: "border-teal-600",
  },
  categoryAlphabet: {
    sidebarActive: "bg-sky-50 text-sky-700 border-l-4 border-sky-600",
    sidebarNormal: "text-gray-600 hover:bg-gray-50 hover:text-gray-900",
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
  categoryLearning: {
    sidebarActive: "bg-sky-50 text-sky-700 border-l-4 border-sky-600",
    sidebarNormal: "text-gray-600 hover:bg-gray-50 hover:text-gray-900",
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
    sidebarActive: "bg-violet-50 text-violet-700 border-l-4 border-violet-600",
    sidebarNormal: "text-gray-600 hover:bg-gray-50 hover:text-gray-900",
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
  users: {
    sidebarActive: "bg-purple-50 text-purple-700 border-l-4 border-purple-600",
    sidebarNormal: "text-gray-600 hover:bg-gray-50 hover:text-gray-900",
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

export function getCategoryStyle(category) {
  return getCategoryBadgeStyle(category);
}
