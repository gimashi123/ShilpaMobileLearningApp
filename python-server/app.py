from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import uvicorn
import os
import logging
import logging.handlers
from dotenv import load_dotenv
import sys

# Load environment variables
load_dotenv()

sys.stdout.reconfigure(encoding="utf-8")

# Configure logging
def setup_logging():
    """Configure logging for the application"""
    log_dir = "logs"
    os.makedirs(log_dir, exist_ok=True)
    
    # Create logger
    logger = logging.getLogger()
    logger.setLevel(logging.DEBUG)
    
    # Console handler
    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.INFO)
    console_format = logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    console_handler.setFormatter(console_format)
    
    # File handler (rotating)
    file_handler = logging.handlers.RotatingFileHandler(
        os.path.join(log_dir, 'python_server.log'),
        maxBytes=10*1024*1024,  # 10MB
        backupCount=5
    )
    file_handler.setLevel(logging.DEBUG)
    file_format = logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - [%(filename)s:%(lineno)d] - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    file_handler.setFormatter(file_format)
    
    # Add handlers
    logger.addHandler(console_handler)
    logger.addHandler(file_handler)
    
    return logger

logger = setup_logging()

# Import routes
from routes.hearing_impairment_routes import router as hearing_impairment_router
from services.model_loader import initialize_models

# Store models in app state
lifespan_models = {}

@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("=" * 60)
    logger.info("Starting application startup sequence")
    logger.info("=" * 60)
    logger.info("Loading ML models...")
    try:
        logger.debug("Calling initialize_models()...")
        app.state.models = initialize_models()   # ✅ store in app state
        logger.info(f"Models loaded successfully. Loaded models: {list(app.state.models.keys())}")
        logger.info("=" * 60)
    except Exception as e:
        logger.error(f"Failed to load models: {str(e)}", exc_info=True)
        logger.error("=" * 60)
        raise
    yield
    logger.info("=" * 60)
    logger.info("Starting application shutdown sequence")
    logger.info("Shutting down...")
    logger.info("=" * 60)

app = FastAPI(
    title="Shilpa Learning API",
    description="API for ML model predictions",
    version="1.0.0",
    lifespan=lifespan
)

# Custom exception handler for all unhandled exceptions
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

@app.exception_handler(Exception)
async def general_exception_handler(request, exc):
    logger.error(f"[EXCEPTION_HANDLER] Unhandled exception: {str(exc)}", exc_info=True)
    logger.error(f"[EXCEPTION_HANDLER] Request URL: {request.url}")
    logger.error(f"[EXCEPTION_HANDLER] Request method: {request.method}")
    return JSONResponse(
        status_code=500,
        content={
            "detail": f"Internal server error: {str(exc)}",
            "error_type": type(exc).__name__
        }
    )

@app.exception_handler(StarletteHTTPException)
async def http_exception_handler(request, exc):
    logger.error(f"[HTTP_EXCEPTION] HTTP {exc.status_code}: {exc.detail}")
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.detail}
    )

# CORS Configuration
origins = [
    "http://localhost:3000",
    "http://localhost:5000",
    "http://127.0.0.1:3000",
    "http://127.0.0.1:5000",
    "http://127.0.0.1:5173",
    # os.getenv("CORS_ORIGINS", "http://localhost:3000"),
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Add logging middleware to capture request/response details
from starlette.middleware.base import BaseHTTPMiddleware
from time import time

class LoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        start_time = time()
        logger.debug(f"[REQUEST] {request.method} {request.url.path}")
        logger.debug(f"[REQUEST] Query params: {dict(request.query_params)}")
        
        try:
            response = await call_next(request)
            process_time = time() - start_time
            logger.debug(f"[RESPONSE] Status: {response.status_code} | Time: {process_time:.3f}s")
            return response
        except Exception as e:
            process_time = time() - start_time
            logger.error(f"[MIDDLEWARE_ERROR] Exception during request: {str(e)} | Time: {process_time:.3f}s", exc_info=True)
            raise

app.add_middleware(LoggingMiddleware)

# Include routers
app.include_router(hearing_impairment_router, prefix="/api/hearing-impairment", tags=["hearing-impairment"])
logger.info("Hearing impairment router registered")

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    logger.debug("Health check endpoint called")
    return {
        "status": "healthy",
        "service": "Shilpa Learning ML API"
    }

@app.get("/")
async def root():
    """Root endpoint"""
    logger.debug("Root endpoint called")
    return {
        "message": "Welcome to Shilpa Learning ML API",
        "docs": "/docs",
        "health": "/health"
    }

if __name__ == "__main__":
    port = int(os.getenv("PYTHON_SERVER_PORT", 8000))
    logger.info(f"Starting Shilpa Learning ML API server on port {port}")
    uvicorn.run(app, host="0.0.0.0", port=port)
