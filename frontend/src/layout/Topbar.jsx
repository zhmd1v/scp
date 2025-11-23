import notifIcon from "../assets/notification.png";
import { useAuth } from "../auth/AuthContext";
import { useNavigate } from "react-router-dom";
import { useEffect, useRef, useState } from "react";
import { useTranslation } from "react-i18next";

export default function Topbar() {
    const { user, logout } = useAuth();
    const navigate = useNavigate();
    const { t, i18n } = useTranslation();

    const [notificationsOpen, setNotificationsOpen] = useState(false);
    const panelRef = useRef(null);

    // Notifications must be computed on every render so they update when the language changes
    const notifications = [
        { id: 1, text: t("notifications.orderPending") },
        { id: 2, text: t("notifications.complaintEscalated") },
        { id: 3, text: t("notifications.newLinkRequest") },
    ];

    // Close notifications when clicking outside
    useEffect(() => {
        function handleClick(e) {
            if (panelRef.current && !panelRef.current.contains(e.target)) {
                setNotificationsOpen(false);
            }
        }
        if (notificationsOpen) {
            document.addEventListener("mousedown", handleClick);
        }
        return () => document.removeEventListener("mousedown", handleClick);
    }, [notificationsOpen]);

    // EN → RU → KZ → EN cycle
    const toggleLanguage = () => {
        const order = ["en", "ru", "kz"];
        const current = i18n.language;
        const next = order[(order.indexOf(current) + 1) % order.length];
        i18n.changeLanguage(next);
    };

    return (
        <div className="topbar">

            {/* LEFT */}
            <div className="topbar-left">
                <h2 className="topbar-title">{t("topbar.title")}</h2>

                <span className="lang-selector" onClick={toggleLanguage}>
                    {i18n.language.toUpperCase()}
                </span>
            </div>

            {/* RIGHT */}
            <div className="topbar-right">

                {/* Notifications */}
                <div className="notification-container" ref={panelRef}>
                    <img
                        src={notifIcon}
                        alt="Notifications"
                        className="notification-icon"
                        onClick={() => setNotificationsOpen(!notificationsOpen)}
                    />

                    {notificationsOpen && (
                        <div className="notification-panel">
                            <h4>{t("topbar.notifications")}</h4>

                            {notifications.length === 0 ? (
                                <p className="no-notifications">
                                    {t("topbar.noNotifications")}
                                </p>
                            ) : (
                                notifications.map((n) => (
                                    <div key={n.id} className="notif-item">
                                        {n.text}
                                    </div>
                                ))
                            )}
                        </div>
                    )}
                </div>

                {/* USER */}
                {user && (
                    <span className="topbar-username">
                        {user.email}
                        <span className="topbar-role">({user.role})</span>
                    </span>
                )}

                {/* AUTH */}
                {!user ? (
                    <button className="login-btn" onClick={() => navigate("/login")}>
                        {t("authLogin.login")}
                    </button>
                ) : (
                    <button className="login-btn" onClick={logout}>
                        {t("authLogin.logout")}
                    </button>
                )}
            </div>
        </div>
    );
}