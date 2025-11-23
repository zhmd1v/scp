import { useState } from "react";
import { useTranslation } from "react-i18next";
import Sidebar from "./Sidebar";
import Topbar from "./Topbar";
import "./layout.css";

export default function GlobalLayout({ children }) {
    const [open, setOpen] = useState(false);
    const { t } = useTranslation();

    return (
        <div className="global-layout">

            {!open && (
                <button
                    className="global-toggle-btn"
                    onClick={() => setOpen(true)}
                >
                    ☰
                </button>
            )}

            <div className={open ? "sidebar open" : "sidebar closed"}>
                {open && (
                    <div className="sidebar-header">
                        <button
                            className="sidebar-menu-btn"
                            onClick={() => setOpen(false)}
                        >
                            ☰
                        </button>
                        <h2 className="sidebar-title">{t("layout.menu")}</h2>
                    </div>
                )}

                <Sidebar />
            </div>

            <div className="global-main">
                <Topbar />
                <div className="global-page-content">{children}</div>
            </div>
        </div>
    );
}