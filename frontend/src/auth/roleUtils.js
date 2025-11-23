export function normalizeRole(userType) {
    switch (userType) {

        // Raw backend values
        case "supplier_owner":
        case "platform_admin":
            return "owner";

        case "supplier_manager":
            return "manager";

        case "salesman":
        case"supplier_sales":
            return "sales";

        // Already normalized values — keep them!
        case "owner":
        case "manager":
        case "sales":
            return userType;

        default:
            return "unknown";
    }
}