import { useEffect, useMemo, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { useAuth } from "../auth/AuthContext";
import { useTranslation } from "react-i18next";
import api from "../api/api";
import "./chat.css";

export default function ChatList() {
    const { t } = useTranslation();
    const { user } = useAuth();
    const navigate = useNavigate();
    const role = user?.role;

    // Block sales on web
    useEffect(() => {
        if (role === "sales") navigate("/unauthorized");
    }, [role, navigate]);

    const [conversations, setConversations] = useState([]);
    const [filter, setFilter] = useState("all");

    // -------------------------------------------------------
    // Load conversations from backend
    // -------------------------------------------------------
    useEffect(() => {
        async function load() {
            try {
                const res = await api.get("/chat/conversations/");

                const mapped = res.data.map(c => ({
                    id: c.id,
                    consumerId: c.consumer,
                    consumerName: `Consumer #${c.consumer}`,
                    linked: true,
                    lastMessage: { text: "(open chat to view)", ts: c.updated_at },
                    unreadCount: c.unread_messages || 0,
                    updatedAt: c.updated_at
                }));

                setConversations(mapped);

            } catch (err) {
                console.error("Failed to load conversations", err);
            }
        }

        load();
    }, []);

    // -------------------------------------------------------
    // Filtering logic (only "all" and "recent" now)
    // -------------------------------------------------------
    const visible = useMemo(() => {
        let list = conversations.filter(c => c.linked);

        if (filter === "recent")
            list = [...list].sort(
                (a, b) => new Date(b.updatedAt) - new Date(a.updatedAt)
            );

        return list;
    }, [conversations, filter]);

    // -------------------------------------------------------
    // UI
    // -------------------------------------------------------
    return (
        <div className="chat-page">
            <h2>{t("chat.title")}</h2>

            {/* Filters */}
            <div className="chat-controls">
                <div className="filters">
                    <button
                        className={filter === "all" ? "active" : ""}
                        onClick={() => setFilter("all")}
                    >
                        {t("chat.filters.all")}
                    </button>

                    <button
                        className={filter === "recent" ? "active" : ""}
                        onClick={() => setFilter("recent")}
                    >
                        {t("chat.filters.recent")}
                    </button>
                </div>
            </div>

            {/* Conversation list */}
            <div className="conversations-list">
                {visible.length === 0 && (
                    <p className="empty">{t("chat.empty")}</p>
                )}

                {visible.map(conv => (
                    <div key={conv.id} className="conversation-row">

                        <Link to={`/chat/${conv.id}`} className="conv-link">
                            <div className="conv-left">
                                <div className="avatar">
                                    {conv.consumerName
                                        .split(" ")
                                        .map(s => s[0])
                                        .slice(0, 2)
                                        .join("")}
                                </div>
                            </div>

                            <div className="conv-body">
                                <div className="conv-top">
                                    <strong>{conv.consumerName}</strong>
                                    <span className="conv-ts">
                                        {new Date(conv.updatedAt).toLocaleString()}
                                    </span>
                                </div>

                                <div className="conv-bottom">
                                    <span className="preview">
                                        {conv.lastMessage.text}
                                    </span>

                                    <div className="conv-meta">
                                        {conv.unreadCount > 0 && (
                                            <span className="unread-badge">
                                                {conv.unreadCount}
                                            </span>
                                        )}
                                    </div>
                                </div>
                            </div>
                        </Link>
                    </div>
                ))}
            </div>
        </div>
    );
}
