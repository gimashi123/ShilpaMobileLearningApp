# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Shilpa is an inclusive mobile learning app for Sri Lankan Grade 3–5 students with visual, hearing, physical, or cognitive impairments. The codebase is a polyrepo-in-monorepo: each top-level folder is an independent service with its own dependencies and lifecycle.

## Architecture

The system is a **4-tier pipeline** with several auxiliary services:

```
mobile_app (Flutter)
    ↓ HTTP
backend (Node.js/Express/TS, port 3000)
    ↓ axios proxy
python-server (FastAPI, port 8000)  ←  loads scikit-learn / keras / mediapipe models
```

Auxiliary services (each is a standalone Python app, not part of `python-server`):
- `backend/chat_backend/` — FastAPI wrapper around Google Gemini for the in-app chatbot.
- `backend/python_stt/` — FastAPI Whisper-based Sinhala/English speech-to-text used by quizzes.

Web frontends (admin/teacher/parent tooling — separate from the mobile app):
- `my-frontend/` — Vite + React 19 + Tailwind, dashboards and quiz/paper authoring.
- `model-test-fe/` — Vite + React 19 scratch UI for testing ML models.

Key cross-cutting points:
- **The Node backend is a thin gateway** for ML calls: `POST /api/models/hearing-impairment/predict-video` accepts a video upload, forwards it to `${PYTHON_SERVER_URL}/api/hearing-impairment/predict-video` via `form-data`, then deletes the temp file (see `backend/src/routes/model.routes.ts`).
- **Python models load once at FastAPI startup** into `app.state.models` (see `python-server/services/model_loader.py`); routes retrieve them via `get_model(request, name)`. Level keys: `hearing_impairment_level{1..4}` plus alias `hearing_impairment` (= level 1) and `visual_impairment_braille_numbers`. Loader chooses joblib vs `tensorflow.keras` based on file extension config.
- **Mobile app reads endpoints from `.env`** loaded as a Flutter asset via `flutter_dotenv`. `lib/config/AppConfig.dart` exposes `apiBaseUrl` and `apiChatBaseUrl`. `.env` is listed in `pubspec.yaml` `assets:` — adding new env vars requires no rebuild config, but the file must exist or `dotenv.load()` throws.

## Backend (Node.js/TypeScript)

Working directory: `backend/`.

```bash
npm install
npm run dev      # nodemon → ts-node -r tsconfig-paths/register src/server.ts
npm run build    # tsc to dist/
npm start        # node dist/server.js
```

There is no test script and no linter configured.

