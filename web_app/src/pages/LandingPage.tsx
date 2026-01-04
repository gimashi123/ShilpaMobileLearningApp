import { Link } from "react-router-dom";
import { motion } from "framer-motion";
import { 
  Sparkles, 
  BookOpen, 
  Users, 
  Smartphone, 
  Award, 
  Target,
  ChevronRight,
  Shield,
  GraduationCap
} from "lucide-react";

export default function Landing() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-indigo-50/30 overflow-hidden">
      {/* Animated Background Elements */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute -top-40 -right-40 w-80 h-80 bg-blue-200 rounded-full mix-blend-multiply filter blur-3xl opacity-20 animate-pulse"></div>
        <div className="absolute -bottom-40 -left-40 w-80 h-80 bg-indigo-200 rounded-full mix-blend-multiply filter blur-3xl opacity-20 animate-pulse delay-1000"></div>
      </div>

      {/* HERO SECTION */}
      <section className="relative mx-auto max-w-7xl px-6 py-20 md:py-32 grid gap-12 md:grid-cols-2 items-center">
        {/* Decorative Elements */}
        <div className="absolute top-10 left-10 w-24 h-24 bg-gradient-to-r from-blue-400 to-indigo-400 rounded-full opacity-10 blur-xl"></div>
        <div className="absolute bottom-10 right-10 w-32 h-32 bg-gradient-to-r from-blue-300 to-purple-300 rounded-full opacity-10 blur-xl"></div>
        
        {/* LEFT CONTENT */}
        <motion.div
          initial={{ opacity: 0, x: -50 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ duration: 0.8 }}
        >
          {/* Badge */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.2 }}
            className="inline-flex items-center gap-2 bg-gradient-to-r from-blue-100 to-indigo-100 text-blue-700 px-4 py-2 rounded-full mb-6 font-semibold"
          >
            <Sparkles className="w-4 h-4" />
            <span>අලුත්ම ඉගෙනීමේ වේදිකාව</span>
          </motion.div>

          {/* Main Heading */}
          <h1 className="text-5xl md:text-6xl lg:text-7xl font-bold leading-tight text-slate-900">
            <span className="block">සිසුන්ට</span>
            <span className="relative inline-block">
              <span className="relative z-10 bg-gradient-to-r from-blue-600 to-indigo-600 bg-clip-text text-transparent">
                පහසු ඉගෙනීම
              </span>
              <span className="absolute bottom-2 left-0 w-full h-4 bg-blue-100 -rotate-1 -z-0"></span>
            </span>
            <span className="block mt-3 text-4xl md:text-5xl">අලුත් අත්දැකීමක්</span>
          </h1>

          {/* Description */}
          <p className="mt-8 text-lg text-slate-600 max-w-xl leading-relaxed font-medium">
            ශිල්ප යනු සිසුන්, ගුරුවරුන් සහ මව්පියන් සඳහා නිර්මාණය කළ
            <span className="font-bold text-blue-600"> සරල, පැහැදිලි සහ ප්‍රවේශ විය හැකි </span>
            ඉගෙනීමේ වේදිකාවකි.
          </p>

          {/* Stats */}
          <div className="mt-10 flex flex-wrap gap-8">
            <div className="flex items-center gap-3">
              <div className="w-12 h-12 bg-gradient-to-br from-blue-500 to-blue-600 rounded-2xl flex items-center justify-center">
                <Users className="w-6 h-6 text-white" />
              </div>
              <div>
                <div className="text-2xl font-bold text-slate-900">500+</div>
                <div className="text-sm text-slate-500 font-medium">සක්‍රීය සිසුන්</div>
              </div>
            </div>
            <div className="flex items-center gap-3">
              <div className="w-12 h-12 bg-gradient-to-br from-indigo-500 to-purple-600 rounded-2xl flex items-center justify-center">
                <BookOpen className="w-6 h-6 text-white" />
              </div>
              <div>
                <div className="text-2xl font-bold text-slate-900">100+</div>
                <div className="text-sm text-slate-500 font-medium">පාඩම්</div>
              </div>
            </div>
          </div>

          {/* CTA Buttons */}
          <motion.div 
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.4 }}
            className="mt-12 flex flex-wrap gap-4"
          >
            <Link
              to="/register"
              className="group relative inline-flex items-center gap-3 rounded-2xl bg-gradient-to-r from-blue-600 to-indigo-600 px-8 py-4 text-base font-bold text-white hover:shadow-xl hover:shadow-blue-500/25 transition-all duration-300 transform hover:-translate-y-1"
            >
              <span>Create Account</span>
              <ChevronRight className="w-5 h-5 group-hover:translate-x-1 transition-transform" />
              <div className="absolute inset-0 rounded-2xl border-2 border-white/20 group-hover:border-white/40 transition-colors"></div>
            </Link>

            <Link
              to="/login"
              className="group relative inline-flex items-center gap-3 rounded-2xl bg-white px-8 py-4 text-base font-bold text-slate-900 hover:shadow-lg transition-all duration-300 border-2 border-slate-200 hover:border-blue-300 transform hover:-translate-y-1"
            >
              <GraduationCap className="w-5 h-5" />
              <span>Login</span>
            </Link>
          </motion.div>
        </motion.div>
        {/* RIGHT CONTENT - Illustration */}
        <motion.div
          initial={{ opacity: 0, x: 50 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ duration: 0.8, delay: 0.2 }}
          className="relative"
        >
          <div className="relative bg-gradient-to-br from-blue-100/50 to-indigo-100/50 rounded-3xl p-8 md:p-12 shadow-2xl shadow-blue-500/10 border border-blue-100">
            {/* Floating Elements */}
            <div className="absolute -top-6 -left-6 w-24 h-24 bg-gradient-to-br from-yellow-400 to-orange-400 rounded-2xl rotate-12 shadow-lg flex items-center justify-center">
              <Award className="w-12 h-12 text-white" />
            </div>
            <div className="absolute -bottom-6 -right-6 w-20 h-20 bg-gradient-to-br from-green-400 to-emerald-500 rounded-2xl -rotate-12 shadow-lg flex items-center justify-center">
              <Shield className="w-10 h-10 text-white" />
            </div>
            
            <div className="text-center">
              <div className="inline-flex items-center justify-center w-24 h-24 bg-gradient-to-r from-blue-500 to-indigo-600 rounded-full mb-8 shadow-lg shadow-blue-500/30">
                <BookOpen className="w-12 h-12 text-white" />
              </div>
              <h3 className="text-2xl font-bold text-slate-900 mb-4">
                පුදුම සහගත ඉගෙනීමක්
              </h3>
              <p className="text-slate-600 font-medium">
                ඕනෑම අවස්ථාවක, ඕනෑම තැනක
              </p>
            </div>
          </div>
        </motion.div>
      </section>

      {/* FEATURES SECTION */}
      <section className="relative mx-auto max-w-7xl px-6 py-20 md:py-32">
        <div className="text-center max-w-3xl mx-auto mb-16">
          <h2 className="text-4xl md:text-5xl font-bold text-slate-900 mb-6">
            Why choose <span className="bg-gradient-to-r from-blue-600 to-indigo-600 bg-clip-text text-transparent">ශිල්ප</span>?
          </h2>
          <p className="text-lg text-slate-600 font-medium">
            සියලු වයස් කාණ්ඩ සඳහා නිර්මාණය කරන ලද ප්‍රවේශ විය හැකි ඉගෙනීමේ වේදිකාවක්
          </p>
        </div>

        <div className="grid gap-8 md:grid-cols-2 lg:grid-cols-3">
          <FeatureCard
            icon={<Smartphone className="w-8 h-8" />}
            title="Fully Responsive"
            desc="Mobile, tablet, and desktop compatible"
            gradient="from-blue-500 to-cyan-400"
            delay={0.1}
          />
          <FeatureCard
            icon={<Target className="w-8 h-8" />}
            title="Personalized Learning"
            desc="Adaptive learning paths for each student"
            gradient="from-indigo-500 to-purple-400"
            delay={0.2}
          />
          <FeatureCard
            icon={<Users className="w-8 h-8" />}
            title="Collaborative Tools"
            desc="Teachers, students, and parents together"
            gradient="from-violet-500 to-pink-400"
            delay={0.3}
          />
          <FeatureCard
            icon={<Award className="w-8 h-8" />}
            title="Progress Tracking"
            desc="Real-time analytics and reports"
            gradient="from-orange-500 to-yellow-400"
            delay={0.4}
          />
          <FeatureCard
            icon={<BookOpen className="w-8 h-8" />}
            title="Rich Content Library"
            desc="Interactive lessons and materials"
            gradient="from-green-500 to-emerald-400"
            delay={0.5}
          />
          <FeatureCard
            icon={<Sparkles className="w-8 h-8" />}
            title="AI Powered"
            desc="Smart recommendations and assistance"
            gradient="from-rose-500 to-pink-400"
            delay={0.6}
          />
        </div>
      </section>

      {/* TESTIMONIAL */}
      <section className="mx-auto max-w-4xl px-6 py-20">
        <div className="bg-gradient-to-br from-white to-blue-50/50 rounded-3xl p-8 md:p-12 shadow-xl shadow-blue-500/10 border border-blue-100">
          <div className="flex items-start gap-6">
            <div className="w-20 h-20 bg-gradient-to-r from-blue-400 to-indigo-500 rounded-2xl flex items-center justify-center flex-shrink-0">
              <span className="text-3xl text-white">👩‍🏫</span>
            </div>
            <div>
              <div className="text-2xl text-slate-900 font-bold mb-2">
                "මගේ සිසුන්ගේ අධ්‍යාපනික කාර්ය සාධනය ඉහළ ගියා!"
              </div>
              <p className="text-slate-600 font-medium mb-4">
                ශිල්ප වේදිකාව සිසුන්ගේ උනන්දුව සහ සහභාගි වීම වැඩි කරන ලදී. 
                දැන් ඔවුන් ඉගෙනීමට තවත් උනන්දු වෙනවා.
              </p>
              <div className="text-slate-700 font-bold">
                - කුසුම් පෙරේරා, ගණිත ගුරුවරිය
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* FINAL CTA */}
      <section className="mx-auto max-w-4xl px-6 py-20 text-center">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="bg-gradient-to-r from-blue-600 to-indigo-600 rounded-3xl p-12 shadow-2xl shadow-indigo-500/25"
        >
          <h3 className="text-3xl md:text-4xl font-bold text-white mb-6">
            අදම ආරම්භ කරන්න
          </h3>
          <p className="text-blue-100 text-lg mb-8 max-w-2xl mx-auto font-medium">
            ඔබේ ඉගෙනීමේ ගමන අලුත් මට්ටමකට ඔසවන්න
          </p>
          <Link
            to="/register"
            className="inline-flex items-center gap-3 bg-white text-blue-600 px-10 py-4 rounded-2xl text-lg font-bold hover:bg-blue-50 transition-all duration-300 transform hover:scale-105 shadow-lg"
          >
            <span>Free Account Create කරන්න</span>
            <ChevronRight className="w-5 h-5" />
          </Link>
        </motion.div>
      </section>

      {/* FOOTER */}
      <footer className="border-t border-slate-200 bg-white/80 backdrop-blur-sm">
        <div className="mx-auto max-w-7xl px-6 py-8">
          <div className="flex flex-col md:flex-row justify-between items-center gap-6">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-gradient-to-r from-blue-600 to-indigo-600 rounded-xl flex items-center justify-center">
                <BookOpen className="w-6 h-6 text-white" />
              </div>
              <span className="text-xl font-bold text-slate-900">ශිල්ප</span>
            </div>
            <p className="text-slate-600 text-sm font-medium text-center">
              © {new Date().getFullYear()} ශිල්ප • ඉගෙනීම පහසු සහ ප්‍රවේශ විය හැකි
            </p>
            <div className="flex items-center gap-6">
              <Link to="/privacy" className="text-sm font-medium text-slate-600 hover:text-blue-600">
                Privacy Policy
              </Link>
              <Link to="/terms" className="text-sm font-medium text-slate-600 hover:text-blue-600">
                Terms
              </Link>
              <Link to="/contact" className="text-sm font-medium text-slate-600 hover:text-blue-600">
                Contact
              </Link>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}

