# Python Server Configuration
# This file shows environment variables used by the Python ML server
# Copy this to .env and update values as needed

# Server Port
PYTHON_SERVER_PORT=8000

# Logging Level (DEBUG, INFO, WARNING, ERROR, CRITICAL)
LOG_LEVEL=INFO

# CORS Origins (comma-separated)
CORS_ORIGINS=http://localhost:3000,http://localhost:5000,http://127.0.0.1:3000,http://127.0.0.1:5000

# Backend Server URL
BACKEND_URL=http://localhost:3000




------------

1. create venv 
`python -m venv .venv`


.venv\Scripts\activate