Conventions and gotchas:
- **Path aliases** are defined in `tsconfig.json` (`@/`, `@controllers/`, `@models/`, `@routes/`, `@config/`, `@middlewares/`, `@utils/`, `@types/`). Both `tsconfig-paths` (dev) and `module-alias` (prod, with `_moduleAliases` in `package.json`) resolve them. **Mixing alias and relative imports in the same file is common in this repo** — match the surrounding style.
- **Two entry points exist.** `src/server.ts` is the active one (referenced by `nodemon.json` and `npm start`'s compiled path). `src/Index.ts` is older/dead code — do not edit it expecting the running server to change.
- `src/server.ts` mounts routes in two passes: some are mounted before `app.listen(...)` (auth, models) and others (lessons, braille, stt, user, cognitive, quizzes, answer validation, plus a top-level `/api/sign/predict_video`) are mounted **after** `app.listen`. This works in Express but reordering matters if you debug startup behavior.
- **MongoDB connect has a dev fallback**: if `MONGODB_URI` fails, `connectDB` (in `src/config/db.conf.ts`) starts an in-memory MongoDB via `mongodb-memory-server` when `NODE_ENV !== 'production'`. Production fails fast.
- **`JWT_SECRET` auto-generates in development** if missing (logged as a warning); production exits with code 1. Tokens issued by a dev-generated secret won't validate after restart.
- `.env` is loaded from `process.cwd()/.env` first, then `src/.env` as a fallback.

## Python ML Server

Working directory: `python-server/`. Requires Python 3.11 and a venv.

```bash
python -m venv .venv
.venv\Scripts\activate          # Windows; use source .venv/bin/activate on Unix
pip install -r requirements.txt
python app.py                    # uvicorn on PYTHON_SERVER_PORT (default 8000)
```

- Models live under `python-server/models/{hearing-impairments-models,visual-impairements-models,cognative-impairments-models,mediapipe}`. They are gitignored (`*.pkl`, `*.keras`, `*.h5`) — **must be obtained out-of-band**.
- The lifespan hook calls `initialize_models()` and stores the dict on `app.state.models`. If a model file is missing, that level is skipped (warning logged) but server continues.
- CORS is currently `allow_origins=["*"]` regardless of the `origins` list defined above it.
- Routers are mounted under `/api/hearing-impairment` and `/api/visual-impairment` (the visual router is `include_router`'d twice — both calls use the same prefix, harmless but worth knowing).

## Auxiliary Python Services

Each has its own `requirements.txt` and is run independently:

```bash
# Gemini chat (used by mobile chatbot)
cd backend/chat_backend && pip install -r requirements.txt && uvicorn main:app --reload

# Whisper Sinhala/English STT (used for voice-based quiz answers)
cd backend/python_stt && pip install -r requirements.txt && uvicorn app:app --reload
```

`chat_backend/main.py` reads `.env` from its own folder first, then falls back to `backend/.env`. The STT app loads `WHISPER_MODEL` (default `openai/whisper-medium`) once at startup — first request after launch is slow.

## Mobile App (Flutter)

Working directory: `mobile_app/`. Requires Flutter SDK ≥ 3.9.2.

```bash
flutter pub get
flutter run                                # uses .env from assets
flutter pub run flutter_launcher_icons:main # regenerate launcher icons
```

- **Copy `env.example` → `.env`** before running; without `.env` the app crashes in `main()` at `dotenv.load()`. Keys vary across the example file vs `AppConfig.dart` (`API_BASE_URL`/`API_CHAT_BASE_URL` vs `APP_BASE_URL`/`APP_PYTHON_BACKEND_URL`/`CHAT_BASE_URL`) — confirm which keys the code currently reads when wiring a new device.
- **Cameras are initialized in `main()` before `runApp`** and exposed as a top-level `late final List<CameraDescription> cameras`. Pages that need cameras (e.g. `MathGameDeaf`) receive this list as a constructor arg from the route table in `main.dart`.
- Routes are declared statically in `MyApp.routes`; dynamic ones (currently just `/quizscreen`) go through `onGenerateRoute`.
- Cognitive games run a TFLite model on-device (`assets/models/lq_model.tflite`) — they do not call the backend for inference.
- `lib/component/` (singular) and `lib/components/` (plural) both exist with different files; check both when searching for shared widgets.

## Web Frontends

Both `my-frontend/` and `model-test-fe/` use the same toolchain:

```bash
npm install
npm run dev      # vite dev server
npm run build    # tsc -b && vite build
npm run lint     # eslint . (only in my-frontend/model-test-fe; no lint in backend or mobile_app)
```

`my-frontend/` is the production admin/teacher/parent UI. `model-test-fe/` is a sandbox for hitting the ML server directly.

## Disability Module Map

Each disability area has parallel implementations split across all tiers. When changing a feature, expect to touch all of these:

| Area      | Mobile (Flutter)                         | Backend (Node)                              | ML (Python)                                |
|-----------|------------------------------------------|---------------------------------------------|--------------------------------------------|
| Visual    | `lib/pages/dashboard/visual_*`, `lib/pages/visual_*`, `lib/services/braille_pdf_service.dart` | `routes/braill.ts`, `controllers/braillePDF.controller.ts` | `routes/visual_impairment_routes.py`       |
| Hearing   | `lib/pages/dashboard/hearing_*`, `lib/lesson_dashboard/hearing_lesson.dart`, `lib/services/sign_number_api.dart` | `routes/model.routes.ts` (video proxy)     | `routes/hearing_impairment_routes.py`      |
| Physical  | `lib/pages/physical/`, `lib/services/eye_tracking_service.dart`, `lib/services/voice_*`, `lib/components/gaze_cursor.dart` | (mostly client-only)                        | (mediapipe assets only)                    |
| Cognitive | `lib/pages/games_cognitive/`, `lib/services/cognitive.dart` (TFLite on-device) | `routes/cognitive/routes.ts`, `controllers/cognitive/`, `models/cognitive/` | `models/cognative-impairments-models/`     |

## Notes from README

- The repo's README references an `ml/` folder for ML resources that does not exist; ML lives in `python-server/models/` and (for cognitive) in `mobile_app/assets/models/`.
- The README's claim that backend uses `helmet` is only true for the dead `Index.ts` entry point — the active `server.ts` does not use helmet or any rate limiting.
