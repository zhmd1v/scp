import { useState } from "react";
import { useTranslation } from "react-i18next";

export default function ResetPassword() {
    const { t } = useTranslation();
    const [email, setEmail] = useState("");

    const handleSubmit = () => {
        alert(`${t("auth.resetEmailSent")} ${email}`);
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
            <h2>{t("auth.resetPassword")}</h2>
            <p>{t("auth.resetPasswordDescription")}</p>

            <input
                type="email"
                placeholder={t("auth.email")}
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                style={{
                    width: "100%",
                    padding: "10px",
                    marginTop: "15px",
                    borderRadius: "6px",
                    border: "1px solid #ccc"
                }}
            />

            <button
                onClick={handleSubmit}
                style={{
                    marginTop: "20px",
                    width: "100%",
                    padding: "10px",
                    background: "#2563eb",
                    color: "white",
                    border: "none",
                    borderRadius: "6px",
                    cursor: "pointer",
                }}
            >
                {t("auth.sendResetEmail")}
            </button>
        </div>
    );
}