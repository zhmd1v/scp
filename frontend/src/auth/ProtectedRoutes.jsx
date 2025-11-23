import { Navigate, Outlet } from "react-router-dom";
import { useAuth } from "./AuthContext";

export default function ProtectedRoutes() {
    const { user } = useAuth();

    // If no user → ALWAYS redirect to login
    if (!user) return <Navigate to="/login" replace />;

    return <Outlet />;
}