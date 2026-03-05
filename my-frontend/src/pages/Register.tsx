import { useEffect, useState } from "react";
import { useNavigate, Link } from "react-router-dom";

const Register = () => {
  const [isMobile, setIsMobile] = useState(false);
  const navigate = useNavigate();
  
  // Form state
  const [formData, setFormData] = useState({
    name: "",
    email: "",
    role: "parent",
    password: "",
    disabilityType: "",
    grade: "",
    age: "",
    agreeToTerms: false,
    receiveUpdates: true
  });
  
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [apiError, setApiError] = useState("");

  useEffect(() => {
    const checkMobile = () => {
      setIsMobile(window.innerWidth <= 768);
    };
    
    checkMobile();
    window.addEventListener('resize', checkMobile);
    
    return () => window.removeEventListener('resize', checkMobile);
  }, []);

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value, type, checked } = e.target as HTMLInputElement;
    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value
    }));
    
    if (errors[name]) {
      setErrors(prev => ({ ...prev, [name]: "" }));
    }
    if (apiError) setApiError("");
  };

  const validateForm = () => {
    const newErrors: Record<string, string> = {};
    
    if (!formData.name.trim()) {
      newErrors.name = "Name is required";
    }
    
    if (!formData.email.trim()) {
      newErrors.email = "Email is required";
    } else if (!/\S+@\S+\.\S+/.test(formData.email)) {
      newErrors.email = "Email is invalid";
    }
    
    if (!formData.role) {
      newErrors.role = "Please select a role";
    }
    
    if (formData.role === "student") {
      if (!formData.disabilityType) {
        newErrors.disabilityType = "Disability type is required";
      }
      
      if (!formData.grade) {
        newErrors.grade = "Grade is required";
      } else if (!["3", "4", "5"].includes(formData.grade)) {
        newErrors.grade = "Grade must be 3, 4, or 5";
      }
      
      if (formData.age) {
        const ageNum = Number(formData.age);
        if (isNaN(ageNum) || ageNum < 5 || ageNum > 12) {
          newErrors.age = "Age must be between 5 and 12";
        }
      }
    }
    
    if (!formData.password) {
      newErrors.password = "Password is required";
    } else if (formData.password.length < 6) {
      newErrors.password = "Password must be at least 6 characters";
    }
    
    if (!formData.agreeToTerms) {
      newErrors.agreeToTerms = "You must agree to the terms";
    }
    
    return newErrors;
  };

  const handleSubmit = async (e: { preventDefault: () => void; }) => {
    e.preventDefault();
    setApiError("");
    
    const validationErrors = validateForm();
    if (Object.keys(validationErrors).length > 0) {
      setErrors(validationErrors);
      return;
    }
    
    setIsSubmitting(true);
    
    try {
      const submitData: {
        name: string;
        email: string;
        password: string;
        role: string;
        disabilityType?: string;
        grade?: number;
        age?: number;
      } = {
        name: formData.name,
        email: formData.email,
        password: formData.password,
        role: formData.role,
      };
      
      if (formData.role === "student") {
        submitData.disabilityType = formData.disabilityType;
        submitData.grade = parseInt(formData.grade);
        if (formData.age) submitData.age = parseInt(formData.age);
      }
      
      const response = await fetch("http://localhost:3000/api/auth/register", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(submitData)
      });
      
      const data = await response.json();
      
      if (!response.ok) {
        throw new Error(data.message || "Registration failed");
      }
      
      if (data.success) {
        localStorage.setItem("token", data.data.token);
        alert("Registration successful! Welcome to Shilpa!");
        
        if (data.data.user.role === 'student') {
          navigate("/student-dashboard");
        } else if (data.data.user.role === 'parent') {
          navigate("/parent-dashboard");
        } else if (data.data.user.role === 'teacher') {
          navigate("/teacher-dashboard");
        } else {
          navigate("/dashboard");
        }
      } else {
        setApiError(data.message || "Registration failed");
      }
      
    } catch (error) {
      console.error("Registration error:", error);
      setApiError(
        typeof error === "object" && error !== null && "message" in error
          ? (error as { message?: string }).message || "Registration failed. Please try again."
          : "Registration failed. Please try again."
      );
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
            <span style={{ fontSize: "32px", color: "white" }}>🎓</span>
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
            Create Your Account
          </h1>
          
          <p style={{
            color: "#718096",
            fontSize: "16px",
            margin: "0"
          }}>
            Join Shilpa's inclusive learning community
          </p>
        </div>

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

        <form onSubmit={handleSubmit} style={{
          position: "relative",
          zIndex: 1
        }}>
          
          <div style={{ marginBottom: "20px" }}>
            <label style={{
              display: "block",
              marginBottom: "8px",
              fontWeight: "600",
              color: "#2d3748",
              fontSize: "16px"
            }}>
              Name *
            </label>
            <input
              type="text"
              name="name"
              value={formData.name}
              onChange={handleInputChange}
              placeholder="Enter your full name"
              style={{
                width: "100%",
                padding: "16px",
                border: `2px solid ${errors.name ? "#e16162" : "#e2e8f0"}`,
                borderRadius: "12px",
                fontSize: "16px",
                transition: "all 0.3s ease",
                boxSizing: "border-box",
                outline: "none"
              }}
              onFocus={(e) => {
                e.target.style.borderColor = errors.name ? "#e16162" : "#004643";
                e.target.style.boxShadow = errors.name ? "0 0 0 3px rgba(225, 97, 98, 0.1)" : "0 0 0 3px rgba(0, 70, 67, 0.1)";
              }}
              onBlur={(e) => {
                e.target.style.borderColor = errors.name ? "#e16162" : "#e2e8f0";
                e.target.style.boxShadow = "none";
              }}
            />
            {errors.name && (
              <div style={{
                color: "#e16162",
                fontSize: "14px",
                marginTop: "6px",
                display: "flex",
                alignItems: "center",
                gap: "6px"
              }}>
                <span>⚠️</span> {errors.name}
              </div>
            )}
          </div>

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

          <div style={{ marginBottom: "20px" }}>
            <label style={{
              display: "block",
              marginBottom: "8px",
              fontWeight: "600",
              color: "#2d3748",
              fontSize: "16px"
            }}>
              Role *
            </label>
            <div style={{ position: "relative" }}>
              <select
                name="role"
                value={formData.role}
                onChange={handleInputChange}
                style={{
                  width: "100%",
                  padding: "16px",
                  border: `2px solid ${errors.role ? "#e16162" : "#e2e8f0"}`,
                  borderRadius: "12px",
                  fontSize: "16px",
                  transition: "all 0.3s ease",
                  boxSizing: "border-box",
                  outline: "none",
                  background: "white",
                  appearance: "none",
                  cursor: "pointer"
                }}
                onFocus={(e) => {
                  e.target.style.borderColor = errors.role ? "#e16162" : "#004643";
                  e.target.style.boxShadow = errors.role ? "0 0 0 3px rgba(225, 97, 98, 0.1)" : "0 0 0 3px rgba(0, 70, 67, 0.1)";
                }}
                onBlur={(e) => {
                  e.target.style.borderColor = errors.role ? "#e16162" : "#e2e8f0";
                  e.target.style.boxShadow = "none";
                }}
              >
                <option value="">Select your role</option>
                <option value="parent">👪 Parent / Guardian</option>
                <option value="teacher">👨‍🏫 Teacher / Educator</option>
                <option value="student">🎓 Student</option>
              </select>
              <div style={{
                position: "absolute",
                right: "16px",
                top: "50%",
                transform: "translateY(-50%)",
                pointerEvents: "none",
                fontSize: "20px",
                color: "#004643"
              }}>
                ▼
              </div>
            </div>
            {errors.role && (
              <div style={{
                color: "#e16162",
                fontSize: "14px",
                marginTop: "6px",
                display: "flex",
                alignItems: "center",
                gap: "6px"
              }}>
                <span>⚠️</span> {errors.role}
              </div>
            )}
            
            <div style={{
              marginTop: "10px",
              fontSize: "14px",
              color: "#718096",
              display: "flex",
              alignItems: "flex-start",
              gap: "8px",
              background: "#f8fafc",
              padding: "12px",
              borderRadius: "8px",
              borderLeft: "3px solid #007b72"
            }}>
              <div style={{ fontSize: "16px", marginTop: "1px" }}>
                {formData.role === "parent" ? "👪" : 
                 formData.role === "teacher" ? "👨‍🏫" : 
                 formData.role === "student" ? "🎓" : "💡"}
              </div>
              <div>
                {formData.role === "parent" && (
                  <>Track your child's progress and support their learning journey.</>
                )}
                {formData.role === "teacher" && (
                  <>Create classes and monitor student progress.</>
                )}
                {formData.role === "student" && (
                  <>Access personalized learning materials and track your progress.</>
                )}
                {!formData.role && (
                  <>Select your role to continue.</>
                )}
              </div>
            </div>
          </div>

          {formData.role === "student" && (
            <>
              <div style={{ marginBottom: "20px" }}>
                <label style={{
                  display: "block",
                  marginBottom: "8px",
                  fontWeight: "600",
                  color: "#2d3748",
                  fontSize: "16px"
                }}>
                  Disability Type *
                </label>
                <div style={{ position: "relative" }}>
                  <select
                    name="disabilityType"
                    value={formData.disabilityType}
                    onChange={handleInputChange}
                    style={{
                      width: "100%",
                      padding: "16px",
                      border: `2px solid ${errors.disabilityType ? "#e16162" : "#e2e8f0"}`,
                      borderRadius: "12px",
                      fontSize: "16px",
                      transition: "all 0.3s ease",
                      boxSizing: "border-box",
                      outline: "none",
                      background: "white",
                      appearance: "none",
                      cursor: "pointer"
                    }}
                    onFocus={(e) => {
                      e.target.style.borderColor = errors.disabilityType ? "#e16162" : "#004643";
                      e.target.style.boxShadow = errors.disabilityType ? "0 0 0 3px rgba(225, 97, 98, 0.1)" : "0 0 0 3px rgba(0, 70, 67, 0.1)";
                    }}
                    onBlur={(e) => {
                      e.target.style.borderColor = errors.disabilityType ? "#e16162" : "#e2e8f0";
                      e.target.style.boxShadow = "none";
                    }}
                  >
                    <option value="">Select disability type</option>
                    <option value="visual">👁️ Visual Impairment</option>
                    <option value="hearing">👂 Hearing Impairment</option>
                    <option value="physical">🦾 Physical Disability</option>
                    <option value="cognitive">🧠 Cognitive/Learning Disability</option>
                    <option value="none">🌟 No Disability</option>
                  </select>
                  <div style={{
                    position: "absolute",
                    right: "16px",
                    top: "50%",
                    transform: "translateY(-50%)",
                    pointerEvents: "none",
                    fontSize: "20px",
                    color: "#004643"
                  }}>
                    ▼
                  </div>
                </div>
                {errors.disabilityType && (
                  <div style={{
                    color: "#e16162",
                    fontSize: "14px",
                    marginTop: "6px",
                    display: "flex",
                    alignItems: "center",
                    gap: "6px"
                  }}>
                    <span>⚠️</span> {errors.disabilityType}
                  </div>
                )}
              </div>

              <div style={{ marginBottom: "20px" }}>
                <label style={{
                  display: "block",
                  marginBottom: "8px",
                  fontWeight: "600",
                  color: "#2d3748",
                  fontSize: "16px"
                }}>
                  Grade *
                </label>
                <div style={{
                  display: "grid",
                  gridTemplateColumns: "repeat(3, 1fr)",
                  gap: "10px"
                }}>
                  {["3", "4", "5"].map((grade) => (
                    <div
                      key={grade}
                      onClick={() => {
                        setFormData(prev => ({ ...prev, grade }));
                        if (errors.grade) {
                          setErrors(prev => ({ ...prev, grade: "" }));
                        }
                      }}
                      style={{
                        padding: "16px",
                        border: `2px solid ${formData.grade === grade ? "#004643" : "#e2e8f0"}`,
                        borderRadius: "10px",
                        textAlign: "center",
                        cursor: "pointer",
                        transition: "all 0.3s ease",
                        backgroundColor: formData.grade === grade ? "#e8f4f3" : "white",
                        fontSize: "18px",
                        fontWeight: "600"
                      }}
                      onMouseEnter={(e) => {
                        if (formData.grade !== grade) {
                          e.currentTarget.style.borderColor = "#007b72";
                        }
                      }}
                      onMouseLeave={(e) => {
                        if (formData.grade !== grade) {
                          e.currentTarget.style.borderColor = "#e2e8f0";
                        }
                      }}
                    >
                      Grade {grade}
                    </div>
                  ))}
                </div>
                {errors.grade && (
                  <div style={{
                    color: "#e16162",
                    fontSize: "14px",
                    marginTop: "8px",
                    display: "flex",
                    alignItems: "center",
                    gap: "6px"
                  }}>
                    <span>⚠️</span> {errors.grade}
                  </div>
                )}
              </div>

              <div style={{ marginBottom: "20px" }}>
                <label style={{
                  display: "block",
                  marginBottom: "8px",
                  fontWeight: "600",
                  color: "#2d3748",
                  fontSize: "16px"
                }}>
                  Age (Optional)
                </label>
                <input
                  type="number"
                  name="age"
                  value={formData.age}
                  onChange={handleInputChange}
                  placeholder="Enter age (5-12)"
                  min="5"
                  max="12"
                  style={{
                    width: "100%",
                    padding: "16px",
                    border: `2px solid ${errors.age ? "#e16162" : "#e2e8f0"}`,
                    borderRadius: "12px",
                    fontSize: "16px",
                    transition: "all 0.3s ease",
                    boxSizing: "border-box",
                    outline: "none"
                  }}
                  onFocus={(e) => {
                    e.target.style.borderColor = errors.age ? "#e16162" : "#004643";
                    e.target.style.boxShadow = errors.age ? "0 0 0 3px rgba(225, 97, 98, 0.1)" : "0 0 0 3px rgba(0, 70, 67, 0.1)";
                  }}
                  onBlur={(e) => {
                    e.target.style.borderColor = errors.age ? "#e16162" : "#e2e8f0";
                    e.target.style.boxShadow = "none";
                  }}
                />
                {errors.age && (
                  <div style={{
                    color: "#e16162",
                    fontSize: "14px",
                    marginTop: "6px",
                    display: "flex",
                    alignItems: "center",
                    gap: "6px"
                  }}>
                    <span>⚠️</span> {errors.age}
                  </div>
                )}
              </div>
            </>
          )}

          <div style={{ marginBottom: "20px" }}>
            <label style={{
              display: "block",
              marginBottom: "8px",
              fontWeight: "600",
              color: "#2d3748",
              fontSize: "16px"
            }}>
              Password *
            </label>
            <input
              type="password"
              name="password"
              value={formData.password}
              onChange={handleInputChange}
              placeholder="Create a password (min. 6 characters)"
              style={{
                width: "100%",
                padding: "16px",
                border: `2px solid ${errors.password ? "#e16162" : "#e2e8f0"}`,
                borderRadius: "12px",
                fontSize: "16px",
                transition: "all 0.3s ease",
                boxSizing: "border-box",
                outline: "none"
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

          <div style={{ marginBottom: "30px" }}>
            <div style={{ marginBottom: "15px" }}>
              <label style={{
                display: "flex",
                alignItems: "flex-start",
                gap: "12px",
                cursor: "pointer"
              }}>
                <input
                  type="checkbox"
                  name="agreeToTerms"
                  checked={formData.agreeToTerms}
                  onChange={handleInputChange}
                  style={{
                    width: "20px",
                    height: "20px",
                    marginTop: "3px",
                    cursor: "pointer"
                  }}
                />
                <div>
                  <div style={{
                    color: errors.agreeToTerms ? "#e16162" : "#2d3748",
                    fontSize: "15px",
                    lineHeight: "1.5"
                  }}>
                    I agree to the{" "}
                    <Link 
                      to="/terms" 
                      style={{ 
                        color: "#007b72", 
                        fontWeight: "600",
                        textDecoration: "none"
                      }}
                    >
                      Terms
                    </Link>
                    {" "}and{" "}
                    <Link 
                      to="/privacy" 
                      style={{ 
                        color: "#007b72", 
                        fontWeight: "600",
                        textDecoration: "none"
                      }}
                    >
                      Privacy Policy
                    </Link>
                    *
                  </div>
                  {errors.agreeToTerms && (
                    <div style={{
                      color: "#e16162",
                      fontSize: "14px",
                      marginTop: "6px",
                      display: "flex",
                      alignItems: "center",
                      gap: "6px"
                    }}>
                      <span>⚠️</span> {errors.agreeToTerms}
                    </div>
                  )}
                </div>
              </label>
            </div>

            <div>
              <label style={{
                display: "flex",
                alignItems: "flex-start",
                gap: "12px",
                cursor: "pointer"
              }}>
                <input
                  type="checkbox"
                  name="receiveUpdates"
                  checked={formData.receiveUpdates}
                  onChange={handleInputChange}
                  style={{
                    width: "20px",
                    height: "20px",
                    marginTop: "3px",
                    cursor: "pointer"
                  }}
                />
                <div style={{
                  color: "#4a5568",
                  fontSize: "15px",
                  lineHeight: "1.5"
                }}>
                  I want to receive updates from Shilpa
                </div>
              </label>
            </div>
          </div>

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
              opacity: isSubmitting ? 0.8 : 1
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
                Creating Account...
              </div>
            ) : (
              <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: "10px" }}>
                <span style={{ fontSize: "20px" }}>🚀</span>
                Create Account
              </div>
            )}
          </button>

          <div style={{
            textAlign: "center",
            marginTop: "30px",
            paddingTop: "20px",
            borderTop: "1px solid #e2e8f0",
            color: "#718096",
            fontSize: "16px"
          }}>
            Already have an account?{" "}
            <Link 
              to="/login"
              style={{
                color: "#007b72",
                fontWeight: "600",
                textDecoration: "none"
              }}
            >
              Sign In
            </Link>
          </div>
        </form>

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

export default Register;