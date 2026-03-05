import { useEffect, useState } from "react";
import { useNavigate, Link } from "react-router-dom";

const Dashboard = () => {
  const [isMobile, setIsMobile] = useState(false);
  const navigate = useNavigate();
  
  // Mock user data (in a real app, this would come from authentication)
  const [user, setUser] = useState({
    name: "John Doe",
    role: "parent",
    grade: "3",
    school: "Colombo International School",
    avatar: "👨‍👧‍👦"
  });
  
  const [activeTab, setActiveTab] = useState("overview");

  useEffect(() => {
    const checkMobile = () => {
      setIsMobile(window.innerWidth <= 768);
    };
    
    checkMobile();
    window.addEventListener('resize', checkMobile);
    
    return () => window.removeEventListener('resize', checkMobile);
  }, []);

  const handleLogout = () => {
    if (window.confirm("Are you sure you want to logout?")) {
      // In a real app, clear authentication tokens here
      navigate("/login");
    }
  };

  // Mock data for dashboard
  const progressData = [
    { subject: "Mathematics", progress: 75, color: "#004643", icon: "🧮" },
    { subject: "English", progress: 60, color: "#f9bc60", icon: "📚" },
    { subject: "Science", progress: 85, color: "#e16162", icon: "🔬" },
    { subject: "Sinhala", progress: 45, color: "#007b72", icon: "📝" },
    { subject: "Tamil", progress: 30, color: "#3da9fc", icon: "📖" },
  ];

  const recentActivities = [
    { id: 1, activity: "Completed Math Quiz", time: "2 hours ago", icon: "✅" },
    { id: 2, activity: "Started English Lesson", time: "Yesterday", icon: "📚" },
    { id: 3, activity: "Earned Science Badge", time: "2 days ago", icon: "🏆" },
    { id: 4, activity: "Joined Study Group", time: "3 days ago", icon: "👥" },
    { id: 5, activity: "Completed Assignment", time: "1 week ago", icon: "📝" },
  ];

  const learningModules = [
    { id: 1, title: "Basic Mathematics", description: "Numbers, Addition, Subtraction", icon: "➕", color: "#004643", status: "completed" },
    { id: 2, title: "English Grammar", description: "Nouns, Verbs, Sentences", icon: "📝", color: "#f9bc60", status: "in-progress" },
    { id: 3, title: "Science Basics", description: "Plants, Animals, Environment", icon: "🔬", color: "#e16162", status: "not-started" },
    { id: 4, title: "Sinhala Language", description: "Alphabet, Words, Reading", icon: "📖", color: "#007b72", status: "in-progress" },
  ];

  const quickActions = [
    { title: "Continue Learning", icon: "▶️", color: "#004643", link: "/learn" },
    { title: "View Progress", icon: "📊", color: "#f9bc60", link: "/progress" },
    { title: "Join Class", icon: "👥", color: "#007b72", link: "/classes" },
    { title: "Take Quiz", icon: "🧠", color: "#e16162", link: "/quiz" },
  ];

  return (
    <div style={{
      minHeight: "100vh",
      width: "100vw",
      background: "linear-gradient(135deg, #f0f9ff 0%, #fef7ff 100%)",
      fontFamily: "'Segoe UI', 'Inter', -apple-system, sans-serif",
      color: "#333",
      overflowX: "hidden"
    }}>
      
      {/* Main Dashboard Container */}
      <div style={{
        width: "100%",
        maxWidth: "1400px",
        margin: "0 auto",
        padding: isMobile ? "15px" : "30px 20px"
      }}>
        
        {/* Header/Navbar */}
        <div style={{
          background: "white",
          borderRadius: "20px",
          padding: isMobile ? "20px" : "25px 30px",
          marginBottom: "25px",
          boxShadow: "0 10px 30px rgba(0, 70, 67, 0.08)",
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          flexWrap: "wrap",
          gap: "15px"
        }}>
          {/* Logo and Brand */}
          <div style={{
            display: "flex",
            alignItems: "center",
            gap: "15px"
          }}>
            <div style={{
              width: "50px",
              height: "50px",
              background: "linear-gradient(135deg, #004643, #007b72)",
              borderRadius: "15px",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              color: "white",
              fontSize: "24px",
              fontWeight: "bold"
            }}>
              S
            </div>
            <div>
              <h1 style={{
                margin: "0",
                fontSize: isMobile ? "20px" : "24px",
                fontWeight: "800",
                color: "#004643"
              }}>
                Shilpa Dashboard
              </h1>
              <p style={{
                margin: "5px 0 0 0",
                fontSize: "14px",
                color: "#718096"
              }}>
                Inclusive Learning Platform
              </p>
            </div>
          </div>

          {/* User Profile and Actions */}
          <div style={{
            display: "flex",
            alignItems: "center",
            gap: "20px",
            flexWrap: "wrap"
          }}>
            {/* Quick Stats */}
            <div style={{
              display: "flex",
              gap: "15px",
              flexWrap: "wrap"
            }}>
              <div style={{
                background: "#e8f4f3",
                padding: "8px 15px",
                borderRadius: "12px",
                display: "flex",
                alignItems: "center",
                gap: "8px"
              }}>
                <span style={{ fontSize: "20px" }}>📚</span>
                <span style={{ fontWeight: "600", color: "#004643" }}>5</span>
                <span style={{ color: "#718096", fontSize: "14px" }}>Courses</span>
              </div>
              <div style={{
                background: "#fff4e6",
                padding: "8px 15px",
                borderRadius: "12px",
                display: "flex",
                alignItems: "center",
                gap: "8px"
              }}>
                <span style={{ fontSize: "20px" }}>🏆</span>
                <span style={{ fontWeight: "600", color: "#c05621" }}>12</span>
                <span style={{ color: "#718096", fontSize: "14px" }}>Badges</span>
              </div>
            </div>

            {/* User Profile */}
            <div style={{
              display: "flex",
              alignItems: "center",
              gap: "12px",
              background: "#f8fafc",
              padding: "10px 20px",
              borderRadius: "15px",
              cursor: "pointer",
              transition: "all 0.3s ease"
            }}
            onMouseEnter={e => {
              e.currentTarget.style.background = "#e8f4f3";
              e.currentTarget.style.transform = "translateY(-2px)";
            }}
            onMouseLeave={e => {
              e.currentTarget.style.background = "#f8fafc";
              e.currentTarget.style.transform = "translateY(0)";
            }}>
              <div style={{
                width: "40px",
                height: "40px",
                background: "linear-gradient(135deg, #004643, #007b72)",
                borderRadius: "50%",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                color: "white",
                fontSize: "20px"
              }}>
                {user.avatar}
              </div>
              <div>
                <div style={{
                  fontWeight: "600",
                  color: "#2d3748",
                  fontSize: "16px"
                }}>
                  {user.name}
                </div>
                <div style={{
                  fontSize: "12px",
                  color: "#718096",
                  display: "flex",
                  alignItems: "center",
                  gap: "5px"
                }}>
                  <span style={{
                    background: user.role === "student" ? "#e8f4f3" : 
                               user.role === "parent" ? "#fff4e6" : "#e6f7ff",
                    color: user.role === "student" ? "#004643" : 
                          user.role === "parent" ? "#c05621" : "#007b72",
                    padding: "2px 8px",
                    borderRadius: "10px",
                    fontSize: "11px",
                    fontWeight: "600"
                  }}>
                    {user.role.charAt(0).toUpperCase() + user.role.slice(1)}
                  </span>
                  <span>•</span>
                  <span>Grade {user.grade}</span>
                </div>
              </div>
            </div>

            {/* Logout Button */}
            <button
              onClick={handleLogout}
              style={{
                background: "linear-gradient(90deg, #f9bc60, #ff9a3c)",
                color: "white",
                border: "none",
                padding: "10px 20px",
                borderRadius: "12px",
                cursor: "pointer",
                fontWeight: "600",
                fontSize: "14px",
                transition: "all 0.3s ease",
                display: "flex",
                alignItems: "center",
                gap: "8px"
              }}
              onMouseEnter={e => {
                e.currentTarget.style.transform = "translateY(-2px)";
                e.currentTarget.style.boxShadow = "0 5px 15px rgba(249, 188, 96, 0.4)";
              }}
              onMouseLeave={e => {
                e.currentTarget.style.transform = "translateY(0)";
                e.currentTarget.style.boxShadow = "none";
              }}
            >
              <span>🚪</span>
              Logout
            </button>
          </div>
        </div>

        {/* Main Dashboard Content */}
        <div style={{
          display: "grid",
          gridTemplateColumns: isMobile ? "1fr" : "300px 1fr",
          gap: "25px"
        }}>
          
          {/* Sidebar */}
          <div style={{
            background: "white",
            borderRadius: "20px",
            padding: "25px",
            boxShadow: "0 10px 30px rgba(0, 70, 67, 0.08)",
            height: "fit-content"
          }}>
            <h3 style={{
              margin: "0 0 20px 0",
              fontSize: "18px",
              fontWeight: "700",
              color: "#004643"
            }}>
              Quick Menu
            </h3>
            
            <div style={{
              display: "flex",
              flexDirection: "column",
              gap: "10px"
            }}>
              {[
                { id: "overview", label: "📊 Overview", icon: "📊" },
                { id: "courses", label: "📚 My Courses", icon: "📚" },
                { id: "progress", label: "📈 Progress", icon: "📈" },
                { id: "assignments", label: "📝 Assignments", icon: "📝" },
                { id: "messages", label: "💬 Messages", icon: "💬" },
                { id: "settings", label: "⚙️ Settings", icon: "⚙️" }
              ].map(item => (
                <button
                  key={item.id}
                  onClick={() => setActiveTab(item.id)}
                  style={{
                    textAlign: "left",
                    padding: "15px",
                    border: "none",
                    background: activeTab === item.id ? "#e8f4f3" : "transparent",
                    color: activeTab === item.id ? "#004643" : "#718096",
                    borderRadius: "12px",
                    cursor: "pointer",
                    fontWeight: "600",
                    fontSize: "15px",
                    transition: "all 0.3s ease",
                    display: "flex",
                    alignItems: "center",
                    gap: "12px"
                  }}
                  onMouseEnter={e => {
                    if (activeTab !== item.id) {
                      e.currentTarget.style.background = "#f8fafc";
                      e.currentTarget.style.color = "#2d3748";
                    }
                  }}
                  onMouseLeave={e => {
                    if (activeTab !== item.id) {
                      e.currentTarget.style.background = "transparent";
                      e.currentTarget.style.color = "#718096";
                    }
                  }}
                >
                  <span style={{ fontSize: "18px" }}>{item.icon}</span>
                  {item.label}
                </button>
              ))}
            </div>

            {/* School Info */}
            <div style={{
              marginTop: "30px",
              padding: "20px",
              background: "linear-gradient(135deg, #e8f4f3, #ffffff)",
              borderRadius: "15px",
              border: "1px solid #d0efec"
            }}>
              <h4 style={{
                margin: "0 0 10px 0",
                fontSize: "16px",
                fontWeight: "600",
                color: "#004643"
              }}>
                School Information
              </h4>
              <p style={{
                margin: "0 0 15px 0",
                fontSize: "14px",
                color: "#4a5568",
                lineHeight: "1.5"
              }}>
                {user.school}
              </p>
              <div style={{
                display: "flex",
                alignItems: "center",
                gap: "8px",
                fontSize: "12px",
                color: "#718096"
              }}>
                <span>🎯</span>
                <span>Grade {user.grade} Student</span>
              </div>
            </div>
          </div>

          {/* Main Content Area */}
          <div>
            {/* Welcome Card */}
            <div style={{
              background: "linear-gradient(135deg, #004643, #007b72)",
              borderRadius: "20px",
              padding: "30px",
              color: "white",
              marginBottom: "25px",
              boxShadow: "0 15px 40px rgba(0, 70, 67, 0.3)"
            }}>
              <div style={{
                display: "flex",
                justifyContent: "space-between",
                alignItems: "center",
                flexWrap: "wrap",
                gap: "20px"
              }}>
                <div>
                  <h2 style={{
                    margin: "0 0 10px 0",
                    fontSize: isMobile ? "24px" : "28px",
                    fontWeight: "700"
                  }}>
                    Welcome back, {user.name}! 👋
                  </h2>
                  <p style={{
                    margin: "0",
                    fontSize: "16px",
                    opacity: "0.9",
                    maxWidth: "600px"
                  }}>
                    Continue your learning journey with personalized lessons, 
                    track your progress, and unlock new achievements today!
                  </p>
                </div>
                <div style={{
                  fontSize: "60px",
                  opacity: "0.8"
                }}>
                  🚀
                </div>
              </div>
            </div>

            {/* Quick Actions */}
            <div style={{
              display: "grid",
              gridTemplateColumns: isMobile ? "1fr" : "repeat(2, 1fr)",
              gap: "20px",
              marginBottom: "25px"
            }}>
              {quickActions.map((action, index) => (
                <Link
                  key={index}
                  to={action.link}
                  style={{
                    background: "white",
                    borderRadius: "15px",
                    padding: "25px",
                    textDecoration: "none",
                    color: "#2d3748",
                    transition: "all 0.3s ease",
                    display: "flex",
                    alignItems: "center",
                    gap: "20px",
                    boxShadow: "0 5px 20px rgba(0, 70, 67, 0.1)"
                  }}
                  onMouseEnter={e => {
                    e.currentTarget.style.transform = "translateY(-5px)";
                    e.currentTarget.style.boxShadow = `0 10px 30px ${action.color}30`;
                  }}
                  onMouseLeave={e => {
                    e.currentTarget.style.transform = "translateY(0)";
                    e.currentTarget.style.boxShadow = "0 5px 20px rgba(0, 70, 67, 0.1)";
                  }}
                >
                  <div style={{
                    width: "60px",
                    height: "60px",
                    background: `${action.color}20`,
                    borderRadius: "12px",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    fontSize: "28px",
                    color: action.color
                  }}>
                    {action.icon}
                  </div>
                  <div>
                    <h3 style={{
                      margin: "0 0 8px 0",
                      fontSize: "18px",
                      fontWeight: "700",
                      color: "#1a202c"
                    }}>
                      {action.title}
                    </h3>
                    <p style={{
                      margin: "0",
                      fontSize: "14px",
                      color: "#718096"
                    }}>
                      Click to get started
                    </p>
                  </div>
                </Link>
              ))}
            </div>

            {/* Progress Overview */}
            <div style={{
              background: "white",
              borderRadius: "20px",
              padding: "30px",
              marginBottom: "25px",
              boxShadow: "0 10px 30px rgba(0, 70, 67, 0.08)"
            }}>
              <div style={{
                display: "flex",
                justifyContent: "space-between",
                alignItems: "center",
                marginBottom: "25px",
                flexWrap: "wrap",
                gap: "15px"
              }}>
                <h3 style={{
                  margin: "0",
                  fontSize: "22px",
                  fontWeight: "700",
                  color: "#1a202c"
                }}>
                  Learning Progress
                </h3>
                <Link 
                  to="/progress"
                  style={{
                    color: "#007b72",
                    fontWeight: "600",
                    textDecoration: "none",
                    fontSize: "14px",
                    display: "flex",
                    alignItems: "center",
                    gap: "8px"
                  }}
                  onMouseEnter={e => {
                    e.currentTarget.style.color = "#004643";
                  }}
                  onMouseLeave={e => {
                    e.currentTarget.style.color = "#007b72";
                  }}
                >
                  View All <span>→</span>
                </Link>
              </div>

              <div style={{
                display: "grid",
                gridTemplateColumns: isMobile ? "1fr" : "repeat(2, 1fr)",
                gap: "20px"
              }}>
                {progressData.map((subject, index) => (
                  <div key={index} style={{
                    background: "#f8fafc",
                    borderRadius: "15px",
                    padding: "20px",
                    borderLeft: `4px solid ${subject.color}`
                  }}>
                    <div style={{
                      display: "flex",
                      justifyContent: "space-between",
                      alignItems: "center",
                      marginBottom: "15px"
                    }}>
                      <div style={{
                        display: "flex",
                        alignItems: "center",
                        gap: "12px"
                      }}>
                        <div style={{
                          width: "40px",
                          height: "40px",
                          background: `${subject.color}20`,
                          borderRadius: "10px",
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "center",
                          fontSize: "20px",
                          color: subject.color
                        }}>
                          {subject.icon}
                        </div>
                        <div>
                          <h4 style={{
                            margin: "0 0 4px 0",
                            fontSize: "16px",
                            fontWeight: "600",
                            color: "#1a202c"
                          }}>
                            {subject.subject}
                          </h4>
                          <p style={{
                            margin: "0",
                            fontSize: "12px",
                            color: "#718096"
                          }}>
                            Grade {user.grade} Curriculum
                          </p>
                        </div>
                      </div>
                      <span style={{
                        fontSize: "16px",
                        fontWeight: "700",
                        color: subject.color
                      }}>
                        {subject.progress}%
                      </span>
                    </div>
                    
                    {/* Progress Bar */}
                    <div style={{
                      width: "100%",
                      height: "8px",
                      background: "#e2e8f0",
                      borderRadius: "4px",
                      overflow: "hidden"
                    }}>
                      <div style={{
                        width: `${subject.progress}%`,
                        height: "100%",
                        background: subject.color,
                        borderRadius: "4px",
                        transition: "width 0.5s ease"
                      }} />
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Learning Modules and Recent Activity */}
            <div style={{
              display: "grid",
              gridTemplateColumns: isMobile ? "1fr" : "2fr 1fr",
              gap: "25px"
            }}>
              {/* Learning Modules */}
              <div style={{
                background: "white",
                borderRadius: "20px",
                padding: "30px",
                boxShadow: "0 10px 30px rgba(0, 70, 67, 0.08)"
              }}>
                <h3 style={{
                  margin: "0 0 25px 0",
                  fontSize: "22px",
                  fontWeight: "700",
                  color: "#1a202c"
                }}>
                  My Learning Modules
                </h3>

                <div style={{
                  display: "flex",
                  flexDirection: "column",
                  gap: "15px"
                }}>
                  {learningModules.map(module => (
                    <div key={module.id} style={{
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "space-between",
                      padding: "20px",
                      background: "#f8fafc",
                      borderRadius: "15px",
                      borderLeft: `4px solid ${module.color}`,
                      transition: "all 0.3s ease"
                    }}
                    onMouseEnter={e => {
                      e.currentTarget.style.transform = "translateX(5px)";
                      e.currentTarget.style.boxShadow = "0 5px 20px rgba(0, 0, 0, 0.05)";
                    }}
                    onMouseLeave={e => {
                      e.currentTarget.style.transform = "translateX(0)";
                      e.currentTarget.style.boxShadow = "none";
                    }}>
                      <div style={{
                        display: "flex",
                        alignItems: "center",
                        gap: "15px"
                      }}>
                        <div style={{
                          width: "50px",
                          height: "50px",
                          background: `${module.color}20`,
                          borderRadius: "12px",
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "center",
                          fontSize: "24px",
                          color: module.color
                        }}>
                          {module.icon}
                        </div>
                        <div>
                          <h4 style={{
                            margin: "0 0 5px 0",
                            fontSize: "16px",
                            fontWeight: "600",
                            color: "#1a202c"
                          }}>
                            {module.title}
                          </h4>
                          <p style={{
                            margin: "0",
                            fontSize: "14px",
                            color: "#718096"
                          }}>
                            {module.description}
                          </p>
                        </div>
                      </div>
                      
                      <div style={{
                        display: "flex",
                        alignItems: "center",
                        gap: "15px"
                      }}>
                        <span style={{
                          padding: "6px 12px",
                          background: module.status === "completed" ? "#e8f4f3" : 
                                     module.status === "in-progress" ? "#fff4e6" : "#f8fafc",
                          color: module.status === "completed" ? "#004643" : 
                                 module.status === "in-progress" ? "#c05621" : "#718096",
                          borderRadius: "20px",
                          fontSize: "12px",
                          fontWeight: "600"
                        }}>
                          {module.status === "completed" ? "✅ Completed" : 
                           module.status === "in-progress" ? "⏳ In Progress" : "📋 Not Started"}
                        </span>
                        <button style={{
                          background: "none",
                          border: "none",
                          color: module.color,
                          fontSize: "20px",
                          cursor: "pointer",
                          padding: "5px"
                        }}>
                          →
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              {/* Recent Activity */}
              <div style={{
                background: "white",
                borderRadius: "20px",
                padding: "30px",
                boxShadow: "0 10px 30px rgba(0, 70, 67, 0.08)"
              }}>
                <h3 style={{
                  margin: "0 0 25px 0",
                  fontSize: "22px",
                  fontWeight: "700",
                  color: "#1a202c"
                }}>
                  Recent Activity
                </h3>

                <div style={{
                  display: "flex",
                  flexDirection: "column",
                  gap: "15px"
                }}>
                  {recentActivities.map(activity => (
                    <div key={activity.id} style={{
                      display: "flex",
                      alignItems: "flex-start",
                      gap: "15px",
                      padding: "15px",
                      background: "#f8fafc",
                      borderRadius: "12px"
                    }}>
                      <div style={{
                        width: "40px",
                        height: "40px",
                        background: "#e8f4f3",
                        borderRadius: "10px",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        fontSize: "18px"
                      }}>
                        {activity.icon}
                      </div>
                      <div>
                        <h4 style={{
                          margin: "0 0 5px 0",
                          fontSize: "14px",
                          fontWeight: "600",
                          color: "#1a202c"
                        }}>
                          {activity.activity}
                        </h4>
                        <p style={{
                          margin: "0",
                          fontSize: "12px",
                          color: "#718096"
                        }}>
                          {activity.time}
                        </p>
                      </div>
                    </div>
                  ))}
                </div>

                {/* Statistics Card */}
                <div style={{
                  marginTop: "30px",
                  padding: "20px",
                  background: "linear-gradient(135deg, #e8f4f3, #ffffff)",
                  borderRadius: "15px",
                  border: "1px solid #d0efec"
                }}>
                  <h4 style={{
                    margin: "0 0 15px 0",
                    fontSize: "16px",
                    fontWeight: "600",
                    color: "#004643"
                  }}>
                    Learning Stats
                  </h4>
                  <div style={{
                    display: "grid",
                    gridTemplateColumns: "repeat(2, 1fr)",
                    gap: "15px"
                  }}>
                    <div>
                      <div style={{
                        fontSize: "24px",
                        fontWeight: "700",
                        color: "#004643"
                      }}>
                        15h
                      </div>
                      <div style={{
                        fontSize: "12px",
                        color: "#718096"
                      }}>
                        Study Time
                      </div>
                    </div>
                    <div>
                      <div style={{
                        fontSize: "24px",
                        fontWeight: "700",
                        color: "#f9bc60"
                      }}>
                        87%
                      </div>
                      <div style={{
                        fontSize: "12px",
                        color: "#718096"
                      }}>
                        Avg. Score
                      </div>
                    </div>
                    <div>
                      <div style={{
                        fontSize: "24px",
                        fontWeight: "700",
                        color: "#007b72"
                      }}>
                        24
                      </div>
                      <div style={{
                        fontSize: "12px",
                        color: "#718096"
                      }}>
                        Lessons
                      </div>
                    </div>
                    <div>
                      <div style={{
                        fontSize: "24px",
                        fontWeight: "700",
                        color: "#e16162"
                      }}>
                        8
                      </div>
                      <div style={{
                        fontSize: "12px",
                        color: "#718096"
                      }}>
                        Quizzes
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Footer */}
        <footer style={{
          marginTop: "50px",
          textAlign: "center",
          paddingTop: "30px",
          borderTop: "1px solid #e2e8f0",
          color: "#718096",
          fontSize: "14px"
        }}>
          <p>© {new Date().getFullYear()} Shilpa - Inclusive Learning Platform. All rights reserved.</p>
          <p style={{ fontSize: "12px", marginTop: "5px" }}>
            Designed for Sri Lankan primary education (Grades 3-5)
          </p>
        </footer>
      </div>
    </div>
  );
};

export default Dashboard;