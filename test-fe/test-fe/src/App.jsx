import { useState } from "react";

function App() {
  const [video, setVideo] = useState(null);
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState(null);
  const [error, setError] = useState(null);

  const submitVideo = async () => {
    if (!video) {
      alert("Please select a video");
      return;
    }

    const formData = new FormData();
    formData.append("video", video);

    setLoading(true);
    setError(null);
    setResult(null);

    try {
      const res = await fetch(
        "http://localhost:8000/api/hearing-impairment/predict-video",
        {
          method: "POST",
          body: formData,
        }
      );

      if (!res.ok) {
        const txt = await res.text();
        throw new Error(txt);
      }

      const data = await res.json();
      setResult(data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ padding: 24, fontFamily: "sans-serif" }}>
      <h2>Sign Number Prediction – Video Test</h2>

      <input
        type="file"
        accept="video/*"
        onChange={(e) => setVideo(e.target.files[0])}
      />

      <br /><br />

      <button onClick={submitVideo} disabled={loading}>
        {loading ? "Predicting..." : "Upload & Predict"}
      </button>

      <br /><br />

      {result && (
        <div style={{ padding: 12, border: "1px solid #ccc" }}>
          <h3>Result</h3>
          <p><b>Prediction:</b> {result.prediction}</p>
          <p><b>Confidence:</b> {result.confidence ?? "N/A"}</p>
          <p><b>Status:</b> {result.success ? "Success" : "Fail"}</p>
          <p>{result.message}</p>
        </div>
      )}

      {error && (
        <div style={{ color: "red", marginTop: 12 }}>
          <b>Error:</b> {error}
        </div>
      )}
    </div>
  );
}

export default App;
