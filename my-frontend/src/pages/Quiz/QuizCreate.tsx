import React, { useState, useCallback } from 'react';
import { v4 as uuidv4 } from 'uuid';

interface QuizQuestion {
    id: string;
    question: string;
    answer: string;   // ✅ NEW FIELD
    grade: string;
    type: string;
    subject: string;
}

const QuizCreate: React.FC = () => {
    const [quizzes, setQuizzes] = useState<QuizQuestion[]>([]);
    const [loading, setLoading] = useState(false);

    const normalizeGrade = (grade: string): '3' | '4' | '5' | '' => {
        const num = grade.replace(/\D/g, '');
        if (num === '3' || num === '4' || num === '5') return num;
        return '';
    };

    const addQuiz = () => {
        setQuizzes(prev => [
            ...prev,
            {
                id: uuidv4(),
                question: '',
                answer: '',      // ✅ initialize
                grade: '',
                type: '',
                subject: ''
            }
        ]);
    };

    const removeQuiz = (id: string) => {
        setQuizzes(prev => prev.filter(q => q.id !== id));
    };

    const updateQuiz = <K extends keyof QuizQuestion>(
        id: string,
        field: K,
        value: QuizQuestion[K]
    ) => {
        setQuizzes(prev =>
            prev.map(q => (q.id === id ? { ...q, [field]: value } : q))
        );
    };

    const handleSubmit = useCallback(async () => {
        if (quizzes.length === 0) {
            alert('Add at least one quiz.');
            return;
        }

        const formatted = quizzes.map(q => ({
            question: q.question.trim(),
            answer: q.answer.trim().toLowerCase(), // ✅ normalize
            grade: normalizeGrade(q.grade),
            type: q.type.trim(),
            subject: q.subject.trim()
        }));

        const invalid = formatted.filter(
            q => !q.question || !q.answer || !q.grade || !q.type || !q.subject
        );

        if (invalid.length > 0) {
            alert('All fields required. Grade must be 3, 4 or 5.');
            return;
        }

        try {
            setLoading(true);

            const response = await fetch(
                'http://localhost:3000/api/quizzes/add',
                {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ quizzes: formatted })
                }
            );

            const data = await response.json();
            if (!response.ok) throw new Error(data.message);

            alert(`Saved ${data.total} quizzes successfully`);
            setQuizzes([]);

        } catch (error) {
            console.error(error);
            alert('Error saving quizzes');
        } finally {
            setLoading(false);
        }
    }, [quizzes]);

    return (
        <div style={styles.page}>
            <div style={styles.container}>
                <h1 style={styles.title}>📚 Quiz Builder</h1>
                <p style={styles.subtitle}>Create short-answer quizzes</p>

                {quizzes.map((quiz, index) => (
                    <div key={quiz.id} style={styles.card}>
                        <div style={styles.cardHeader}>
                            <span style={styles.quizNumber}>Quiz {index + 1}</span>
                        </div>

                        <textarea
                            placeholder="Enter question..."
                            value={quiz.question}
                            onChange={e =>
                                updateQuiz(quiz.id, 'question', e.target.value)
                            }
                            style={styles.textarea}
                        />

                        {/* ✅ NEW ANSWER FIELD */}
                        <input
                            type="text"
                            placeholder="Correct Answer"
                            value={quiz.answer}
                            onChange={e =>
                                updateQuiz(quiz.id, 'answer', e.target.value)
                            }
                            style={styles.input}
                        />

                        <div style={styles.grid}>
                            <input
                                type="text"
                                placeholder="Grade (3,4,5)"
                                value={quiz.grade}
                                onChange={e =>
                                    updateQuiz(quiz.id, 'grade', e.target.value)
                                }
                                style={styles.input}
                            />

                            <input
                                type="text"
                                placeholder="Type (e.g. addition)"
                                value={quiz.type}
                                onChange={e =>
                                    updateQuiz(quiz.id, 'type', e.target.value)
                                }
                                style={styles.input}
                            />

                            <input
                                type="text"
                                placeholder="Subject (e.g. Mathematics)"
                                value={quiz.subject}
                                onChange={e =>
                                    updateQuiz(quiz.id, 'subject', e.target.value)
                                }
                                style={styles.input}
                            />
                        </div>

                        <button
                            onClick={() => removeQuiz(quiz.id)}
                            style={styles.removeBtn}
                        >
                            🗑 Remove
                        </button>
                    </div>
                ))}

                <div style={styles.buttonGroup}>
                    <button onClick={addQuiz} style={styles.addBtn}>
                        ➕ Add Quiz
                    </button>

                    <button
                        onClick={handleSubmit}
                        disabled={loading}
                        style={{
                            ...styles.publishBtn,
                            opacity: loading ? 0.7 : 1
                        }}
                    >
                        {loading ? 'Saving...' : '🚀 Publish'}
                    </button>
                </div>
            </div>
        </div>
    );
};

const styles: Record<string, React.CSSProperties> = {
    page: {
        minHeight: '100vh',
        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
        padding: '3rem 1rem'
    },
    container: {
        maxWidth: '900px',
        margin: 'auto',
        background: 'white',
        padding: '2.5rem',
        borderRadius: '20px',
        boxShadow: '0 20px 40px rgba(0,0,0,0.15)'
    },
    title: {
        fontSize: '2.2rem',
        fontWeight: 700,
        marginBottom: '0.5rem'
    },
    subtitle: {
        color: '#666',
        marginBottom: '2rem'
    },
    card: {
        background: '#f9fafc',
        padding: '1.5rem',
        borderRadius: '15px',
        marginBottom: '1.5rem',
        border: '1px solid #e3e8ef'
    },
    cardHeader: {
        marginBottom: '1rem',
        fontWeight: 600
    },
    quizNumber: {
        background: '#667eea',
        color: 'white',
        padding: '0.3rem 0.8rem',
        borderRadius: '20px',
        fontSize: '0.9rem'
    },
    textarea: {
        width: '100%',
        padding: '0.8rem',
        borderRadius: '10px',
        border: '1px solid #d1d9e6',
        marginBottom: '1rem',
        fontSize: '1rem'
    },
    grid: {
        display: 'grid',
        gridTemplateColumns: '1fr 1fr 1fr',
        gap: '1rem',
        marginBottom: '1rem'
    },
    input: {
        padding: '0.7rem',
        borderRadius: '10px',
        border: '1px solid #d1d9e6',
        fontSize: '0.95rem'
    },
    removeBtn: {
        background: '#ffe6e6',
        border: 'none',
        padding: '0.5rem 1rem',
        borderRadius: '8px',
        cursor: 'pointer',
        color: '#d32f2f',
        fontWeight: 500
    },
    buttonGroup: {
        display: 'flex',
        gap: '1rem',
        marginTop: '2rem'
    },
    addBtn: {
        flex: 1,
        padding: '0.9rem',
        borderRadius: '40px',
        border: '2px solid #667eea',
        background: 'white',
        color: '#667eea',
        fontWeight: 600,
        cursor: 'pointer'
    },
    publishBtn: {
        flex: 1,
        padding: '0.9rem',
        borderRadius: '40px',
        border: 'none',
        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
        color: 'white',
        fontWeight: 600,
        cursor: 'pointer'
    }
};

export default QuizCreate;