/* ---------- Feature Card Component ---------- */
function FeatureCard({ 
  icon, 
  title, 
  desc, 
  gradient, 
  delay 
}: { 
  icon: React.ReactNode; 
  title: string; 
  desc: string; 
  gradient: string;
  delay: number;
}) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 30 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true }}
      transition={{ duration: 0.5, delay }}
      whileHover={{ y: -8 }}
      className="group relative bg-white rounded-3xl p-8 shadow-lg hover:shadow-2xl transition-all duration-300 border border-slate-100"
    >
      <div className={`absolute inset-0 bg-gradient-to-br ${gradient} rounded-3xl opacity-0 group-hover:opacity-5 transition-opacity duration-300`}></div>
      <div className={`relative w-16 h-16 bg-gradient-to-br ${gradient} rounded-2xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform duration-300`}>
        <div className="text-white">
          {icon}
        </div>
      </div>
      <h4 className="text-xl font-bold text-slate-900 mb-3 group-hover:text-blue-600 transition-colors">
        {title}
      </h4>
      <p className="text-slate-600 font-medium">
        {desc}
      </p>
      <div className="mt-6 pt-6 border-t border-slate-100">
        <span className="text-sm font-semibold text-blue-600 inline-flex items-center gap-1">
          Learn more
          <ChevronRight className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
        </span>
      </div>
    </motion.div>
  );
}