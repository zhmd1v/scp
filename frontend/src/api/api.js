import axios from "axios";

const api = axios.create({
    baseURL: "http://localhost:8000/api",
});

api.interceptors.request.use((config) => {
    const token = localStorage.getItem("token"); // <-- your real token key
    if (token) {
        config.headers.Authorization = `Token ${token}`; // <-- not Bearer
    }
    return config;
});

export default api;