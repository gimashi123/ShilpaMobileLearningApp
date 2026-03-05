import { useEffect, useState } from "react";
import { useNavigate, Link } from "react-router-dom";

const Login = () => {
  const [isMobile, setIsMobile] = useState(false);
  const navigate = useNavigate();
  
  // Form state
  const [formData, setFormData] = useState({
    email: "",
    password: "",
    rememberMe: false
  });
  
  const [errors, setErrors] = useState<{ email?: string; password?: string }>({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [apiError, setApiError] = useState("");

  useEffect(() => {
    const checkMobile = () => {
      setIsMobile(window.innerWidth <= 768);
    };
    
    checkMobile();
    window.addEventListener('resize', checkMobile);
    
    return () => window.removeEventListener('resize', checkMobile);
    
  }, []);

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value, type, checked } = e.target as HTMLInputElement;
    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value
    }));
    
    // Clear error for this field
    if (name === 'email' || name === 'password') {
      if (errors[name]) {
        setErrors(prev => ({
          ...prev,
          [name]: ""
        }));
      }
    }
    // Clear API error when user starts typing
    if (apiError) setApiError("");
  };

  const validateForm = () => {
    const newErrors: { email?: string; password?: string } = {};
    
    if (!formData.email.trim()) {
      newErrors.email = "Email is required";
    } else if (!/\S+@\S+\.\S+/.test(formData.email)) {
      newErrors.email = "Email is invalid";
    }
    
    if (!formData.password) {
      newErrors.password = "Password is required";
    }
    
    return newErrors;
  };

  const handleSubmit = async (e: { preventDefault: () => void; }) => {
    e.preventDefault();
    
    const validationErrors = validateForm();
    if (Object.keys(validationErrors).length > 0) {
      setErrors(validationErrors);
      return;
    }
    
    setIsSubmitting(true);
    setApiError("");
    
    try {
      // API call to your backend
      const response = await fetch("http://localhost:3000/api/auth/login", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          email: formData.email,
          password: formData.password
        })
      });
      
      const data = await response.json();
      
      if (!response.ok) {
        throw new Error(data.message || "Login failed");
      }
      
      if (data.success) {
        // Save token to localStorage
        localStorage.setItem("token", data.data.token);
        
        // Remember me functionality
        if (formData.rememberMe) {
          localStorage.setItem("rememberedEmail", formData.email);
        } else {
          localStorage.removeItem("rememberedEmail");
        }
        
        // Show success message
        alert("Login successful! Welcome back to Shilpa!");
        
        // Redirect based on role
        if (data.data.user.role === 'student') {
          navigate("/student-dashboard");
        } else if (data.data.user.role === 'parent') {
          navigate("/parent-dashboard");
        } else if (data.data.user.role === 'teacher') {
          navigate("/teacher-dashboard");
        } else if (data.data.user.role === 'admin') {
          navigate("/admin-dashboard");
        } else {
          navigate("/dashboard");
        }
      } else {
        setApiError(data.message || "Login failed");
      }
      
    } catch (error) {
      console.error("Login error:", error);
      const errorMessage = error instanceof Error ? error.message : "Login failed. Please check your credentials and try again.";
      setApiError(errorMessage);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div style={{
      minHeight: "100vh",
      width: "100vw",
      background: "linear-gradient(135deg, #f0f9ff 0%, #fef7ff 100%)",
      fontFamily: "'Segoe UI', 'Inter', -apple-system, sans-serif",
      color: "#333",
      overflowX: "hidden",
      padding: isMobile ? "20px" : "40px 20px"
    }}>
      
      {/* Main Content Container */}
      <div style={{
        width: "100%",
        maxWidth: isMobile ? "100%" : "500px",
        margin: "0 auto",
        background: "white",
        borderRadius: "24px",
        boxShadow: "0 10px 40px rgba(0, 70, 67, 0.12)",
        padding: isMobile ? "30px 20px" : "40px",
        position: "relative",
        overflow: "hidden",
        minHeight: isMobile ? "auto" : "600px"
      }}>
        
        {/* Decorative Elements */}
        {!isMobile && (
          <>
            <div style={{
              position: "absolute",
              top: "-50px",
              right: "-50px",
              width: "200px",
              height: "200px",
              background: "linear-gradient(45deg, #00464322, #abd1c622)",
              borderRadius: "50%",
              zIndex: 0
            }} />
            
            <div style={{
              position: "absolute",
              bottom: "-40px",
              left: "-40px",
              width: "150px",
              height: "150px",
              background: "linear-gradient(45deg, #f9bc6022, #e1616222)",
              borderRadius: "50%",
              zIndex: 0
            }} />
          </>
        )}

        {/* Back to Home Link */}
        <div style={{
          marginBottom: "20px",
          position: "relative",
          zIndex: 1
        }}>
          <Link 
            to="/"
            style={{
              display: "inline-flex",
              alignItems: "center",
              gap: "8px",
              color: "#007b72",
              textDecoration: "none",
              fontWeight: "600",
              fontSize: "16px",
              transition: "all 0.3s ease"
            }}
            onMouseEnter={(e) => {
              e.currentTarget.style.gap = "12px";
              e.currentTarget.style.color = "#004643";
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.gap = "8px";
              e.currentTarget.style.color = "#007b72";
            }}
          >
            <span style={{ fontSize: "20px" }}>←</span> Back to Home
          </Link>
        </div>

        {/* Header */}
        <div style={{
          textAlign: "center",
          marginBottom: "30px",
          position: "relative",
          zIndex: 1
        }}>
          <div style={{
            width: "70px",
            height: "70px",
            background: "linear-gradient(135deg, #004643, #007b72)",
            borderRadius: "20px",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            margin: "0 auto 20px",
            boxShadow: "0 8px 25px rgba(0, 70, 67, 0.3)"
          }}>
            <span style={{ fontSize: "32px", color: "white" }}>🔐</span>
          </div>
          
          <h1 style={{
            background: "linear-gradient(90deg, #004643, #007b72)",
            WebkitBackgroundClip: "text",
            WebkitTextFillColor: "transparent",
            fontSize: isMobile ? "28px" : "32px",
            fontWeight: "800",
            margin: "0 0 8px 0",
            lineHeight: "1.3"
          }}>
            Welcome Back!
          </h1>
          
          <p style={{
            color: "#718096",
            fontSize: "16px",
            margin: "0"
          }}>
            Sign in to your Shilpa account
          </p>
        </div>

        {/* API Error Display */}
        {apiError && (
          <div style={{
            background: "#fee",
            border: "1px solid #e16162",
            borderRadius: "12px",
            padding: "15px",
            marginBottom: "20px",
            color: "#e16162",
            fontSize: "15px",
            display: "flex",
            alignItems: "center",
            gap: "10px"
          }}>
            <span style={{ fontSize: "20px" }}>❌</span>
            <span>{apiError}</span>
          </div>
        )}

        {/* Login Form */}
        <form onSubmit={handleSubmit} style={{
          position: "relative",
          zIndex: 1
        }}>
          
          {/* Email */}
          <div style={{ marginBottom: "20px" }}>
            <label style={{
              display: "block",
              marginBottom: "8px",
              fontWeight: "600",
              color: "#2d3748",
              fontSize: "16px"
            }}>
              Email Address *
            </label>
            <input
              type="email"
              name="email"
              value={formData.email}
              onChange={handleInputChange}
              placeholder="Enter your email"
              style={{
                width: "100%",
                padding: "16px",
                border: `2px solid ${errors.email ? "#e16162" : "#e2e8f0"}`,
                borderRadius: "12px",
                fontSize: "16px",
                transition: "all 0.3s ease",
                boxSizing: "border-box",
                outline: "none"
              }}
              onFocus={(e) => {
                e.target.style.borderColor = errors.email ? "#e16162" : "#004643";
                e.target.style.boxShadow = errors.email ? "0 0 0 3px rgba(225, 97, 98, 0.1)" : "0 0 0 3px rgba(0, 70, 67, 0.1)";
              }}
              onBlur={(e) => {
                e.target.style.borderColor = errors.email ? "#e16162" : "#e2e8f0";
                e.target.style.boxShadow = "none";
              }}
            />
            {errors.email && (
              <div style={{
                color: "#e16162",
                fontSize: "14px",
                marginTop: "6px",
                display: "flex",
                alignItems: "center",
                gap: "6px"
              }}>
                <span>⚠️</span> {errors.email}
              </div>
            )}
          </div>

          {/* Password */}
          <div style={{ marginBottom: "20px" }}>
            <div style={{
              display: "flex",
              justifyContent: "space-between",
              alignItems: "center",
              marginBottom: "8px"
            }}>
              <label style={{
                fontWeight: "600",
                color: "#2d3748",
                fontSize: "16px"
              }}>
                Password *
              </label>
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                style={{
                  background: "none",
                  border: "none",
                  color: "#007b72",
                  cursor: "pointer",
                  fontSize: "14px",
                  fontWeight: "600",
                  display: "flex",
                  alignItems: "center",
                  gap: "6px",
                  padding: "0"
                }}
                onMouseEnter={(e) => {
                  e.currentTarget.style.color = "#004643";
                }}
                onMouseLeave={(e) => {
                  e.currentTarget.style.color = "#007b72";
                }}
              >
                {showPassword ? (
                  <>
                    <span>👁️</span> Hide
                  </>
                ) : (
                  <>
                    <span>👁️‍🗨️</span> Show
                  </>
                )}
              </button>
            </div>
            
            <div style={{ position: "relative" }}>
              <input
                type={showPassword ? "text" : "password"}
                name="password"
                value={formData.password}
                onChange={handleInputChange}
                placeholder="Enter your password"
                style={{
                  width: "100%",
                  padding: "16px",
                  border: `2px solid ${errors.password ? "#e16162" : "#e2e8f0"}`,
                  borderRadius: "12px",
                  fontSize: "16px",
                  transition: "all 0.3s ease",
                  boxSizing: "border-box",
                  outline: "none",
                  paddingRight: "50px"
                }}
                onFocus={(e) => {
                  e.target.style.borderColor = errors.password ? "#e16162" : "#004643";
                  e.target.style.boxShadow = errors.password ? "0 0 0 3px rgba(225, 97, 98, 0.1)" : "0 0 0 3px rgba(0, 70, 67, 0.1)";
                }}
                onBlur={(e) => {
                  e.target.style.borderColor = errors.password ? "#e16162" : "#e2e8f0";
                  e.target.style.boxShadow = "none";
                }}
              />
            </div>
            {errors.password && (
              <div style={{
                color: "#e16162",
                fontSize: "14px",
                marginTop: "6px",
                display: "flex",
                alignItems: "center",
                gap: "6px"
              }}>
                <span>⚠️</span> {errors.password}
              </div>
            )}
          </div>

          {/* Remember Me & Forgot Password */}
          <div style={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            marginBottom: "30px",
            flexWrap: "wrap",
            gap: "10px"
          }}>
            <label style={{
              display: "flex",
              alignItems: "center",
              gap: "8px",
              cursor: "pointer",
              fontSize: "15px",
              color: "#2d3748"
            }}>
              <input
                type="checkbox"
                name="rememberMe"
                checked={formData.rememberMe}
                onChange={handleInputChange}
                style={{
                  width: "18px",
                  height: "18px",
                  cursor: "pointer"
                }}
              />
              Remember me
            </label>
            
            <Link 
              to="/forgot-password"
              style={{
                color: "#007b72",
                fontWeight: "600",
                fontSize: "15px",
                textDecoration: "none",
                transition: "all 0.3s ease"
              }}
              onMouseEnter={(e) => {
                e.currentTarget.style.color = "#004643";
                e.currentTarget.style.textDecoration = "underline";
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.color = "#007b72";
                e.currentTarget.style.textDecoration = "none";
              }}
            >
              Forgot password?
            </Link>
          </div>

          {/* Submit Button */}
          <button
            type="submit"
            disabled={isSubmitting}
            style={{
              width: "100%",
              padding: "18px",
              fontSize: "18px",
              fontWeight: "700",
              background: "linear-gradient(90deg, #004643, #007b72)",
              color: "white",
              border: "none",
              borderRadius: "12px",
              cursor: isSubmitting ? "not-allowed" : "pointer",
              transition: "all 0.3s ease",
              boxShadow: "0 8px 25px rgba(0, 70, 67, 0.4)",
              position: "relative",
              overflow: "hidden",
              opacity: isSubmitting ? 0.8 : 1,
              marginBottom: "30px"
            }}
            onMouseEnter={(e) => {
              if (!isSubmitting) {
                e.currentTarget.style.transform = "translateY(-3px)";
                e.currentTarget.style.boxShadow = "0 15px 35px rgba(0, 70, 67, 0.6)";
              }
            }}
            onMouseLeave={(e) => {
              if (!isSubmitting) {
                e.currentTarget.style.transform = "translateY(0)";
                e.currentTarget.style.boxShadow = "0 8px 25px rgba(0, 70, 67, 0.4)";
              }
            }}
          >
            {isSubmitting ? (
              <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: "10px" }}>
                <div style={{
                  width: "20px",
                  height: "20px",
                  border: "3px solid rgba(255,255,255,0.3)",
                  borderTop: "3px solid white",
                  borderRadius: "50%",
                  animation: "spin 1s linear infinite"
                }} />
                Signing In...
              </div>
            ) : (
              <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: "10px" }}>
                <span style={{ fontSize: "20px" }}>🔑</span>
                Sign In
              </div>
            )}
          </button>

          {/* Divider */}
          <div style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            marginBottom: "30px"
          }}>
            <div style={{
              flex: 1,
              height: "1px",
              background: "#e2e8f0"
            }} />
            <span style={{
              padding: "0 15px",
              color: "#718096",
              fontSize: "14px"
            }}>
              Don't have an account?
            </span>
            <div style={{
              flex: 1,
              height: "1px",
              background: "#e2e8f0"
            }} />
          </div>

          {/* Register Link */}
          <div style={{
            textAlign: "center"
          }}>
            <Link 
              to="/register"
              style={{
                display: "inline-block",
                width: "100%",
                padding: "16px",
                fontSize: "16px",
                fontWeight: "600",
                background: "transparent",
                color: "#007b72",
                border: "2px solid #007b72",
                borderRadius: "12px",
                cursor: "pointer",
                transition: "all 0.3s ease",
                textDecoration: "none",
                textAlign: "center"
              }}
              onMouseEnter={(e) => {
                e.currentTarget.style.background = "#e8f4f3";
                e.currentTarget.style.color = "#004643";
                e.currentTarget.style.borderColor = "#004643";
                e.currentTarget.style.transform = "translateY(-3px)";
                e.currentTarget.style.boxShadow = "0 8px 25px rgba(0, 70, 67, 0.15)";
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.background = "transparent";
                e.currentTarget.style.color = "#007b72";
                e.currentTarget.style.borderColor = "#007b72";
                e.currentTarget.style.transform = "translateY(0)";
                e.currentTarget.style.boxShadow = "none";
              }}
            >
              <span style={{ fontSize: "18px", marginRight: "8px" }}>📝</span>
              Create New Account
            </Link>
          </div>
        </form>

        {/* Footer */}
        <footer style={{
          marginTop: "40px",
          textAlign: "center",
          paddingTop: "20px",
          borderTop: "1px solid #e2e8f0",
          color: "#718096",
          fontSize: "14px",
          position: "relative",
          zIndex: 1
        }}>
          <p style={{ margin: "0 0 5px 0" }}>
            © {new Date().getFullYear()} Shilpa - Inclusive Learning Platform
          </p>
          <p style={{ margin: "0", fontSize: "12px" }}>
            Designed for Sri Lankan primary education (Grades 3-5)
          </p>
        </footer>
      </div>

      <style>{`
        @keyframes spin {
          0% { transform: rotate(0deg); }
          100% { transform: rotate(360deg); }
        }
      `}</style>
    </div>
  );
};

export default Login;