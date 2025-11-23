import { useState, useEffect } from "react";
import { useTranslation } from "react-i18next";
import "./links.css";
import api from "../api/api"; // <-- USE AXIOS INSTANCE WITH Token AUTH

export default function LinkManagement() {
    const { t } = useTranslation();

    const [pending, setPending] = useState([]);
    const [linked, setLinked] = useState([]);
    const [loading, setLoading] = useState(true);

    // ------------------------------------
    // Load links from backend (correct)
    // ------------------------------------
    useEffect(() => {
        async function loadLinks() {
            try {
                const res = await api.get("/accounts/links/");
                const data = res.data;

                console.log("Links:", data);

                setPending(data.filter(l => l.status === "pending"));
                setLinked(data.filter(l => l.status === "accepted"));
            } catch (err) {
                console.error("Failed to load links", err);
            }
            setLoading(false);
        }

        loadLinks();
    }, []);

    // ------------------------------------
    // API ACTIONS (correct)
    // ------------------------------------
    const postAction = async (id, action) => {
        await api.post(`/accounts/links/${id}/${action}/`);
    };

    const approve = async (id) => {
        await postAction(id, "approve");
        const link = pending.find(p => p.id === id);

        setPending(pending.filter(p => p.id !== id));
        setLinked([...linked, { ...link, status: "accepted" }]);
    };

    const deny = async (id) => {
        await postAction(id, "reject");
        setPending(pending.filter(p => p.id !== id));
    };

    const unlink = async (id) => {
        await postAction(id, "reject");
        setLinked(linked.filter(l => l.id !== id));
    };

    const block = async (id) => {
        await postAction(id, "block");

        setPending(pending.filter(p => p.id !== id));
        setLinked(linked.filter(l => l.id !== id));

        alert(t("links.alertBlocked"));
    };

    if (loading) return <p>{t("loading")}</p>;

    return (
        <div className="links-page">
            <h2>{t("links.title")}</h2>

            {/* ---------------- PENDING ---------------- */}
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
                                <td>{p.consumer}</td>
                                <td>{new Date(p.requested_at).toLocaleDateString()}</td>
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

            {/* ---------------- LINKED ---------------- */}
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
                                <td>{l.consumer}</td>
                                <td>{new Date(l.requested_at).toLocaleDateString()}</td>
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

