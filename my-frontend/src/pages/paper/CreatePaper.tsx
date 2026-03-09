import { useNavigate } from "react-router-dom";
import styled from '@emotion/styled';
import {
    Calculator,
    Languages,
    BookOpen,
    PenTool,
    Sparkles,
    ChevronRight
} from 'lucide-react';
import {useState} from "react";

const PageContainer = styled.div`
    min-height: 100vh;
    background-color: #f8fafc;
`;

// Cover Section
const CoverSection = styled.div`
    background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
    color: white;
    padding: 60px 20px;
    position: relative;
    overflow: hidden;

    &::before {
        content: '';
        position: absolute;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background: url('data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" opacity="0.1"><path d="M20 20 L80 20 L80 80 L20 80 Z" fill="none" stroke="white" stroke-width="2"/><circle cx="50" cy="50" r="15" fill="none" stroke="white" stroke-width="2"/></svg>');
        background-size: 60px 60px;
        opacity: 0.1;
    }
`;

const CoverContent = styled.div`
    max-width: 1200px;
    margin: 0 auto;
    position: relative;
    z-index: 1;
`;

const CoverTitle = styled.h1`
    font-size: 48px;
    font-weight: 800;
    margin: 0 0 16px 0;
    background: linear-gradient(135deg, #60a5fa 0%, #a78bfa 100%);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;

    @media (max-width: 768px) {
        font-size: 36px;
    }
`;

const CoverSubtitle = styled.p`
    font-size: 20px;
    color: #94a3b8;
    margin: 0 0 32px 0;
    max-width: 600px;
    line-height: 1.6;

    @media (max-width: 768px) {
        font-size: 18px;
    }
`;

const StatsRow = styled.div`
    display: flex;
    gap: 40px;
    margin-top: 40px;

    @media (max-width: 768px) {
        flex-direction: column;
        gap: 20px;
    }
`;

const StatItem = styled.div`
    display: flex;
    align-items: center;
    gap: 12px;
`;

const StatIcon = styled.div`
    width: 48px;
    height: 48px;
    border-radius: 12px;
    background: rgba(255, 255, 255, 0.1);
    display: flex;
    align-items: center;
    justify-content: center;
    color: #60a5fa;
`;

const StatInfo = styled.div`
    display: flex;
    flex-direction: column;
`;

const StatValue = styled.span`
    font-size: 24px;
    font-weight: 700;
    color: white;
`;

const StatLabel = styled.span`
    font-size: 14px;
    color: #94a3b8;
`;

// Main Content Section
const MainContent = styled.div`
    max-width: 1200px;
    margin: -40px auto 0;
    padding: 0 20px 60px;
    position: relative;
    z-index: 2;
`;

const SectionHeader = styled.div`
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 32px;

    @media (max-width: 768px) {
        flex-direction: column;
        align-items: flex-start;
        gap: 16px;
    }
`;

const SectionTitle = styled.h2`
    font-size: 28px;
    font-weight: 700;
    color: #0f172a;
    margin: 0;
`;

const SectionBadge = styled.div`
    background-color: #e2e8f0;
    padding: 8px 16px;
    border-radius: 30px;
    font-size: 14px;
    font-weight: 500;
    color: #334155;
    display: flex;
    align-items: center;
    gap: 8px;
`;

const SubjectsGrid = styled.div`
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
    gap: 24px;
`;

const SubjectCard = styled.div<{ color?: string }>`
    background: white;
    border-radius: 20px;
    padding: 28px;
    box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
    transition: all 0.3s ease;
    border: 1px solid #e2e8f0;
    cursor: pointer;
    display: flex;
    flex-direction: column;

    &:hover {
        transform: translateY(-8px);
        box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
        border-color: ${props => props.color || '#cbd5e1'};
    }
`;

const CardHeader = styled.div`
    display: flex;
    align-items: center;
    gap: 16px;
    margin-bottom: 20px;
`;

const IconWrapper = styled.div<{ bgColor: string }>`
    width: 64px;
    height: 64px;
    border-radius: 18px;
    background-color: ${props => props.bgColor};
    display: flex;
    align-items: center;
    justify-content: center;
    color: white;
    box-shadow: 0 10px 15px -3px ${props => props.bgColor}40;
`;

const SubjectTitle = styled.h3`
    font-size: 22px;
    font-weight: 700;
    color: #0f172a;
    margin: 0;
`;

const SubjectDescription = styled.p`
    font-size: 15px;
    color: #64748b;
    margin: 0 0 20px 0;
    line-height: 1.6;
    flex: 1;
`;

