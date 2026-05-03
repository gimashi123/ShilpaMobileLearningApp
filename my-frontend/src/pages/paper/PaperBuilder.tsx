import { useEffect, useRef, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import styled from "@emotion/styled";
import { jsPDF } from "jspdf";
import {
    ArrowLeft,
    Loader2,
    AlertCircle,
    FileDown,
    Upload
} from "lucide-react";

type Quiz = {
    _id: string;
    question: string;
    answer?: string;
    grade: string;
    type: string;
    subject: string;
};

type ValidationResult = {
    question: number;
    correct: number;
    predicted: number;
    isCorrect: boolean;
};

const Container = styled.div`
    min-height: 100vh;
    background-color: #f5f5f5;
    padding: 30px 20px;
`;

const Paper = styled.div`
    max-width: 800px;
    margin: 0 auto;
    background: white;
    border-radius: 12px;
    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
`;

const Header = styled.div`
    background:#2c3e50;
    color:white;
    padding:20px 24px;
    display:flex;
    align-items:center;
    gap:16px;
`;

const BackButton = styled.button`
    background:none;
    border:none;
    color:white;
    cursor:pointer;
`;

const Content = styled.div`
    padding:30px;
`;

const QuestionsList = styled.div`
    display:flex;
    flex-direction:column;
    gap:12px;
`;

const QuestionItem = styled.div`
    padding:12px;
    background:#f8f9fa;
    border-radius:6px;
`;

const QuestionNumber = styled.span`
    font-weight:600;
    margin-right:8px;
`;

const Button = styled.button`
    background:#27ae60;
    color:white;
    border:none;
    padding:12px 20px;
    border-radius:6px;
    margin-bottom:20px;
    font-weight:600;
    display:flex;
    gap:8px;
    align-items:center;
    cursor:pointer;

    &:hover{
        background:#1e874b;
    }
`;

const UploadButton = styled(Button)`
    background:#3498db;

    &:hover{
        background:#2c80b4;
    }
`;

const ResultBox = styled.div`
    background:#ecf0f1;
    padding:16px;
    border-radius:6px;
    margin-top:20px;
`;

const LoadingState = styled.div`
    text-align:center;
    padding:40px;
`;

const ErrorState = styled.div`
    text-align:center;
    padding:40px;
    color:red;
`;

const Spinner = styled(Loader2)`
    animation: spin 1s linear infinite;
`;

const TeacherPaperBuilder = () => {

    const navigate = useNavigate();
    const { subject, type } = useParams<{subject:string;type:string}>();

    const [quizzes,setQuizzes] = useState<Quiz[]>([]);
    const [quizId,setQuizId] = useState<string>("");
    const [loading,setLoading] = useState(false);
    const [error,setError] = useState("");
    const [result,setResult] = useState<ValidationResult[]>([]);

    const fileInputRef = useRef<HTMLInputElement>(null);
    const [isSaved, setIsSaved] = useState(false);

    /* LOAD QUIZ */

    useEffect(()=>{

        const loadQuiz = async()=>{

            if(!subject || !type) return;

            try{

                setLoading(true);

                const token = localStorage.getItem("token");
                const res = await fetch(
                    `http://localhost:3000/api/quizzes/random?grade=3&subject=${subject}&type=${type}`
                );

                const data = await res.json();

                setQuizzes(data.quizzes || []);
                // setQuizId(data.quizId || ""); // quizId will be set after saving

            }catch(err){

                console.error(err);
                setError("Failed to load quizzes");

            }finally{

                setLoading(false);

            }

        };

        loadQuiz();

    },[subject,type]);

    const handleBack = ()=>{
        navigate(`/teacher/create-paper/${subject}`);
    };

    /* BRAILLE MAP */

    const brailleMap:Record<string,number[]> = {
        "1":[1],
        "2":[1,2],
        "3":[1,4],
        "4":[1,4,5],
        "5":[1,5],
        "6":[1,2,4],
        "7":[1,2,4,5],
        "8":[1,2,5],
        "9":[2,4],
        "0":[2,4,5],
        "+":[2,3,5],
        "-":[3,6],
        "*":[1,6],
        "/":[3,4],
        "=":[2,3,5,6],
        "#":[3,4,5,6]
    };

    const questionToTokens=(question:string):string[]=>{

        const tokens:string[]=[];
        const parts = question.match(/\d+|[+\-*/=]/g) || [];

        parts.forEach(part=>{
            if(/^\d+$/.test(part)){
                tokens.push("#");
                part.split("").forEach(d=>tokens.push(d));
            }else{
                tokens.push(part);
            }
        });

        return tokens;
    };

    const drawBrailleCell=(doc:jsPDF,x:number,y:number,dots:number[])=>{

        const rowGap=3.2;
        const colGap=3.2;

        const positions:Record<number,[number,number]> = {
            1:[x,y],
            2:[x,y+rowGap],
            3:[x,y+rowGap*2],
            4:[x+colGap,y],
            5:[x+colGap,y+rowGap],
            6:[x+colGap,y+rowGap*2]
        };

        dots.forEach(dot=>{
            const [dx,dy] = positions[dot];
            doc.circle(dx,dy,0.9,"F");
        });

    };

    const drawBrailleSequence=(doc:jsPDF,tokens:string[],startX:number,startY:number)=>{

        let x=startX;

        tokens.forEach(token=>{
            const dots = brailleMap[token] || [];
            drawBrailleCell(doc,x,startY,dots);
            x+=8;
        });

    };

    /* GENERATE PDF AND SAVE */

    const generateBraillePDF= async ()=>{

        const doc = new jsPDF();
        let y=20;

        doc.text("Braille Mathematics Quiz",20,y);
        y+=15;

        // Save to backend first or after
        try {
            const token = localStorage.getItem("token");
            const res = await fetch("http://localhost:3000/api/quizzes/save-paper", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    Authorization: `Bearer ${token}`
                },
                body: JSON.stringify({
                    grade: "3",
                    subject,
                    type,
                    questions: quizzes.map(q => ({
                        questionId: q._id,
                        question: q.question,
                        answer: q.answer
                    }))
                })
            });

            const data = await res.json();
            if (res.ok) {
                setQuizId(data.quizId);
                setIsSaved(true);
                
                doc.text(`Quiz ID: ${data.quizId}`,20,y);
                y+=15;

                quizzes.forEach((q,index)=>{
                    doc.text(`${index+1}.`,20,y);
                    const tokens = questionToTokens(q.question);
                    drawBrailleSequence(doc,tokens,35,y-2);
                    y+=18;
                });

                doc.save(`braille_quiz_${data.quizId}.pdf`);
                alert("Paper generated and saved to dashboard!");
            }
        } catch (err) {
            console.error("Failed to save paper:", err);
            alert("Failed to save paper to dashboard");
        }
    };

    /* UPLOAD FULL ANSWER SHEET */

    const uploadAnswerSheet = async(file:File)=>{

        const formData = new FormData();
        formData.append("image",file);

        const res = await fetch(
            "http://localhost:8000/api/visual-impairment/predict-sheet",
            {
                method:"POST",
                body:formData
            }
        );

        const data = await res.json();

        const validation = quizzes.map((q,i)=>({
            question:i+1,
            correct:Number(q.answer),
            predicted:data.digits[i],
            isCorrect:Number(q.answer) === data.digits[i]
        }));

        setResult(validation);

    };

    const checkIndividualAnswer = async (file: File, index: number) => {
        const formData = new FormData();
        formData.append("image", file);

        // Assuming level1 prediction for individual digits
        const res = await fetch(
            "http://localhost:8000/api/visual-impairment/predict-level1",
            {
                method: "POST",
                body: formData
            }
        );

        const data = await res.json();
        const predicted = data.prediction;
        const correct = Number(quizzes[index].answer);

        const newResult = [...result];
        const validation = {
            question: index + 1,
            correct,
            predicted,
            isCorrect: predicted === correct
        };

        // Find if already exists and update, or add
        const existingIdx = newResult.findIndex(r => r.question === index + 1);
        if (existingIdx > -1) {
            newResult[existingIdx] = validation;
        } else {
            newResult.push(validation);
        }
        
        setResult(newResult);
    };

    const [checkingIndex, setCheckingIndex] = useState<number | null>(null);
    const individualFileInputRef = useRef<HTMLInputElement>(null);

    const handleIndividualUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
        if (e.target.files?.[0] && checkingIndex !== null) {
            checkIndividualAnswer(e.target.files[0], checkingIndex);
        }
    };

    const handleSheetUpload=(e:React.ChangeEvent<HTMLInputElement>)=>{

        if(e.target.files?.[0]){
            uploadAnswerSheet(e.target.files[0]);
        }

    };

    return(

        <Container>

            <Paper>

                <Header>

                    <BackButton onClick={handleBack}>
                        <ArrowLeft size={18}/>
                    </BackButton>

                    <h2>Create Paper</h2>

                </Header>

                <Content>

                    <Button onClick={generateBraillePDF}>
                        <FileDown size={18}/>
                        Generate Braille Quiz PDF
                    </Button>

                    <UploadButton onClick={()=>fileInputRef.current?.click()}>
                        <Upload size={18}/>
                        Upload Answer Sheet
                    </UploadButton>

                    <Button onClick={() => alert("Answers Submitted Successfully!")} style={{ background: "#8e44ad" }}>
                        Submit Answer
                    </Button>

                    <input
                        type="file"
                        hidden
                        ref={fileInputRef}
                        onChange={handleSheetUpload}
                    />

                    <input
                        type="file"
                        hidden
                        ref={individualFileInputRef}
                        onChange={handleIndividualUpload}
                    />

                    {loading && (
                        <LoadingState>
                            <Spinner size={40}/>
                            <p>Loading questions...</p>
                        </LoadingState>
                    )}

                    {error && (
                        <ErrorState>
                            <AlertCircle size={30}/>
                            <p>{error}</p>
                        </ErrorState>
                    )}

                    {!loading && quizzes.length>0 && (

                        <QuestionsList>

                            {quizzes.map((q,index)=>(
                                <QuestionItem key={q._id}>
                                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                        <div>
                                            <QuestionNumber>{index + 1}.</QuestionNumber>
                                            {q.question}
                                        </div>
                                        <button 
                                            onClick={() => {
                                                setCheckingIndex(index);
                                                individualFileInputRef.current?.click();
                                            }}
                                            style={{
                                                padding: '4px 12px',
                                                borderRadius: '4px',
                                                border: '1px solid #3498db',
                                                background: 'white',
                                                color: '#3498db',
                                                cursor: 'pointer',
                                                fontSize: '12px'
                                            }}
                                        >
                                            Check Answer
                                        </button>
                                    </div>
                                </QuestionItem>
                            ))}

                        </QuestionsList>

                    )}

                    {result.length>0 && (

                        <ResultBox>

                            <h3>Validation Result</h3>

                            {result.map((r,i)=>(
                                <div key={i}>
                                    Q{r.question} → predicted {r.predicted} / correct {r.correct}
                                    {r.isCorrect ? " ✔" : " ❌"}
                                </div>
                            ))}

                        </ResultBox>

                    )}

                </Content>

            </Paper>

        </Container>

    );

};

export default TeacherPaperBuilder;