import { useAuth } from "../auth/AuthContext";
import { Link } from "react-router-dom";
import { useTranslation } from "react-i18next";

export default function Sidebar() {
    const { user } = useAuth();
    const role = user?.user_type;
    const { t } = useTranslation();

    return (
        <div className="sidebar-inner">


            {/* ---------- OWNER ONLY ---------- */}
            {role === "owner" && (
                <>
                    <div className="sidebar-item">
                        <span className="sidebar-dot">•</span>
                        <Link to="/owner">{t("sidebar.ownerDashboard")}</Link>
                    </div>

                    <div className="sidebar-item">
                        <span className="sidebar-dot">•</span>
                        <Link to="/staff">{t("sidebar.staffManagement")}</Link>
                    </div>
                </>
            )}

            {/* ---------- MANAGER ONLY ---------- */}
            {role === "manager" && (
                <>
                    <div className="sidebar-item">
                        <span className="sidebar-dot">•</span>
                        <Link to="/manager">{t("sidebar.managerDashboard")}</Link>
                    </div>

                    <div className="sidebar-item">
                        <span className="sidebar-dot">•</span>
                        <Link to="/staff">{t("sidebar.staffManagement")}</Link>
                    </div>
                </>
            )}

            {/* ---------- ORDER MANAGEMENT (BOTH) ---------- */}
            {(role === "owner" || role === "manager") && (
                <div className="sidebar-item">
                    <span className="sidebar-dot">•</span>
                    <Link to="/orders">{t("sidebar.orderManagement")}</Link>
                </div>
            )}

            {/* ---------- PRODUCT MANAGEMENT (BOTH) ---------- */}
            {(role === "owner" || role === "manager") && (
                <div className="sidebar-item">
                    <span className="sidebar-dot">•</span>
                    <Link to="/products">{t("sidebar.productManagement")}</Link>
                </div>
            )}

            {/* ---------- CHATS (BOTH) ---------- */}
            {(role === "owner" || role === "manager") && (
                <div className="sidebar-item">
                    <span className="sidebar-dot">•</span>
                    <Link to="/chats">{t("sidebar.chats")}</Link>
                </div>
            )}

            {/* ---------- LINKS (BOTH) ---------- */}
            {(role === "owner" || role === "manager") && (
                <div className="sidebar-item">
                    <span className="sidebar-dot">•</span>
                    <Link to="/links">{t("sidebar.linkManagement")}</Link>
                </div>
            )}

            {/* ---------- NEW: COMPLAINTS (OWNER + MANAGER) ---------- */}
            {(role === "owner" || role === "manager") && (
                <div className="sidebar-item">
                    <span className="sidebar-dot">•</span>
                    <Link to="/complaints">{t("sidebar.complaints")}</Link>
                </div>
            )}

            {/* ---------- PROFILE (ALL ROLES) ---------- */}
            <div className="sidebar-item">
                <span className="sidebar-dot">•</span>
                <Link to="/profile">{t("sidebar.profileSettings")}</Link>
            </div>

        </div>
    );
}

