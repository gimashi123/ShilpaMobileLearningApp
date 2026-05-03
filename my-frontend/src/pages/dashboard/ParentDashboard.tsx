import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import * as Icons from "lucide-react";

import StudentsPage from "../StudentPage.tsx";
import TeachersPage from "../TeacherPage.tsx";
import ParentsPage from "../ParentsPage.tsx";


type User = {
  id: string;
  name: string;
  email: string;
  role: string;
};

// ✅ Backend base URL
const API_BASE = "http://localhost:3000";

// ================= STYLES =================
const styles = {
  container: {
    minHeight: "100vh",
    background: "#f8fafc", // Soft gray background
    padding: "24px",
    fontFamily: "'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
  },
  header: {
    background: "#ffffff",
    borderRadius: "16px",
    padding: "16px 24px",
    marginBottom: "24px",
    display: "flex",
    justifyContent: "space-between",
    alignItems: "center",
    boxShadow: "0 2px 8px rgba(0,0,0,0.04)",
    border: "1px solid #edf2f7",
  },
  headerTitle: {
    margin: 0,
    fontSize: "1.5rem",
    fontWeight: 600,
    color: "#1e293b",
    letterSpacing: "-0.3px",
    display: "flex",
    alignItems: "center",
    gap: "8px",
  },
  userInfo: {
    display: "flex",
    alignItems: "center",
    gap: "20px",
  },
  userDetails: {
    textAlign: "right" as const,
  },
  userName: {
    display: "block",
    fontWeight: 600,
    color: "#1e293b",
    fontSize: "0.95rem",
  },
  userRole: {
    fontSize: "0.7rem",
    color: "#64748b",
    textTransform: "uppercase" as const,
    letterSpacing: "0.3px",
  },
  logoutBtn: {
    padding: "8px 20px",
    borderRadius: "8px",
    border: "1px solid #e2e8f0",
    background: "#ffffff",
    color: "#ef4444",
    cursor: "pointer",
    fontWeight: 500,
    fontSize: "0.9rem",
    transition: "all 0.2s",
    display: "flex",
    alignItems: "center",
    gap: "8px",

  },
  sidebar: {
    background: "#ffffff",
    borderRadius: "16px",
    padding: "20px",
    boxShadow: "0 2px 8px rgba(0,0,0,0.04)",
    border: "1px solid #edf2f7",
  },
  sidebarTitle: {
    marginBottom: "16px",
    color: "#1e293b",
    fontSize: "1rem",
    fontWeight: 600,
    paddingBottom: "12px",
    borderBottom: "1px solid #edf2f7",
    display: "flex",
    alignItems: "center",
    gap: "8px",
  },
  menuItem: {
    width: "100%",
    textAlign: "left" as const,
    padding: "12px 14px",
    border: "none",
    borderRadius: "10px",
    marginBottom: "4px",
    cursor: "pointer",
    fontSize: "14px",
    fontWeight: 500,
    transition: "all 0.2s",
    display: "flex",
    alignItems: "center",
    gap: "12px",
  },
  welcomeCard: {
    background: "#ffffff",
    borderRadius: "16px",
    padding: "24px",
    marginBottom: "24px",
    boxShadow: "0 2px 8px rgba(0,0,0,0.04)",
    border: "1px solid #edf2f7",
  },
  welcomeTitle: {
    fontSize: "1.5rem",
    fontWeight: 600,
    marginBottom: "8px",
    color: "#1e293b",
  },
  welcomeText: {
    fontSize: "0.95rem",
    color: "#64748b",
    marginBottom: "20px",
    lineHeight: "1.6",
  },
  cardGrid: {
    display: "grid",
    gridTemplateColumns: "repeat(auto-fit, minmax(260px, 1fr))",
    gap: "20px",
  },
  card: {
    background: "#ffffff",
    borderRadius: "14px",
    padding: "20px",
    boxShadow: "0 2px 8px rgba(0,0,0,0.04)",
    cursor: "pointer",
    transition: "all 0.2s",
    border: "1px solid #edf2f7",
    position: "relative" as const,
    overflow: "hidden" as const,
  },
  cardIcon: {
    width: "48px",
    height: "48px",
    borderRadius: "12px",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    marginBottom: "16px",
  },
  cardTitle: {
    fontSize: "1.1rem",
    fontWeight: 600,
    color: "#1e293b",
    marginBottom: "6px",
  },
  cardDescription: {
    color: "#64748b",
    fontSize: "0.85rem",
    marginBottom: "16px",
    lineHeight: "1.5",
  },
  cardFooter: {
    display: "flex",
    justifyContent: "space-between",
    alignItems: "center",
    marginTop: "8px",
  },
  cardBadge: {
    background: "#f1f5f9",
    color: "#475569",
    padding: "4px 10px",
    borderRadius: "6px",
    fontSize: "0.75rem",
    fontWeight: 500,
  },
  loadingContainer: {
    minHeight: "100vh",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    background: "#f8fafc",
  },
  loadingCard: {
    background: "#ffffff",
    padding: "40px",
    borderRadius: "16px",
    boxShadow: "0 4px 12px rgba(0,0,0,0.05)",
    textAlign: "center" as const,
  },
  spinner: {
    width: "40px",
    height: "40px",
    border: "3px solid #f1f5f9",
    borderTopColor: "#3b82f6",
    borderRadius: "50%",
    animation: "spin 0.8s linear infinite",
    margin: "0 auto 20px",
  },
  chip: {
    background: "#f8fafc",
    padding: "6px 14px",
    borderRadius: "8px",
    fontSize: "0.85rem",
    color: "#475569",
    display: "flex",
    alignItems: "center",
    gap: "6px",
    border: "1px solid #e2e8f0",
  },
  avatar: {
    width: "40px",
    height: "40px",
    borderRadius: "10px",
    background: "#f1f5f9",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    color: "#475569",
    fontWeight: 600,
    fontSize: "1rem",
    marginRight: "12px",
  },
};

