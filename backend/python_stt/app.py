import os
import uuid
import re
from fastapi import FastAPI, UploadFile, File, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from transformers import pipeline

app = FastAPI()

# ✅ CORS (so Node/Flutter can call)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ✅ Choose model (Sinhala accuracy: medium > small > base)
# If your PC is slow, change to "openai/whisper-small"
MODEL_NAME = os.getenv("WHISPER_MODEL", "openai/whisper-medium")

# ✅ Load once at startup
stt = pipeline("automatic-speech-recognition", model=MODEL_NAME)

UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

# Sinhala/English answer mapping (voice -> A/B/C/D/1/2/3/4)
MAP = [
    (r"\b(a|ඒ|ඒයි)\b", "A"),
    (r"\b(b|බී|බීයි|බි)\b", "B"),
    (r"\b(c|සී|සි)\b", "C"),
    (r"\b(d|ඩී|ඩි)\b", "D"),
    (r"\b(1|එක)\b", "1"),
    (r"\b(2|දෙක)\b", "2"),
    (r"\b(3|තුන)\b", "3"),
    (r"\b(4|හතර)\b", "4"),
]

def normalize_text(t: str) -> str:
    t = (t or "").strip().lower()
    # remove common punctuation
    t = re.sub(r"[^\w\u0D80-\u0DFF\s]", " ", t)  # keep Sinhala block + words
    t = re.sub(r"\s+", " ", t).strip()
    return t

def extract_answer(transcript: str):
    n = normalize_text(transcript)
    for pattern, value in MAP:
        if re.search(pattern, n):
            return value
    return None

@app.get("/health")
def health():
    return {"status": "ok", "model": MODEL_NAME}
@app.post("/stt")
async def speech_to_text(file: UploadFile = File(...), lang: str = Query("si")):
    print("✅ /stt called")
    print("✅ filename:", file.filename, "content_type:", file.content_type)

    ext = os.path.splitext(file.filename or "")[1].lower() or ".wav"
    save_path = os.path.join(UPLOAD_DIR, f"{uuid.uuid4().hex}{ext}")

    print("✅ reading file bytes...")
    data = await file.read()
    print("✅ bytes:", len(data))

    if not data:
        raise HTTPException(status_code=400, detail="Empty audio file")

    with open(save_path, "wb") as f:
        f.write(data)

    print("✅ saved to:", save_path)
    print("⏳ starting whisper...")

    gen = {"task": "transcribe"}
    if lang.lower() in ("si", "en"):
        gen["language"] = lang.lower()

    result = stt(save_path, generate_kwargs=gen)

    print("✅ whisper finished")
    text = (result.get("text") or "").strip()
    answer = extract_answer(text)

    try:
        os.remove(save_path)
    except Exception:
        pass

    return {"text": text, "answer": answer, "lang": gen.get("language", "auto")}