const FeaturesList = styled.div`
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    margin-bottom: 20px;
`;

const FeatureTag = styled.span<{ bgColor: string }>`
    background-color: ${props => props.bgColor}10;
    color: ${props => props.bgColor};
    padding: 4px 12px;
    border-radius: 20px;
    font-size: 12px;
    font-weight: 500;
`;

const CardFooter = styled.div`
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-top: auto;
    border-top: 1px solid #e2e8f0;
    padding-top: 20px;
`;

const LessonCount = styled.div`
    display: flex;
    align-items: center;
    gap: 6px;
    color: #64748b;
    font-size: 14px;
`;

// Fixed CreateButton - removed nested selector
const CreateButton = styled.div<{ bgColor: string; isHovered?: boolean }>`
    background-color: ${props => props.isHovered
    ? (props.bgColor === '#3b82f6' ? '#2563eb' : props.bgColor === '#ef4444' ? '#dc2626' : props.bgColor)
    : props.bgColor};
    color: white;
    border: none;
    border-radius: 30px;
    padding: 10px 20px;
    font-size: 14px;
    font-weight: 500;
    display: flex;
    align-items: center;
    gap: ${props => props.isHovered ? '12px' : '8px'};
    transition: all 0.2s ease;
`;

const ComingSoonCard = styled(SubjectCard)`
    opacity: 0.7;
    cursor: not-allowed;
    background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%);
    
    &:hover {
        transform: translateY(-4px);
    }
`;

const QuickStartSection = styled.div`
    margin-top: 48px;
    background: white;
    border-radius: 20px;
    padding: 32px;
    border: 1px solid #e2e8f0;
`;

const QuickStartTitle = styled.h3`
    font-size: 20px;
    font-weight: 600;
    color: #0f172a;
    margin: 0 0 20px 0;
`;

const QuickStartGrid = styled.div`
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
    gap: 16px;
`;

const QuickStartItem = styled.div`
    padding: 16px;
    background: #f8fafc;
    border-radius: 12px;
    display: flex;
    align-items: center;
    gap: 12px;
    cursor: pointer;
    transition: all 0.2s ease;

    &:hover {
        background: #f1f5f9;
        transform: translateX(4px);
    }
`;

