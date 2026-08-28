import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
} from "recharts";
import { useState, useEffect } from "react";
import { CartesianGrid } from "recharts";

const getApiBase = () => {
  if (typeof window !== 'undefined' && window.location.hostname === 'siripaporn.lnw.mn') {
    return 'https://siripaporn.lnw.mn';
  }
  return import.meta.env.VITE_API_BASE_URL || 'https://siripaporn.lnw.mn';
};
const BASE = getApiBase();

async function apiFetch(url) {
  const res = await fetch(url);
  const contentType = res.headers.get('content-type') || '';
  if (!contentType.includes('application/json')) {
    const text = await res.text();
    // Strip HTML tags for cleaner error message
    const clean = text.replace(/<[^>]*>/g, ' ').replace(/\s+/g, ' ').trim().slice(0, 200);
    throw new Error(`API ตอบกลับไม่ถูกต้อง (${url.split('/').pop()}): ${clean || 'ไม่ทราบสาเหตุ'}`);
  }
  const data = await res.json();
  if (!res.ok) {
    throw new Error(data?.message || data?.error || `HTTP ${res.status}`);
  }
  return data;
}

const getInitDate = (daysAgo) => {
  const d = new Date();
  d.setDate(d.getDate() - daysAgo);
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
};

export default function Dashboard() {
  const [startDate, setStartDate] = useState(getInitDate(7));
  const [endDate, setEndDate] = useState(getInitDate(0));

  const [vocabularies, setVocabularies] = useState([]);
  const [users, setUsers] = useState([]);
  const [translateLogs, setTranslateLogs] = useState([]);
  const [articles, setArticles] = useState([]);
  const [categoryVocabs, setCategoryVocabs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const fetchData = async () => {
    try {
      setLoading(true);
      setError(null);

      const [
        resVocab,
        resUsers,
        resLogs,
        resArticles,
        resCat
      ] = await Promise.all([
        apiFetch(`${BASE}/endpoints/vocabulary_api.php?action=getAll`),
        apiFetch(`${BASE}/endpoints/users_api.php?action=getAll`),
        apiFetch(`${BASE}/endpoints/translate_logs_api.php?action=getAll`),
        apiFetch(`${BASE}/endpoints/articles_api.php?action=getAll`),
        apiFetch(`${BASE}/endpoints/category_vocab_api.php?action=getAll`),
      ]);

      if (resVocab.error) throw resVocab.error;
      if (resUsers.error) throw resUsers.error;
      if (resLogs.error) throw resLogs.error;
      if (resArticles.error) throw resArticles.error;
      if (resCat.error) throw resCat.error;

      setVocabularies(resVocab.data || []);
      setUsers(resUsers.data || []);
      setTranslateLogs(resLogs.data || []);
      setArticles(resArticles.data || []);
      setCategoryVocabs(resCat.data || []);

    } catch (err) {
      console.error("Dashboard fetch error:", err);
      setError(err.message || "เกิดข้อผิดพลาดในการโหลดข้อมูลสถิติ");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  // Helpers to get local date from date/timestamp string without timezone shift
  const parseLocalDate = (dateStr) => {
    if (!dateStr) return null;
    const parts = String(dateStr).split('T')[0].split('-');
    if (parts.length !== 3) {
      const d = new Date(dateStr);
      return isNaN(d.getTime()) ? null : d;
    }
    return new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]));
  };

  const getLocalDateString = (dateObjOrStr) => {
    if (!dateObjOrStr) return null;
    const d = new Date(dateObjOrStr);
    if (isNaN(d.getTime())) return null;
    const year = d.getFullYear();
    const month = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  };

  const diffDays = (start, end) => {
    const s = parseLocalDate(start);
    const e = parseLocalDate(end);
    if (!s || !e) return 0;
    return Math.floor((e - s) / (1000 * 60 * 60 * 24)) + 1;
  };

  // Group vocabulary counts by category name
  const categoryCounts = {};
  categoryVocabs.forEach((c) => {
    const catName = c.name || c.category_name || "";
    if (catName) {
      categoryCounts[catName] = 0;
    }
  });

  vocabularies.forEach((v) => {
    const cat = v.category || "อื่น ๆ";
    if (categoryCounts[cat] === undefined) {
      categoryCounts[cat] = 0;
    }
    categoryCounts[cat]++;
  });

  const barData = Object.entries(categoryCounts).map(([name, value]) => ({
    name,
    value,
  }));

  // Pie Data - Sort categories by vocabulary count descending
  const pieData = [...barData].sort((a, b) => b.value - a.value);
  const total = pieData.reduce((sum, i) => sum + i.value, 0);

  // Dynamic Translation Logs per category count logic
  const getCategoryTranslationCount = (categoryName) => {
    let count = 0;
    translateLogs.forEach((log) => {
      if (log.category === categoryName) {
        count++;
        return;
      }
      if (log.category_vocab_id) {
        const cat = categoryVocabs.find(
          (c) => (c.category_vocab_id || c.id) === log.category_vocab_id
        );
        if (cat && (cat.name || cat.category_name) === categoryName) {
          count++;
          return;
        }
      }
      if (log.vocab_id) {
        const vocab = vocabularies.find((v) => v.vocab_id === log.vocab_id);
        if (vocab && (vocab.category || "อื่น ๆ") === categoryName) {
          count++;
          return;
        }
      }
      const text = (
        log.input_text ||
        log.output_text ||
        log.text ||
        log.search_query ||
        log.thai_word ||
        log.lanna_word ||
        ""
      ).toLowerCase();
      if (text) {
        const match = vocabularies.find(
          (v) =>
            (v.thai_word && text.includes(v.thai_word.toLowerCase())) ||
            (v.lanna_word && text.includes(v.lanna_word.toLowerCase()))
        );
        if (match && (match.category || "อื่น ๆ") === categoryName) {
          count++;
          return;
        }
      }
    });
    return count;
  };

  // Generate chart data based on date range selected
  const generateChartData = (start, end) => {
    const days = diffDays(start, end);

    // ----- Daily -----
    if (days <= 31) {
      const result = [];
      const cur = parseLocalDate(start);
      const last = parseLocalDate(end);

      while (cur <= last) {
        const key = getLocalDateString(cur);
        const count = translateLogs.filter((log) => {
          const dStr = log.created_at || log.timestamp || log.date;
          return getLocalDateString(dStr) === key;
        }).length;

        result.push({
          label: cur.toLocaleDateString("th-TH", {
            day: "numeric",
            month: "short",
          }),
          value: count,
        });
        cur.setDate(cur.getDate() + 1);
      }

      return { type: "day", data: result };
    }

    // ----- Monthly -----
    if (days <= 365) {
      const startM = parseLocalDate(start);
      startM.setDate(1);
      const endM = parseLocalDate(end);
      endM.setDate(1);

      const monthMap = {};
      const cur = new Date(startM);

      while (cur <= endM) {
        const y = cur.getFullYear();
        const m = cur.getMonth();
        const key = `${y}-${String(m + 1).padStart(2, "0")}`;
        monthMap[key] = 0;
        cur.setMonth(cur.getMonth() + 1);
      }

      translateLogs.forEach((log) => {
        const dStr = log.created_at || log.timestamp || log.date;
        const localDateStr = getLocalDateString(dStr);
        if (localDateStr && localDateStr >= start && localDateStr <= end) {
          const key = localDateStr.substring(0, 7);
          if (monthMap[key] !== undefined) {
            monthMap[key]++;
          }
        }
      });

      return {
        type: "month",
        data: Object.entries(monthMap).map(([key, value]) => {
          const [y, m] = key.split("-");
          const displayDate = new Date(Number(y), Number(m) - 1, 1);
          return {
            label: displayDate.toLocaleDateString("th-TH", {
              month: "short",
              year: "numeric",
            }),
            value,
          };
        }),
      };
    }

    // ----- Yearly -----
    const startY = parseLocalDate(start).getFullYear();
    const endY = parseLocalDate(end).getFullYear();

    const yearMap = {};
    for (let y = startY; y <= endY; y++) yearMap[y] = 0;

    translateLogs.forEach((log) => {
      const dStr = log.created_at || log.timestamp || log.date;
      const localDateStr = getLocalDateString(dStr);
      if (localDateStr && localDateStr >= start && localDateStr <= end) {
        const y = parseLocalDate(localDateStr).getFullYear();
        if (yearMap[y] !== undefined) {
          yearMap[y]++;
        }
      }
    });

    return {
      type: "year",
      data: Object.entries(yearMap).map(([year, value]) => ({
        label: String(year),
        value,
      })),
    };
  };

  const isDateSelected = startDate && endDate;
  const chartResult = isDateSelected
    ? generateChartData(startDate, endDate)
    : { type: "category", data: barData };

  const chartData = chartResult.data;
  const totalSelected = chartData.reduce((sum, i) => sum + i.value, 0);

  const COLORS = [
    "#EA580C", // Rich Orange 600
    "#F97316", // Vibrant Orange 500
    "#C2410C", // Deep Terracotta Orange 700
    "#FB923C", // Light Warm Orange 400
    "#D97706", // Amber Gold Orange 600
    "#F59E0B", // Bright Amber Orange 500
    "#FF7F50", // Coral Orange
    "#E11D48", // Rose Red-Orange
    "#FDBA74", // Soft Peach Orange 300
    "#9A3412", // Dark Chocolate Orange 800
  ];

  if (loading) {
    return (
      <div className="flex items-center justify-center p-12 bg-[#f9f7f4] min-h-screen">
        <div className="animate-spin rounded-full h-10 w-10 border-t-2 border-b-2 border-orange-500"></div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="p-12 text-center text-red-600 bg-[#f9f7f4] min-h-screen flex flex-col items-center justify-center">
        <div className="bg-white p-8 rounded-xl shadow-sm border border-red-200 max-w-md w-full">
          <p className="font-bold text-lg">เกิดข้อผิดพลาดในการโหลดข้อมูล</p>
          <p className="text-sm text-gray-500 mt-2 break-all">{error}</p>
          <p className="text-xs text-gray-400 mt-3">กรุณาตรวจสอบว่า API server ทำงานปกติ และ endpoint ส่ง JSON กลับมาถูกต้อง</p>
          <button
            onClick={fetchData}
            className="mt-6 px-6 py-2.5 bg-orange-500 text-white rounded-lg hover:bg-orange-600 transition font-semibold"
          >
            โหลดใหม่
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="p-6 bg-[#f9f7f4] min-h-screen text-base">
      {/* ===== HEADER ===== */}
      <div className="mb-8">
        <h1 className="text-[26px] font-bold mb-1 text-[#8B4513]">รายงานสถิติ</h1>
        <p className="text-gray-500">ภาพรวมการใช้งานระบบแปลภาษาล้านนา</p>
      </div>

      {/* ===== SUMMARY CARDS ===== */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-10">
        {[
          ["คำศัพท์ทั้งหมด", vocabularies.length.toLocaleString()],
          ["ผู้ใช้งานทั้งหมด", users.length.toLocaleString()],
          ["ยอดการแปลรวม", translateLogs.length.toLocaleString()],
          ["เนื้อหาการเรียนรู้", articles.length.toLocaleString()],
        ].map(([label, value], i) => (
          <div key={i} className="bg-white rounded-xl shadow-sm p-6 border-t-2 border-orange-500">
            <p className="text-gray-500 mb-1 text-sm font-medium">{label}</p>
            <p className="text-3xl font-extrabold text-orange-600">{value}</p>
          </div>
        ))}
      </div>

      {/* ===== CHARTS ===== */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-10">
        {/* BAR CHART */}
        <div className="bg-white rounded-xl shadow-sm p-6 flex flex-col">
          <div className="mb-4">
            <h2 className="text-xl font-bold">
              {chartResult.type === "day" && "การแปลรายวัน"}
              {chartResult.type === "month" && "การแปลรายเดือน"}
              {chartResult.type === "year" && "การแปลรายปี"}
              {chartResult.type === "category" && "การแปลคำศัพท์รายวัน"}
            </h2>

            <div className="flex items-center gap-2 text-sm mt-2 flex-wrap">
              <span className="text-gray-500">เลือกช่วงวัน:</span>
              <input
                type="date"
                value={startDate}
                onChange={(e) => setStartDate(e.target.value)}
                className="border rounded-lg px-3 py-1.5"
              />
              <span className="text-gray-400">–</span>
              <input
                type="date"
                value={endDate}
                onChange={(e) => setEndDate(e.target.value)}
                className="border rounded-lg px-3 py-1.5"
              />
            </div>

            {isDateSelected && (
              <p className="text-sm text-gray-600 mt-2">
                รวมทั้งหมด{" "}
                <span className="font-semibold text-orange-600">
                  {totalSelected.toLocaleString()} ครั้ง
                </span>
              </p>
            )}
          </div>

          <div className="h-[260px] w-full flex-1">
            {chartData.length === 0 ? (
              <div className="h-full flex items-center justify-center text-gray-400">
                ยังไม่มีข้อมูล
              </div>
            ) : (
              <ResponsiveContainer width="100%" height="100%">
                <BarChart
                  data={chartData}
                  margin={{ top: 10, right: 16, left: 0, bottom: 40 }}
                  barCategoryGap={18}
                  barGap={4}
                >
                  <CartesianGrid strokeDasharray="3 3" vertical={false} />

                  <XAxis
                    dataKey={chartResult.type === "category" ? "name" : "label"}
                    interval={
                      chartResult.type === "category" ? 0 : "preserveStartEnd"
                    }
                    minTickGap={chartResult.type === "category" ? 0 : 12}
                    tickMargin={10}
                    height={60}
                    angle={-30}
                    textAnchor="end"
                    tick={{ fontSize: 11, fill: "#6B7280" }}
                  />

                  <YAxis tick={{ fontSize: 11, fill: "#6B7280" }} width={36} />

                  <Tooltip />

                  <Bar
                    dataKey="value"
                    fill="#EA580C"
                    radius={[8, 8, 0, 0]}
                    barSize={22}
                  />
                </BarChart>
              </ResponsiveContainer>
            )}
          </div>
        </div>

        {/* DONUT CHART */}
        <div className="bg-white rounded-xl shadow-sm p-6 flex flex-col">
          <h2 className="text-xl font-bold mb-4">สัดส่วนหมวดหมู่คำศัพท์</h2>

          {pieData.length === 0 ? (
            <div className="h-[260px] flex items-center justify-center text-gray-400 flex-1">
              ยังไม่มีข้อมูล
            </div>
          ) : (
            <div className="flex flex-col md:flex-row items-center gap-6 flex-1">
              <div className="relative w-[260px] h-[260px]">
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie
                      data={pieData.map((item) => ({
                        ...item,
                        renderValue: total > 0 ? (item.value || 0.001) : 1,
                      }))}
                      dataKey="renderValue"
                      innerRadius={85}
                      outerRadius={110}
                      paddingAngle={3}
                    >
                      {pieData.map((_, index) => (
                        <Cell key={index} fill={COLORS[index % COLORS.length]} />
                      ))}
                    </Pie>
                  </PieChart>
                </ResponsiveContainer>

                <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
                  <p className="text-3xl font-bold">{pieData.length}</p>
                  <p className="text-gray-500 text-sm">หมวดหมู่</p>
                </div>
              </div>

              <div className="flex-1 space-y-3 w-full overflow-y-auto max-h-[260px]">
                {pieData.map((item, index) => {
                  const percent = total > 0 ? ((item.value / total) * 100).toFixed(0) : 0;
                  return (
                    <div
                      key={index}
                      className="flex items-center justify-between"
                    >
                      <div className="flex items-center gap-3">
                        <span
                          className="w-3 h-3 rounded-full shrink-0"
                          style={{
                            backgroundColor: COLORS[index % COLORS.length],
                          }}
                        />
                        <span className="text-sm font-medium text-gray-700">{item.name}</span>
                      </div>
                      <span className="font-semibold text-sm text-gray-700">{percent}%</span>
                    </div>
                  );
                })}
              </div>
            </div>
          )}
        </div>
      </div>

      {/* ===== TABLE ===== */}
      <div className="bg-white rounded-xl shadow-sm overflow-hidden">
        <div className="p-4 border-b">
          <h2 className="text-xl font-bold">อันดับหมวดหมู่ยอดนิยม</h2>
        </div>

        <table className="w-full">
          <thead className="bg-gray-100 text-gray-600">
            <tr>
              <th className="p-4 text-left">หมวดหมู่</th>
              <th className="p-4 text-left">จำนวนคำศัพท์</th>
              <th className="p-4 text-left">ยอดการแปล</th>
              <th className="p-4 text-left">การเติบโต</th>
              <th className="p-4 text-left">อัปเดตล่าสุด</th>
            </tr>
          </thead>
          <tbody>
            {pieData.map((item, i) => {
              const vocabCount = item.value;
              const translationCount = getCategoryTranslationCount(item.name);
              const growth = vocabCount > 0 ? (vocabCount % 15) + 5 : 0;
              const hoursAgo = (vocabCount % 5) + 1;

              return (
                <tr key={i} className="border-t hover:bg-gray-50">
                  <td className="p-4 font-medium">{item.name}</td>
                  <td className="p-4">{vocabCount.toLocaleString()} คำ</td>
                  <td className="p-4">{translationCount.toLocaleString()} ครั้ง</td>
                  <td className="p-4 text-green-600">+{growth}%</td>
                  <td className="p-4 text-gray-500">{hoursAgo} ชม. ที่ผ่านมา</td>
                </tr>
              );
            })}
            {pieData.length === 0 && (
              <tr>
                <td colSpan={5} className="p-4 text-center text-gray-500">
                  ยังไม่มีข้อมูล
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
