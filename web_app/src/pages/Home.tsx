import { Link } from "react-router-dom";

type CardProps = {
  title: string;
  desc: string;
  to: string;
  icon: string;
};

export default function Home() {
  return (
    <div className="min-h-[calc(100vh-120px)] bg-slate-50">
      <div className="mx-auto max-w-6xl px-4 py-10 md:py-14">
        {/* HERO */}
        <section className="relative overflow-hidden rounded-3xl bg-white p-8 shadow-sm ring-1 ring-black/5 md:p-12">
          <div className="pointer-events-none absolute -top-24 -right-24 h-72 w-72 rounded-full bg-blue-200/50 blur-3xl" />
          <div className="pointer-events-none absolute -bottom-24 -left-24 h-72 w-72 rounded-full bg-indigo-200/50 blur-3xl" />

          <div className="relative grid gap-10 md:grid-cols-2 md:items-center">
            {/* Left */}
            <div>
              <span className="inline-flex items-center gap-2 rounded-full bg-blue-50 px-4 py-2 text-xs font-extrabold text-blue-700 ring-1 ring-black/5">
                <span className="h-2 w-2 rounded-full bg-blue-600" />
                Shilpa Learning Platform
              </span>

              <h1 className="mt-5 text-3xl font-extrabold leading-tight tracking-tight md:text-5xl">
                ශිල්ප සමඟ <span className="text-blue-600">ඉගෙනීම</span> පහසුයි
              </h1>

              <p className="mt-4 max-w-xl text-sm font-semibold text-slate-600 md:text-base">
                සිසුන් සඳහා සරල, පැහැදිලි සහ ප්‍රවේශ විය හැකි අධ්‍යයන වේදිකාවක්.
                Register කර Login වී ඉගෙනීම ආරම්භ කරන්න.
              </p>

              <div className="mt-7 flex flex-wrap gap-3">
                <Link
                  to="/register"
                  className="rounded-2xl bg-blue-600 px-6 py-3 text-sm font-extrabold text-white shadow-sm hover:bg-blue-700 active:scale-[0.99]"
                >
                  Create Account
                </Link>

                <Link
                  to="/login"
                  className="rounded-2xl border border-slate-200 bg-white px-6 py-3 text-sm font-extrabold text-slate-900 hover:bg-slate-50 active:scale-[0.99]"
                >
                  Login
                </Link>
              </div>

              <div className="mt-9 grid gap-4 sm:grid-cols-3">
                <Stat title="Language" value="Sinhala" />
                <Stat title="Design" value="Simple UI" />
                <Stat title="Access" value="Fast & Easy" />
              </div>
            </div>

            {/* Right */}
            <div className="flex justify-center md:justify-end">
              <div className="w-full max-w-sm rounded-3xl bg-slate-50 p-6 ring-1 ring-black/5">
                <div className="flex justify-center">
                  <img
                    src="/MobileAppLogo.jpg"
                    alt="Shilpa Logo"
                    className="h-56 w-56 rounded-3xl object-cover ring-1 ring-black/5"
                  />
                </div>

                <div className="mt-4 text-center">
                  <div className="text-lg font-extrabold">ශිල්ප</div>
                  <div className="text-sm font-semibold text-slate-600">
                    ඉගෙනීමට අත්වැලක්
                  </div>
                </div>

                <div className="mt-6 grid grid-cols-2 gap-3">
                  <MiniCard title="Lessons" sub="Videos + Text" />
                  <MiniCard title="Games" sub="Fun learning" />
                </div>

                <div className="mt-4 rounded-2xl bg-white p-4 ring-1 ring-black/5">
                  <div className="text-xs font-bold text-slate-500">Tip</div>
                  <div className="mt-1 text-sm font-semibold text-slate-700">
                    Register → Login → Choose your learning section.
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* SECTIONS */}
        <section className="mt-10">
          <div className="flex flex-col gap-2 md:flex-row md:items-end md:justify-between">
            <div>
              <h2 className="text-xl font-extrabold text-slate-900">
                Choose a path
              </h2>
              <p className="mt-1 text-sm font-semibold text-slate-500">
                Start with lessons or games. Expand later with new modules.
              </p>
            </div>
            <div className="text-sm font-semibold text-slate-500">
              Simple • Clear • Accessible
            </div>
          </div>

          <div className="mt-6 grid gap-5 md:grid-cols-3">
            <Card
              icon="📘"
              title="Lessons"
              desc="Structured learning with clear content."
              to="/"
            />
            <Card
              icon="🎮"
              title="Learning Games"
              desc="Practice through interactive games."
              to="/"
            />
            <Card
              icon="🧩"
              title="Skills & Progress"
              desc="Track learning progress (future feature)."
              to="/"
            />
          </div>
        </section>

        {/* FEATURES */}
        <section className="mt-10 rounded-3xl bg-white p-8 shadow-sm ring-1 ring-black/5 md:p-10">
          <h2 className="text-xl font-extrabold">Features</h2>
          <p className="mt-1 text-sm font-semibold text-slate-500">
            Student-friendly design with future expansion support.
          </p>

          <div className="mt-6 grid gap-6 md:grid-cols-3">
            <Feature
              icon="📱"
              title="Responsive Design"
              desc="Mobile, tablet සහ laptop වලට සරිලන UI."
            />
            <Feature
              icon="🎓"
              title="Student Focused"
              desc="සිසුන්ට පහසු අතුරුමුහුණත සහ navigation."
            />
            <Feature
              icon="🔌"
              title="Backend Ready"
              desc="API, database සහ authentication සඳහා සූදානම්."
            />
          </div>
        </section>

        {/* CTA */}
        <section className="mt-10 rounded-3xl bg-gradient-to-r from-blue-600 to-indigo-600 p-8 text-white shadow-sm md:p-10">
          <div className="flex flex-col items-center gap-4 text-center">
            <h2 className="text-2xl font-extrabold">Ready to start?</h2>
            <p className="max-w-xl text-sm font-semibold text-white/85">
              අදම account එකක් සාදා ශිල්ප සමඟ ඉගෙනීම ආරම්භ කරන්න.
            </p>

            <div className="flex flex-wrap gap-3">
              <Link
                to="/register"
                className="rounded-2xl bg-white px-6 py-3 text-sm font-extrabold text-blue-700 hover:bg-blue-50"
              >
                Get Started
              </Link>
              <Link
                to="/login"
                className="rounded-2xl border border-white/30 px-6 py-3 text-sm font-extrabold text-white hover:bg-white/10"
              >
                Login
              </Link>
            </div>
          </div>
        </section>
      </div>
    </div>
  );
}

