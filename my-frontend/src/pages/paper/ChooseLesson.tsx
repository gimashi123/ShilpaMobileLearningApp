import { useState } from "react";
import { useNavigate } from "react-router-dom";
import * as Icons from "lucide-react";

const TeacherCreatePaper = () => {
    const navigate = useNavigate();
    const [selectedSubject, setSelectedSubject] = useState<string | null>(null);

    const subjects = [
        { 
            id: "maths", 
            name: "එකතු කිරීම ", 
            icon: Icons.Calculator,
            color: "#3b82f6",
            bgColor: "#eff6ff",
            description: "Create mathematics papers with equations and problems",
            topics: ["Algebra", "Geometry", "Arithmetic", "Trigonometry"]
        },
        { 
            id: "maths", 
            name: "අඩු කිරීම ", 
            icon: Icons.Calculator,
            color: "#3b82f6",
            bgColor: "#eff6ff",
            description: "Create mathematics papers with equations and problems",
            topics: ["Algebra", "Geometry", "Arithmetic", "Trigonometry"]
        },
         { 
            id: "maths", 
            name: "ගුණ කිරීම ", 
            icon: Icons.Calculator,
            color: "#3b82f6",
            bgColor: "#eff6ff",
            description: "Create mathematics papers with equations and problems",
            topics: ["Algebra", "Geometry", "Arithmetic", "Trigonometry"]
        },
         { 
            id: "maths", 
            name: "බෙදීම ", 
            icon: Icons.Calculator,
            color: "#3b82f6",
            bgColor: "#eff6ff",
            description: "Create mathematics papers with equations and problems",
            topics: ["Algebra", "Geometry", "Arithmetic", "Trigonometry"]
        },
        // { 
        //     id: "english", 
        //     name: "English", 
        //     icon: Icons.BookOpen,
        //     color: "#8b5cf6",
        //     bgColor: "#f5f3ff",
        //     description: "Create English language and literature papers",
        //     topics: ["Grammar", "Literature", "Comprehension", "Writing"]
        // },
        // { 
        //     id: "science", 
        //     name: "Science", 
        //     icon: Icons.FlaskConical,
        //     color: "#ec4899",
        //     bgColor: "#fdf2f8",
        //     description: "Create science papers with diagrams and experiments",
        //     topics: ["Physics", "Chemistry", "Biology", "General Science"]
        // },
        // { 
        //     id: "history", 
        //     name: "History", 
        //     icon: Icons.History,
        //     color: "#f59e0b",
        //     bgColor: "#fffbeb",
        //     description: "Create history papers with timelines and events",
        //     topics: ["World History", "Local History", "Ancient Civilizations", "Modern Era"]
        // },
        // { 
        //     id: "geography", 
        //     name: "Geography", 
        //     icon: Icons.Map,
        //     color: "#14b8a6",
        //     bgColor: "#f0fdfa",
        //     description: "Create geography papers with maps and concepts",
        //     topics: ["Physical Geography", "Human Geography", "Maps", "Environment"]
        // },
    ];

    const handleSubjectSelect = (subjectId: string) => {
        setSelectedSubject(subjectId);
        // Navigate to paper creation page with subject
        navigate(`/teacher/create-paper/${subjectId}`);
    };

    const styles = {
        container: {
            padding: "24px",
            background: "#f8fafc",
            minHeight: "100vh",
        },
        header: {
            background: "#ffffff",
            borderRadius: "16px",
            padding: "24px",
            marginBottom: "24px",
            border: "1px solid #edf2f7",
        },
        title: {
            fontSize: "1.8rem",
            fontWeight: 600,
            color: "#1e293b",
            margin: "0 0 8px 0",
        },
        subtitle: {
            fontSize: "1rem",
            color: "#64748b",
            margin: "0 0 24px 0",
        },
        grid: {
            display: "grid",
            gridTemplateColumns: "repeat(auto-fit, minmax(300px, 1fr))",
            gap: "20px",
        },
        card: {
            background: "#ffffff",
            borderRadius: "16px",
            padding: "20px",
            cursor: "pointer",
            transition: "all 0.2s",
            border: "1px solid #edf2f7",
        },
        iconContainer: {
            width: "60px",
            height: "60px",
            borderRadius: "16px",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            marginBottom: "16px",
        },
        subjectName: {
            fontSize: "1.3rem",
            fontWeight: 600,
            color: "#1e293b",
            margin: "0 0 8px 0",
        },
        subjectDescription: {
            fontSize: "0.9rem",
            color: "#64748b",
            margin: "0 0 16px 0",
            lineHeight: "1.5",
        },
        topicsContainer: {
            display: "flex",
            flexWrap: "wrap" as const,
            gap: "8px",
            marginTop: "12px",
        },
        topicTag: {
            background: "#f1f5f9",
            color: "#475569",
            padding: "4px 10px",
            borderRadius: "6px",
            fontSize: "0.75rem",
            fontWeight: 500,
        },
        backButton: {
            padding: "8px 16px",
            borderRadius: "8px",
            border: "1px solid #e2e8f0",
            background: "#ffffff",
            color: "#64748b",
            cursor: "pointer",
            display: "flex",
            alignItems: "center",
            gap: "8px",
            marginBottom: "20px",
        },
        statsCard: {
            background: "#ffffff",
            borderRadius: "12px",
            padding: "16px",
            border: "1px solid #edf2f7",
            marginTop: "24px",
        },
    };

    return (
        <div style={styles.container}>
            {/* Back Button */}
            <button
                onClick={() => navigate(-1)}
                style={styles.backButton}
                onMouseEnter={(e) => {
                    e.currentTarget.style.background = "#f8fafc";
                }}
                onMouseLeave={(e) => {
                    e.currentTarget.style.background = "#ffffff";
                }}
            >
                <Icons.ArrowLeft size={16} />
                Back to Dashboard
            </button>

            {/* Header */}
            <div style={styles.header}>
                <h1 style={styles.title}>Choose Lessons 📝</h1>
                <p style={styles.subtitle}>
                    Select a subject to start creating your exam paper. Choose from multiple subjects and customize questions.
                </p>
                
                {/* Quick Stats */}
                {/* <div style={{
                    display: "flex",
                    gap: "20px",
                    marginTop: "20px",
                }}>
                    <div style={styles.statsCard}>
                        <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
                            <Icons.FileText size={24} color="#3b82f6" />
                            <div>
                                <div style={{ fontSize: "1.5rem", fontWeight: 600, color: "#1e293b" }}>6</div>
                                <div style={{ fontSize: "0.85rem", color: "#64748b" }}>Subjects</div>
                            </div>
                        </div>
                    </div>
                    <div style={styles.statsCard}>
                        <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
                            <Icons.Clock size={24} color="#10b981" />
                            <div>
                                <div style={{ fontSize: "1.5rem", fontWeight: 600, color: "#1e293b" }}>30+</div>
                                <div style={{ fontSize: "0.85rem", color: "#64748b" }}>Templates</div>
                            </div>
                        </div>
                    </div>
                </div> */}
            </div>

            {/* Subjects Grid */}
            <div style={styles.grid}>
                {subjects.map((subject) => {
                    const IconComponent = subject.icon;
                    return (
                        <div
                            key={subject.id}
                            onClick={() => handleSubjectSelect(subject.id)}
                            style={styles.card}
                            className="subject-card"
                            onMouseEnter={(e) => {
                                e.currentTarget.style.transform = "translateY(-4px)";
                                e.currentTarget.style.boxShadow = "0 12px 24px rgba(0,0,0,0.06)";
                                e.currentTarget.style.borderColor = subject.color;
                            }}
                            onMouseLeave={(e) => {
                                e.currentTarget.style.transform = "translateY(0)";
                                e.currentTarget.style.boxShadow = "none";
                                e.currentTarget.style.borderColor = "#edf2f7";
                            }}
                        >
                            <div style={{
                                ...styles.iconContainer,
                                background: subject.bgColor,
                            }}>
                                <IconComponent size={30} color={subject.color} />
                            </div>
                            
                            <h2 style={styles.subjectName}>{subject.name}</h2>
                            <p style={styles.subjectDescription}>{subject.description}</p>
                            
                            <div style={styles.topicsContainer}>
                                {subject.topics.map((topic, index) => (
                                    <span key={index} style={styles.topicTag}>
                                        {topic}
                                    </span>
                                ))}
                            </div>

                            <div style={{
                                display: "flex",
                                justifyContent: "space-between",
                                alignItems: "center",
                                marginTop: "20px",
                                paddingTop: "16px",
                                borderTop: "1px solid #edf2f7",
                            }}>
                                <span style={{
                                    color: subject.color,
                                    fontWeight: 500,
                                    fontSize: "0.9rem",
                                }}>
                                    Create Paper →
                                </span>
                                <Icons.ChevronRight size={18} color={subject.color} />
                            </div>
                        </div>
                    );
                })}
            </div>

            {/* Add CSS for animations */}
            <style>{`
                .subject-card {
                    transition: all 0.2s ease;
                }
            `}</style>
        </div>
    );
};

export default TeacherCreatePaper;