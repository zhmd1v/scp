import { useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import api from "../api/api";
import "./complaints.css";

export default function ComplaintDetail() {
    const { id } = useParams();
    const navigate = useNavigate();

    const [complaint, setComplaint] = useState(null);
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);

    const [status, setStatus] = useState("");
    const [severity, setSeverity] = useState("");
    const [resolution, setResolution] = useState("");

    useEffect(() => {
        async function load() {
            try {
                const res = await api.get(`/complaints/${id}/`);
                setComplaint(res.data);

                setStatus(res.data.status);
                setSeverity(res.data.severity);
            } catch (err) {
                console.error("Failed to load complaint", err);
            }
            setLoading(false);
        }
        load();
    }, [id]);


    async function updateFields() {
        setSaving(true);

        try {
            await api.post(`/complaints/${id}/status/`, {
                status,
                severity,
                resolution_note: resolution || null,
            });

            alert("Changes saved");
            navigate("/complaints");

        } catch (err) {
            console.error("Failed to update complaint", err);
            alert("Failed to update complaint");
        }

        setSaving(false);
    }

    if (loading) return <p>Loading...</p>;
    if (!complaint) return <p>Complaint not found.</p>;

    return (
        <div className="complaint-detail-page">
            <h2>Complaint #{complaint.id}</h2>

            <div className="detail-block">
                <p><strong>Title:</strong> {complaint.title}</p>
                <p><strong>Description:</strong> {complaint.description}</p>
                <p><strong>Type:</strong> {complaint.complaint_type}</p>
                <p><strong>Created At:</strong> {new Date(complaint.created_at).toLocaleString()}</p>
            </div>

            <h3>Update Complaint</h3>

            <div className="detail-form">

                {/* STATUS */}
                <label>
                    Status:
                    <select value={status} onChange={(e) => setStatus(e.target.value)}>
                        <option value="open">Open</option>
                        <option value="in_progress">In Progress</option>
                        <option value="resolved">Resolved</option>
                        <option value="closed">Closed</option>
                    </select>
                </label>

                {/* SEVERITY */}
                <label>
                    Severity:
                    <select value={severity} onChange={(e) => setSeverity(e.target.value)}>
                        <option value="low">Low</option>
                        <option value="medium">Medium</option>
                        <option value="high">High</option>
                        <option value="critical">Critical</option>
                    </select>
                </label>

                {/* RESOLUTION NOTE */}
                <label>
                    Resolution Note (optional):
                    <textarea
                        value={resolution}
                        onChange={(e) => setResolution(e.target.value)}
                        placeholder="Describe resolution..."
                    />
                </label>

                <button
                    className="save-btn"
                    onClick={updateFields}
                    disabled={saving}
                >
                    {saving ? "Saving..." : "Save Changes"}
                </button>

            </div>
        </div>
    );
}

