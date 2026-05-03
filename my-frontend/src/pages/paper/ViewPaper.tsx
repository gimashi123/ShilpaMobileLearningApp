import { useEffect, useRef, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import styled from "@emotion/styled";
import { jsPDF } from "jspdf";
import {
    ArrowLeft,
    Loader2,
    AlertCircle,
    FileDown,
    Upload,
    CheckCircle2,
    XCircle
} from "lucide-react";

type Question = {
    questionId: string;
    question: string;
    answer: string | number;
};

type PaperData = {
    _id: string;
    grade: string;
    subject: string;
    type: string;
    questions: Question[];
    createdAt: string;
};

type ValidationResult = {
    question: number;
    correct: number;
    predicted: number;
    isCorrect: boolean;
};

const Container = styled.div`
    min-height: 100vh;
    background-color: #f8fafc;
    padding: 40px 20px;
    font-family: 'Inter', sans-serif;
`;

const PaperCard = styled.div`
    max-width: 900px;
    margin: 0 auto;
    background: white;
    border-radius: 20px;
    box-shadow: 0 10px 25px rgba(0,0,0,0.05);
    overflow: hidden;
    border: 1px solid #e2e8f0;
`;

const Header = styled.div`
    background: #1e293b;
    color: white;
    padding: 24px 32px;
    display: flex;
    justify-content: space-between;
    align-items: center;
`;

const HeaderInfo = styled.div`
    display: flex;
    align-items: center;
    gap: 16px;
`;

const BackButton = styled.button`
    background: rgba(255,255,255,0.1);
    border: none;
    color: white;
    padding: 8px;
    border-radius: 10px;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: all 0.2s;

    &:hover {
        background: rgba(255,255,255,0.2);
    }
`;

const Content = styled.div`
    padding: 32px;
`;

const ActionRow = styled.div`
    display: flex;
    gap: 16px;
    margin-bottom: 32px;
    flex-wrap: wrap;
`;

const Button = styled.button<{ variant?: 'primary' | 'secondary' | 'success' }>`
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 12px 24px;
    border-radius: 12px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.2s;
    border: none;
    
    ${props => props.variant === 'primary' && `
        background: #3b82f6;
        color: white;
        &:hover { background: #2563eb; }
    `}

    ${props => props.variant === 'secondary' && `
        background: #f1f5f9;
        color: #475569;
        border: 1px solid #e2e8f0;
        &:hover { background: #e2e8f0; }
    `}

    ${props => props.variant === 'success' && `
        background: #10b981;
        color: white;
        &:hover { background: #059669; }
    `}
`;

const QuestionsGrid = styled.div`
    display: grid;
    gap: 16px;
`;

const QuestionItem = styled.div`
    padding: 20px;
    background: #f8fafc;
    border-radius: 12px;
    border: 1px solid #e2e8f0;
    display: flex;
    justify-content: space-between;
    align-items: center;
`;

const ResultBox = styled.div`
    margin-top: 32px;
    padding: 24px;
    background: #f0f9ff;
    border-radius: 16px;
    border: 1px solid #bae6fd;
`;

const ResultTable = styled.table`
    width: 100%;
    border-collapse: collapse;
    margin-top: 16px;
`;

const Th = styled.th`
    text-align: left;
    padding: 12px;
    border-bottom: 2px solid #e0f2fe;
    color: #0369a1;
`;

const Td = styled.td`
    padding: 12px;
    border-bottom: 1px solid #e0f2fe;
`;

const StatusBadge = styled.span<{ success: boolean }>`
    padding: 4px 10px;
    border-radius: 20px;
    font-size: 12px;
    font-weight: 600;
    display: inline-flex;
    align-items: center;
    gap: 4px;
    background: ${props => props.success ? '#dcfce7' : '#fee2e2'};
    color: ${props => props.success ? '#166534' : '#991b1b'};
`;

const ViewPaper = () => {
    const { id } = useParams<{ id: string }>();
    const navigate = useNavigate();
    const [paper, setPaper] = useState<PaperData | null>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState("");
    const [result, setResult] = useState<ValidationResult[]>([]);
    const [uploading, setUploading] = useState(false);
    
    const fileInputRef = useRef<HTMLInputElement>(null);

    useEffect(() => {
        const fetchPaper = async () => {
            try {
                const token = localStorage.getItem("token");
                const res = await fetch(`http://localhost:3000/api/quizzes/paper/${id}`, {
                    headers: { Authorization: `Bearer ${token}` }
                });
                const data = await res.json();
                if (!res.ok) throw new Error(data.message || "Failed to load paper");
                setPaper(data.paper);
            } catch (err: any) {
                setError(err.message);
            } finally {
                setLoading(false);
            }
        };
        fetchPaper();
    }, [id]);

    /* BRAILLE LOGIC (Reused from PaperBuilder) */
    const brailleMap: Record<string, number[]> = {
        "1": [1], "2": [1, 2], "3": [1, 4], "4": [1, 4, 5], "5": [1, 5],
        "6": [1, 2, 4], "7": [1, 2, 4, 5], "8": [1, 2, 5], "9": [2, 4], "0": [2, 4, 5],
        "+": [2, 3, 5], "-": [3, 6], "*": [1, 6], "/": [3, 4], "=": [2, 3, 5, 6], "#": [3, 4, 5, 6]
    };

    const questionToTokens = (question: string): string[] => {
        const tokens: string[] = [];
        const parts = question.match(/\d+|[+\-*/=]/g) || [];
        parts.forEach(part => {
            if (/^\d+$/.test(part)) {
                tokens.push("#");
                part.split("").forEach(d => tokens.push(d));
            } else {
                tokens.push(part);
            }
        });
        return tokens;
    };

    const drawBrailleCell = (doc: jsPDF, x: number, y: number, dots: number[]) => {
        const rowGap = 3.2; const colGap = 3.2;
        const positions: Record<number, [number, number]> = {
            1: [x, y], 2: [x, y + rowGap], 3: [x, y + rowGap * 2],
            4: [x + colGap, y], 5: [x + colGap, y + rowGap], 6: [x + colGap, y + rowGap * 2]
        };
        dots.forEach(dot => {
            const [dx, dy] = positions[dot];
            doc.circle(dx, dy, 0.9, "F");
        });
    };

    const drawBrailleSequence = (doc: jsPDF, tokens: string[], startX: number, startY: number) => {
        let x = startX;
        tokens.forEach(token => {
            const dots = brailleMap[token] || [];
            drawBrailleCell(doc, x, startY, dots);
            x += 8;
        });
    };

    const handleDownloadPDF = () => {
        if (!paper) return;
        const doc = new jsPDF();
        let y = 20;
        doc.setFontSize(18);
        doc.text(`${paper.subject.toUpperCase()} - Braille Quiz`, 20, y);
        y += 15;
        doc.setFontSize(12);
        doc.text(`Paper ID: ${paper._id}`, 20, y);
        doc.text(`Grade: ${paper.grade}`, 150, y);
        y += 20;

        paper.questions.forEach((q, index) => {
            doc.text(`${index + 1}.`, 20, y);
            const tokens = questionToTokens(q.question);
            drawBrailleSequence(doc, tokens, 35, y - 2);
            y += 18;
            if (y > 270) { doc.addPage(); y = 20; }
        });
        doc.save(`braille_paper_${paper._id}.pdf`);
    };

    const handleUploadSheet = async (e: React.ChangeEvent<HTMLInputElement>) => {
        if (!e.target.files?.[0] || !paper) return;
        
        try {
            setUploading(true);
            const formData = new FormData();
            formData.append("image", e.target.files[0]);

            const res = await fetch("http://localhost:8000/api/visual-impairment/predict-sheet", {
                method: "POST",
                body: formData
            });

            const data = await res.json();
            const validation = paper.questions.map((q, i) => ({
                question: i + 1,
                correct: Number(q.answer),
                predicted: data.digits[i],
                isCorrect: Number(q.answer) === data.digits[i]
            }));

            setResult(validation);
        } catch (err) {
            console.error(err);
            alert("Failed to process answer sheet");
        } finally {
            setUploading(false);
        }
    };

    if (loading) return (
        <Container style={{ display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
            <Loader2 className="animate-spin" size={48} color="#3b82f6" />
        </Container>
    );

    if (error || !paper) return (
        <Container>
            <PaperCard style={{ padding: '40px', textAlign: 'center' }}>
                <AlertCircle size={48} color="#ef4444" style={{ marginBottom: '16px' }} />
                <h3>Error Loading Paper</h3>
                <p>{error || "Paper not found"}</p>
                <Button variant="primary" onClick={() => navigate(-1)} style={{ marginTop: '20px' }}>Go Back</Button>
            </PaperCard>
        </Container>
    );

    return (
        <Container>
            <PaperCard>
                <Header>
                    <HeaderInfo>
                        <BackButton onClick={() => navigate(-1)}>
                            <ArrowLeft size={20} />
                        </BackButton>
                        <div>
                            <h2 style={{ margin: 0, fontSize: '20px' }}>{paper.subject.toUpperCase()} Paper</h2>
                            <span style={{ opacity: 0.7, fontSize: '14px' }}>Grade {paper.grade} • {paper.type}</span>
                        </div>
                    </HeaderInfo>
                    <StatusBadge success={true} style={{ background: 'rgba(255,255,255,0.1)', color: 'white' }}>
                        ID: {paper._id.slice(-6)}
                    </StatusBadge>
                </Header>

                <Content>
                    <ActionRow>
                        <Button variant="primary" onClick={handleDownloadPDF}>
                            <FileDown size={18} />
                            Download Braille PDF
                        </Button>
                        
                        <Button variant="success" onClick={() => fileInputRef.current?.click()} disabled={uploading}>
                            {uploading ? <Loader2 className="animate-spin" size={18} /> : <Upload size={18} />}
                            Upload Answer Sheet
                        </Button>
                        <input type="file" hidden ref={fileInputRef} onChange={handleUploadSheet} />
                    </ActionRow>

                    <h3 style={{ marginBottom: '20px', color: '#1e293b' }}>Questions List</h3>
                    <QuestionsGrid>
                        {paper.questions.map((q, index) => (
                            <QuestionItem key={index}>
                                <div>
                                    <span style={{ fontWeight: 700, marginRight: '12px', color: '#64748b' }}>{index + 1}.</span>
                                    <span style={{ fontSize: '18px', fontWeight: 500 }}>{q.question}</span>
                                </div>
                                <div style={{ color: '#94a3b8', fontSize: '14px' }}>
                                    Ans: {q.answer}
                                </div>
                            </QuestionItem>
                        ))}
                    </QuestionsGrid>

                    {result.length > 0 && (
                        <ResultBox>
                            <h3 style={{ margin: 0, color: '#0369a1', display: 'flex', alignItems: 'center', gap: '8px' }}>
                                <CheckCircle2 size={20} />
                                Validation Results
                            </h3>
                            <ResultTable>
                                <thead>
                                    <tr>
                                        <Th>#</Th>
                                        <Th>Correct Answer</Th>
                                        <Th>Student's Answer</Th>
                                        <Th>Result</Th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {result.map((r, i) => (
                                        <tr key={i}>
                                            <Td>{r.question}</Td>
                                            <Td>{r.correct}</Td>
                                            <Td>{r.predicted}</Td>
                                            <Td>
                                                <StatusBadge success={r.isCorrect}>
                                                    {r.isCorrect ? <CheckCircle2 size={14} /> : <XCircle size={14} />}
                                                    {r.isCorrect ? "Correct" : "Incorrect"}
                                                </StatusBadge>
                                            </Td>
                                        </tr>
                                    ))}
                                </tbody>
                            </ResultTable>
                        </ResultBox>
                    )}
                </Content>
            </PaperCard>
        </Container>
    );
};

export default ViewPaper;
