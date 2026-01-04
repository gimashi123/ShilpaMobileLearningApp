import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";

type User = {
  name: string;
  email: string;
  role: string;
};

export default function ParentDashboard() {
  const navigate = useNavigate();
  const [user, setUser] = useState<User | null>(null);

  useEffect(() => {
    const storedUser = localStorage.getItem("user");
    const token = localStorage.getItem("token");

    if (!storedUser || !token) {
      navigate("/login");
      return;
    }

    const parsed = JSON.parse(storedUser);
    if (parsed.role !== "parent") {
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
      {/* Header */}
      <header className="bg-white border-b">
        <div className="mx-auto max-w-6xl px-4 py-4 flex items-center justify-between">
          <h1 className="text-xl font-extrabold text-slate-900">
            Parent Dashboard
          </h1>
          <button
            onClick={logout}
            className="rounded-lg bg-red-500 px-4 py-2 text-sm font-bold text-white hover:bg-red-600"
          >
            Logout
          </button>
        </div>
      </header>

      {/* Content */}
      <main className="mx-auto max-w-6xl px-4 py-8 space-y-8">
        {/* Welcome */}
        <section className="rounded-3xl bg-white p-6 shadow-sm ring-1 ring-black/5">
          <h2 className="text-lg font-extrabold text-slate-900">
            Welcome, {user.name}
          </h2>
          <p className="mt-1 text-sm font-semibold text-slate-600">
            Monitor your child’s learning progress and activities.
          </p>
        </section>

        {/* Cards */}
        <section className="grid gap-6 md:grid-cols-3">
          <DashboardCard
            title="Child Progress"
            desc="View learning performance and achievements."
            action="View Progress"
          />
          <DashboardCard
            title="Assigned Lessons"
            desc="Check lessons assigned to your child."
            action="View Lessons"
          />
          <DashboardCard
            title="Learning Games"
            desc="Track game-based learning activities."
            action="View Games"
          />
        </section>

        {/* Info */}
        <section className="rounded-3xl bg-white p-6 shadow-sm ring-1 ring-black/5">
          <h3 className="text-base font-extrabold text-slate-900">
            Tips for Parents
          </h3>
          <ul className="mt-3 space-y-2 text-sm font-semibold text-slate-600">
            <li>• Encourage daily practice</li>
            <li>• Monitor progress weekly</li>
            <li>• Support learning through games</li>
          </ul>
        </section>
      </main>
    </div>
  );
}

function DashboardCard({
  title,
  desc,
  action,
}: {
  title: string;
  desc: string;
  action: string;
}) {
  return (
    <div className="rounded-3xl bg-white p-6 shadow-sm ring-1 ring-black/5 flex flex-col justify-between">
      <div>
        <h3 className="text-base font-extrabold text-slate-900">{title}</h3>
        <p className="mt-2 text-sm font-semibold text-slate-600">{desc}</p>
      </div>
      <button className="mt-4 rounded-xl bg-blue-600 px-4 py-2 text-sm font-extrabold text-white hover:bg-blue-700">
        {action}
      </button>
    </div>
  );
}
