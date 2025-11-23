import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { useTranslation } from "react-i18next";
import api from "../api/api";
import "./complaints.css";

export default function ComplaintsList() {
    const { t } = useTranslation();

    const [complaints, setComplaints] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        async function load() {
            try {
                const res = await api.get("/complaints/");
                setComplaints(res.data);
            } catch (err) {
                console.error(t("complaints.error_load"), err);
            }
            setLoading(false);
        }
        load();
    }, [t]);

    if (loading) return <p>{t("common.loading")}</p>;

    // Group by backend statuses
    const open = complaints.filter(c => c.status === "open");
    const inProgress = complaints.filter(c => c.status === "in_progress");
    const resolved = complaints.filter(c => c.status === "resolved");
    const closed = complaints.filter(c => c.status === "closed");

    return (
        <div className="complaints-page">
            <h2>{t("complaints.title")}</h2>

            <Section title={t("complaints.open")} items={open} />
            <Section title={t("complaints.in_progress")} items={inProgress} />
            <Section title={t("complaints.resolved")} items={resolved} />
            <Section title={t("complaints.closed")} items={closed} />
        </div>
    );
}

function Section({ title, items }) {
    const { t } = useTranslation();

    return (
        <section className="complaints-section">
            <h3>{title}</h3>

            {items.length === 0 ? (
                <p className="empty">{t("complaints.none")}</p>
            ) : (
                <table>
                    <thead>
                    <tr>
                        <th>{t("complaints.id")}</th>
                        <th>{t("complaints.title_col")}</th>
                        <th>{t("complaints.type")}</th>
                        <th>{t("complaints.severity")}</th>
                        <th>{t("complaints.created")}</th>
                        <th>{t("complaints.status")}</th>
                        <th>{t("common.actions")}</th>
                    </tr>
                    </thead>
                    <tbody>
                    {items.map(c => (
                        <tr key={c.id}>
                            <td>{c.id}</td>
                            <td>{c.title}</td>
                            <td>{c.complaint_type}</td>
                            <td>{c.severity}</td>
                            <td>{new Date(c.created_at).toLocaleString()}</td>
                            <td>{c.status}</td>
                            <td>
                                <Link className="view-btn" to={`/complaints/${c.id}`}>
                                    {t("common.view")}
                                </Link>
                            </td>
                        </tr>
                    ))}
                    </tbody>
                </table>
            )}
        </section>
    );
}
