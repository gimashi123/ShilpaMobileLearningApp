import { useEffect, useState, useRef } from "react";
import { useNavigate } from "react-router-dom";

const Home = () => {
  const [isMobile, setIsMobile] = useState(false);
  const [scrollY, setScrollY] = useState(0);
  const [isVisible, setIsVisible] = useState({
    hero: false,
    features: false,
    stats: false,
    cta: false
  });

  const navigate = useNavigate();
  const sectionsRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const checkMobile = () => {
      setIsMobile(window.innerWidth <= 768);
    };

    const handleScroll = () => {
      setScrollY(window.scrollY);

      // Check visibility of sections
      const heroSection = document.getElementById('hero');
      const featuresSection = document.getElementById('features');
      const statsSection = document.getElementById('stats');
      const ctaSection = document.getElementById('cta');

      if (heroSection) {
        const rect = heroSection.getBoundingClientRect();
        setIsVisible(prev => ({ ...prev, hero: rect.top < window.innerHeight * 0.8 }));
      }

      if (featuresSection) {
        const rect = featuresSection.getBoundingClientRect();
        setIsVisible(prev => ({ ...prev, features: rect.top < window.innerHeight * 0.8 }));
      }

      if (statsSection) {
        const rect = statsSection.getBoundingClientRect();
        setIsVisible(prev => ({ ...prev, stats: rect.top < window.innerHeight * 0.8 }));
      }

      if (ctaSection) {
        const rect = ctaSection.getBoundingClientRect();
        setIsVisible(prev => ({ ...prev, cta: rect.top < window.innerHeight * 0.8 }));
      }
    };

    checkMobile();
    window.addEventListener('resize', checkMobile);
    window.addEventListener('scroll', handleScroll);

    return () => {
      window.removeEventListener('resize', checkMobile);
      window.removeEventListener('scroll', handleScroll);
    };
  }, []);

  const handleRegisterClick = () => {
    navigate("/register");
  };

  const FloatingElement = ({ delay, left, top, size, color }: never) => (
      <div
          style={{
            position: "absolute",
            left,
            top,
            width: size,
            height: size,
            background: color,
            borderRadius: "50%",
            filter: "blur(60px)",
            opacity: 0.3,
            // eslint-disable-next-line react-hooks/purity
            animation: `float ${8 + Math.random() * 5}s ease-in-out infinite`,
            animationDelay: `${delay}s`,
            zIndex: 0,
            pointerEvents: "none",
            transform: `translateY(${scrollY * 0.02}px)`
          }}
      />
  );

  const stats = [
    { value: "10,000+", label: "Active Students", icon: "👥", color: "#004643" },
    { value: "500+", label: "Interactive Lessons", icon: "📚", color: "#007b72" },
    { value: "50+", label: "Schools", icon: "🏫", color: "#c05621" },
    { value: "4.8★", label: "Parent Rating", icon: "⭐", color: "#e67e22" }
  ];

  const features = [
    {
      icon: "🎮",
      title: "Gamified Learning",
      desc: "Turn education into an adventure with points, badges, and rewards",
      color: "#004643",
      bgColor: "linear-gradient(135deg, #00464310, #007b7210)"
    },
    {
      icon: "📖",
      title: "Interactive Stories",
      desc: "Learn through captivating stories featuring Sri Lankan characters",
      color: "#007b72",
      bgColor: "linear-gradient(135deg, #007b7210, #00a89610)"
    },
    {
      icon: "🎨",
      title: "Creative Activities",
      desc: "Drawing, coloring, and craft activities that reinforce learning",
      color: "#c05621",
      bgColor: "linear-gradient(135deg, #c0562110, #e67e2210)"
    },
    {
      icon: "🗣️",
      title: "Voice Learning",
      desc: "Sinhala & Tamil voiceovers for better comprehension",
      color: "#8e44ad",
      bgColor: "linear-gradient(135deg, #8e44ad10, #9b59b610)"
    },
    {
      icon: "🧩",
      title: "Adaptive Difficulty",
      desc: "Content automatically adjusts to each student's pace",
      color: "#16a085",
      bgColor: "linear-gradient(135deg, #16a08510, #1abc9c10)"
    },
    {
      icon: "👪",
      title: "Parent Dashboard",
      desc: "Track progress and celebrate achievements together",
      color: "#e67e22",
      bgColor: "linear-gradient(135deg, #e67e2210, #f39c1210)"
    }
  ];

  const learningPaths = [
    { grade: "Grade 3", color: "#004643", icon: "🐘", lessons: "30+ Lessons" },
    { grade: "Grade 4", color: "#007b72", icon: "🦚", lessons: "35+ Lessons" },
    { grade: "Grade 5", color: "#c05621", icon: "🦁", lessons: "40+ Lessons" }
  ];

  return (
      <div style={{
        minHeight: "100vh",
        width: "100vw",
        background: "linear-gradient(135deg, #f8fafc 0%, #f0f9ff 100%)",
        fontFamily: "'Poppins', 'Segoe UI', 'Inter', sans-serif",
        color: "#1a202c",
        overflowX: "hidden",
        position: "relative"
      }}>

        {/* Global animations */}
        <style>
          {`
          @import url('https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700;800&display=swap');
          
          @keyframes float {
            0%, 100% { transform: translateY(0px) scale(1); }
            50% { transform: translateY(-20px) scale(1.05); }
          }
          
          @keyframes pulse {
            0%, 100% { opacity: 0.6; transform: scale(1); }
            50% { opacity: 1; transform: scale(1.1); }
          }
          
          @keyframes slideInLeft {
            from { opacity: 0; transform: translateX(-50px); }
            to { opacity: 1; transform: translateX(0); }
          }
          
          @keyframes slideInRight {
            from { opacity: 0; transform: translateX(50px); }
            to { opacity: 1; transform: translateX(0); }
          }
          
          @keyframes slideInUp {
            from { opacity: 0; transform: translateY(50px); }
            to { opacity: 1; transform: translateY(0); }
          }
          
          @keyframes rotate {
            from { transform: rotate(0deg); }
            to { transform: rotate(360deg); }
          }
          
          @keyframes shimmer {
            0% { background-position: -1000px 0; }
            100% { background-position: 1000px 0; }
          }
          
          .shimmer {
            background: linear-gradient(90deg, transparent, rgba(255,255,255,0.2), transparent);
            background-size: 1000px 100%;
            animation: shimmer 2s infinite;
          }
          
          .floating {
            animation: float 6s ease-in-out infinite;
          }
          
          .pulse {
            animation: pulse 3s ease-in-out infinite;
          }
          
          .slide-in-left {
            animation: slideInLeft 0.8s ease forwards;
          }
          
          .slide-in-right {
            animation: slideInRight 0.8s ease forwards;
          }
          
          .slide-in-up {
            animation: slideInUp 0.8s ease forwards;
          }
          
          .gradient-text {
            background: linear-gradient(135deg, #004643, #007b72, #00a896);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
          }
        `}
        </style>

        {/* Floating background elements */}
        <FloatingElement delay={0} left="5%" top="10%" size="300px" color="#004643" />
        <FloatingElement delay={2} left="80%" top="20%" size="400px" color="#007b72" />
        <FloatingElement delay={4} left="60%" top="70%" size="350px" color="#c05621" />
        <FloatingElement delay={1} left="30%" top="80%" size="250px" color="#e67e22" />

        {/* Main Content */}
        <div style={{
          maxWidth: "1400px",
          margin: "0 auto",
          padding: isMobile ? "1rem" : "2rem",
          position: "relative",
          zIndex: 2
        }}>

          {/* Hero Section */}
          <section id="hero" style={{
            minHeight: "90vh",
            display: "flex",
            flexDirection: isMobile ? "column" : "row",
            alignItems: "center",
            justifyContent: "space-between",
            gap: "4rem",
            padding: isMobile ? "2rem 1rem" : "3rem 2rem",
            position: "relative",
            opacity: isVisible.hero ? 1 : 0,
            transform: isVisible.hero ? "translateY(0)" : "translateY(30px)",
            transition: "all 1s ease"
          }}>

            {/* Left Content */}
            <div style={{
              flex: 1,
              animation: isVisible.hero ? "slideInLeft 0.8s ease" : "none"
            }}>
              <div style={{
                display: "inline-block",
                padding: "0.5rem 1.5rem",
                background: "rgba(0, 70, 67, 0.1)",
                borderRadius: "30px",
                marginBottom: "1.5rem",
                border: "1px solid #00464320"
              }}>
              <span style={{ color: "#004643", fontWeight: "600" }}>
                🎓 Welcome to the Future of Learning
              </span>
              </div>

              <h1 style={{
                fontSize: isMobile ? "2.5rem" : "4rem",
                fontWeight: "800",
                lineHeight: "1.2",
                marginBottom: "1.5rem"
              }}>
                <span className="gradient-text">Shilpa</span>
                <br />
                <span style={{ color: "#1a202c" }}>
                Where Learning
              </span>
                <br />
                <span style={{
                  background: "linear-gradient(135deg, #004643, #007b72)",
                  WebkitBackgroundClip: "text",
                  WebkitTextFillColor: "transparent"
                }}>
                Comes Alive!
              </span>
              </h1>

              <p style={{
                fontSize: isMobile ? "1.1rem" : "1.25rem",
                color: "#4a5568",
                lineHeight: "1.8",
                marginBottom: "2rem",
                maxWidth: "600px"
              }}>
                An inclusive mobile learning platform designed specifically for Sri Lankan
                primary students (Grades 3–5), celebrating diversity and making education
                accessible for every child.
              </p>

              {/* CTA Buttons */}
              <div style={{
                display: "flex",
                gap: "1rem",
                flexWrap: "wrap"
              }}>
                <button
                    onClick={handleRegisterClick}
                    style={{
                      padding: isMobile ? "1rem 2rem" : "1.2rem 2.5rem",
                      fontSize: isMobile ? "1rem" : "1.1rem",
                      fontWeight: "600",
                      background: "linear-gradient(135deg, #004643, #007b72)",
                      color: "white",
                      border: "none",
                      borderRadius: "50px",
                      cursor: "pointer",
                      boxShadow: "0 10px 30px rgba(0, 70, 67, 0.3)",
                      transition: "all 0.3s ease",
                      position: "relative",
                      overflow: "hidden"
                    }}
                    onMouseEnter={(e) => {
                      e.currentTarget.style.transform = "translateY(-3px) scale(1.05)";
                      e.currentTarget.style.boxShadow = "0 20px 40px rgba(0, 70, 67, 0.4)";
                    }}
                    onMouseLeave={(e) => {
                      e.currentTarget.style.transform = "translateY(0) scale(1)";
                      e.currentTarget.style.boxShadow = "0 10px 30px rgba(0, 70, 67, 0.3)";
                    }}
                >
                <span style={{ position: "relative", zIndex: 2 }}>
                  🚀 Start Learning Free
                </span>
                  <div className="shimmer" style={{
                    position: "absolute",
                    top: 0,
                    left: 0,
                    width: "100%",
                    height: "100%",
                    opacity: 0.5
                  }} />
                </button>

                {/*<button*/}
                {/*    style={{*/}
                {/*      padding: isMobile ? "1rem 2rem" : "1.2rem 2.5rem",*/}
                {/*      fontSize: isMobile ? "1rem" : "1.1rem",*/}
                {/*      fontWeight: "600",*/}
                {/*      background: "transparent",*/}
                {/*      color: "#004643",*/}
                {/*      border: "2px solid #004643",*/}
                {/*      borderRadius: "50px",*/}
                {/*      cursor: "pointer",*/}
                {/*      transition: "all 0.3s ease"*/}
                {/*    }}*/}
                {/*    onMouseEnter={(e) => {*/}
                {/*      e.currentTarget.style.background = "#004643";*/}
                {/*      e.currentTarget.style.color = "white";*/}
                {/*    }}*/}
                {/*    onMouseLeave={(e) => {*/}
                {/*      e.currentTarget.style.background = "transparent";*/}
                {/*      e.currentTarget.style.color = "#004643";*/}
                {/*    }}*/}
                {/*>*/}
                {/*  🎬 Watch Demo*/}
                {/*</button>*/}
              </div>

              {/* Trust Indicators */}
              <div style={{
                display: "flex",
                gap: "2rem",
                marginTop: "3rem",
                flexWrap: "wrap"
              }}>
                {["🏆 Award Winning", "📱 Mobile First", "🔒 Safe & Secure"].map((text, i) => (
                    <div key={i} style={{
                      display: "flex",
                      alignItems: "center",
                      gap: "0.5rem"
                    }}>
                      <span style={{ fontSize: "1.2rem" }}>✓</span>
                      <span style={{ color: "#4a5568", fontWeight: "500" }}>{text}</span>
                    </div>
                ))}
              </div>
            </div>

            {/* Right Hero Image/Animation */}
            <div style={{
              flex: 1,
              position: "relative",
              animation: isVisible.hero ? "slideInRight 0.8s ease" : "none"
            }}>
              <div style={{
                position: "relative",
                width: "100%",
                height: isMobile ? "300px" : "500px"
              }}>
                {/* Floating Learning Elements */}
                {[
                  { top: "10%", left: "20%", icon: "📚", delay: "0s", size: "60px" },
                  { top: "30%", right: "10%", icon: "✏️", delay: "0.5s", size: "50px" },
                  { top: "60%", left: "10%", icon: "🎨", delay: "1s", size: "70px" },
                  { top: "80%", right: "20%", icon: "🧮", delay: "1.5s", size: "55px" }
                ].map((item, i) => (
                    <div
                        key={i}
                        className="floating"
                        style={{
                          position: "absolute",
                          top: item.top,
                          left: item.left,
                          right: item.right,
                          width: item.size,
                          height: item.size,
                          background: "linear-gradient(135deg, #ffffff, #f8fafc)",
                          borderRadius: "20px",
                          boxShadow: "0 20px 40px rgba(0,0,0,0.1)",
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "center",
                          fontSize: "2rem",
                          animationDelay: item.delay,
                          // eslint-disable-next-line react-hooks/purity
                          transform: `rotate(${Math.random() * 10 - 5}deg)`
                        }}
                    >
                      {item.icon}
                    </div>
                ))}

                {/* Central Element */}
                <div className="pulse" style={{
                  position: "absolute",
                  top: "50%",
                  left: "50%",
                  transform: "translate(-50%, -50%)",
                  width: isMobile ? "150px" : "200px",
                  height: isMobile ? "150px" : "200px",
                  background: "linear-gradient(135deg, #004643, #007b72)",
                  borderRadius: "30px",
                  boxShadow: "0 30px 60px rgba(0, 70, 67, 0.3)",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  fontSize: isMobile ? "4rem" : "5rem"
                }}>
                  🦁
                </div>
              </div>
            </div>
          </section>

          {/* Stats Section */}
          <section id="stats" style={{
            padding: "4rem 2rem",
            opacity: isVisible.stats ? 1 : 0,
            transform: isVisible.stats ? "translateY(0)" : "translateY(30px)",
            transition: "all 0.8s ease"
          }}>
            <div style={{
              display: "grid",
              gridTemplateColumns: isMobile ? "1fr 1fr" : "repeat(4, 1fr)",
              gap: "2rem",
              background: "rgba(255, 255, 255, 0.8)",
              backdropFilter: "blur(10px)",
              borderRadius: "30px",
              padding: "3rem",
              boxShadow: "0 20px 40px rgba(0,0,0,0.05)"
            }}>
              {stats.map((stat, index) => (
                  <div
                      key={index}
                      style={{
                        textAlign: "center",
                        animation: isVisible.stats ? `slideInUp 0.5s ease ${index * 0.1}s forwards` : "none",
                        opacity: 0
                      }}
                  >
                    <div style={{
                      fontSize: "3rem",
                      marginBottom: "1rem"
                    }}>
                      {stat.icon}
                    </div>
                    <h3 style={{
                      fontSize: "2rem",
                      fontWeight: "800",
                      color: stat.color,
                      margin: "0.5rem 0"
                    }}>
                      {stat.value}
                    </h3>
                    <p style={{
                      color: "#4a5568",
                      fontWeight: "500"
                    }}>
                      {stat.label}
                    </p>
                  </div>
              ))}
            </div>
          </section>

          {/* Features Section */}
          <section id="features" style={{
            padding: "4rem 0",
            opacity: isVisible.features ? 1 : 0,
            transform: isVisible.features ? "translateY(0)" : "translateY(30px)",
            transition: "all 0.8s ease"
          }}>
            <div style={{ textAlign: "center", marginBottom: "4rem" }}>
              <h2 style={{
                fontSize: isMobile ? "2rem" : "2.5rem",
                fontWeight: "800",
                marginBottom: "1rem"
              }}>
                <span className="gradient-text">Amazing Features</span>
              </h2>
              <p style={{
                fontSize: "1.1rem",
                color: "#4a5568",
                maxWidth: "600px",
                margin: "0 auto"
              }}>
                Everything your child needs to succeed in a fun, engaging environment
              </p>
            </div>

            <div style={{
              display: "grid",
              gridTemplateColumns: isMobile ? "1fr" : "repeat(3, 1fr)",
              gap: "2rem"
            }}>
              {features.map((feature, index) => (
                  <div
                      key={index}
                      style={{
                        background: feature.bgColor,
                        borderRadius: "30px",
                        padding: "2rem",
                        transition: "all 0.3s ease",
                        border: "1px solid rgba(0,0,0,0.05)",
                        position: "relative",
                        overflow: "hidden",
                        cursor: "pointer",
                        animation: isVisible.features ? `slideInUp 0.5s ease ${index * 0.1}s forwards` : "none",
                        opacity: 0
                      }}
                      onMouseEnter={(e) => {
                        e.currentTarget.style.transform = "translateY(-10px)";
                        e.currentTarget.style.boxShadow = "0 30px 60px rgba(0,70,67,0.15)";
                      }}
                      onMouseLeave={(e) => {
                        e.currentTarget.style.transform = "translateY(0)";
                        e.currentTarget.style.boxShadow = "none";
                      }}
                  >
                    <div style={{
                      fontSize: "3rem",
                      marginBottom: "1.5rem"
                    }}>
                      {feature.icon}
                    </div>
                    <h3 style={{
                      fontSize: "1.5rem",
                      fontWeight: "700",
                      color: feature.color,
                      marginBottom: "1rem"
                    }}>
                      {feature.title}
                    </h3>
                    <p style={{
                      color: "#4a5568",
                      lineHeight: "1.7"
                    }}>
                      {feature.desc}
                    </p>
                    <div style={{
                      position: "absolute",
                      bottom: "-20px",
                      right: "-20px",
                      width: "100px",
                      height: "100px",
                      background: feature.color,
                      opacity: 0.05,
                      borderRadius: "50%"
                    }} />
                  </div>
              ))}
            </div>
          </section>

          {/* Learning Paths */}
          <section style={{
            padding: "4rem 0",
            background: "linear-gradient(135deg, #00464308, #007b7208)",
            borderRadius: "50px",
            margin: "2rem 0"
          }}>
            <div style={{ textAlign: "center", marginBottom: "3rem" }}>
              <h2 style={{
                fontSize: isMobile ? "2rem" : "2.5rem",
                fontWeight: "800"
              }}>
                Choose Your <span className="gradient-text">Learning Path</span>
              </h2>
            </div>

            <div style={{
              display: "flex",
              flexDirection: isMobile ? "column" : "row",
              justifyContent: "center",
              gap: "2rem",
              padding: "0 2rem"
            }}>
              {learningPaths.map((path, index) => (
                  <div
                      key={index}
                      className="floating"
                      style={{
                        flex: 1,
                        background: "white",
                        borderRadius: "30px",
                        padding: "3rem 2rem",
                        textAlign: "center",
                        boxShadow: "0 20px 40px rgba(0,0,0,0.05)",
                        border: `3px solid ${path.color}20`,
                        transition: "all 0.3s ease",
                        animationDelay: `${index * 0.2}s`,
                        cursor: "pointer"
                      }}
                      onMouseEnter={(e) => {
                        e.currentTarget.style.transform = "scale(1.05)";
                        e.currentTarget.style.borderColor = path.color;
                      }}
                      onMouseLeave={(e) => {
                        e.currentTarget.style.transform = "scale(1)";
                        e.currentTarget.style.borderColor = `${path.color}20`;
                      }}
                  >
                    <div style={{
                      fontSize: "4rem",
                      marginBottom: "1rem"
                    }}>
                      {path.icon}
                    </div>
                    <h3 style={{
                      fontSize: "2rem",
                      fontWeight: "700",
                      color: path.color,
                      marginBottom: "1rem"
                    }}>
                      {path.grade}
                    </h3>
                    <p style={{
                      color: "#4a5568",
                      marginBottom: "1.5rem"
                    }}>
                      {path.lessons}
                    </p>
                    <button style={{
                      padding: "0.8rem 2rem",
                      background: path.color,
                      color: "white",
                      border: "none",
                      borderRadius: "25px",
                      fontWeight: "600",
                      cursor: "pointer",
                      transition: "all 0.3s ease"
                    }}
                            onMouseEnter={(e) => {
                              e.currentTarget.style.transform = "scale(1.1)";
                              e.currentTarget.style.boxShadow = `0 10px 20px ${path.color}40`;
                            }}
                            onMouseLeave={(e) => {
                              e.currentTarget.style.transform = "scale(1)";
                              e.currentTarget.style.boxShadow = "none";
                            }}>
                      Explore
                    </button>
                  </div>
              ))}
            </div>
          </section>

          {/* CTA Section */}
          <section id="cta" style={{
            padding: "5rem 2rem",
            textAlign: "center",
            background: "linear-gradient(135deg, #004643, #007b72)",
            borderRadius: "50px",
            margin: "4rem 0",
            position: "relative",
            overflow: "hidden",
            opacity: isVisible.cta ? 1 : 0,
            transform: isVisible.cta ? "translateY(0)" : "translateY(30px)",
            transition: "all 0.8s ease"
          }}>
            {/* Animated background */}
            <div style={{
              position: "absolute",
              top: "-50%",
              left: "-50%",
              width: "200%",
              height: "200%",
              background: "linear-gradient(45deg, transparent 30%, rgba(255,255,255,0.1) 50%, transparent 70%)",
              animation: "rotate 20s linear infinite"
            }} />

            <div style={{ position: "relative", zIndex: 2 }}>
              <div style={{
                fontSize: "5rem",
                marginBottom: "2rem",
                animation: "pulse 2s ease-in-out infinite"
              }}>
                🚀
              </div>

              <h2 style={{
                fontSize: isMobile ? "2rem" : "3rem",
                fontWeight: "800",
                color: "white",
                marginBottom: "1.5rem"
              }}>
                Ready to Start the Adventure?
              </h2>

              <p style={{
                fontSize: "1.2rem",
                color: "rgba(255,255,255,0.9)",
                maxWidth: "600px",
                margin: "0 auto 2.5rem",
                lineHeight: "1.8"
              }}>
                Join thousands of happy learners and discover the joy of education
                with Shilpa's inclusive platform.
              </p>

              <button
                  onClick={handleRegisterClick}
                  style={{
                    padding: isMobile ? "1.2rem 3rem" : "1.5rem 4rem",
                    fontSize: isMobile ? "1.1rem" : "1.3rem",
                    fontWeight: "700",
                    background: "white",
                    color: "#004643",
                    border: "none",
                    borderRadius: "60px",
                    cursor: "pointer",
                    boxShadow: "0 20px 40px rgba(0,0,0,0.2)",
                    transition: "all 0.3s ease",
                    position: "relative",
                    overflow: "hidden"
                  }}
                  onMouseEnter={(e) => {
                    e.currentTarget.style.transform = "translateY(-5px) scale(1.05)";
                    e.currentTarget.style.boxShadow = "0 30px 60px rgba(0,0,0,0.3)";
                  }}
                  onMouseLeave={(e) => {
                    e.currentTarget.style.transform = "translateY(0) scale(1)";
                    e.currentTarget.style.boxShadow = "0 20px 40px rgba(0,0,0,0.2)";
                  }}
              >
              <span style={{ position: "relative", zIndex: 2 }}>
                ✨ Create Free Account
              </span>
                <div className="shimmer" style={{
                  position: "absolute",
                  top: 0,
                  left: 0,
                  width: "100%",
                  height: "100%",
                  opacity: 0.3
                }} />
              </button>

              <div style={{
                display: "flex",
                justifyContent: "center",
                gap: "2rem",
                marginTop: "3rem",
                flexWrap: "wrap"
              }}>
                {["No credit card required", "Instant access", "Cancel anytime"].map((text, i) => (
                    <div key={i} style={{
                      display: "flex",
                      alignItems: "center",
                      gap: "0.5rem",
                      color: "white"
                    }}>
                      <span style={{ fontSize: "1.2rem" }}>✓</span>
                      <span>{text}</span>
                    </div>
                ))}
              </div>
            </div>
          </section>

          {/* Testimonials */}
          <section style={{
            padding: "4rem 0"
          }}>
            <div style={{ textAlign: "center", marginBottom: "3rem" }}>
              <h2 style={{
                fontSize: isMobile ? "2rem" : "2.5rem",
                fontWeight: "800"
              }}>
                What <span className="gradient-text">Parents Say</span>
              </h2>
            </div>

            <div style={{
              display: "grid",
              gridTemplateColumns: isMobile ? "1fr" : "repeat(3, 1fr)",
              gap: "2rem"
            }}>
              {[
                {
                  name: "Kamali Perera",
                  role: "Parent of Grade 4 Student",
                  content: "My daughter's confidence has grown so much! She actually looks forward to learning now.",
                  rating: 5,
                  avatar: "👩"
                },
                {
                  name: "Nuwan Silva",
                  role: "Father of Grade 3 Student",
                  content: "The adaptive learning feature is amazing. It perfectly matches my son's learning pace.",
                  rating: 5,
                  avatar: "👨"
                },
                {
                  name: "Dr. Priya Rajan",
                  role: "Child Psychologist",
                  content: "Finally, a platform that truly understands inclusive education. Highly recommended!",
                  rating: 5,
                  avatar: "👩‍⚕️"
                }
              ].map((testimonial, index) => (
                  <div
                      key={index}
                      style={{
                        background: "white",
                        borderRadius: "30px",
                        padding: "2rem",
                        boxShadow: "0 20px 40px rgba(0,0,0,0.05)",
                        position: "relative"
                      }}
                  >
                    <div style={{
                      fontSize: "4rem",
                      position: "absolute",
                      top: "1rem",
                      right: "1rem",
                      opacity: 0.1
                    }}>
                      ❝
                    </div>

                    <div style={{
                      display: "flex",
                      alignItems: "center",
                      gap: "1rem",
                      marginBottom: "1.5rem"
                    }}>
                      <div style={{
                        width: "60px",
                        height: "60px",
                        background: "linear-gradient(135deg, #004643, #007b72)",
                        borderRadius: "50%",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        fontSize: "2rem",
                        color: "white"
                      }}>
                        {testimonial.avatar}
                      </div>
                      <div>
                        <h4 style={{
                          fontWeight: "700",
                          margin: "0 0 0.3rem 0"
                        }}>
                          {testimonial.name}
                        </h4>
                        <p style={{
                          color: "#718096",
                          fontSize: "0.9rem",
                          margin: 0
                        }}>
                          {testimonial.role}
                        </p>
                      </div>
                    </div>

                    <p style={{
                      color: "#4a5568",
                      lineHeight: "1.7",
                      marginBottom: "1.5rem",
                      fontStyle: "italic"
                    }}>
                      "{testimonial.content}"
                    </p>

                    <div style={{
                      display: "flex",
                      gap: "0.3rem"
                    }}>
                      {[...Array(testimonial.rating)].map((_, i) => (
                          <span key={i} style={{ color: "#fbbf24", fontSize: "1.2rem" }}>★</span>
                      ))}
                    </div>
                  </div>
              ))}
            </div>
          </section>

          {/* Footer */}
          <footer style={{
            marginTop: "4rem",
            padding: "3rem 0 2rem",
            borderTop: "1px solid #e2e8f0"
          }}>
            <div style={{
              display: "grid",
              gridTemplateColumns: isMobile ? "1fr" : "repeat(4, 1fr)",
              gap: "2rem",
              marginBottom: "2rem"
            }}>
              <div>
                <h3 style={{
                  fontSize: "1.5rem",
                  fontWeight: "700",
                  marginBottom: "1rem"
                }}>
                  <span className="gradient-text">Shilpa</span>
                </h3>
                <p style={{
                  color: "#718096",
                  lineHeight: "1.7"
                }}>
                  Making learning inclusive, engaging, and accessible for every Sri Lankan child.
                </p>
              </div>

              {[
                {
                  title: "Quick Links",
                  links: ["About Us", "How It Works", "Pricing", "FAQ"]
                },
                {
                  title: "Resources",
                  links: ["Blog", "Parent Guide", "Teacher Resources", "Support"]
                },
                {
                  title: "Legal",
                  links: ["Privacy Policy", "Terms of Use", "Cookie Policy", "Contact"]
                }
              ].map((section, i) => (
                  <div key={i}>
                    <h4 style={{
                      fontWeight: "700",
                      marginBottom: "1rem",
                      color: "#1a202c"
                    }}>
                      {section.title}
                    </h4>
                    <ul style={{
                      listStyle: "none",
                      padding: 0,
                      margin: 0
                    }}>
                      {section.links.map((link, j) => (
                          <li key={j} style={{
                            marginBottom: "0.8rem"
                          }}>
                            <a href="#" style={{
                              color: "#718096",
                              textDecoration: "none",
                              transition: "color 0.3s ease"
                            }}
                               onMouseEnter={(e) => e.currentTarget.style.color = "#004643"}
                               onMouseLeave={(e) => e.currentTarget.style.color = "#718096"}>
                              {link}
                            </a>
                          </li>
                      ))}
                    </ul>
                  </div>
              ))}
            </div>

            <div style={{
              textAlign: "center",
              paddingTop: "2rem",
              borderTop: "1px solid #e2e8f0",
              color: "#718096",
              fontSize: "0.9rem"
            }}>
              <p>© {new Date().getFullYear()} Shilpa - Inclusive Learning Platform. All rights reserved.</p>
              <p style={{ marginTop: "0.5rem" }}>
                Made with ❤️ for Sri Lankan primary education (Grades 3-5)
              </p>
            </div>
          </footer>
        </div>
      </div>
  );
};

export default Home;