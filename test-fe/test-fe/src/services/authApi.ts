const API_BASE =
  import.meta.env.VITE_API_BASE_URL || "http://localhost:3000";

export async function loginUser(email: string, password: string) {
  const res = await fetch(`${API_BASE}/api/auth/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password }),
  });

  const json = await res.json();

  if (!res.ok) {
    throw new Error(json?.message || "Login failed");
  }

  // Support both:
  // 1) { token, user }
  // 2) { data: { token, user } }
  const payload = json?.data ?? json;

  if (!payload?.token || !payload?.user) {
    throw new Error("Login response missing token/user");
  }

  return payload; // always { token, user }
}


/**
 * REGISTER
 */
export async function registerUser(payload: {
  name: string;
  email: string;
  password: string;
  role: "student" | "teacher" | "parent";
  disabilityType?: string;
  grade?: number;
  age?: number;
}) {
  const res = await fetch(`${API_BASE}/auth/register`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });

  const data = await res.json();

  if (!res.ok) {
    throw new Error(data.message || "Register failed");
  }

  return data;
}
