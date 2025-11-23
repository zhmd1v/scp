import { useEffect, useRef, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { useAuth } from "../auth/AuthContext";
import api from "../api/api";
import "./chat.css";

export default function ChatThread() {
    const { id } = useParams();
    const { user } = useAuth();
    const navigate = useNavigate();
    const bottomRef = useRef(null);

    const role = user?.role;

    useEffect(() => {
        if (role === "sales") navigate("/unauthorized");
    }, [role, navigate]);

    const [messages, setMessages] = useState([]);
    const [conversationName, setConversationName] = useState("Conversation");
    const [loading, setLoading] = useState(true);

    const [text, setText] = useState("");
    const [file, setFile] = useState(null);
    const [previewUrl, setPreviewUrl] = useState(null);

    // ---------------------------
    // Load messages
    // ---------------------------
    useEffect(() => {
        async function load() {
            try {
                const res = await api.get(`/chat/conversations/${id}/messages/`);
                const msgs = res.data.map(m => convertBackendMessage(m));
                setMessages(msgs);

                setConversationName("Chat #" + id);
            } catch (err) {
                console.error("Failed to load messages", err);
            }
            setLoading(false);
        }

        load();
    }, [id]);

    function convertBackendMessage(m) {
        return {
            id: m.id,
            from: m.sender_username === user.username ? role : "consumer",
            type: m.attachment ? "attachment" : "text",
            text: m.text,
            url: m.attachment || null,
            filename: m.attachment ? m.attachment.split("/").pop() : null,
            mime: guessMime(m.attachment),
            ts: new Date(m.sent_at).getTime()
        };
    }

    function guessMime(filename) {
        if (!filename) return null;
        const ext = filename.split(".").pop().toLowerCase();
        if (["jpg", "jpeg", "png", "gif", "webp"].includes(ext)) return "image/" + ext;
        return "application/octet-stream";
    }

    // ---------------------------
    // Scroll to bottom
    // ---------------------------
    useEffect(() => {
        bottomRef.current?.scrollIntoView({ behavior: "smooth" });
    }, [messages]);

    // ---------------------------
    // Send message
    // ---------------------------
    async function sendMessage() {
        if (!text && !file) return;

        const form = new FormData();
        form.append("conversation", id);
        if (text) form.append("text", text);
        if (file) form.append("attachment", file);

        try {
            const res = await api.post(
                `/chat/conversations/${id}/messages/`,
                form,
                { headers: { "Content-Type": "multipart/form-data" } }
            );

            const newMsg = convertBackendMessage(res.data);
            setMessages(prev => [...prev, newMsg]);
        } catch (err) {
            console.error("Failed to send message", err.response?.data || err);
        }

        setText("");
        setFile(null);
        setPreviewUrl(null);
    }

    // ---------------------------
    // File selected → preview it
    // ---------------------------
    const handleFileChange = e => {
        const f = e.target.files[0];
        if (!f) return;

        setFile(f);

        // Only preview if image
        const ext = f.name.split(".").pop().toLowerCase();
        if (["jpg", "jpeg", "png", "gif", "webp"].includes(ext)) {
            setPreviewUrl(URL.createObjectURL(f));
        } else {
            setPreviewUrl(null);
        }
    };

    if (loading) return <p>Loading chat...</p>;

    return (
        <div className="chat-thread-page">
            <div className="chat-header">
                <button onClick={() => window.history.back()} className="btn-back">
                    ← Back
                </button>

                <h3>{conversationName}</h3>
            </div>

            <div className="messages-area">
                {messages.map(m => (
                    <div key={m.id} className={`message ${m.from}`}>
                        <div className="meta">
                            <span className="who">{m.from}</span>
                            <span className="ts">{new Date(m.ts).toLocaleTimeString()}</span>
                        </div>

                        {m.type === "text" && (
                            <div className="bubble">{m.text}</div>
                        )}

                        {m.type === "attachment" && (
                            <div className="bubble bubble-attachment">
                                {m.mime?.startsWith("image/") ? (
                                    <img
                                        src={m.url}
                                        alt={m.filename}
                                        className="attachment-img"
                                    />
                                ) : (
                                    <a href={m.url} download>{m.filename}</a>
                                )}
                            </div>
                        )}
                    </div>
                ))}

                <div ref={bottomRef} />
            </div>

            <div className="composer">
                <div className="composer-row">
                    <input
                        type="text"
                        placeholder="Type a message"
                        value={text}
                        onChange={e => setText(e.target.value)}
                        onKeyDown={e => e.key === "Enter" && sendMessage()}
                    />

                    <label className="attach-btn">
                        {/* accept removed → now ANY file */}
                        <input type="file" onChange={handleFileChange} />
                        <img src="/icons/attach.png" alt="attach" className="attach-icon" />
                    </label>

                    <button onClick={sendMessage} className="btn-send">
                        Send
                    </button>
                </div>

                {previewUrl && (
                    <div className="image-preview-bar">
                        <img src={previewUrl} className="preview-img" />

                        <button
                            className="remove-preview"
                            onClick={() => { setFile(null); setPreviewUrl(null); }}
                        >
                            ✖
                        </button>
                    </div>
                )}
            </div>
        </div>
    );
}
