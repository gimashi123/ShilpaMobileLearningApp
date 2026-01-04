import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { loginUser } from "../services/authApi";


export default function Login() {
  const navigate = useNavigate();

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setLoading(true);

    try {
      const data = await loginUser(email, password);

      // Your backend returns: { token, user }
      localStorage.setItem("token", data.token);
      localStorage.setItem("user", JSON.stringify(data.user));

      // Optional: role-based redirect
      if (data.user.role === "teacher") {
        navigate("/teacher/dashboard");
      } else if (data.user.role === "parent") {
        navigate("/parent/dashboard");
      } else if (data.user.role === "admin") {
        navigate("/admin/dashboard");
      } else {
        navigate("/home");
      }
    } catch (err: any) {
      setError(err.message || "Login failed");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="min-h-screen bg-slate-50 flex items-center justify-center px-4">
      <div className="w-full max-w-md rounded-3xl bg-white p-8 shadow-sm ring-1 ring-black/5">
        {/* Header */}
        <div className="text-center">
          <h1 className="text-2xl font-extrabold text-slate-900">
            Login
          </h1>
          <p className="mt-1 text-sm font-semibold text-slate-500">
            Welcome back to ශිල්ප
          </p>
        </div>

        {/* Error */}
        {error && (
          <div className="mt-4 rounded-xl bg-red-50 p-3 text-sm font-semibold text-red-700">
            {error}
          </div>
        )}

        {/* Form */}
        <form onSubmit={handleSubmit} className="mt-6 space-y-4">
          {/* Email */}
          <div>
            <label className="text-sm font-bold text-slate-700">
              Email Address
            </label>
            <input
              type="email"
              placeholder="example@email.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="mt-1 w-full rounded-xl border border-slate-200 px-4 py-2 text-sm focus:border-blue-500 focus:outline-none"
              required
            />
          </div>

          {/* Password */}
          <div>
            <label className="text-sm font-bold text-slate-700">
              Password
            </label>
            <input
              type="password"
              placeholder="Enter your password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="mt-1 w-full rounded-xl border border-slate-200 px-4 py-2 text-sm focus:border-blue-500 focus:outline-none"
              required
            />
          </div>

          {/* Remember / Forgot */}
          <div className="flex items-center justify-between text-sm">
            <label className="flex items-center gap-2 font-semibold text-slate-600">
              <input type="checkbox" className="rounded border-slate-300" />
              Remember me
            </label>

            <Link
              to="#"
              className="font-semibold text-blue-600 hover:underline"
            >
              Forgot password?
            </Link>
          </div>

          {/* Submit */}
          <button
            type="submit"
            disabled={loading}
            className="mt-4 w-full rounded-xl bg-blue-600 px-4 py-3 text-sm font-extrabold text-white hover:bg-blue-700 disabled:opacity-60"
          >
            {loading ? "Logging in..." : "Login"}
          </button>
        </form>

        {/* Footer */}
        <div className="mt-6 text-center text-sm font-semibold text-slate-600">
          Don’t have an account?{" "}
          <Link
            to="/register"
            className="font-extrabold text-blue-600 hover:underline"
          >
            Register
          </Link>
        </div>
      </div>
    </div>
  );
}
