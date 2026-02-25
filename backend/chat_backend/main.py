from __future__ import annotations

import logging
import os
from pathlib import Path
from typing import Literal

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from google import genai
from pydantic import BaseModel, ConfigDict, Field

CHAT_BACKEND_DIR = Path(__file__).resolve().parent
load_dotenv(CHAT_BACKEND_DIR / ".env")
# Allow sharing a single backend/.env after folder moves.
load_dotenv(CHAT_BACKEND_DIR.parent / ".env", override=False)

logger = logging.getLogger("chat_backend")
logging.basicConfig(level=logging.INFO)


class ChatRequest(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)

    message: str = Field(..., min_length=1, max_length=4000)
    language: Literal["si", "en"] = "en"


class ChatResponse(BaseModel):
    reply: str
    response: str


def _build_prompt(message: str, language: Literal["si", "en"]) -> str:
    base_instruction = (
        "Keep answers short, age-appropriate, and supportive. "
        "Avoid harmful or unsafe content."
    )
    if language == "si":
        return (
            "Respond in Sinhala only. "
            f"{base_instruction}\n\nUser: {message.strip()}"
        )
    return f"Respond in English only. {base_instruction}\n\nUser: {message.strip()}"


app = FastAPI(title="Flutter Chatbot Backend", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def _get_client_and_model() -> tuple[genai.Client, str]:
    api_key = os.getenv("GEMINI_API_KEY", "").strip()
    model_name = os.getenv("GEMINI_MODEL", "gemini-2.0-flash").strip()

    if not api_key:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=(
                "GEMINI_API_KEY is not set. Add it to "
                "backend/chat_backend/.env (or backend/.env)."
            ),
        )
    return genai.Client(api_key=api_key), model_name


@app.get("/health", tags=["health"])
def health() -> dict[str, str]:
    return {"status": "ok", "service": "chat-backend"}


@app.post("/chat", response_model=ChatResponse, tags=["chat"])
def chat(payload: ChatRequest) -> ChatResponse:
    client, model_name = _get_client_and_model()
    prompt = _build_prompt(payload.message, payload.language)

    try:
        llm_response = client.models.generate_content(
            model=model_name,
            contents=prompt,
        )
    except Exception as exc:
        logger.exception("Gemini request failed: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="AI service returned an error.",
        ) from exc

    text = (getattr(llm_response, "text", "") or "").strip()
    if not text:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="AI service returned an empty response.",
        )

    # Keep both keys for compatibility with old/new mobile code.
    return ChatResponse(reply=text, response=text)
