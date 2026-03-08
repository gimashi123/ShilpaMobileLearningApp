import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import Home from './pages/Home';
import Register from './pages/Register';
import Login from './pages/Login'; 
import ParentDashboard from './pages/ParentDashboard';
import TeacherDashboard from './pages/dashboard/TeacherDashboard';
import AdminDashboard from './pages/dashboard/AdminDashboard';
import QuizCreate from "./pages/Quiz/QuizCreate.tsx";
import StudentPage from "./pages/StudentPage.tsx";
import TeacherPage from "./pages/TeacherPage.tsx";
import ParentsPage from "./pages/ParentsPage.tsx";
import CreatePaper from './pages/paper/CreatePaper.tsx';
import ChooseLesson from './pages/paper/ChooseLesson.tsx';

function App() {
  return (
    <Router>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/register" element={<Register />} />
        <Route path="/login" element={<Login />} /> 
        <Route path="/parent-dashboard" element={<ParentDashboard />} />
        <Route path="/teacher-dashboard" element={<TeacherDashboard />} />
        <Route path="/admin-dashboard" element={<AdminDashboard />} />
        <Route path="/quiz" element={<QuizCreate/>}/>
        <Route path= "/student-details" element={<StudentPage/>} />
        <Route path= "/teacher-details" element={<TeacherPage/>} />
        <Route path= "/parent-details" element={<ParentsPage/>} />

        <Route path="/paper-create" element={<CreatePaper />} />
        <Route path="/teacher/create-paper/:subjectId" element={<ChooseLesson />} />
        {/* Add more routes as needed */}
      </Routes>
    </Router>
  );
}

export default App;