// Add CSS animations
const styleSheet = document.createElement('style');
styleSheet.textContent = `
    @keyframes spin {
        0% { transform: rotate(0deg); }
        100% { transform: rotate(360deg); }
    }
    .dashboard-card:hover {
        transform: translateY(-2px);
        box-shadow: 0 8px 16px rgba(0,0,0,0.06);
        border-color: #cbd5e1;
    }
    .menu-item:hover {
        background: #f8fafc;
    }
    .logout-btn:hover {
        background: #fef2f2;
        border-color: #fecaca;
    }
`;
document.head.appendChild(styleSheet);

const Dashboard = () => {
  const [isMobile, setIsMobile] = useState(false);
  const [activeTab, setActiveTab] = useState("overview");

  const [user, setUser] = useState<User | null>(null);
  const [loadingUser, setLoadingUser] = useState(true);

  const navigate = useNavigate();

  useEffect(() => {
    const checkMobile = () => setIsMobile(window.innerWidth <= 768);
    checkMobile();
    window.addEventListener("resize", checkMobile);
    return () => window.removeEventListener("resize", checkMobile);
  }, []);

  useEffect(() => {
    const fetchProfile = async () => {
      try {
        const token = localStorage.getItem("token");

        if (!token) {
          navigate("/login", { replace: true });
          return;
        }

        const res = await fetch(`${API_BASE}/api/auth/me`, {
          method: "GET",
          headers: {
            Authorization: `Bearer ${token}`,
          },
        });

        if (!res.ok) {
          localStorage.removeItem("token");
          navigate("/login", { replace: true });
          return;
        }

        const json = await res.json();
        const profile = json.data;

        setUser({
          id: profile.id,
          name: profile.name,
          email: profile.email,
          role: profile.role,
        });
      } catch {
        localStorage.removeItem("token");
        navigate("/login", { replace: true });
      } finally {
        setLoadingUser(false);
      }
    };

    fetchProfile();
  }, [navigate]);

  const quickMenuItems = [
    { id: "overview", label: "Overview", icon: Icons.LayoutDashboard, description: "Dashboard home", color: "#3b82f6" },
    { id: "progress", label: "View Progress", icon: Icons.TrendingUp, description: "Track student performance", color: "#8b5cf6" },
    { id: "messages", label: "Messages", icon: Icons.MessageSquare, description: "Communications", color: "#f59e0b" },
    { id: "papers", label: "My Papers", icon: Icons.FileText, description: "Generated assessments", color: "#ec4899" },
    { id: "settings", label: "Settings", icon: Icons.Settings, description: "Preferences", color: "#64748b" },
  ];

  const dashboardCards = [
    {
      title: "View Progress",
      icon: Icons.TrendingUp,
      description: "Track student performance",
      path: "/progress-view",
      color: "#8b5cf6",
      bgColor: "#f5f3ff"
    },
    {
      title: "Create Paper",
      icon: Icons.FileText,
      description: "Build assessments",
      path: "/paper-create",
      color: "#14b8a6",
      bgColor: "#f0fdfa"
    },
  ];

  const handleLogout = () => {
    localStorage.removeItem("token");
    navigate("/login", { replace: true });
  };

  const renderIcon = (IconComponent: any, size: number = 18, color: string = "currentColor") => {
    return <IconComponent size={size} color={color} />;
  };

  if (loadingUser) {
    return (
        <div style={styles.loadingContainer}>
          <div style={styles.loadingCard}>
            <div style={styles.spinner}></div>
            <h3 style={{ color: "#1e293b", marginBottom: "8px", fontSize: "1.1rem" }}>Loading Dashboard</h3>
            <p style={{ color: "#64748b", fontSize: "0.9rem" }}>Please wait a moment...</p>
          </div>
        </div>
    );
  }

  if (!user) return null;

  return (
      <div style={styles.container}>
        {/* ================= HEADER ================= */}
        <div style={styles.header}>
          <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
            <div style={styles.avatar}>
              {renderIcon(Icons.LayoutDashboard, 20, "#3b82f6")}
            </div>
            <h2 style={styles.headerTitle}>Parent Dashboard</h2>
          </div>

          <div style={styles.userInfo}>
            <div style={styles.userDetails}>
              <strong style={styles.userName}>{user.name}</strong>
              <span style={styles.userRole}>{user.role}</span>
            </div>

            <button
                onClick={handleLogout}
                className="logout-btn"
                style={styles.logoutBtn}

            >
              {renderIcon(Icons.LogOut, 16, "#ef4444")}
              Sign Out
            </button>
          </div>
        </div>

        {/* ================= MAIN LAYOUT ================= */}
        <div
            style={{
              display: "grid",
              gridTemplateColumns: isMobile ? "1fr" : "240px 1fr",
              gap: "24px",
            }}
        >
          {/* ================= SIDEBAR ================= */}
          <div style={styles.sidebar}>
            <div style={styles.sidebarTitle}>
              {renderIcon(Icons.Menu, 16, "#64748b")}
              Quick Menu
            </div>

            {quickMenuItems.map((item) => {
              const isActive = activeTab === item.id;
              return (
                            <button
                                key={item.id}
                                onClick={() => {
                                    if (item.id === "progress") navigate("/progress-view");
                                    else setActiveTab(item.id);
                                }}
                                className="menu-item"
                      style={{
                        ...styles.menuItem,
                        background: isActive ? "#f1f5f9" : "transparent",
                      }}
                  >
                    <div style={{
                      width: "32px",
                      height: "32px",
                      borderRadius: "8px",
                      background: isActive ? item.color : "#f1f5f9",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                    }}>
                      {renderIcon(item.icon, 16, isActive ? "#ffffff" : "#64748b")}
                    </div>
                    <div style={{ flex: 1 }}>
                      <div style={{
                        fontWeight: isActive ? 600 : 500,
                        color: isActive ? "#1e293b" : "#475569"
                      }}>
                        {item.label}
                      </div>
                      <div style={{
                        fontSize: "0.7rem",
                        color: "#94a3b8",
                        marginTop: "2px",
                      }}>
                        {item.description}
                      </div>
                    </div>
                    {isActive && (
                        <div style={{
                          width: "3px",
                          height: "24px",
                          background: item.color,
                          borderRadius: "3px",
                        }} />
                    )}
                  </button>
              );
            })}
          </div>

          {/* ================= RIGHT PANEL ================= */}
          <div>
            {activeTab === "overview" && (
                <>
                  {/* Welcome Card */}
                  <div style={styles.welcomeCard}>
                    <div style={{ display: "flex", alignItems: "center", gap: "8px", marginBottom: "12px" }}>
                      {renderIcon(Icons.Waves, 20, "#3b82f6")}
                      <h1 style={styles.welcomeTitle}>Welcome back, {user.name}!</h1>
                    </div>
                    <p style={styles.welcomeText}>
                      Continue your learning journey with personalized lessons, track your progress,
                      and unlock new achievements today!
                    </p>
                    <div style={{
                      display: "flex",
                      gap: "12px",
                      flexWrap: "wrap"
                    }}>
                                    <span style={styles.chip}>
                                        {renderIcon(Icons.Calendar, 14, "#64748b")}
                                      {new Date().toLocaleDateString('en-US', {
                                        weekday: 'long',
                                        year: 'numeric',
                                        month: 'long',
                                        day: 'numeric'
                                      })}
                                    </span>
                      <span style={styles.chip}>
                                        {renderIcon(Icons.User, 14, "#64748b")}
                        Role: {user.role}
                                    </span>
                    </div>
                  </div>

                  {/* Dashboard Cards Grid */}
                  <div style={styles.cardGrid}>
                    {dashboardCards.map((card, index) => (
                        <div
                            key={index}
                            className="dashboard-card"
                            onClick={() => navigate(card.path)}
                            style={styles.card}
                        >
                          <div style={{
                            ...styles.cardIcon,
                            background: card.bgColor,
                          }}>
                            {renderIcon(card.icon, 24, card.color)}
                          </div>
                          <h3 style={styles.cardTitle}>{card.title}</h3>
                          <p style={styles.cardDescription}>{card.description}</p>
                          <div style={styles.cardFooter}>
                            <span style={styles.cardBadge}>Get started</span>
                            <span style={{ color: "#94a3b8" }}>
                                                 {renderIcon(Icons.ArrowRight, 16)}
                                             </span>
                          </div>
                        </div>
                    ))}
                  </div>
                </>
            )}

            {activeTab === "students" && <StudentsPage />}
            {activeTab === "teachers" && <TeachersPage />}
            {activeTab === "parents" && <ParentsPage />}

            {activeTab === "papers" && <MyPapersSection />}

            {activeTab === "messages" && (
                <div style={{
                  background: "#ffffff",
                  borderRadius: "16px",
                  padding: "40px",
                  textAlign: "center" as const,
                  border: "1px solid #edf2f7"
                }}>
                  <div style={{ marginBottom: "16px" }}>
                    {renderIcon(Icons.MessageSquare, 48, "#94a3b8")}
                  </div>
                  <h3 style={{ margin: "0 0 8px 0", color: "#1e293b", fontWeight: 600 }}>Messages Coming Soon</h3>
                  <p style={{ color: "#64748b", margin: 0 }}>This feature is under development</p>
                </div>
            )}

            {activeTab === "settings" && (
                <div style={{
                  background: "#ffffff",
                  borderRadius: "16px",
                  padding: "40px",
                  textAlign: "center" as const,
                  border: "1px solid #edf2f7"
                }}>
                  <div style={{ marginBottom: "16px" }}>
                    {renderIcon(Icons.Settings, 48, "#94a3b8")}
                  </div>
                  <h3 style={{ margin: "0 0 8px 0", color: "#1e293b", fontWeight: 600 }}>Settings Coming Soon</h3>
                  <p style={{ color: "#64748b", margin: 0 }}>This feature is under development</p>
                </div>
            )}
          </div>
        </div>
      </div>
  );
};

