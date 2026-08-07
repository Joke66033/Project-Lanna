import { useState, useEffect } from "react";
import { supabase } from "../lib/supabaseClient";
import Pagination from "../components/Pagination.jsx";
import { trackRecentActivity, sortRecentData } from "../lib/recentActivity.js";
import { SuccessModal } from "../components/AlertModals.jsx";

/* ================= MODAL ================= */
import Modal from "../components/Modal.jsx";
import { categoryColors } from "../lib/categoryColors";

/* ================= CONSTANTS ================= */
// ตาราง users คอลัมน์ status เป็น smallint: 1 = กำลังใช้งาน, 0 = ถูกระงับ
const USER_STATUS = {
  ACTIVE: 1,
  SUSPENDED: 0,
};

/* ================= PAGE ================= */
export default function Users() {
  const colors = categoryColors.users;
  const ITEMS_PER_PAGE = 10;

  /* ===== STATES ===== */
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [totalCount, setTotalCount] = useState(0);

  const [search, setSearch] = useState("");
  const [selectedStatus, setSelectedStatus] = useState("all");
  const [currentPage, setCurrentPage] = useState(1);

  const [showConfirm, setShowConfirm] = useState(false);
  const [showSuccess, setShowSuccess] = useState(false);
  const [successText, setSuccessText] = useState("");
  const [pendingUser, setPendingUser] = useState(null);

  // toggling = user_id ที่กำลัง update อยู่ (ป้องกันกดซ้ำ)
  const [toggling, setToggling] = useState(null);

  /* ===== FETCH ===== */
  const fetchData = async (page = currentPage, searchQuery = search, sStatus = selectedStatus) => {
    setLoading(true);
    try {
      let list = [];
      try {
        const res = await fetch(`${BASE}/endpoints/users_api.php?action=getAll`);
        const json = await res.json();
        list = json.data || [];
      } catch (e) {
        console.warn("MySQL PHP API fetch error, falling back to Supabase:", e);
      }

      if (!Array.isArray(list) || list.length === 0) {
        const { data: resData } = await supabase
          .from("users")
          .select("*");
        list = resData || [];
      }

      if (searchQuery.trim() !== "") {
        const q = searchQuery.trim().toLowerCase();
        list = list.filter((item) => 
          (item.username && item.username.toLowerCase().includes(q)) ||
          (item.email && item.email.toLowerCase().includes(q))
        );
      }

      if (sStatus === "active") {
        list = list.filter((item) => String(item.status) === String(USER_STATUS.ACTIVE));
      } else if (sStatus === "suspended") {
        list = list.filter((item) => String(item.status) === String(USER_STATUS.SUSPENDED));
      }

      setTotalCount(list.length);

      const from = (page - 1) * ITEMS_PER_PAGE;
      const paginated = list.slice(from, from + ITEMS_PER_PAGE);

      if (page > 1 && paginated.length === 0 && list.length > 0) {
        setCurrentPage(page - 1);
      } else {
        const sorted = sortRecentData(paginated, "users", "user_id");
        setData(sorted);
        setError(null);
      }
    } catch (err) {
      console.error("users fetchData error:", err);
      setError(err.message || "เกิดข้อผิดพลาดในการโหลดข้อมูลสมาชิก");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    const delayDebounceFn = setTimeout(() => {
      fetchData(currentPage, search, selectedStatus);
    }, 200);
    return () => clearTimeout(delayDebounceFn);
  }, [currentPage, search, selectedStatus]);

  useEffect(() => {
    const channel = supabase
      .channel("users_realtime")
      .on("postgres_changes",
        { event: "*", schema: "public", table: "users" },
        () => fetchData(currentPage, search, selectedStatus)
      )
      .subscribe();
    return () => supabase.removeChannel(channel);
  }, [currentPage, search, selectedStatus]);

  /* ===== MAP DATA ===== */
  // status ใน Supabase เป็น smallint: 1 = กำลังใช้งาน, 0 = ถูกระงับ
  const users = (data || []).map((item) => ({
    ...item,
    id: item.user_id || item.id,
    name: item.username || item.name || "—",
    email: item.email || "—",
    isActive: Number(item.status) === USER_STATUS.ACTIVE,
    rawStatus: item.status,
  }));

  const paginatedUsers = users;

  /* ===== OPEN CONFIRM ===== */
  const openToggleConfirm = (user) => {
    setPendingUser(user);
    setShowConfirm(true);
  };

  /* ===== CONFIRM TOGGLE ===== */
  const confirmToggleStatus = async () => {
    if (!pendingUser) return;
    // ส่งค่า integer ตาม schema จริง: 1 = active, 0 = suspended
    const newStatus = pendingUser.isActive ? USER_STATUS.SUSPENDED : USER_STATUS.ACTIVE;
    const userId = pendingUser.id;

    setToggling(userId);
    setShowConfirm(false);

    try {
      const { error: updateError } = await supabase
        .from("users")
        .update({ status: newStatus })
        .eq("user_id", userId);

      if (updateError) throw updateError;

      // Optimistic update: เปลี่ยน local state ทันที (ใช้ integer ตาม schema) และย้ายขึ้นอันดับแรกสุด
      trackRecentActivity("users", userId);
      setData((prev) => {
        const mapped = prev.map((u) =>
          (u.user_id || u.id) === userId
            ? { ...u, status: newStatus }
            : u
        );
        return sortRecentData(mapped, "users", "user_id");
      });

      setSuccessText(
        pendingUser.isActive
          ? `ระงับบัญชี "${pendingUser.name}" เรียบร้อยแล้ว`
          : `เปิดใช้งานบัญชี "${pendingUser.name}" เรียบร้อยแล้ว`
      );
      setShowSuccess(true);
      setPendingUser(null);

      // Refetch เพื่อให้ข้อมูลล่าสุดจาก DB
      fetchData(currentPage, search, selectedStatus);
    } catch (err) {
      console.error("Toggle status error:", err);
      alert(`เกิดข้อผิดพลาด: ${err.message}\n\nกรุณาตรวจสอบสิทธิ์การแก้ไขข้อมูล (RLS policy) ใน Supabase`);
    } finally {
      setToggling(null);
    }
  };

  return (
    <div className="p-6 bg-[#f9f7f4] min-h-screen text-base">
      {/* ===== TITLE ===== */}
      <div className="mb-6">
          <h1 className={`text-[26px] font-bold mb-1 ${colors.title}`}>จัดการสมาชิก</h1>
          <p className="text-gray-500 text-base">
            จัดการสถานะและสิทธิ์การใช้งานของสมาชิกในระบบ
          </p>
        </div>

      {/* ===== SEARCH & FILTER ===== */}
      <div className="flex gap-4 mb-6">
        <div className="flex-1">
          <input
            className={`w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 ${colors.ringFocus} bg-white`}
            placeholder="ค้นหาด้วยชื่อผู้ใช้งาน (Username) หรืออีเมล..."
            value={search}
            onChange={(e) => {
              setSearch(e.target.value);
              setCurrentPage(1);
            }}
          />
        </div>
        <div className="w-64">
          <select
            className={`w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 ${colors.ringFocus} bg-white cursor-pointer`}
            value={selectedStatus}
            onChange={(e) => {
              setSelectedStatus(e.target.value);
              setCurrentPage(1);
            }}
          >
            <option value="all">ทั้งหมด</option>
            <option value="active">กำลังใช้งาน (Active)</option>
            <option value="suspended">ถูกระงับ (Suspended)</option>
          </select>
        </div>
      </div>

      {/* ===== TABLE ===== */}
      {loading ? (
        <div className="flex items-center justify-center p-12 bg-white rounded-xl shadow-sm">
          <div className={`animate-spin rounded-full h-10 w-10 border-t-2 border-b-2 ${colors.borderCol}`} />
        </div>
      ) : error ? (
        <div className="p-12 text-center text-red-600 bg-white rounded-xl shadow-sm border border-red-200">
          <p className="font-bold text-lg">เกิดข้อผิดพลาดในการโหลดข้อมูล</p>
          <p className="text-sm mt-1">{error}</p>
          <button
            onClick={() => fetchData()}
            className={`mt-4 px-4 py-2 ${colors.primaryBg} text-white rounded-lg ${colors.primaryBgHover} transition`}
          >
            โหลดใหม่
          </button>
        </div>
      ) : (
        <div className="lanna-table-card">
          <table className="lanna-table">
            <thead className={colors.theadBg}>
              <tr className={`${colors.theadText} border-b-2 ${colors.theadBorder}`} style={{ background: 'none' }}>
                <th className="th-num">#</th>
                <th className="th-left">ชื่อผู้ใช้งาน</th>
                <th className="th-left">อีเมล</th>
                <th className="!text-center">สถานะ</th>
                <th>การจัดการ</th>
              </tr>
            </thead>

            <tbody>
              {paginatedUsers.map((user, index) => {
                const isToggling = toggling === user.id;
                return (
                  <tr key={user.id || user.email}>
                    {/* ลำดับ */}
                    <td className="td-num">
                      <span className={`lanna-seq ${colors.seqBg} ${colors.seqText} ${colors.seqBgHover} ${colors.seqTextHover}`}>
                        {(currentPage - 1) * ITEMS_PER_PAGE + index + 1}
                      </span>
                    </td>

                    {/* ชื่อผู้ใช้ */}
                    <td>
                      <p className="lanna-cell-main">{user.name}</p>
                    </td>

                    {/* อีเมล */}
                    <td className="lanna-cell-sub">
                      {user.email}
                    </td>

                    {/* สถานะ */}
                    <td className="text-center">
                      {user.isActive ? (
                        <span className="lanna-badge" style={{ backgroundColor: '#f0fdf4', color: '#15803d', border: '1px solid #bbf7d0' }}>
                          <span className="lanna-badge-dot" style={{ backgroundColor: '#22c55e' }} />
                          กำลังใช้งาน
                        </span>
                      ) : (
                        <span className="lanna-badge" style={{ backgroundColor: '#fef2f2', color: '#dc2626', border: '1px solid #fecaca' }}>
                          <span className="lanna-badge-dot" style={{ backgroundColor: '#ef4444' }} />
                          ถูกระงับ
                        </span>
                      )}
                    </td>

                    {/* ปุ่มจัดการ */}
                    <td className="text-center">
                      <button
                        onClick={() => openToggleConfirm(user)}
                        disabled={isToggling}
                        className={`inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg border text-xs font-semibold transition-all disabled:opacity-50 disabled:cursor-not-allowed ${
                          user.isActive
                            ? "border-red-300 text-red-600 hover:bg-red-50 hover:border-red-400"
                            : "border-green-300 text-green-600 hover:bg-green-50 hover:border-green-400"
                        }`}
                      >
                        {isToggling ? (
                          <>
                            <span className="w-3 h-3 rounded-full border-2 border-current border-t-transparent animate-spin" />
                            กำลังดำเนินการ...
                          </>
                        ) : user.isActive ? (
                          <>
                            <span className="w-1.5 h-1.5 rounded-full bg-red-400 shrink-0" />
                            ระงับบัญชี
                          </>
                        ) : (
                          <>
                            <span className="w-1.5 h-1.5 rounded-full bg-green-500 shrink-0" />
                            เปิดใช้งาน
                          </>
                        )}
                      </button>
                    </td>
                  </tr>
                );
              })}

              {paginatedUsers.length === 0 && (
                <tr>
                  <td colSpan={5}>
                    <div className="lanna-empty">
                      <svg className="lanna-empty-icon" fill="none" stroke="currentColor" strokeWidth="1.5" viewBox="0 0 24 24" style={{width:40,height:40}}>
                        <path strokeLinecap="round" strokeLinejoin="round" d="M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zm8.25 2.25a2.625 2.625 0 11-5.25 0 2.625 2.625 0 015.25 0z" />
                      </svg>
                      <p className="lanna-empty-title">ยังไม่มีข้อมูลสมาชิก</p>
                      <p className="lanna-empty-sub">ยังไม่มีสมาชิกลงทะเบียนในระบบ</p>
                    </div>
                  </td>
                </tr>
              )}
            </tbody>
          </table>

          {/* PAGINATION */}
          <Pagination
            currentPage={currentPage}
            totalItems={totalCount}
            pageSize={ITEMS_PER_PAGE}
            onPageChange={setCurrentPage}
            colors={colors}
          />
        </div>
      )}

      {/* ===== CONFIRM MODAL ===== */}
      {showConfirm && pendingUser && (
        <Modal title="" onClose={() => setShowConfirm(false)}>
          <div className="flex flex-col items-center text-center space-y-5 p-6">
            {/* ไอคอน */}
            <div className={`w-16 h-16 rounded-full flex items-center justify-center ${
              pendingUser.isActive ? "bg-red-50" : "bg-green-50"
            }`}>
              {pendingUser.isActive ? (
                <svg className="w-8 h-8 text-red-500" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 005.636 5.636m12.728 12.728L5.636 5.636" />
                </svg>
              ) : (
                <svg className="w-8 h-8 text-green-500" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              )}
            </div>

            <div>
              <h3 className="text-lg font-bold text-gray-900 mb-1.5">
                {pendingUser.isActive ? "ระงับบัญชีผู้ใช้" : "เปิดใช้งานบัญชีผู้ใช้"}
              </h3>
              <p className="text-gray-500 text-sm">
                คุณต้องการ{pendingUser.isActive ? "ระงับ" : "เปิดใช้งาน"}บัญชีของ{" "}
                <span className="font-semibold text-gray-700">{pendingUser.name}</span>{" "}
                ใช่หรือไม่?
              </p>
              {pendingUser.isActive && (
                <p className="text-xs text-red-400 mt-2">
                  ผู้ใช้จะไม่สามารถเข้าสู่ระบบได้จนกว่าจะเปิดใช้งานอีกครั้ง
                </p>
              )}
            </div>

            <div className="flex w-full gap-3 pt-2">
              <button
                onClick={() => setShowConfirm(false)}
                className="flex-1 py-2.5 rounded-xl border border-gray-200 bg-white text-gray-600 hover:bg-gray-50 transition text-sm font-medium"
              >
                ยกเลิก
              </button>
              <button
                onClick={confirmToggleStatus}
                className={`flex-1 py-2.5 rounded-xl text-white text-sm font-semibold transition ${
                  pendingUser.isActive
                    ? "bg-red-500 hover:bg-red-600"
                    : "bg-green-500 hover:bg-green-600"
                }`}
              >
                {pendingUser.isActive ? "ยืนยันการระงับ" : "ยืนยันการเปิด"}
              </button>
            </div>
          </div>
        </Modal>
      )}

      {/* ===== SUCCESS MODAL ===== */}
      <SuccessModal
        isOpen={showSuccess}
        onClose={() => setShowSuccess(false)}
        message={successText}
      />
    </div>
  );
}
