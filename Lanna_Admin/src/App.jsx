import { Routes, Route, Navigate } from "react-router-dom";
import Layout from "./components/layout.jsx";

import Login from "./pages/login.jsx";

// ✅ auth pages
import ForgotPassword from "./pages/auth/forgotPassword.jsx";
import Otp from "./pages/auth/otp.jsx";
import ResetPassword from "./pages/auth/reset_password.jsx";

import Dashboard from "./pages/dashboard.jsx";
import VocabularyPage from './pages/VocabularyPage';
import Alphabet from "./pages/alphabet.jsx";
import Users from "./pages/users.jsx";
import Articles from "./pages/articles.jsx";
import AdminProfile from "./pages/adminProfile.jsx";
import CategoryAlphabet from "./pages/categoryAlphabet.jsx";
import CategoryLannaChar from "./pages/categoryLannaChar.jsx";
import CategoryLearning from "./pages/categoryLearning.jsx";
import CharacterStrokesPage from "./pages/characterStrokes.jsx";

/* ================= PROTECTED ROUTE ================= */
function ProtectedRoute({ children }) {
  const user = localStorage.getItem("admin_user") || sessionStorage.getItem("admin_user");
  if (!user) return <Navigate to="/login" replace />;
  return children;
}

/* ================= APP ================= */
export default function App() {
  return (
    <Routes>
      {/* ✅ เปิดเว็บมาให้ไปหน้า login */}
      <Route path="/" element={<Navigate to="/login" replace />} />

      {/* ✅ LOGIN (ไม่ใช้ Layout) */}
      <Route path="/login" element={<Login />} />

      {/* ✅ AUTH FLOW (ไม่ใช้ Layout / ไม่ protected) */}
      <Route path="/forgot-password" element={<ForgotPassword />} />
      <Route path="/otp" element={<Otp />} />
      <Route path="/reset-password" element={<ResetPassword />} />

      {/* ✅ ADMIN PROFILE (ไม่ใช้ Layout แต่ยัง protected) */}
      <Route
        path="/admin-profile"
        element={
          <ProtectedRoute>
            <AdminProfile />
          </ProtectedRoute>
        }
      />

      {/* ✅ PROTECTED ADMIN AREA (ใช้ Layout) */}
      <Route
        element={
          <ProtectedRoute>
            <Layout />
          </ProtectedRoute>
        }
      >
        <Route path="/dashboard" element={<Dashboard />} />
        <Route path="/vocabulary" element={<VocabularyPage />} />
        <Route path="/categoryAlphabet" element={<CategoryAlphabet />} />
        <Route path="/categoryLearning" element={<CategoryLearning />} />
        <Route path="/categoryLannaChar" element={<CategoryLannaChar />} />
        <Route path="/alphabet" element={<Alphabet />} />
        <Route path="/characterStrokes" element={<CharacterStrokesPage />} />
        <Route path="/articles" element={<Articles />} />
        <Route path="/users" element={<Users />} />
      </Route>

      {/* ✅ CATCH ALL */}
      <Route path="*" element={<Navigate to="/login" replace />} />
    </Routes>
  );
}