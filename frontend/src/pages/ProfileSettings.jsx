import { useState } from "react";
import { useTranslation } from "react-i18next";
import "./profile.css";

export default function ProfileSettings() {
    const { t } = useTranslation();

    // ---- Profile Data ----
    const [profile, setProfile] = useState({
        supplierName: "GoodFood Supply LTD",
        legalName: "GoodFood Group LLP",
        address: "Almaty, Dostyk Ave 123",
        phone: "+7 701 123 4567",
        email: "support@goodfood.kz",
        logo: null
    });

    const [backup, setBackup] = useState(profile);
    const [isEditing, setIsEditing] = useState(false);

    // ---- Settings Data ----
    const [settings, setSettings] = useState({
        timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
        dateFormat: "DD/MM/YYYY",
        deliveryEnabled: true,
        pickupEnabled: true,
        leadTime: ""
    });

    const handleProfileChange = (field, value) => {
        if (!isEditing) return;
        setProfile(prev => ({ ...prev, [field]: value }));
    };

    const handleSettingsChange = (field, value) => {
        setSettings(prev => ({ ...prev, [field]: value }));
    };

    const handleLogoUpload = (e) => {
        if (!isEditing) return;
        const file = e.target.files[0];
        if (!file) return;

        const reader = new FileReader();
        reader.onload = () => {
            setProfile(prev => ({ ...prev, logo: reader.result }));
        };
        reader.readAsDataURL(file);
    };

    const saveProfile = () => {
        alert(t("profile.saved"));
        setBackup(profile);
        setIsEditing(false);
    };

    const cancelEdit = () => {
        setProfile(backup);
        setIsEditing(false);
    };

    return (
        <div className="profile-page">
            <h2>{t("profile.title")}</h2>
            <p className="subtitle">{t("profile.subtitle")}</p>

            {/* ====================== PROFILE SECTION ====================== */}
            <div className="profile-card">
                <div className="header-row">
                    <h3>{t("profile.section.supplierProfile")}</h3>

                    {!isEditing && (
                        <button className="btn-edit" onClick={() => setIsEditing(true)}>
                            {t("profile.actions.edit")}
                        </button>
                    )}
                </div>

                <div className="form-grid">
                    <label>
                        {t("profile.fields.supplierName")}
                        <input
                            type="text"
                            value={profile.supplierName}
                            onChange={e => handleProfileChange("supplierName", e.target.value)}
                            disabled={!isEditing}
                        />
                    </label>

                    <label>
                        {t("profile.fields.legalName")}
                        <input
                            type="text"
                            value={profile.legalName}
                            onChange={e => handleProfileChange("legalName", e.target.value)}
                            disabled={!isEditing}
                        />
                    </label>

                    <label>
                        {t("profile.fields.address")}
                        <input
                            type="text"
                            value={profile.address}
                            onChange={e => handleProfileChange("address", e.target.value)}
                            disabled={!isEditing}
                        />
                    </label>

                    <label>
                        {t("profile.fields.phone")}
                        <input
                            type="text"
                            value={profile.phone}
                            onChange={e => handleProfileChange("phone", e.target.value)}
                            disabled={!isEditing}
                        />
                    </label>

                    <label>
                        {t("profile.fields.email")}
                        <input
                            type="email"
                            value={profile.email}
                            onChange={e => handleProfileChange("email", e.target.value)}
                            disabled={!isEditing}
                        />
                    </label>

                    {isEditing && (
                        <label>
                            {t("profile.fields.logo")}
                            <input
                                type="file"
                                accept="image/*"
                                onChange={handleLogoUpload}
                                disabled={!isEditing}
                            />
                        </label>
                    )}
                </div>

                {!isEditing && (
                    <div className="logo-preview">
                        <h4>{t("profile.fields.logo")}</h4>
                        <img
                            src={profile.logo || "/placeholder-company-logo.png"}
                            alt="company logo"
                            className="logo-img"
                        />
                    </div>
                )}

                {isEditing && profile.logo && (
                    <div className="logo-preview">
                        <h4>{t("profile.logoPreview")}</h4>
                        <img src={profile.logo} alt="logo preview" className="logo-img" />
                    </div>
                )}

                {isEditing && (
                    <div className="edit-actions">
                        <button className="btn-save" onClick={saveProfile}>
                            {t("profile.actions.save")}
                        </button>
                        <button className="btn-cancel" onClick={cancelEdit}>
                            {t("profile.actions.cancel")}
                        </button>
                    </div>
                )}
            </div>

            {/* ====================== SETTINGS SECTION ====================== */}
            <div className="profile-card">
                <h3>{t("profile.section.settings")}</h3>

                <div className="form-grid">

                    {/* Timezone */}
                    <label>
                        {t("profile.settings.timezone")}
                        <select
                            value={settings.timezone}
                            onChange={e => handleSettingsChange("timezone", e.target.value)}
                        >
                            {Intl.supportedValuesOf("timeZone").map(tz => (
                                <option key={tz} value={tz}>{tz}</option>
                            ))}
                        </select>
                    </label>

                    {/* Date Format */}
                    <label>
                        {t("profile.settings.dateFormat")}
                        <select
                            value={settings.dateFormat}
                            onChange={e => handleSettingsChange("dateFormat", e.target.value)}
                        >
                            <option value="DD/MM/YYYY">DD/MM/YYYY</option>
                            <option value="MM/DD/YYYY">MM/DD/YYYY</option>
                            <option value="YYYY-MM-DD">YYYY-MM-DD</option>
                        </select>
                    </label>

                    {/* Delivery Enabled */}
                    <label>
                        {t("profile.settings.enableDelivery")}
                        <input
                            type="checkbox"
                            checked={settings.deliveryEnabled}
                            onChange={e => handleSettingsChange("deliveryEnabled", e.target.checked)}
                        />
                    </label>

                    {/* Pickup Enabled */}
                    <label>
                        {t("profile.settings.enablePickup")}
                        <input
                            type="checkbox"
                            checked={settings.pickupEnabled}
                            onChange={e => handleSettingsChange("pickupEnabled", e.target.checked)}
                        />
                    </label>

                    {/* Lead Time */}
                    <label>
                        {t("profile.settings.leadTime")}
                        <input
                            type="text"
                            value={settings.leadTime}
                            placeholder={t("profile.settings.leadTimePlaceholder")}
                            onChange={e => handleSettingsChange("leadTime", e.target.value)}
                        />
                    </label>

                </div>
            </div>
        </div>
    );
}
