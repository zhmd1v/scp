import { useState, useEffect } from "react";
import "./orders.css";
import { useTranslation } from "react-i18next";
import api from "../api/api";

export default function OrderManagement() {
    const { t } = useTranslation();

    const [orders, setOrders] = useState([]);
    const [activeTab, setActiveTab] = useState("pending");
    const [loading, setLoading] = useState(false);

    // -------------------------------
    // LOAD ORDERS FROM BACKEND
    // -------------------------------
    const loadOrders = async () => {
        try {
            setLoading(true);
            const res = await api.get("/orders/my/supplier/");
            setOrders(res.data);
        } catch (err) {
            console.error("Failed to load orders:", err);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        loadOrders();
    }, []);

    // -------------------------------
    // ORDER ACTIONS
    // -------------------------------
    const acceptOrder = async (orderId) => {
        await api.post(`/orders/${orderId}/confirm/`);
        loadOrders();
    };

    const rejectOrder = async (orderId) => {
        await api.post(`/orders/${orderId}/reject/`);
        loadOrders();
    };

    // -------------------------------
    // FILTERED ORDERS BY TAB
    // -------------------------------
    const filtered = orders.filter(o => o.status === activeTab);

    // -------------------------------
    // Supported statuses
    // -------------------------------
    const statusTabs = [
        "pending",
        "confirmed",
        "in_delivery",
        "completed",
        "rejected",
        "cancelled",
    ];

    return (
        <div className="orders-page">
            <h2>{t("orders.title")}</h2>
            <p className="subtitle">{t("orders.subtitle")}</p>

            {/* ================= FILTER TABS ================= */}
            <div className="order-tabs">
                {statusTabs.map(tab => (
                    <button
                        key={tab}
                        className={tab === activeTab ? "tab active" : "tab"}
                        onClick={() => setActiveTab(tab)}
                    >
                        {t(`orders.status.${tab}`, tab)}
                    </button>
                ))}
            </div>

            {/* ================= ORDERS LIST ================= */}
            <section className="orders-section">
                <h3>{t("orders.listTitle")}</h3>

                {loading && <p>{t("loading")}</p>}

                {!loading && filtered.length === 0 && (
                    <p className="empty">{t("orders.incoming.empty")}</p>
                )}

                <div className="orders-list">
                    {filtered.map(order => (
                        <div key={order.id} className="order-card">
                            <div className="order-info">
                                <p className="order-id">
                                    <strong>OrderID:</strong> {order.id}
                                </p>

                                <p className="order-consumer">
                                    Consumer #{order.consumer}
                                </p>

                                <p className="order-date">
                                    {new Date(order.created_at).toLocaleString()}
                                </p>

                                <p className={`status ${order.status}`}>
                                    {order.status.replace("_", " ").toUpperCase()}
                                </p>
                            </div>

                            {/* Only pending orders can be acted on */}
                            {order.status === "pending" && (
                                <div className="order-actions">
                                    <button
                                        className="accept-btn"
                                        onClick={() => acceptOrder(order.id)}
                                    >
                                        {t("orders.accept")}
                                    </button>

                                    <button
                                        className="reject-btn"
                                        onClick={() => rejectOrder(order.id)}
                                    >
                                        {t("orders.reject")}
                                    </button>
                                </div>
                            )}
                        </div>
                    ))}
                </div>
            </section>
        </div>
    );
}
