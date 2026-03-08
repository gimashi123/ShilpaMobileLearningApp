import { useEffect, useState } from "react";

const BrailleResults = () => {

    const [results, setResults] = useState([]);

    useEffect(() => {

        const load = async () => {

            const res = await fetch(
                "http://localhost:3000/api/braille/results/USER_ID"
            );

            const data = await res.json();

            setResults(data);

        };

        load();

    }, []);

    return (

        <div style={{ padding: 40 }}>

            <h2>Past Braille Papers</h2>

            {results.map((r: any) => (

                <div key={r._id}
                     style={{
                         border: "1px solid #ccc",
                         padding: 20,
                         marginBottom: 10
                     }}
                >

                    <p>Quiz ID: {r.quizId}</p>

                    <p>
                        Correct: {r.correctCount} | Wrong: {r.wrongCount}
                    </p>

                    <img
                        src={`http://localhost:3000${r.answerImageUrl}`}
                        width="200"
                    />

                </div>

            ))}

        </div>

    );

};

export default BrailleResults;