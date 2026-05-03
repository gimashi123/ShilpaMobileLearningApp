import { useState } from "react";
import styled from "@emotion/styled";
import { 
    Search, 
    User, 
    BookOpen, 
    Trophy, 
    Gamepad2, 
    ArrowLeft,
    Loader2,
    Calendar,
    ChevronRight,
    TrendingUp
} from "lucide-react";
import { useNavigate } from "react-router-dom";

const Container = styled.div`
    min-height: 100vh;
    background: #f8fafc;
    padding: 40px 20px;
    font-family: 'Inter', sans-serif;
`;

const Content = styled.div`
    max-width: 1000px;
    margin: 0 auto;
`;

const Header = styled.div`
    display: flex;
    align-items: center;
    gap: 16px;
    margin-bottom: 32px;
`;

const BackButton = styled.button`
    background: white;
    border: 1px solid #e2e8f0;
    padding: 8px;
    border-radius: 12px;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: all 0.2s;
    &:hover { background: #f1f5f9; }
`;

const SearchBox = styled.div`
    background: white;
    padding: 32px;
    border-radius: 20px;
    box-shadow: 0 4px 20px rgba(0,0,0,0.03);
    border: 1px solid #edf2f7;
    margin-bottom: 32px;
`;

const InputGroup = styled.div`
    display: flex;
    gap: 12px;
    margin-top: 16px;
`;

const Input = styled.input`
    flex: 1;
    padding: 14px 20px;
    border-radius: 12px;
    border: 2px solid #e2e8f0;
    font-size: 16px;
    outline: none;
    transition: border-color 0.2s;
    &:focus { border-color: #3b82f6; }
`;

const SearchButton = styled.button`
    background: #3b82f6;
    color: white;
    padding: 14px 28px;
    border-radius: 12px;
    border: none;
    font-weight: 600;
    cursor: pointer;
    display: flex;
    align-items: center;
    gap: 8px;
    transition: all 0.2s;
    &:hover { background: #2563eb; transform: translateY(-1px); }
    &:disabled { opacity: 0.7; cursor: not-allowed; }
`;

const StatsGrid = styled.div`
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 20px;
    margin-bottom: 32px;
`;

const StatCard = styled.div<{ color: string }>`
    background: white;
    padding: 24px;
    border-radius: 20px;
    border: 1px solid #edf2f7;
    display: flex;
    flex-direction: column;
    gap: 12px;
    
    .icon {
        width: 40px;
        height: 40px;
        border-radius: 10px;
        background: ${props => props.color}15;
        color: ${props => props.color};
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .value {
        font-size: 24px;
        font-weight: 700;
        color: #1e293b;
    }

    .label {
        color: #64748b;
        font-size: 14px;
    }
`;

const HistorySection = styled.div`
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 24px;
    
    @media (max-width: 768px) {
        grid-template-columns: 1fr;
    }
`;

const Card = styled.div`
    background: white;
    border-radius: 20px;
    padding: 24px;
    border: 1px solid #edf2f7;
`;

const List = styled.div`
    display: flex;
    flex-direction: column;
    gap: 12px;
    margin-top: 20px;
`;

const ListItem = styled.div`
    padding: 16px;
    background: #f8fafc;
    border-radius: 12px;
    border: 1px solid #f1f5f9;
    display: flex;
    justify-content: space-between;
    align-items: center;
`;