const MyPapersSection = () => {
    const navigate = useNavigate();
    const [papers, setPapers] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetchPapers = async () => {
            try {
                const token = localStorage.getItem("token");
                const res = await fetch("http://localhost:3000/api/quizzes/my-papers", {
                    headers: { Authorization: `Bearer ${token}` }
                });
                const data = await res.json();
                setPapers(data.papers || []);
            } catch (err) {
                console.error(err);
            } finally {
                setLoading(false);
            }
        };
        fetchPapers();
    }, []);

    if (loading) return <div style={{ padding: "20px" }}>Loading papers...</div>;

    return (
        <div style={{ background: "white", padding: "24px", borderRadius: "16px", border: "1px solid #edf2f7" }}>
            <div style={{ display: "flex", alignItems: "center", gap: "10px", marginBottom: "20px" }}>
                <Icons.FileText size={24} color="#ec4899" />
                <h3 style={{ margin: 0 }}>My Generated Papers</h3>
            </div>
            {papers.length === 0 ? (
                <div style={{ textAlign: "center", padding: "40px", color: "#64748b" }}>
                    <Icons.FileX size={48} style={{ marginBottom: "12px", opacity: 0.5 }} />
                    <p>No papers generated yet. Start by creating a new paper!</p>
                </div>
            ) : (
                <div style={{ display: "grid", gap: "16px" }}>
                    {papers.map((p) => (
                        <div key={p._id} style={{ padding: "16px", border: "1px solid #e2e8f0", borderRadius: "12px", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                            <div>
                                <div style={{ fontWeight: 600, color: "#1e293b" }}>{p.subject.toUpperCase()} - {p.type}</div>
                                <div style={{ fontSize: "13px", color: "#64748b", marginTop: "4px" }}>
                                    Grade {p.grade} • {p.questions.length} Questions • {new Date(p.createdAt).toLocaleDateString()}
                                </div>
                            </div>
                            <button 
                                onClick={() => navigate(`/paper-view/${p._id}`)}
                                style={{ 
                                    padding: "8px 16px", 
                                    background: "#3b82f6", 
                                    color: "white", 
                                    border: "none", 
                                    borderRadius: "8px", 
                                    cursor: "pointer",
                                    fontSize: "14px",
                                    fontWeight: 500,
                                    display: "flex",
                                    alignItems: "center",
                                    gap: "6px"
                                }}
                            >
                                <Icons.Eye size={16} />
                                View Paper
                            </button>
                        </div>
                    ))}
                </div>
            )}
        </div>
    );
};

export default Dashboard;