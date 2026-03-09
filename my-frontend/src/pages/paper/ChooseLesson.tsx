import { useMemo, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import styled from '@emotion/styled';
import {
    ArrowRight,
    Calculator,
    BookOpen,
    Plus,
    Minus,
    X,
    Divide,
    LetterText,
    Languages,
    FileText,
    PenLine,
    ArrowLeft,
    AlertCircle,
    BookX,
    Sparkles,
    Clock,
    ChevronRight
} from 'lucide-react';

type Lesson = {
    id: string;
    name: string;
};

const LESSONS_BY_SUBJECT: Record<string, Lesson[]> = {
    maths: [
        { id: "addition", name: "එකතු කිරීම" },
        { id: "subtraction", name: "අඩු කිරීම" },
        { id: "multiplication", name: "ගුණ කිරීම" },
        { id: "division", name: "බෙදීම" },
    ],
    sinhala: [
        { id: "letters", name: "අකුරු" },
        { id: "words", name: "වචන" },
        { id: "sentences", name: "වාක්‍ය" },
    ],
};

// Page Container
const PageContainer = styled.div`
    min-height: 100vh;
    background-color: #f0f2f5;
    padding: 20px;
`;

// Cover Section - Solid colors only
const CoverSection = styled.div<{ subjectType: string }>`
    background-color: ${props =>
    props.subjectType === 'maths' ? '#1e293b' :
        props.subjectType === 'sinhala' ? '#321515' :
            '#1e293b'};
    color: white;
    padding: 40px 20px 80px;
    border-radius: 24px;
    margin-bottom: 20px;
    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
`;

const CoverContent = styled.div`
    max-width: 1200px;
    margin: 0 auto;
`;

const CoverTitle = styled.h1`
    font-size: 36px;
    font-weight: 700;
    margin: 0 0 12px 0;
    color: white;

    @media (max-width: 768px) {
        font-size: 28px;
    }
`;

const CoverSubtitle = styled.p`
    font-size: 16px;
    color: rgba(255, 255, 255, 0.9);
    margin: 0 0 24px 0;
    max-width: 600px;
    line-height: 1.5;
`;

const CoverStats = styled.div`
    display: flex;
    gap: 24px;
    flex-wrap: wrap;
`;

const CoverStat = styled.div`
    display: flex;
    align-items: center;
    gap: 12px;
    background: rgba(255, 255, 255, 0.1);
    padding: 12px 20px;
    border-radius: 12px;
`;

const CoverStatIcon = styled.div`
    display: flex;
    align-items: center;
    justify-content: center;
    color: white;
`;

const CoverStatInfo = styled.div`
    display: flex;
    flex-direction: column;
`;

const CoverStatValue = styled.span`
    font-size: 20px;
    font-weight: 600;
    color: white;
`;

const CoverStatLabel = styled.span`
    font-size: 13px;
    color: rgba(255, 255, 255, 0.8);
`;

// Main Content Section
const MainContent = styled.div`
    max-width: 1200px;
    margin: -40px auto 0;
    padding: 0;
    position: relative;
    z-index: 2;
`;

const NavigationRow = styled.div`
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 24px;
    background: white;
    padding: 12px 20px;
    border-radius: 12px;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
    border: 1px solid #e5e7eb;
`;

const BackButton = styled.button<{ subjectType: string }>`
    background: none;
    border: none;
    color: ${props => props.subjectType === 'maths' ? '#2563eb' : props.subjectType === 'sinhala' ? '#dc2626' : '#64748b'};
    font-size: 14px;
    font-weight: 500;
    cursor: pointer;
    padding: 8px 16px;
    display: flex;
    align-items: center;
    gap: 8px;
    border-radius: 8px;
    transition: all 0.2s;

    &:hover {
        background-color: ${props => props.subjectType === 'maths' ? '#2563eb20' : props.subjectType === 'sinhala' ? '#dc262620' : '#64748b20'};
    }
`;

const SubjectInfo = styled.div<{ subjectType: string }>`
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 6px 16px;
    background-color: ${props => props.subjectType === 'maths' ? '#2563eb10' : props.subjectType === 'sinhala' ? '#dc262610' : '#64748b10'};
    border-radius: 30px;
    color: ${props => props.subjectType === 'maths' ? '#2563eb' : props.subjectType === 'sinhala' ? '#dc2626' : '#64748b'};
    font-weight: 500;
`;

const SectionHeader = styled.div`
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 24px;
    background: white;
    padding: 20px 24px;
    border-radius: 16px;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
    border: 1px solid #e5e7eb;

    @media (max-width: 768px) {
        flex-direction: column;
        align-items: flex-start;
        gap: 12px;
    }
`;

const SectionTitle = styled.h2`
    font-size: 24px;
    font-weight: 600;
    color: #1e293b;
    margin: 0;
`;

const SectionBadge = styled.div`
    background-color: #f1f5f9;
    padding: 6px 16px;
    border-radius: 30px;
    font-size: 14px;
    font-weight: 500;
    color: #475569;
    display: flex;
    align-items: center;
    gap: 6px;
`;

const LessonsGrid = styled.div`
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
    gap: 20px;
    margin-bottom: 32px;
`;

const LessonCard = styled.div<{ subjectType: string }>`
    background: white;
    border-radius: 16px;
    padding: 24px;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
    border: 1px solid #e5e7eb;
    display: flex;
    flex-direction: column;
    transition: all 0.2s ease;
    cursor: pointer;

    &:hover {
        transform: translateY(-4px);
        box-shadow: 0 12px 20px -8px rgba(0, 0, 0, 0.15);
        border-color: ${props => props.subjectType === 'maths' ? '#2563eb' : '#dc2626'};
    }
`;

const CardHeader = styled.div`
    display: flex;
    align-items: center;
    gap: 16px;
    margin-bottom: 16px;
`;

const IconWrapper = styled.div<{ bgColor: string }>`
    width: 56px;
    height: 56px;
    border-radius: 14px;
    background-color: ${props => props.bgColor};
    display: flex;
    align-items: center;
    justify-content: center;
    color: white;
`;

const LessonTitle = styled.h3`
    font-size: 20px;
    font-weight: 600;
    color: #1e293b;
    margin: 0 0 4px 0;
`;

const LessonMeta = styled.div`
    display: flex;
    gap: 12px;
`;

const MetaItem = styled.div`
    display: flex;
    align-items: center;
    gap: 4px;
    font-size: 13px;
    color: #64748b;
`;

const LessonDescription = styled.p`
    font-size: 14px;
    color: #475569;
    margin: 0 0 16px 0;
    line-height: 1.5;
    flex: 1;
`;

const FeaturesList = styled.div`
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    margin-bottom: 20px;
`;

const FeatureTag = styled.span<{ subjectType: string }>`
    background-color: ${props => props.subjectType === 'maths' ? '#2563eb10' : '#dc262610'};
    color: ${props => props.subjectType === 'maths' ? '#2563eb' : '#dc2626'};
    padding: 4px 10px;
    border-radius: 16px;
    font-size: 12px;
    font-weight: 500;
`;

const GetStartedButton = styled.button<{ subjectType: string }>`
    background-color: ${props => props.subjectType === 'maths' ? '#2563eb' : '#dc2626'};
    color: white;
    border: none;
    border-radius: 10px;
    padding: 12px 16px;
    font-size: 15px;
    font-weight: 500;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
    transition: all 0.2s;
    width: 100%;

    &:hover {
        background-color: ${props => props.subjectType === 'maths' ? '#1d4ed8' : '#b91c1c'};
    }
`;

// Recommended Section
const RecommendedSection = styled.div`
    margin-top: 32px;
`;

const RecommendedTitle = styled.h3`
    font-size: 18px;
    font-weight: 600;
    color: #1e293b;
    margin: 0 0 16px 0;
    display: flex;
    align-items: center;
    gap: 8px;
`;

const RecommendedGrid = styled.div`
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
    gap: 12px;
`;

const RecommendedCard = styled.div<{ subjectType: string }>`
    background: white;
    border-radius: 12px;
    padding: 16px;
    border: 1px solid #e5e7eb;
    cursor: pointer;
    transition: all 0.2s;
    display: flex;
    align-items: center;
    justify-content: space-between;

    &:hover {
        border-color: ${props => props.subjectType === 'maths' ? '#2563eb' : '#dc2626'};
        background-color: ${props => props.subjectType === 'maths' ? '#2563eb08' : '#dc262608'};
    }
`;

const RecommendedInfo = styled.div`
    display: flex;
    align-items: center;
    gap: 12px;
`;

const RecommendedIcon = styled.div<{ subjectType: string }>`
    width: 36px;
    height: 36px;
    border-radius: 8px;
    background-color: ${props => props.subjectType === 'maths' ? '#2563eb10' : '#dc262610'};
    color: ${props => props.subjectType === 'maths' ? '#2563eb' : '#dc2626'};
    display: flex;
    align-items: center;
    justify-content: center;
`;

const RecommendedName = styled.span`
    font-size: 15px;
    font-weight: 500;
    color: #1e293b;
`;

// Empty States
const EmptyState = styled.div`
    grid-column: 1 / -1;
    text-align: center;
    padding: 60px 24px;
    background: white;
    border-radius: 16px;
    border: 2px dashed #cbd5e1;
`;

const EmptyStateIcon = styled.div`
    display: flex;
    justify-content: center;
    margin-bottom: 16px;
    color: #94a3b8;
`;

const EmptyStateTitle = styled.h3`
    font-size: 20px;
    font-weight: 600;
    color: #1e293b;
    margin: 0 0 8px 0;
`;

const EmptyStateText = styled.p`
    font-size: 15px;
    color: #64748b;
    margin: 0;
`;

const ChooseLesson = () => {
    const navigate = useNavigate();
    const { subject } = useParams<{ subject: string }>();
    const [, setHoveredCard] = useState<string | null>(null);

    const currentSubject = subject || '';

    const lessons = useMemo(() => {
        if (!currentSubject) return [];
        return LESSONS_BY_SUBJECT[currentSubject] || [];
    }, [currentSubject]);

    const handleLessonClick = (type: string) => {
        if (!currentSubject) return;
        navigate(`/teacher/create-paper/${currentSubject}/${type}`);
    };

    const handleBack = () => {
        navigate('/teacher/subjects');
    };

    const getSubjectIcon = () => {
        if (currentSubject === 'maths') return <Calculator size={20} />;
        if (currentSubject === 'sinhala') return <Languages size={20} />;
        return <BookOpen size={20} />;
    };

    const getSubjectDisplayName = (subjectParam: string) => {
        if (subjectParam === 'maths') return 'Mathematics';
        if (subjectParam === 'sinhala') return 'Sinhala';
        return subjectParam || 'Unknown';
    };

    const getSubjectColor = (subjectParam: string) => {
        if (subjectParam === 'maths') return '#2563eb';
        if (subjectParam === 'sinhala') return '#dc2626';
        return '#64748b';
    };

    const getLessonIcon = (lessonId: string) => {
        const icons: Record<string, React.ReactNode> = {
            addition: <Plus size={24} />,
            subtraction: <Minus size={24} />,
            multiplication: <X size={24} />,
            division: <Divide size={24} />,
            letters: <LetterText size={24} />,
            words: <BookOpen size={24} />,
            sentences: <FileText size={24} />,
        };
        return icons[lessonId] || <PenLine size={24} />;
    };

    const getLessonDescription = (lessonId: string) => {
        const descriptions: Record<string, string> = {
            addition: "Practice addition with interactive exercises",
            subtraction: "Learn subtraction step by step",
            multiplication: "Master multiplication tables",
            division: "Understand division concepts",
            letters: "Learn Sinhala letters and pronunciation",
            words: "Build vocabulary with common words",
            sentences: "Form complete sentences",
        };
        return descriptions[lessonId] || "Start learning";
    };

    const getLessonFeatures = (lessonId: string) => {
        const features: Record<string, string[]> = {
            addition: ["Beginner", "10 exercises"],
            subtraction: ["Beginner", "8 exercises"],
            multiplication: ["Intermediate", "12 exercises"],
            division: ["Intermediate", "10 exercises"],
            letters: ["Beginner", "15 letters"],
            words: ["Beginner", "20 words"],
            sentences: ["Advanced", "10 patterns"],
        };
        return features[lessonId] || ["New"];
    };

    const getTimeEstimate = (lessonId: string) => {
        const estimates: Record<string, string> = {
            addition: "15 min",
            subtraction: "15 min",
            multiplication: "20 min",
            division: "20 min",
            letters: "25 min",
            words: "20 min",
            sentences: "30 min",
        };
        return estimates[lessonId] || "15 min";
    };

    const recommendedLessons = lessons.slice(0, 3);

    return (
        <PageContainer>
            {/* Cover Section */}
            <CoverSection subjectType={currentSubject}>
                <CoverContent>
                    <CoverTitle>
                        {getSubjectDisplayName(currentSubject)} Lessons
                    </CoverTitle>
                    <CoverSubtitle>
                        Choose from our collection of {getSubjectDisplayName(currentSubject)} lessons
                    </CoverSubtitle>

                    <CoverStats>
                        <CoverStat>
                            <CoverStatIcon>
                                <BookOpen size={20} />
                            </CoverStatIcon>
                            <CoverStatInfo>
                                <CoverStatValue>{lessons.length}</CoverStatValue>
                                <CoverStatLabel>Lessons</CoverStatLabel>
                            </CoverStatInfo>
                        </CoverStat>
                        <CoverStat>
                            <CoverStatIcon>
                                <Clock size={20} />
                            </CoverStatIcon>
                            <CoverStatInfo>
                                <CoverStatValue>15-30 min</CoverStatValue>
                                <CoverStatLabel>Per lesson</CoverStatLabel>
                            </CoverStatInfo>
                        </CoverStat>
                    </CoverStats>
                </CoverContent>
            </CoverSection>

            {/* Main Content */}
            <MainContent>
                {/* Navigation Row */}
                <NavigationRow>
                    <BackButton subjectType={currentSubject} onClick={handleBack}>
                        <ArrowLeft size={16} />
                        Back
                    </BackButton>
                    <SubjectInfo subjectType={currentSubject}>
                        {getSubjectIcon()}
                        <span>{getSubjectDisplayName(currentSubject)}</span>
                    </SubjectInfo>
                </NavigationRow>

                {/* Main Lessons Grid */}
                <SectionHeader>
                    <SectionTitle>Available Lessons</SectionTitle>
                    <SectionBadge>
                        <Sparkles size={16} />
                        {lessons.length} lessons
                    </SectionBadge>
                </SectionHeader>

                <LessonsGrid>
                    {!currentSubject ? (
                        <EmptyState>
                            <EmptyStateIcon>
                                <AlertCircle size={48} />
                            </EmptyStateIcon>
                            <EmptyStateTitle>No Subject Selected</EmptyStateTitle>
                            <EmptyStateText>Please select a subject first.</EmptyStateText>
                        </EmptyState>
                    ) : lessons.length === 0 ? (
                        <EmptyState>
                            <EmptyStateIcon>
                                <BookX size={48} />
                            </EmptyStateIcon>
                            <EmptyStateTitle>No Lessons Found</EmptyStateTitle>
                            <EmptyStateText>
                                No lessons available for {getSubjectDisplayName(currentSubject)} yet.
                            </EmptyStateText>
                        </EmptyState>
                    ) : (
                        lessons.map((lesson) => (
                            <LessonCard
                                key={lesson.id}
                                subjectType={currentSubject}
                                onMouseEnter={() => setHoveredCard(lesson.id)}
                                onMouseLeave={() => setHoveredCard(null)}
                                onClick={() => handleLessonClick(lesson.id)}
                            >
                                <CardHeader>
                                    <IconWrapper bgColor={getSubjectColor(currentSubject)}>
                                        {getLessonIcon(lesson.id)}
                                    </IconWrapper>
                                    <div>
                                        <LessonTitle>{lesson.name}</LessonTitle>
                                        <LessonMeta>
                                            <MetaItem>
                                                <Clock size={12} />
                                                {getTimeEstimate(lesson.id)}
                                            </MetaItem>
                                        </LessonMeta>
                                    </div>
                                </CardHeader>

                                <LessonDescription>
                                    {getLessonDescription(lesson.id)}
                                </LessonDescription>

                                <FeaturesList>
                                    {getLessonFeatures(lesson.id).map((feature, index) => (
                                        <FeatureTag key={index} subjectType={currentSubject}>
                                            {feature}
                                        </FeatureTag>
                                    ))}
                                </FeaturesList>

                                <GetStartedButton subjectType={currentSubject}>
                                    Start <ArrowRight size={16} />
                                </GetStartedButton>
                            </LessonCard>
                        ))
                    )}
                </LessonsGrid>

                {/* Recommended Lessons */}
                {lessons.length > 0 && (
                    <RecommendedSection>
                        <RecommendedTitle>
                            <Sparkles size={18} color={getSubjectColor(currentSubject)} />
                            Recommended
                        </RecommendedTitle>
                        <RecommendedGrid>
                            {recommendedLessons.map((lesson) => (
                                <RecommendedCard
                                    key={lesson.id}
                                    subjectType={currentSubject}
                                    onClick={() => handleLessonClick(lesson.id)}
                                >
                                    <RecommendedInfo>
                                        <RecommendedIcon subjectType={currentSubject}>
                                            {getLessonIcon(lesson.id)}
                                        </RecommendedIcon>
                                        <RecommendedName>{lesson.name}</RecommendedName>
                                    </RecommendedInfo>
                                    <ChevronRight size={16} color={getSubjectColor(currentSubject)} />
                                </RecommendedCard>
                            ))}
                        </RecommendedGrid>
                    </RecommendedSection>
                )}
            </MainContent>
        </PageContainer>
    );
};

export default ChooseLesson;