const StudentProgress = () => {
    const navigate = useNavigate();
    const [email, setEmail] = useState("");
    const [loading, setLoading] = useState(false);
    const [data, setData] = useState<any>(null);
    const [error, setError] = useState("");

    const handleSearch = async () => {
        if (!email) return;
        setLoading(true);
        setError("");
        setData(null);
        try {
            const token = localStorage.getItem("token");
            const res = await fetch(`http://localhost:3000/api/progress/by-email/${email}`, {
                headers: { Authorization: `Bearer ${token}` }
            });
            const json = await res.json();
            if (!res.ok) throw new Error(json.message || "Failed to fetch progress");
            setData(json.data);
        } catch (err: any) {
            setError(err.message);
        } finally {
            setLoading(false);
        }
    };

    return (
        <Container>
            <Content>
                <Header>
                    <BackButton onClick={() => navigate(-1)}>
                        <ArrowLeft size={20} />
                    </BackButton>
                    <div>
                        <h1 style={{ margin: 0, fontSize: '24px', fontWeight: 700, color: '#1e293b' }}>Student Progress Tracker</h1>
                        <p style={{ margin: 0, color: '#64748b' }}>Monitor your student's learning journey</p>
                    </div>
                </Header>

                <SearchBox>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: '#1e293b' }}>
                        <Search size={20} color="#3b82f6" />
                        <h3 style={{ margin: 0 }}>Find Student by Email</h3>
                    </div>
                    <InputGroup>
                        <Input 
                            type="email" 
                            placeholder="e.g. student@shilpa.com" 
                            value={email}
                            onChange={(e) => setEmail(e.target.value)}
                            onKeyDown={(e) => e.key === 'Enter' && handleSearch()}
                        />
                        <SearchButton onClick={handleSearch} disabled={loading}>
                            {loading ? <Loader2 className="animate-spin" size={18} /> : <Search size={18} />}
                            {loading ? "Searching..." : "Track Progress"}
                        </SearchButton>
                    </InputGroup>
                    {error && <p style={{ color: '#ef4444', marginTop: '12px', fontSize: '14px' }}>{error}</p>}
                </SearchBox>

                {data && (
                    <>
                        <div style={{ marginBottom: '24px', display: 'flex', alignItems: 'center', gap: '10px' }}>
                            <div style={{ padding: '8px', background: '#3b82f6', borderRadius: '10px', color: 'white' }}>
                                <User size={20} />
                            </div>
                            <h2 style={{ margin: 0 }}>Results for {data.summary.name}</h2>
                        </div>

                        <StatsGrid>
                            <StatCard color="#3b82f6">
                                <div className="icon"><TrendingUp size={20} /></div>
                                <div className="value">{data.summary.totalXp}</div>
                                <div className="label">Total XP Earned</div>
                            </StatCard>
                            <StatCard color="#10b981">
                                <div className="icon"><BookOpen size={20} /></div>
                                <div className="value">{data.summary.lessonsCompleted}</div>
                                <div className="label">Lessons Completed</div>
                            </StatCard>
                            <StatCard color="#f59e0b">
                                <div className="icon"><Trophy size={20} /></div>
                                <div className="value">{data.summary.quizzesCompleted}</div>
                                <div className="label">Quizzes Passed</div>
                            </StatCard>
                            <StatCard color="#ec4899">
                                <div className="icon"><Gamepad2 size={20} /></div>
                                <div className="value">{data.summary.gamesPlayed}</div>
                                <div className="label">Educational Games</div>
                            </StatCard>
                        </StatsGrid>

                        <HistorySection>
                            <Card>
                                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                    <h3 style={{ margin: 0 }}>Recent Lessons</h3>
                                    <BookOpen size={18} color="#3b82f6" />
                                </div>
                                <List>
                                    {data.history.lessons.length > 0 ? data.history.lessons.map((l: any, i: number) => (
                                        <ListItem key={i}>
                                            <div>
                                                <div style={{ fontWeight: 600 }}>{l.lessonId?.title || "Lesson"}</div>
                                                <div style={{ fontSize: '12px', color: '#64748b', display: 'flex', alignItems: 'center', gap: '4px' }}>
                                                    <Calendar size={12} /> {new Date(l.completedAt).toLocaleDateString()}
                                                </div>
                                            </div>
                                            <div style={{ color: '#10b981', fontWeight: 600 }}>+100 XP</div>
                                        </ListItem>
                                    )) : <p style={{ color: '#64748b', textAlign: 'center', padding: '20px' }}>No lessons completed yet.</p>}
                                </List>
                            </Card>

                            <Card>
                                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                    <h3 style={{ margin: 0 }}>Quiz Attempts</h3>
                                    <Trophy size={18} color="#f59e0b" />
                                </div>
                                <List>
                                    {data.history.quizzes.length > 0 ? data.history.quizzes.map((q: any, i: number) => (
                                        <ListItem key={i}>
                                            <div>
                                                <div style={{ fontWeight: 600 }}>Grade {q.grade} {q.subject}</div>
                                                <div style={{ fontSize: '12px', color: '#64748b' }}>{q.type}</div>
                                            </div>
                                            <div style={{ textAlign: 'right' }}>
                                                <div style={{ fontWeight: 700, color: '#3b82f6' }}>{q.score}%</div>
                                                <div style={{ fontSize: '10px', color: '#94a3b8' }}>{new Date(q.createdAt).toLocaleDateString()}</div>
                                            </div>
                                        </ListItem>
                                    )) : <p style={{ color: '#64748b', textAlign: 'center', padding: '20px' }}>No quiz attempts yet.</p>}
                                </List>
                            </Card>
                        </HistorySection>
                    </>
                )}
            </Content>
        </Container>
    );
};

export default StudentProgress;
