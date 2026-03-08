import React, { useEffect, useMemo, useState } from "react";

type Parent = {
    _id: string;
    name: string;
    email: string;
    role: "parent";
    createdAt?: string;
};

const ParentsPage: React.FC = () => {
    const [parents, setParents] = useState<Parent[]>([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState("");
    const [search, setSearch] = useState("");

    const fetchParents = async () => {
        try {
            setLoading(true);
            setError("");

            const token = localStorage.getItem("token");

            if (!token) {
                setError("Not authenticated. Please login again.");
                return;
            }

            const res = await fetch("http://localhost:3000/api/parents", {
                headers: {
                    Authorization: `Bearer ${token}`,
                    "Content-Type": "application/json",
                },
            });

            const data = await res.json();

            if (!res.ok)
                throw new Error(data.message || "Failed to fetch parents");

            setParents(data.parents || []);
        } catch (e: any) {
            setError(e.message || "Unknown error");
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchParents();
    }, []);

    const filtered = useMemo(() => {
        return parents.filter(
            (p) =>
                p.name.toLowerCase().includes(search.toLowerCase()) ||
                p.email.toLowerCase().includes(search.toLowerCase())
        );
    }, [parents, search]);

    return (
        <div style={styles.page}>
            <div style={styles.card}>
                <h2 style={styles.title}>👨‍👩‍👧 Parents</h2>
                <p style={styles.subTitle}>Fetch all parents from database</p>

                <div style={styles.controls}>
                    <input
                        style={styles.input}
                        placeholder="Search by name or email"
                        value={search}
                        onChange={(e) => setSearch(e.target.value)}
                    />

                    <button
                        style={styles.refreshBtn}
                        onClick={fetchParents}
                        disabled={loading}
                    >
                        {loading ? "Loading..." : "🔄 Refresh"}
                    </button>
                </div>

                {error && <div style={styles.error}>❌ {error}</div>}

                <div style={{ overflowX: "auto" }}>
                    <table style={styles.table}>
                        <thead>
                        <tr>
                            <th style={styles.th}>Name</th>
                            <th style={styles.th}>Email</th>
                            <th style={styles.th}>Created</th>
                        </tr>
                        </thead>
                        <tbody>
                        {!loading && filtered.length === 0 ? (
                            <tr>
                                <td style={styles.td} colSpan={3}>
                                    — No parents found —
                                </td>
                            </tr>
                        ) : (
                            filtered.map((p) => (
                                <tr key={p._id}>
                                    <td style={styles.td}>{p.name}</td>
                                    <td style={styles.td}>{p.email}</td>
                                    <td style={styles.td}>
                                        {p.createdAt
                                            ? new Date(p.createdAt).toLocaleDateString()
                                            : "—"}
                                    </td>
                                </tr>
                            ))
                        )}
                        </tbody>
                    </table>
                </div>

                <div style={styles.footer}>
                    Total parents: <strong>{parents.length}</strong>
                </div>
            </div>
        </div>
    );
};

// ---------- Styles ----------
const styles: Record<string, React.CSSProperties> = {
    page: {
        minHeight: "100vh",
        background: "linear-gradient(135deg, #667eea 0%, #764ba2 100%)",
        padding: "2rem",
    },
    card: {
        maxWidth: 1000,
        margin: "0 auto",
        background: "white",
        borderRadius: 18,
        padding: "2rem",
        boxShadow: "0 20px 40px rgba(0,0,0,0.15)",
    },
    title: {
        margin: 0,
        fontSize: "2rem",
    },
    subTitle: {
        marginTop: 8,
        color: "#666",
        marginBottom: "1.5rem",
    },
    controls: {
        display: "grid",
        gridTemplateColumns: "1fr 160px",
        gap: "1rem",
        marginBottom: "1rem",
    },
    input: {
        padding: "0.8rem 1rem",
        border: "1px solid #ddd",
        borderRadius: 10,
        fontSize: "1rem",
    },
    refreshBtn: {
        background: "linear-gradient(135deg, #667eea 0%, #764ba2 100%)",
        color: "white",
        border: "none",
        borderRadius: 10,
        fontSize: "1rem",
        fontWeight: 600,
        cursor: "pointer",
    },
    error: {
        background: "#ffecec",
        color: "#b00020",
        padding: "0.8rem 1rem",
        borderRadius: 10,
        marginBottom: "1rem",
        border: "1px solid #ffb4b4",
    },
    table: {
        width: "100%",
        borderCollapse: "collapse",
    },
    th: {
        textAlign: "left",
        padding: "0.75rem",
        borderBottom: "2px solid #eee",
        fontSize: "0.9rem",
        color: "#555",
    },
    td: {
        padding: "0.75rem",
        borderBottom: "1px solid #f2f2f2",
    },
    footer: {
        marginTop: "1rem",
        color: "#555",
    },
};

export default ParentsPage;