const TeacherCreatePaper = () => {
    const navigate = useNavigate();
    const [hoveredCard, setHoveredCard] = useState<string | null>(null);

    const subjects = [
        {
            id: "maths",
            name: "Mathematics",
            icon: <Calculator size={32} />,
            color: '#3b82f6',
            description: "Create comprehensive mathematics papers with arithmetic, algebra, geometry, and more. Perfect for all grade levels.",
            lessonCount: 4,
            features: ["Arithmetic", "Algebra", "Geometry", "Word Problems"],
            difficulty: "K-12",
            papersCreated: 2
        },
        {
            id: "sinhala",
            name: "Sinhala",
            icon: <Languages size={32} />,
            color: '#ef4444',
            description: "Design language papers including grammar, literature, comprehension, and writing exercises for Sinhala medium students.",
            lessonCount: 0,
            features: ["Grammar", "Literature", "Comprehension", "Writing"],
            difficulty: "Grade 1-13",
            papersCreated: 0
        },
    ];

    const quickStartTemplates = [
        { id: "quiz", name: "Quick Quiz", icon: "📝", time: "5 mins" },
        { id: "exam", name: "Full Exam", icon: "📋", time: "15 mins" },
        { id: "practice", name: "Practice Sheet", icon: "✏️", time: "10 mins" },
        { id: "homework", name: "Homework", icon: "📚", time: "8 mins" },
    ];

    const handleSubjectSelect = (subject: string) => {
        console.log("selected subject:", subject);
        navigate(`/teacher/create-paper/${subject}`);
    };

    const totalPapers = subjects.reduce((acc, curr) => acc + curr.papersCreated, 0);
    const totalLessons = subjects.reduce((acc, curr) => acc + curr.lessonCount, 0);

    return (
        <PageContainer>
            {/* Cover Section */}
            <CoverSection>
                <CoverContent>
                    <CoverTitle>
                        Create Your Perfect Paper
                    </CoverTitle>
                    <CoverSubtitle>
                        Design customized assessments, quizzes, and exams with our intuitive paper creation tool. Choose from multiple subjects and templates.
                    </CoverSubtitle>

                    <StatsRow>
                        <StatItem>
                            <StatIcon>
                                <PenTool size={24} />
                            </StatIcon>
                            <StatInfo>
                                <StatValue>{totalPapers}+</StatValue>
                                <StatLabel>Papers Created</StatLabel>
                            </StatInfo>
                        </StatItem>
                        <StatItem>
                            <StatIcon>
                                <BookOpen size={24} />
                            </StatIcon>
                            <StatInfo>
                                <StatValue>{totalLessons}+</StatValue>
                                <StatLabel>Lessons Covered</StatLabel>
                            </StatInfo>
                        </StatItem>
                        <StatItem>
                            <StatIcon>
                                <Sparkles size={24} />
                            </StatIcon>
                            <StatInfo>
                                <StatValue>100%</StatValue>
                                <StatLabel>Customizable</StatLabel>
                            </StatInfo>
                        </StatItem>
                    </StatsRow>
                </CoverContent>
            </CoverSection>

            {/* Main Content */}
            <MainContent>
                <SectionHeader>
                    <SectionTitle>Choose a Subject to Begin</SectionTitle>
                    <SectionBadge>
                        <Sparkles size={16} />
                        {subjects.length} subjects available
                    </SectionBadge>
                </SectionHeader>

                <SubjectsGrid>
                    {subjects.map((subject) => (
                        <SubjectCard
                            key={subject.id}
                            color={subject.color}
                            onClick={() => handleSubjectSelect(subject.id)}
                            onMouseEnter={() => setHoveredCard(subject.id)}
                            onMouseLeave={() => setHoveredCard(null)}
                            role="button"
                            tabIndex={0}
                            onKeyDown={(e) => {
                                if (e.key === 'Enter' || e.key === ' ') {
                                    e.preventDefault();
                                    handleSubjectSelect(subject.id);
                                }
                            }}
                        >
                            <CardHeader>
                                <IconWrapper bgColor={subject.color}>
                                    {subject.icon}
                                </IconWrapper>
                                <SubjectTitle>{subject.name}</SubjectTitle>
                            </CardHeader>

                            <SubjectDescription>
                                {subject.description}
                            </SubjectDescription>

                            <FeaturesList>
                                {subject.features.map((feature, index) => (
                                    <FeatureTag key={index} bgColor={subject.color}>
                                        {feature}
                                    </FeatureTag>
                                ))}
                            </FeaturesList>

                            <CardFooter>
                                <LessonCount>
                                    <BookOpen size={16} />
                                    {subject.lessonCount} lessons
                                </LessonCount>
                                <CreateButton
                                    bgColor={subject.color}
                                    isHovered={hoveredCard === subject.id}
                                >
                                    Create Paper <ChevronRight size={16} />
                                </CreateButton>
                            </CardFooter>
                        </SubjectCard>
                    ))}

                    {/* Coming Soon Card */}
                    <ComingSoonCard>
                        <CardHeader>
                            <IconWrapper bgColor="#94a3b8">
                                <Sparkles size={32} />
                            </IconWrapper>
                            <SubjectTitle>More Coming Soon</SubjectTitle>
                        </CardHeader>

                        <SubjectDescription>
                            We're working on adding more subjects including Science, English, History, and Geography. Stay tuned!
                        </SubjectDescription>

                        <FeaturesList>
                            <FeatureTag bgColor="#94a3b8">Science</FeatureTag>
                            <FeatureTag bgColor="#94a3b8">English</FeatureTag>
                            <FeatureTag bgColor="#94a3b8">History</FeatureTag>
                            <FeatureTag bgColor="#94a3b8">Geography</FeatureTag>
                        </FeaturesList>

                        <CardFooter>
                            <LessonCount>
                                <Sparkles size={16} />
                                Coming 2024
                            </LessonCount>
                            <CreateButton bgColor="#94a3b8">
                                Notify Me
                            </CreateButton>
                        </CardFooter>
                    </ComingSoonCard>
                </SubjectsGrid>

                {/* Quick Start Templates */}
                <QuickStartSection>
                    <QuickStartTitle>Quick Start Templates</QuickStartTitle>
                    <QuickStartGrid>
                        {quickStartTemplates.map((template) => (
                            <QuickStartItem key={template.id}>
                                <span style={{ fontSize: '24px' }}>{template.icon}</span>
                                <div style={{ flex: 1 }}>
                                    <div style={{ fontWeight: 600, color: '#0f172a' }}>{template.name}</div>
                                    <div style={{ fontSize: '12px', color: '#64748b' }}>{template.time}</div>
                                </div>
                                <ChevronRight size={16} color="#94a3b8" />
                            </QuickStartItem>
                        ))}
                    </QuickStartGrid>
                </QuickStartSection>
            </MainContent>
        </PageContainer>
    );
};

export default TeacherCreatePaper;