import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { registerUser } from "../services/authApi";

type Role = "student" | "teacher" | "parent";

export default function Register() {
  const navigate = useNavigate();

  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");

  const [role, setRole] = useState<Role>("teacher");

  // Student-only fields
  const [disabilityType, setDisabilityType] = useState("");
  const [grade, setGrade] = useState<number | "">("");
  const [age, setAge] = useState<number | "">("");

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setLoading(true);

    try {
      const payload: any = {
        name,
        email,
        password,
        role,
      };

      // Backend REQUIREMENTS for students
      if (role === "student") {
        if (!disabilityType || !grade) {
          throw new Error("Disability type and grade are required for students");
        }

        payload.disabilityType = disabilityType;
        payload.grade = Number(grade);
        if (age) payload.age = Number(age);
      }

      await registerUser(payload);

      // After successful register → go login
      navigate("/login");
    } catch (err: any) {
      setError(err.message || "Registration failed");
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
            Create Account
          </h1>
          <p className="mt-1 text-sm font-semibold text-slate-500">
            Register to start learning with ශිල්ප
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
          {/* Name */}
          <div>
            <label className="text-sm font-bold text-slate-700">
              Full Name
            </label>
            <input
              type="text"
              placeholder="Enter your full name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="mt-1 w-full rounded-xl border border-slate-200 px-4 py-2 text-sm focus:border-blue-500 focus:outline-none"
              required
            />
          </div>

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
              placeholder="Create a password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="mt-1 w-full rounded-xl border border-slate-200 px-4 py-2 text-sm focus:border-blue-500 focus:outline-none"
              required
            />
          </div>

          {/* Role */}
          <div>
            <label className="text-sm font-bold text-slate-700">
              Register As
            </label>
            <select
              value={role}
              onChange={(e) => setRole(e.target.value as Role)}
              className="mt-1 w-full rounded-xl border border-slate-200 bg-white px-4 py-2 text-sm focus:border-blue-500 focus:outline-none"
            >
              <option value="teacher">Teacher</option>
              <option value="parent">Parent</option>
              <option value="student">Student</option>
            </select>
          </div>

          {/* Student-only fields */}
          {role === "student" && (
            <>
              <div>
                <label className="text-sm font-bold text-slate-700">
                  Disability Type
                </label>
                <input
                  type="text"
                  placeholder="Visual / Hearing / Cognitive"
                  value={disabilityType}
                  onChange={(e) => setDisabilityType(e.target.value)}
                  className="mt-1 w-full rounded-xl border border-slate-200 px-4 py-2 text-sm"
                  required
                />
              </div>

              <div>
                <label className="text-sm font-bold text-slate-700">
                  Grade
                </label>
                <select
                  value={grade}
                  onChange={(e) => setGrade(Number(e.target.value))}
                  className="mt-1 w-full rounded-xl border border-slate-200 bg-white px-4 py-2 text-sm"
                  required
                >
                  <option value="">Select grade</option>
                  <option value={3}>Grade 3</option>
                  <option value={4}>Grade 4</option>
                  <option value={5}>Grade 5</option>
                </select>
              </div>

              <div>
                <label className="text-sm font-bold text-slate-700">
                  Age (optional)
                </label>
                <input
                  type="number"
                  placeholder="Age"
                  value={age}
                  onChange={(e) => setAge(Number(e.target.value))}
                  className="mt-1 w-full rounded-xl border border-slate-200 px-4 py-2 text-sm"
                />
              </div>
            </>
          )}

          {/* Submit */}
          <button
            type="submit"
            disabled={loading}
            className="mt-4 w-full rounded-xl bg-blue-600 px-4 py-3 text-sm font-extrabold text-white hover:bg-blue-700 disabled:opacity-60"
          >
            {loading ? "Creating account..." : "Register"}
          </button>
        </form>

        {/* Footer */}
        <div className="mt-6 text-center text-sm font-semibold text-slate-600">
          Already have an account?{" "}
          <Link
            to="/login"
            className="font-extrabold text-blue-600 hover:underline"
          >
            Login
          </Link>
        </div>
      </div>
    </div>
  );
}
