import React, { useEffect, useMemo, useState } from "react";

type DisabilityType = "visual" | "hearing" | "physical" | "cognitive";

type Student = {
    _id: string;
    name: string;
    email: string;
    role: "student";
    student?: {
        grade?: number;
        age?: number;
    };
    disabilityType?: DisabilityType;
    createdAt?: string;
};

const StudentsPage: React.FC = () => {
    const [students, setStudents] = useState<Student[]>([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string>("");

    // Filters
    const [search, setSearch] = useState("");
    const [gradeFilter, setGradeFilter] = useState<"" | "3" | "4" | "5">("");

    const fetchStudents = async () => {
        try {
            setLoading(true);
            setError("");

            const token = localStorage.getItem("token");

            if (!token) {
                setError("Not authenticated. Please login again.");
                return;
            }

            const res = await fetch("http://localhost:3000/api/students", {
                headers: {
                    Authorization: `Bearer ${token}`,
                    "Content-Type": "application/json"
                }
            });

            const data = await res.json();

            if (!res.ok) throw new Error(data.message || "Failed to fetch students");

            setStudents(data.students || []);
        } catch (e: any) {
            setError(e.message || "Unknown error");
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchStudents();
    }, []);

    const filtered = useMemo(() => {
        return students.filter((s) => {
            const grade = s.student?.grade?.toString() || "";
            const matchGrade = gradeFilter ? grade === gradeFilter : true;

            const matchSearch =
                s.name.toLowerCase().includes(search.toLowerCase()) ||
                s.email.toLowerCase().includes(search.toLowerCase());

            return matchGrade && matchSearch;
        });
    }, [students, search, gradeFilter]);

    return (
        <div style={styles.page}>
            <div style={styles.card}>
                <h2 style={styles.title}>👩‍🎓 Students</h2>
                <p style={styles.subTitle}>Fetch all students from database</p>

                <div style={styles.controls}>
                    <input
                        style={styles.input}
                        placeholder="Search by name or email"
                        value={search}
                        onChange={(e) => setSearch(e.target.value)}
                    />

                    <select
                        style={styles.select}
                        value={gradeFilter}
                        onChange={(e) => setGradeFilter(e.target.value as any)}
                    >
                        <option value="">All Grades</option>
                        <option value="3">Grade 3</option>
                        <option value="4">Grade 4</option>
                        <option value="5">Grade 5</option>
                    </select>

                    <button style={styles.refreshBtn} onClick={fetchStudents} disabled={loading}>
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
                            <th style={styles.th}>Grade</th>
                            {/* <th style={styles.th}>Age</th> */}
                            <th style={styles.th}>Disability</th>
                        </tr>
                        </thead>
                        <tbody>
                        {!loading && filtered.length === 0 ? (
                            <tr>
                                <td style={styles.td} colSpan={5}>
                                    — No students found —
                                </td>
                            </tr>
                        ) : (
                            filtered.map((s) => (
                                <tr key={s._id}>
                                    <td style={styles.td}>{s.name}</td>
                                    <td style={styles.td}>{s.email}</td>
                                    <td style={styles.td}>
                      <span style={{ ...styles.badge, ...gradeBadge(s.student?.grade) }}>
                        {s.student?.grade ? `Grade ${s.student.grade}` : "—"}
                      </span>
                                    </td>
                                    {/* <td style={styles.td}>{s.student?.age ?? "—"}</td> */}
                                    <td style={styles.td}>{s.disabilityType ?? "—"}</td>
                                </tr>
                            ))
                        )}
                        </tbody>
                    </table>
                </div>

                <div style={styles.footer}>
                    Total students: <strong>{students.length}</strong> | Showing:{" "}
                    <strong>{filtered.length}</strong>
                </div>
            </div>
        </div>
    );
};

// ---------- Styles ----------
const styles: Record<string, React.CSSProperties> = {
    page: {
        minHeight: "100vh",
        background: "linear-gradient(135deg, #F3F4F4 0%, #F3F4F4 100%)",
        padding: "2rem",
    },
    card: {
        maxWidth: 1100,
        margin: "0 auto",
        background: "white",
        borderRadius: 18,
        padding: "2rem",
        boxShadow: "0 20px 40px rgba(0,0,0,0.15)",
    },
    title: { margin: 0, fontSize: "2rem" },
    subTitle: { marginTop: 8, color: "#666", marginBottom: "1.5rem" },
    controls: {
        display: "grid",
        gridTemplateColumns: "1fr 180px 160px",
        gap: "1rem",
        marginBottom: "1rem",
    },
    input: {
        padding: "0.8rem 1rem",
        border: "1px solid #ddd",
        borderRadius: 10,
        fontSize: "1rem",
    },
    select: {
        padding: "0.8rem 1rem",
        border: "1px solid #ddd",
        borderRadius: 10,
        fontSize: "1rem",
    },
    refreshBtn: {
        background: "linear-gradient(135deg, #F3F4F4 0%, #F3F4F4 100%)",
        color: "black",
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
    table: { width: "100%", borderCollapse: "collapse" },
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
    badge: {
        padding: "0.25rem 0.7rem",
        borderRadius: 999,
        fontSize: "0.85rem",
        fontWeight: 600,
        display: "inline-block",
    },
    footer: { marginTop: "1rem", color: "#555" },
};

function gradeBadge(grade?: number): React.CSSProperties {
    if (grade === 3) return { background: "#e8f5e9", color: "#2e7d32" };
    if (grade === 4) return { background: "#fff3e0", color: "#f57c00" };
    if (grade === 5) return { background: "#ffebee", color: "#c62828" };
    return { background: "#f1f5f9", color: "#64748b" };
}

export default StudentsPage;