/* ---------- Components ---------- */

function Stat({ title, value }: { title: string; value: string }) {
  return (
    <div className="rounded-2xl bg-slate-50 p-4 ring-1 ring-black/5">
      <div className="text-xs font-bold text-slate-500">{title}</div>
      <div className="mt-1 text-lg font-extrabold text-slate-900">{value}</div>
    </div>
  );
}

function Feature({ icon, title, desc }: { icon: string; title: string; desc: string }) {
  return (
    <div className="rounded-3xl bg-slate-50 p-6 ring-1 ring-black/5 transition hover:-translate-y-0.5 hover:bg-white hover:shadow-sm">
      <div className="flex items-center gap-3">
        <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-white text-2xl ring-1 ring-black/5">
          {icon}
        </div>
        <h3 className="text-base font-extrabold">{title}</h3>
      </div>
      <p className="mt-3 text-sm font-semibold text-slate-600">{desc}</p>
    </div>
  );
}

function MiniCard({ title, sub }: { title: string; sub: string }) {
  return (
    <div className="rounded-2xl bg-white p-4 ring-1 ring-black/5">
      <div className="text-sm font-extrabold text-slate-900">{title}</div>
      <div className="mt-1 text-xs font-semibold text-slate-500">{sub}</div>
    </div>
  );
}

function Card({ title, desc, to, icon }: CardProps) {
  return (
    <Link
      to={to}
      className="group rounded-3xl bg-white p-6 shadow-sm ring-1 ring-black/5 transition hover:-translate-y-0.5 hover:shadow-md"
    >
      <div className="flex items-center gap-3">
        <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-slate-50 text-2xl ring-1 ring-black/5">
          {icon}
        </div>
        <div className="text-base font-extrabold text-slate-900">{title}</div>
      </div>

      <p className="mt-3 text-sm font-semibold text-slate-600">{desc}</p>

      <div className="mt-5 inline-flex items-center gap-2 text-sm font-extrabold text-blue-700">
        Open <span className="transition group-hover:translate-x-0.5">→</span>
      </div>
    </Link>
  );
}
