import { useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";

type User = {
  id?: string;
  name: string;
  email: string;
  role: string;
};

type Activity = {
  time: string;
  action: string;
  by: string;
  status: "success" | "warning" | "danger";
};

export default function AdminDashboard() {
  const navigate = useNavigate();
  const [user, setUser] = useState<User | null>(null);

  // Example dashboard data (replace later with real API data)
  const stats = useMemo(
    () => [
      { title: "Total Users", value: "—", hint: "All roles combined" },
      { title: "Students", value: "—", hint: "Registered students" },
      { title: "Teachers", value: "—", hint: "Registered teachers" },
      { title: "Parents", value: "—", hint: "Registered parents" },
    ],
    [],
  );

  const activities: Activity[] = [
    { time: "Today 10:12", action: "New user registered", by: "system", status: "success" },
    { time: "Today 09:40", action: "Login failed attempt", by: "unknown", status: "warning" },
    { time: "Yesterday 18:22", action: "Role updated", by: "admin", status: "success" },
    { time: "Yesterday 15:05", action: "Account disabled", by: "admin", status: "danger" },
  ];

  useEffect(() => {
    const token = localStorage.getItem("token");
    const storedUser = localStorage.getItem("user");

    if (!token || !storedUser) {
      navigate("/login");
      return;
    }

    const parsed = JSON.parse(storedUser) as User;

    // Only allow admin
    if (parsed.role !== "admin") {
      navigate("/login");
      return;
    }

    setUser(parsed);
  }, [navigate]);

  function logout() {
    localStorage.removeItem("token");
    localStorage.removeItem("user");
    navigate("/login");
  }

  if (!user) return null;

  return (
    <div className="min-h-screen bg-slate-50">
      {/* Top Bar */}
      <header className="sticky top-0 z-50 border-b bg-white/90 backdrop-blur">
        <div className="mx-auto flex max-w-6xl items-center justify-between gap-4 px-4 py-4">
          <div>
            <h1 className="text-xl font-extrabold text-slate-900">Admin Dashboard</h1>
            <p className="text-sm font-semibold text-slate-500">
              Manage users, roles, and platform settings
            </p>
          </div>

          <div className="flex items-center gap-3">
            <div className="hidden sm:block text-right">
              <div className="text-sm font-extrabold text-slate-900">{user.name}</div>
              <div className="text-xs font-semibold text-slate-500">{user.email}</div>
            </div>
            <button
              onClick={logout}
              className="rounded-xl bg-red-500 px-4 py-2 text-sm font-extrabold text-white hover:bg-red-600"
            >
              Logout
            </button>
          </div>
        </div>
      </header>

      {/* Content */}
      <main className="mx-auto max-w-6xl px-4 py-8 space-y-8">
        {/* Quick Actions */}
        <section className="rounded-3xl bg-white p-6 shadow-sm ring-1 ring-black/5">
          <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <h2 className="text-lg font-extrabold text-slate-900">Quick Actions</h2>
              <p className="mt-1 text-sm font-semibold text-slate-600">
                Common admin tasks (buttons can be wired later)
              </p>
            </div>

            <div className="flex flex-wrap gap-3">
              <button className="rounded-xl bg-blue-600 px-4 py-2 text-sm font-extrabold text-white hover:bg-blue-700">
                Add Lessons
              </button>
              <button className="rounded-xl bg-blue-600 px-4 py-2 text-sm font-extrabold text-white hover:bg-blue-700">
                View Lessons
              </button>
              <button className="rounded-xl bg-slate-900 px-4 py-2 text-sm font-extrabold text-white hover:bg-black">
                Manage Roles
              </button>
              
            </div>
          </div>
        </section>

        {/* Stats */}
        <section className="grid gap-4 md:grid-cols-4">
          {stats.map((s) => (
            <div key={s.title} className="rounded-3xl bg-white p-5 shadow-sm ring-1 ring-black/5">
              <div className="text-xs font-bold text-slate-500">{s.title}</div>
              <div className="mt-2 text-2xl font-extrabold text-slate-900">{s.value}</div>
              <div className="mt-1 text-xs font-semibold text-slate-500">{s.hint}</div>
            </div>
          ))}
        </section>

        {/* Activity */}
        <section className="rounded-3xl bg-white p-6 shadow-sm ring-1 ring-black/5">
          <div className="flex items-center justify-between gap-4">
            <h2 className="text-lg font-extrabold text-slate-900">Recent Activity</h2>
            <button className="rounded-xl border border-black/10 bg-white px-4 py-2 text-sm font-extrabold hover:bg-slate-50">
              View All
            </button>
          </div>

          <div className="mt-4 overflow-x-auto">
            <table className="w-full text-left">
              <thead>
                <tr className="text-xs font-extrabold text-slate-500">
                  <th className="py-3">Time</th>
                  <th className="py-3">Action</th>
                  <th className="py-3">By</th>
                  <th className="py-3">Status</th>
                </tr>
              </thead>
              <tbody className="text-sm font-semibold text-slate-700">
                {activities.map((a, idx) => (
                  <tr key={idx} className="border-t">
                    <td className="py-3">{a.time}</td>
                    <td className="py-3">{a.action}</td>
                    <td className="py-3">{a.by}</td>
                    <td className="py-3">
                      <StatusBadge status={a.status} />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <p className="mt-4 text-xs font-semibold text-slate-500">
            Note: Stats and activity are placeholders until you connect real admin APIs.
          </p>
        </section>
      </main>
    </div>
  );
}

function StatusBadge({ status }: { status: "success" | "warning" | "danger" }) {
  const cls =
    status === "success"
      ? "bg-emerald-50 text-emerald-700 ring-emerald-600/20"
      : status === "warning"
      ? "bg-amber-50 text-amber-700 ring-amber-600/20"
      : "bg-red-50 text-red-700 ring-red-600/20";

  const label =
    status === "success" ? "Success" : status === "warning" ? "Warning" : "Danger";

  return (
    <span className={`inline-flex items-center rounded-full px-3 py-1 text-xs font-extrabold ring-1 ${cls}`}>
      {label}
    </span>
  );
}
