import Sidebar from "./sidebar.jsx";
import Topbar from "./topbar.jsx";
import { Outlet } from "react-router-dom";

export default function Layout() {
  return (
    <div className="flex min-h-screen bg-slate-100 text-slate-900">
      {/* เมนูด้านข้าง */}
      <Sidebar />

      {/* เนื้อหา */}
      <div className="flex-1 flex flex-col">
        <Topbar />
        <main className="flex-1">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
