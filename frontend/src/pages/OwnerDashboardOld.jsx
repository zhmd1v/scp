import { useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import api from "../api/api";
import "./OwnerDashboard.css";

export default function OwnerDashboard() {
    const { t } = useTranslation();

    const [pendingOrders, setPendingOrders] = useState([]);
    const [recentOrders, setRecentOrders] = useState([]);
    const [linkRequests, setLinkRequests] = useState([]);
    const [complaints, setComplaints] = useState([]);

    const [consumerMap, setConsumerMap] = useState({}); // id → name

    // ------------------------------
    // Load linked consumers to map ID → name
    // ------------------------------
    const loadConsumers = async () => {
        const res = await api.get("/accounts/links/");
        const map = {};

        res.data.forEach(link => {
            if (link.consumer)
                map[link.consumer.id] = link.consumer.name;
        });

        setConsumerMap(map);
    };

    // ------------------------------
    // Load supplier orders
    // ------------------------------
    const loadOrders = async () => {
        const res = await api.get("/orders/my/supplier/");
        const orders = res.data;

        // Pending
        setPendingOrders(
            orders.filter(o => o.status === "pending").map(o => ({
                id: o.id,
                consumer: consumerMap[o.consumer] || `Consumer #${o.consumer}`,
                date: o.created_at.split("T")[0],
                amount: o.total_amount + " ₸"
            }))
        );

        // Recent activity (last 5)
        setRecentOrders(
            orders
                .sort((a, b) => new Date(b.updated_at) - new Date(a.updated_at))
                .slice(0, 5)
                .map(o => ({
                    id: o.id,
                    consumer: consumerMap[o.consumer] || `Consumer #${o.consumer}`,
                    status: o.status,
                    date: o.updated_at.split("T")[0]
                }))
        );
    };

    // ------------------------------
    // Load complaints
    // ------------------------------
    const loadComplaints = async () => {
        const res = await api.get("/complaints/");
        const complaints = res.data;

        setComplaints(
            complaints.map(c => ({
                id: c.id,
                order: c.order,
                title: c.title,
                severity: c.severity,
                status: c.status
            }))
        );
    };

    // ------------------------------
    // Load link requests (pending)
    // ------------------------------
    const loadLinkRequests = async () => {
        const res = await api.get("/accounts/links/");
        const pending = res.data.filter(l => l.status === "pending");

        setLinkRequests(
            pending.map(l => ({
                id: l.id,
                consumer: l.consumer.name,
                date: l.created_at.split("T")[0]
            }))
        );
    };

    // ------------------------------
    // INITIAL LOAD
    // ------------------------------
    useEffect(() => {
        (async () => {
            await loadConsumers();     // needed first
            await loadOrders();
            await loadComplaints();
            await loadLinkRequests();
        })();
    }, []);

    return (
        <div className="owner-dashboard">

            {/* QUICK STATS */}
            <div className="stats-grid">
                <div className="stat-card">
                    <h3>{t("owner.pendingOrders")}</h3>
                    <p className="stat-number">{pendingOrders.length}</p>
                </div>

                <div className="stat-card">
                    <h3>{t("owner.ordersToday")}</h3>
                    <p className="stat-number">{recentOrders.length}</p>
                </div>

                <div className="stat-card">
                    <h3>{t("owner.linkedConsumers")}</h3>
                    <p className="stat-number">{Object.keys(consumerMap).length}</p>
                </div>
            </div>

            {/* PENDING ORDERS */}
            <div className="section">
                <h2>{t("owner.pendingOrders")}</h2>

                {pendingOrders.length === 0 ? (
                    <p>{t("owner.noPendingOrders")}</p>
                ) : (
                    <div className="list">
                        {pendingOrders.map(o => (
                            <div key={o.id} className="list-item">
                                <div>
                                    <strong>#{o.id}</strong> — {o.consumer}
                                    <div className="small-text">
                                        {t("owner.date")}: {o.date}
                                    </div>
                                </div>

                                <div className="list-actions">
                                    <button className="approve-btn">{t("accept")}</button>
                                    <button className="reject-btn">{t("reject")}</button>
                                </div>
                            </div>
                        ))}
                    </div>
                )}
            </div>

            {/* LINK REQUESTS */}
            <div className="section">
                <h2>{t("owner.consumerLinkRequests")}</h2>

                {linkRequests.length === 0 ? (
                    <p>{t("owner.noNewRequests")}</p>
                ) : (
                    <div className="list">
                        {linkRequests.map(r => (
                            <div key={r.id} className="list-item">
                                <div>
                                    <strong>{r.consumer}</strong>
                                    <div className="small-text">
                                        {t("owner.requested")}: {r.date}
                                    </div>
                                </div>

                                <div className="list-actions">
                                    <button className="approve-btn">{t("approve")}</button>
                                    <button className="reject-btn">{t("deny")}</button>
                                </div>
                            </div>
                        ))}
                    </div>
                )}
            </div>

            {/* RECENT ORDERS */}
            <div className="section">
                <h2>{t("owner.recentOrderActivity")}</h2>

                <div className="list">
                    {recentOrders.map(o => (
                        <div key={o.id} className="list-item">
                            <div>
                                <strong>#{o.id}</strong> — {o.consumer}
                                <div className="small-text">
                                    {t("owner.status")}: {t(`statuses.${o.status}`)}
                                </div>
                            </div>
                        </div>
                    ))}
                </div>
            </div>

            {/* COMPLAINTS */}
            <div className="section">
                <h2>{t("owner.complaintsIncidents")}</h2>

                <div className="list">
                    {complaints.map(c => (
                        <div key={c.id} className="list-item">
                            <div>
                                <strong>{c.title}</strong>
                                <div className="small-text">
                                    {t("owner.order")} #{c.order} —
                                    {t("owner.severity")}: {t(`severity.${c.severity}`)} —
                                    {t("owner.status")}: {t(`statuses.${c.status}`)}
                                </div>
                            </div>
                        </div>
                    ))}
                </div>
            </div>

        </div>
    );
}