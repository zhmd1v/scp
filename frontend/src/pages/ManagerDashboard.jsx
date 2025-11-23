import { useEffect, useState } from "react";
import api from "../api/api";
import { useTranslation } from "react-i18next";

export default function ManagerDashboard() {
    const { t } = useTranslation();

    const [orders, setOrders] = useState([]);
    const [loading, setLoading] = useState(true);

    const [stats, setStats] = useState({
        ordersToday: 0,
        activeConsumers: 0,
        pending: 0,
        confirmed: 0,
        inDelivery: 0,
    });

    useEffect(() => {
        async function load() {
            try {
                setLoading(true);
                const res = await api.get("/orders/");
                const allOrders = Array.isArray(res.data) ? res.data : [];

                setOrders(allOrders);
                calculateStats(allOrders);

            } catch (err) {
                console.error("Failed to load ManagerDashboard:", err);
            } finally {
                setLoading(false);
            }
        }

        load();
    }, []);

    function calculateStats(allOrders) {
        const today = new Date().toISOString().slice(0, 10);

        const ordersToday = allOrders.filter(
            o => o.created_at.slice(0, 10) === today
        );

        const uniqueConsumers = new Set(
            ordersToday.map(o => o.consumer)
        );

        setStats({
            ordersToday: ordersToday.length,
            activeConsumers: uniqueConsumers.size,
            pending: allOrders.filter(o => o.status === "pending").length,
            confirmed: allOrders.filter(o => o.status === "confirmed").length,
            inDelivery: allOrders.filter(o => o.status === "in_delivery").length,
        });
    }

    if (loading) return <p className="p-4">{t("dashboard.loading")}</p>;

    return (
        <div className="p-4">

            {/* ===================== STATS CARDS ===================== */}
            <div style={{
                display: "grid",
                gridTemplateColumns: "repeat(auto-fill, minmax(220px, 1fr))",
                gap: "20px",
                marginBottom: "30px"
            }}>
                <div className="dashboard-card">
                    <h3>{t("dashboard.orders_today")}</h3>
                    <div className="value">{stats.ordersToday}</div>
                </div>

                <div className="dashboard-card">
                    <h3>{t("dashboard.active_consumers")}</h3>
                    <div className="value">{stats.activeConsumers}</div>
                </div>

                <div className="dashboard-card">
                    <h3>{t("dashboard.pending")}</h3>
                    <div className="value">{stats.pending}</div>
                </div>

                <div className="dashboard-card">
                    <h3>{t("dashboard.confirmed")}</h3>
                    <div className="value">{stats.confirmed}</div>
                </div>

                <div className="dashboard-card">
                    <h3>{t("dashboard.in_delivery")}</h3>
                    <div className="value">{stats.inDelivery}</div>
                </div>
            </div>

            {/* ===================== RECENT ORDERS TABLE ===================== */}
            <h2 className="text-xl font-semibold mb-3">
                {t("dashboard.recent_orders")}
            </h2>

            <table className="min-w-full border text-sm">
                <thead className="bg-gray-100">
                <tr>
                    <th className="border p-2">ID</th>
                    <th className="border p-2">{t("dashboard.consumer")}</th>
                    <th className="border p-2">{t("dashboard.supplier")}</th>
                    <th className="border p-2">{t("dashboard.created_at")}</th>
                    <th className="border p-2">{t("dashboard.requested_delivery")}</th>
                    <th className="border p-2">{t("dashboard.items")}</th>
                    <th className="border p-2">{t("dashboard.total")}</th>
                    <th className="border p-2">{t("dashboard.status")}</th>
                </tr>
                </thead>

                <tbody>
                {orders.length === 0 && (
                    <tr>
                        <td colSpan="8" className="text-center p-3">
                            {t("dashboard.no_orders")}
                        </td>
                    </tr>
                )}

                {orders.map(order => (
                    <tr key={order.id}>
                        <td className="border p-2">{order.id}</td>

                        <td className="border p-2">
                            #{order.consumer}
                        </td>

                        <td className="border p-2">
                            {order.supplier?.company_name || t("dashboard.unknown_supplier")}
                        </td>

                        <td className="border p-2">
                            {new Date(order.created_at).toLocaleString()}
                        </td>

                        <td className="border p-2">
                            {order.requested_delivery_date}
                        </td>

                        <td className="border p-2">
                            {order.items?.length ?? 0} {t("dashboard.items_suffix")}
                        </td>

                        <td className="border p-2">
                            {order.total_amount} ₸
                        </td>

                        <td className="border p-2 capitalize">
                            {order.status.replace("_", " ")}
                        </td>
                    </tr>
                ))}
                </tbody>
            </table>
        </div>
    );
}

