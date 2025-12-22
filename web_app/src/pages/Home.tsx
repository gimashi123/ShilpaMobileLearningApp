export default function Home() {
  return (
    <div className="space-y-10">
      {/* Hero */}
      <section className="rounded-3xl bg-white p-8 shadow-sm ring-1 ring-black/5 md:p-12">
        <h1 className="max-w-3xl text-3xl font-extrabold leading-tight md:text-5xl">
          Build your first page fast with a clean responsive layout
        </h1>
        <p className="mt-4 max-w-2xl text-sm font-semibold text-slate-600 md:text-base">
          This page is fully responsive and ready for routing, register/login,
          and backend connection.
        </p>

        <div className="mt-6 flex flex-wrap gap-3">
          <button className="rounded-xl bg-blue-600 px-5 py-3 text-sm font-extrabold text-white hover:bg-blue-700">
            Create Account
          </button>
          <button className="rounded-xl bg-slate-900 px-5 py-3 text-sm font-extrabold text-white hover:bg-black">
            Login
          </button>
        </div>

        <div className="mt-8 grid gap-3 md:grid-cols-3">
          <Stat title="Fast" value="Vite" />
          <Stat title="UI" value="Responsive" />
          <Stat title="Code" value="TypeScript" />
        </div>
      </section>

      {/* Features */}
      <section>
        <h2 className="text-xl font-extrabold">Features</h2>
        <p className="mt-1 text-sm font-semibold text-slate-500">
          Clean structure, responsive layout, ready for next steps.
        </p>

        <div className="mt-4 grid gap-4 md:grid-cols-3">
          <Feature icon="📱" title="Responsive Layout" desc="Looks good on mobile and laptop." />
          <Feature icon="🧩" title="Reusable Components" desc="Easy to split into components/pages." />
          <Feature icon="🔌" title="Ready for Backend" desc="Connect API and show real data." />
        </div>
      </section>
    </div>
  );
}

function Stat({ title, value }: { title: string; value: string }) {
  return (
    <div className="rounded-2xl bg-slate-50 p-4 ring-1 ring-black/5">
      <div className="text-xs font-bold text-slate-500">{title}</div>
      <div className="mt-1 text-lg font-extrabold">{value}</div>
    </div>
  );
}

function Feature({ icon, title, desc }: { icon: string; title: string; desc: string }) {
  return (
    <div className="rounded-2xl bg-white p-5 shadow-sm ring-1 ring-black/5">
      <div className="text-2xl">{icon}</div>
      <div className="mt-2 text-base font-extrabold">{title}</div>
      <div className="mt-1 text-sm font-semibold text-slate-600">{desc}</div>
      <button className="mt-4 rounded-xl border border-black/10 bg-white px-4 py-2 text-sm font-extrabold hover:bg-slate-50">
        Learn more
      </button>
    </div>
  );
}
