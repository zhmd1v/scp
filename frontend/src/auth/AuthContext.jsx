import { createContext, useContext, useState, useEffect } from "react";
import api from "../api/api";
import { normalizeRole } from "./roleUtils";

const AuthContext = createContext();

export function AuthProvider({ children }) {
    const [user, setUser] = useState(null);
    const [token, setToken] = useState(null);
    const [isLoading, setIsLoading] = useState(true);

    useEffect(() => {
        const savedUser = localStorage.getItem("user");
        const savedToken = localStorage.getItem("token");

        if (savedUser && savedToken) {
            const parsedUser = JSON.parse(savedUser);

            // Normalize role on reload
            parsedUser.user_type = normalizeRole(parsedUser.user_type);

            setUser(parsedUser);
            setToken(savedToken);
        }

        setIsLoading(false);
    }, []);

    // ---------------------------
    // LOGIN FUNCTION
    // ---------------------------
    const login = async (username, password) => {
        try {
            // 1. Get token
            const res = await api.post("/auth/token/", { username, password });
            const token = res.data.token;

            setToken(token);
            localStorage.setItem("token", token);

            // 2. Fetch user info
            const me = await api.get("/accounts/me/", {
                headers: { Authorization: `Token ${token}` }
            });

            // Normalize user role
            const normalizedUser = {
                ...me.data,
                user_type: normalizeRole(me.data.user_type),
            };

            setUser(normalizedUser);
            localStorage.setItem("user", JSON.stringify(normalizedUser));

            return { success: true, user: normalizedUser };
        } catch (err) {
            return { success: false, error: err.response?.data };
        }
    };

    // ---------------------------
    // LOGOUT
    // ---------------------------
    const logout = () => {
        setUser(null);
        setToken(null);
        localStorage.removeItem("user");
        localStorage.removeItem("token");
    };

    return (
        <AuthContext.Provider value={{ user, token, login, logout, isLoading }}>
            {children}
        </AuthContext.Provider>
    );
}

export function useAuth() {
    return useContext(AuthContext);
}
