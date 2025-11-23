import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../auth/AuthContext";
import { useTranslation } from "react-i18next";

export default function LoginPage() {
    const { t } = useTranslation();
    const { login } = useAuth();
    const navigate = useNavigate();

    const [username, setUsername] = useState("");
    const [password, setPassword] = useState("");
    const [showPassword, setShowPassword] = useState(false);

    const handleLogin = async () => {
        const result = await login(username, password);

        if (!result.success) {
            alert("Login failed: " + JSON.stringify(result.error));
            return;
        }

        const user = result.user;

// Prefer normalized if exists
        const role = user.normalizedRole || user.user_type;

// Support both raw and normalized
        if (role === "supplier_owner" || role === "owner" || role === "platform_admin") {
            navigate("/owner");
        }
        else if (role === "supplier_manager" || role === "manager") {
            navigate("/manager");
        }
        else {
            alert("Unsupported user type: " + role);
        }
    };

    return (
        <div
            style={{
                maxWidth: "400px",
                margin: "120px auto",
                padding: "30px",
                border: "1px solid #ddd",
                borderRadius: "10px",
                textAlign: "center",
                boxShadow: "0 0 10px rgba(0,0,0,0.05)",
            }}
        >
            <h2>{t("login.title")}</h2>

            {/* Username */}
            <input
                type="text"
                placeholder={t("login.username")}
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                style={{
                    width: "100%",
                    padding: "10px",
                    marginTop: "15px",
                    borderRadius: "6px",
                    border: "1px solid #ccc"
                }}
            />

            {/* Password */}
            <input
                type={showPassword ? "text" : "password"}
                placeholder={t("login.password")}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                style={{
                    width: "100%",
                    padding: "10px",
                    marginTop: "15px",
                    borderRadius: "6px",
                    border: "1px solid #ccc"
                }}
            />

            {/* Show password */}
            <div
                style={{
                    marginTop: "10px",
                    display: "flex",
                    alignItems: "center",
                    gap: "6px"
                }}
            >
                <input
                    type="checkbox"
                    id="showpass"
                    checked={showPassword}
                    onChange={() => setShowPassword(!showPassword)}
                />
                <label htmlFor="showpass" style={{ cursor: "pointer" }}>
                    {t("login.showPassword")}
                </label>
            </div>

            {/* Login Button */}
            <button
                onClick={handleLogin}
                style={{
                    marginTop: "20px",
                    width: "100%",
                    padding: "10px",
                    background: "#2563eb",
                    color: "white",
                    border: "none",
                    borderRadius: "6px",
                    cursor: "pointer",
                    fontSize: "16px"
                }}
            >
                {t("login.button")}
            </button>

            {/* Forgot Password */}
            <button
                onClick={() => navigate("/reset-password")}
                style={{
                    marginTop: "20px",
                    width: "100%",
                    padding: "10px",
                    background: "#f3f4f6",
                    color: "#2563eb",
                    border: "1px solid #2563eb",
                    borderRadius: "6px",
                    cursor: "pointer",
                    fontSize: "16px"
                }}
            >
                {t("login.forgot")}
            </button>
        </div>
    );
}