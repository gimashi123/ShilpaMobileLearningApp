import React from 'react';
import QuizForm from './QuizForm';

interface QuizFormProps {
    onSubmit?: (quizzes: never) => void
}

const App: React.FC = ({onSubmit}: QuizFormProps) => {
    const handleSubmit = (quizzes: never) => {
        // Custom submit handler
        console.log('Final quizzes:', quizzes);
        // You can send to API here
    };

    return (
        <div style={{
            minHeight: '100vh',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            background: 'linear-gradient(145deg, #f6f9fc 0%, #e6f0f5 100%)',
            padding: '1.5rem'
        }}>
            <QuizForm onSubmit={handleSubmit}/>
        </div>
    );
};

export default App;