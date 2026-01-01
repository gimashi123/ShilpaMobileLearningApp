# Python Server ML API

This API exposes machine learning models for the Shilpa Mobile Learning App.

## Setup

1. **Install dependencies:**
```bash
cd python-server
pip install -r requirements.txt
```

2. **Configure environment:**
```bash
cp .env.example .env
# Edit .env if needed
```

3. **Run the server:**
```bash
python app.py
```

The server will start on `http://localhost:8000` by default.

## API Endpoints

### Health Check

Check if the server and models are healthy:

```bash
GET /health
```

Response:
```json
{
  "status": "healthy",
  "service": "Shilpa Learning ML API"
}
```

### Hearing Impairment Model - Health

```bash
GET /api/hearing-impairment/health
```

Response:
```json
{
  "status": "healthy",
  "model_loaded": true,
  "model_path": "/path/to/model"
}
```

### Sign Number Prediction

Predict a sign number based on input features:

```bash
POST /api/hearing-impairment/predict
Content-Type: application/json

{
  "features": [0.1, 0.2, 0.3, ...],
  "description": "optional description of the input"
}
```

Response:
```json
{
  "prediction": 5,
  "confidence": null,
  "success": true,
  "message": "Prediction completed successfully"
}
```

## Backend Integration

The backend exposes these endpoints to call the Python API:

### Check Model Service Health
```bash
GET /api/models/hearing-impairment/health
```

### Get Prediction
```bash
POST /api/models/hearing-impairment/predict
Content-Type: application/json

{
  "features": [0.1, 0.2, 0.3, ...],
  "description": "optional description"
}
```

## Environment Variables

- `PYTHON_SERVER_PORT` - Port the API runs on (default: 8000)
- `LOG_LEVEL` - Logging level (default: INFO)
- `CORS_ORIGINS` - Comma-separated list of allowed origins

## Model Files

Models are loaded from:
- Hearing Impairments: `models/hearing-impairments-models/number_sign_model_level1.pkl`

## Architecture

```
Frontend (Flutter App)
    ↓
Backend (Node.js/Express)
    ↓
Python ML Server (FastAPI)
    ↓
ML Models (joblib)
```

## Running in Development

Start both servers:

**Terminal 1 - Backend:**
```bash
cd backend
npm run dev
```

**Terminal 2 - Python Server:**
```bash
cd python-server
python app.py
```

**Terminal 3 - Mobile App:**
```bash
cd mobile_app
flutter run
```

## Docker (Optional)

You can containerize the Python server:

```dockerfile
FROM python:3.11-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

CMD ["python", "app.py"]
```

Build and run:
```bash
docker build -t shilpa-ml-api .
docker run -p 8000:8000 shilpa-ml-api
```
