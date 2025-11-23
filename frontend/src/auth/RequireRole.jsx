import { Navigate } from "react-router-dom";
import { useAuth } from "./AuthContext";

export default function RequireRole({ roles, children }) {
    const { user, isLoading } = useAuth();

    if (isLoading) {
        return <div>Loading...</div>;
    }

    if (!user) {
        return <Navigate to="/login" replace />;
    }

    // Use normalized user_type, NOT user.role
    if (!roles.includes(user.user_type)) {
        return <Navigate to="/unauthorized" replace />;
    }

    return children;
}