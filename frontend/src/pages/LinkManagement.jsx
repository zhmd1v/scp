import { useState, useEffect } from "react";
import { useTranslation } from "react-i18next";
import "./links.css";
import api from "../api/api";

export default function LinkManagement() {
    const { t } = useTranslation();

    const [pending, setPending] = useState([]);
    const [linked, setLinked] = useState([]);
    const [loading, setLoading] = useState(true);

    // Helper: format consumer name safely
    const getConsumerName = (consumer) => {
        if (!consumer) return t("links.unknownConsumer");

        return (
            consumer.business_name ||
            [consumer.first_name, consumer.last_name].filter(Boolean).join(" ") ||
            t("links.unknownConsumer")
        );
    };

    // Helper: format date
    const formatDate = (date) => {
        try {
            return new Date(date).toLocaleDateString();
        } catch {
            return "-";
        }
    };

    // Load links
    useEffect(() => {
        async function loadLinks() {
            try {
                const res = await api.get("/accounts/links/");
                const data = res.data;

                console.log("Links response:", data);

                setPending(data.filter(l => l.status === "pending"));
                setLinked(data.filter(l => l.status === "accepted"));
            } catch (err) {
                console.error("Failed to load links:", err);
            } finally {
                setLoading(false);
            }
        }

        loadLinks();
    }, []);

    // Actions
    const postAction = (id, action) =>
        api.post(`/accounts/links/${id}/${action}/`);

    const approve = async (id) => {
        const link = pending.find(p => p.id === id);
        try {
            await postAction(id, "approve");
            setPending(prev => prev.filter(p => p.id !== id));
            setLinked(prev => [...prev, { ...link, status: "accepted" }]);
        } catch (err) {
            console.error("Approve failed", err);
        }
    };

    const deny = async (id) => {
        try {
            await postAction(id, "reject");
            setPending(prev => prev.filter(p => p.id !== id));
        } catch (err) {
            console.error("Deny failed", err);
        }
    };

    const unlink = async (id) => {
        try {
            await postAction(id, "reject");
            setLinked(prev => prev.filter(l => l.id !== id));
        } catch (err) {
            console.error("Unlink failed", err);
        }
    };

    const block = async (id) => {
        try {
            await postAction(id, "block");
            setPending(prev => prev.filter(p => p.id !== id));
            setLinked(prev => prev.filter(l => l.id !== id));
            alert(t("links.alertBlocked"));
        } catch (err) {
            console.error("Block failed", err);
        }
    };

    if (loading) {
        return <p>{t("common.loading")}</p>;
    }

    return (
        <div className="links-page">
            <h2>{t("links.title")}</h2>

            {/* ------------------- PENDING REQUESTS ------------------- */}
            <section className="links-section">
                <h3>{t("links.pending")}</h3>

                {pending.length === 0 ? (
                    <p className="empty">{t("links.noPending")}</p>
                ) : (
                    <table>
                        <thead>
                        <tr>
                            <th>{t("links.consumer")}</th>
                            <th>{t("links.requestedAt")}</th>
                            <th>{t("links.actions")}</th>
                        </tr>
                        </thead>
                        <tbody>
                        {pending.map(p => (
                            <tr key={p.id}>
                                <td>{getConsumerName(p.consumer)}</td>
                                <td>{formatDate(p.requested_at)}</td>
                                <td>
                                    <button className="approve-btn" onClick={() => approve(p.id)}>
                                        {t("links.approve")}
                                    </button>
                                    <button className="deny-btn" onClick={() => deny(p.id)}>
                                        {t("links.deny")}
                                    </button>
                                    <button className="block-btn" onClick={() => block(p.id)}>
                                        {t("links.block")}
                                    </button>
                                </td>
                            </tr>
                        ))}
                        </tbody>
                    </table>
                )}
            </section>

            {/* ------------------- LINKED CONSUMERS ------------------- */}
            <section className="links-section">
                <h3>{t("links.linked")}</h3>

                {linked.length === 0 ? (
                    <p className="empty">{t("links.noLinked")}</p>
                ) : (
                    <table>
                        <thead>
                        <tr>
                            <th>{t("links.consumer")}</th>
                            <th>{t("links.linkedAt")}</th>
                            <th>{t("links.actions")}</th>
                        </tr>
                        </thead>
                        <tbody>
                        {linked.map(l => (
                            <tr key={l.id}>
                                <td>{getConsumerName(l.consumer)}</td>
                                <td>{formatDate(l.requested_at)}</td>
                                <td>
                                    <button className="unlink-btn" onClick={() => unlink(l.id)}>
                                        {t("links.unlink")}
                                    </button>
                                    <button className="block-btn" onClick={() => block(l.id)}>
                                        {t("links.block")}
                                    </button>
                                </td>
                            </tr>
                        ))}
                        </tbody>
                    </table>
                )}
            </section>
        </div>
    );
}

