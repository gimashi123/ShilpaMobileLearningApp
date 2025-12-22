import { BrowserRouter, Link } from "react-router-dom";
import AppRoutes from "./routes/AppRoutes";

export default function App() {
  return (
    <BrowserRouter>
      <div className="min-h-screen bg-slate-50 text-slate-900">
        {/* Header */}
        <header className="sticky top-0 z-50 border-b bg-white/90 backdrop-blur">
          <div className="mx-auto flex max-w-6xl items-center justify-between gap-4 px-4 py-3">
            <div className="flex items-center gap-3">
              <img
                src="/MobileAppLogo.jpg"
                alt="Logo"
                className="h-10 w-10 rounded-xl object-cover"
              />
              <div className="leading-tight">
                <div className="text-lg font-extrabold">ශිල්ප</div>
                <div className="text-xs font-semibold text-slate-500">
                  ඉගෙනීමට අත්වැලක්
                </div>
              </div>
            </div>

            <nav className="flex flex-wrap items-center gap-3 text-sm font-bold">
              <Link className="hover:text-blue-600" to="/">
                Home
              </Link>
              <Link className="hover:text-blue-600" to="/register">
                Register
              </Link>
              <Link className="hover:text-blue-600" to="/login">
                Login
              </Link>
              <Link
                to="/register"
                className="rounded-xl bg-blue-600 px-4 py-2 text-white hover:bg-blue-700"
              >
                Get Started
              </Link>
            </nav>
          </div>
        </header>

        {/* Page Content */}
        <main className="mx-auto max-w-6xl px-4 py-6">
          <AppRoutes />
        </main>

        {/* Footer */}
        <footer className="mt-8 border-t bg-slate-900 text-white">
          <div className="mx-auto grid max-w-6xl gap-6 px-4 py-6 md:grid-cols-3">
            <div>
              <div className="text-base font-extrabold">ශිල්ප</div>
              <div className="mt-1 text-sm text-white/75">
                Made with React + TypeScript + Tailwind
              </div>
            </div>

            <div className="flex flex-col gap-2 text-sm font-semibold text-white/80">
              <a className="hover:text-white" href="#">
                Privacy
              </a>
              <a className="hover:text-white" href="#">
                Terms
              </a>
              <a className="hover:text-white" href="#">
                Support
              </a>
            </div>

            <div className="text-sm font-semibold text-white/70 md:text-right">
              © {new Date().getFullYear()} ශිල්ප
            </div>
          </div>
        </footer>
      </div>
    </BrowserRouter>
  );
}
