import { BrowserRouter as Router, Routes, Route, useNavigate } from "react-router-dom";
import { AuthProvider } from "./auth/AuthContext";
import { useAuth } from "./auth/AuthContext";

import GlobalLayout from "./layout/GlobalLayout";

// Pages
import ComplaintsList from "./pages/ComplaintsList";
import ComplaintDetail from "./pages/ComplaintDetail";
import ProfileSettings from "./pages/ProfileSettings";
import LoginPage from "./pages/LoginPage";
import Unauthorized from "./pages/Unauthorized";
import OwnerDashboard from "./pages/OwnerDashboard";
import ManagerDashboard from "./pages/ManagerDashboard";
import RequireRole from "./auth/RequireRole";
import ResetPassword from "./pages/ResetPassword";
import StaffPage from "./pages/StaffPage";
import ProductManagement from "./pages/ProductManagement";
import LinkManagement from "./pages/LinkManagement";
import OrderManagement from "./pages/OrderManagement";
import ChatList from "./pages/ChatList";
import ChatThread from "./pages/ChatThread";
import { useEffect } from "react";


// -------------------------
// Home Page
// -------------------------
function Home() {
    const navigate = useNavigate();
    const { user } = useAuth();

    // Use useEffect to avoid navigate() during render warning
    useEffect(() => {
        if (!user) {
            navigate("/login");
        }
    }, [user, navigate]);

    if (!user) return null;

    return (
        <div
            style={{
                padding: "40px",
                textAlign: "center",
                width: "100vw",
                maxWidth: "100vw",
                overflowX: "hidden",
                boxSizing: "border-box"
            }}
        >
            <h1>Supplier Consumer Platform</h1>
            <p>Welcome to the system.</p>

            <div
                style={{
                    display: "flex",
                    justifyContent: "center",
                    marginTop: "30px"
                }}
            >
                <img
                    src="/assets/shrek.gif"
                    alt="Twerking Shrek"
                    style={{
                        width: "300px",
                        borderRadius: "12px"
                    }}
                />
            </div>
        </div>
    );
}


// -------------------------
// Main Routed Content
// -------------------------
function AppContent() {
    return (
        <GlobalLayout>
            <Routes>
                {/* Public pages */}
                <Route path="/complaints" element={<ComplaintsList />} />
                <Route path="/complaints/:id" element={<ComplaintDetail />} />
                <Route path="/" element={<Home />} />
                <Route path="/login" element={<LoginPage />} />
                <Route path="/unauthorized" element={<Unauthorized />} />
                <Route path="/reset-password" element={<ResetPassword />} />
                <Route path="/profile" element={<ProfileSettings />} />

                {/* Public Link Management (no role restriction) */}
                <Route path="/links" element={<LinkManagement />} />

                {/* Chats */}
                <Route
                    path="/chats"
                    element={
                        <RequireRole roles={["owner", "manager"]}>
                            <ChatList />
                        </RequireRole>
                    }
                />
                <Route
                    path="/chat/:id"
                    element={
                        <RequireRole roles={["owner", "manager"]}>
                            <ChatThread />
                        </RequireRole>
                    }
                />

                {/* Orders */}
                <Route
                    path="/orders"
                    element={
                        <RequireRole roles={["owner", "manager"]}>
                            <OrderManagement />
                        </RequireRole>
                    }
                />

                {/* Staff */}
                <Route
                    path="/staff"
                    element={
                        <RequireRole roles={["owner", "manager"]}>
                            <StaffPage />
                        </RequireRole>
                    }
                />

                {/* Products */}
                <Route
                    path="/products"
                    element={
                        <RequireRole roles={["owner", "manager"]}>
                            <ProductManagement />
                        </RequireRole>
                    }
                />

                {/* Dashboards */}
                <Route
                    path="/owner"
                    element={
                        <RequireRole roles={["owner"]}>
                            <OwnerDashboard />
                        </RequireRole>
                    }
                />

                <Route
                    path="/manager"
                    element={
                        <RequireRole roles={["owner", "manager"]}>
                            <ManagerDashboard />
                        </RequireRole>
                    }
                />
            </Routes>
        </GlobalLayout>
    );
}


// -------------------------
// Root App
// -------------------------
export default function App() {
    return (
        <AuthProvider>
            <Router>
                <AppContent />
            </Router>
        </AuthProvider>
    );
}
