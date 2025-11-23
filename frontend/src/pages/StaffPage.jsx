// Place your updated JSX code here. Provide the original file so I can insert all translations properly.
import { useAuth } from "../auth/AuthContext";
import { useState, useEffect } from "react";
import { useTranslation } from "react-i18next";
import api from "../api/api";
import "./staff.css";
import { normalizeRole } from "../auth/roleUtils";

export default function StaffPage() {
    const { user } = useAuth();
    const { t } = useTranslation();

    const [staff, setStaff] = useState([]);
    const [loading, setLoading] = useState(true);

    // supplier id of logged in user
    const [supplierId, setSupplierId] = useState(null);

    // EDIT MODAL
    const [editingMember, setEditingMember] = useState(null);
    const [editPosition, setEditPosition] = useState("");

    const [editUserData, setEditUserData] = useState({
        first_name: "",
        last_name: "",
        username: "",
        email: "",
    });



    // CREATE MODAL
    const [showCreateModal, setShowCreateModal] = useState(false);

    const [newUserData, setNewUserData] = useState({
        first_name: "",
        last_name: "",
        username: "",
        email: "",
        password: "",
        user_type: "",
    });

    const [newPosition, setNewPosition] = useState("");

    const currentRole = normalizeRole(user.user_type);
    const isOwner = currentRole === "owner";
    const isManager = currentRole === "manager";
    const isAdmin = false;

    useEffect(() => {
        loadStaff();
    }, []);

    const loadStaff = async () => {
        try {
            const res = await api.get("/accounts/staff/");
            const staffList = res.data;

            console.log("RAW STAFF FROM API:", staffList);
            setStaff(staffList);

            // ------------------------------
            // NEW: detect logged-in user staff profile
            // ------------------------------
            const myStaffProfile = staffList.find(
                (m) => m.user?.id === user?.id
            );

            if (myStaffProfile) {
                console.log("FOUND supplier ID:", myStaffProfile.supplier_id);
                setSupplierId(myStaffProfile.supplier_id);
            } else {
                console.warn("Logged-in user has NO staff profile!");
            }

        } catch (err) {
            console.error("Failed to load staff", err);
        } finally {
            setLoading(false);
        }
    };

    const canEditOrDelete = (member) => {
        const targetRole = normalizeRole(member.user.user_type);
        console.log("CHECK PERMISSIONS → currentUser:", currentRole, "target:", targetRole);

        if (isAdmin) return true;
        if (isOwner) return targetRole === "manager" || targetRole === "sales";
        if (isManager) return targetRole === "sales";

        return false;
    };

    const openEditModal = (member) => {
        setEditingMember(member);
        setEditPosition(member.position || "");

        setEditUserData({
            first_name: member.user.first_name,
            last_name: member.user.last_name,
            username: member.user.username,
            email: member.user.email,
        });
    };

    const saveEdit = async () => {
        try {
            await api.patch(`/accounts/staff/${editingMember.id}/`, {
                position: editPosition,
            });

            await api.patch(`/accounts/users/${editingMember.user.id}/`, editUserData);

            setStaff((prev) =>
                prev.map((m) =>
                    m.id === editingMember.id
                        ? {
                            ...m,
                            position: editPosition,
                            user: { ...m.user, ...editUserData },
                        }
                        : m
                )
            );

            closeModal();
        } catch (err) {
            console.error("Failed to update staff or user", err);
        }
    };

    const deleteStaff = async (memberId) => {
        if (!window.confirm("Are you sure you want to delete this staff member?")) return;

        try {
            await api.delete(`/accounts/staff/${memberId}/`);
            setStaff((prev) => prev.filter((m) => m.id !== memberId));
        } catch (err) {
            console.error("Failed to delete staff member", err);
        }
    };

    const closeModal = () => {
        setEditingMember(null);
        setEditPosition("");
        setEditUserData({
            first_name: "",
            last_name: "",
            username: "",
            email: "",
        });
    };

    const getAllowedUserTypes = () => {
        if (isOwner) {
            return [
                { value: "supplier_manager", label: "Manager" },
                { value: "supplier_sales", label: "Salesman" },
            ];
        }
        if (isManager) {
            return [{ value: "supplier_sales", label: "Salesman" }];
        }
        return [];
    };

    const createStaff = async () => {
        const payload = {
            username: newUserData.username,
            email: newUserData.email,
            password: newUserData.password,
            first_name: newUserData.first_name,
            last_name: newUserData.last_name,
            phone: "",
            user_type: newUserData.user_type,
            position: newPosition,
            supplier_id: supplierId,
        };

        console.log("Sending payload to /accounts/staff/create/", payload);

        const res = await api.post("/accounts/staff/create/", payload);

        // Backend now returns the staff object directly
        const created = res.data;

        // Add to UI
        await loadStaff();

        // Reset fields
        setNewUserData({
            first_name: "",
            last_name: "",
            username: "",
            email: "",
            password: "",
            user_type: "",
        });

        setNewPosition("");
        setShowCreateModal(false);
    };

    return (
        <div className="staff-container">
            <h2>{t("staff.title")}</h2>

            <div className="create-staff-header">
                {(isOwner || isManager) && (
                    <button
                        className="create-btn"
                        onClick={() => {
                            const allowed = getAllowedUserTypes();
                            setNewUserData((u) => ({ ...u, user_type: allowed[0].value }));
                            setShowCreateModal(true);
                        }}
                    >
                        + Create Staff
                    </button>
                )}
            </div>

            <hr />

            {loading ? (
                <p>{t("global.loading")}...</p>
            ) : staff.length === 0 ? (
                <p>{t("staff.noStaff")}</p>
            ) : (
                <table className="staff-table">
                    <thead>
                    <tr>
                        <th>ID</th>
                        <th>{t("staff.firstName")}</th>
                        <th>{t("staff.lastName")}</th>
                        <th>{t("staff.username")}</th>
                        <th>{t("staff.email")}</th>
                        <th>User Type</th>
                        <th>{t("staff.actions")}</th>
                    </tr>
                    </thead>

                    <tbody>
                    {staff.map((member) => (
                        <tr key={member.id}>
                            <td>{member.id}</td>
                            <td>{member.user.first_name}</td>
                            <td>{member.user.last_name}</td>
                            <td>{member.user.username}</td>
                            <td>{member.user.email}</td>
                            <td>{normalizeRole(member.user.user_type)}</td>

                            <td>
                                {canEditOrDelete(member) ? (
                                    <>
                                        <button className="edit-btn" onClick={() => openEditModal(member)}>
                                            {t("staff.edit")}
                                        </button>

                                        <button className="delete-btn" onClick={() => deleteStaff(member.id)}>
                                            {t("staff.delete")}
                                        </button>
                                    </>
                                ) : (
                                    <span className="no-actions">—</span>
                                )}
                            </td>
                        </tr>
                    ))}
                    </tbody>
                </table>
            )}

            {/* EDIT MODAL */}
            {editingMember && (
                <div className="modal-overlay">
                    <div className="modal">
                        <h3>Edit Staff #{editingMember.id}</h3>

                        <label>First Name:</label>
                        <input
                            type="text"
                            value={editUserData.first_name}
                            onChange={(e) =>
                                setEditUserData((u) => ({ ...u, first_name: e.target.value }))
                            }
                        />

                        <label>Last Name:</label>
                        <input
                            type="text"
                            value={editUserData.last_name}
                            onChange={(e) =>
                                setEditUserData((u) => ({ ...u, last_name: e.target.value }))
                            }
                        />

                        <label>Username:</label>
                        <input
                            type="text"
                            value={editUserData.username}
                            onChange={(e) =>
                                setEditUserData((u) => ({ ...u, username: e.target.value }))
                            }
                        />

                        <label>Email:</label>
                        <input
                            type="email"
                            value={editUserData.email}
                            onChange={(e) =>
                                setEditUserData((u) => ({ ...u, email: e.target.value }))
                            }
                        />

                        <label>User Type:</label>
                        <input
                            type="text"
                            value={editPosition}
                            onChange={(e) => setEditPosition(e.target.value)}
                        />

                        <div className="modal-actions">
                            <button onClick={saveEdit} className="save-btn">Save</button>
                            <button onClick={closeModal} className="cancel-btn">Cancel</button>
                        </div>
                    </div>
                </div>
            )}

            {/* CREATE STAFF MODAL */}
            {showCreateModal && (
                <div className="modal-overlay">
                    <div className="modal">
                        <h3>Create New Staff</h3>

                        <label>First Name:</label>
                        <input
                            type="text"
                            value={newUserData.first_name}
                            onChange={(e) =>
                                setNewUserData((u) => ({ ...u, first_name: e.target.value }))
                            }
                        />

                        <label>Last Name:</label>
                        <input
                            type="text"
                            value={newUserData.last_name}
                            onChange={(e) =>
                                setNewUserData((u) => ({ ...u, last_name: e.target.value }))
                            }
                        />

                        <label>Username:</label>
                        <input
                            type="text"
                            value={newUserData.username}
                            onChange={(e) =>
                                setNewUserData((u) => ({ ...u, username: e.target.value }))
                            }
                        />

                        <label>Email:</label>
                        <input
                            type="email"
                            value={newUserData.email}
                            onChange={(e) =>
                                setNewUserData((u) => ({ ...u, email: e.target.value }))
                            }
                        />

                        <label>Password:</label>
                        <input
                            type="password"
                            value={newUserData.password}
                            onChange={(e) =>
                                setNewUserData((u) => ({ ...u, password: e.target.value }))
                            }
                        />

                        <label>User Type:</label>
                        <select
                            value={newUserData.user_type}
                            onChange={(e) =>
                                setNewUserData((u) => ({ ...u, user_type: e.target.value }))
                            }
                        >
                            {getAllowedUserTypes().map((opt) => (
                                <option key={opt.value} value={opt.value}>
                                    {opt.label}
                                </option>
                            ))}
                        </select>

                        <label>Position:</label>
                        <input
                            type="text"
                            value={newPosition}
                            onChange={(e) => setNewPosition(e.target.value)}
                        />

                        <div className="modal-actions">
                            <button onClick={createStaff} className="save-btn">
                                Create
                            </button>
                            <button
                                onClick={() => setShowCreateModal(false)}
                                className="cancel-btn"
                            >
                                Cancel
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}

