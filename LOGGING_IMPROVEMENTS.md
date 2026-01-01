# Logging Improvements for 500 Error Debugging

## Summary
Added comprehensive logging throughout the Python server to help identify exactly where the 500 error is occurring in the `/api/hearing-impairment/predict-video` endpoint.

## Changes Made

### 1. **hearing_impairment_routes.py**
Enhanced logging at every step of video processing:

#### `_extract_video_vectors_42()` function:
- **Import logging**: Logs when dependencies are imported
- **Model file validation**: Logs the path being searched and whether the file exists
- **Landmarker creation**: Logs when HandLandmarker is being created
- **Video capture**: Logs video file opening, FPS, frame count
- **Frame processing**: For each frame:
  - Logs frame number and processing
  - Logs RGB conversion success/failure
  - Logs MediaPipe Image creation
  - Logs landmarker detection execution
  - Logs hand detection results
  - Logs feature normalization with min/max values
- **Extraction summary**: Logs final statistics (total frames, frames with hands, extracted vectors)

#### `predict_from_video()` endpoint:
- **Request logging**: Logs filename and description
- **File validation**: Logs temp file creation path
- **Content logging**: Logs bytes read and written
- **Vector extraction**: Logs start of extraction and results with count
- **Model retrieval**: Logs model retrieval attempts
- **Prediction**: Logs raw predictions and final prediction
- **Confidence**: Logs confidence calculation attempts
- **Cleanup**: Logs temp file deletion

#### `predict()` endpoint:
- **Request logging**: Logs description and features count
- **Validation**: Logs feature count validation
- **Normalization**: Logs normalized feature min/max values
- **Model retrieval**: Logs model retrieval attempts
- **Prediction**: Logs prediction execution
- **Confidence**: Logs confidence calculation

### 2. **app.py**
Added global error handling and request logging:

#### Startup sequence:
- Enhanced logging with visual separators (=== lines)
- Logs models being loaded
- Logs available models after initialization

#### Exception handlers:
- **General exception handler**: Catches ALL unhandled exceptions and logs:
  - Full error message with stack trace
  - Request URL and method
  - Error type
  
- **HTTP exception handler**: Logs all HTTP errors with status code

#### Logging middleware:
- **Request logging**: Logs method and path for every request
- **Query params**: Logs all query parameters
- **Response logging**: Logs status code and execution time
- **Error handling**: Catches and logs middleware-level errors

### 3. **model_loader.py**
Enhanced model loading logging:

- **Initialization start**: Visual separator and start message
- **File existence check**: Logs path being searched
- **File found**: Logs successful file location
- **Model loading**: Logs joblib load attempt
- **Model info**: Logs model type and available attributes
- **Error handling**: Logs any loading failures with stack trace
- **Summary**: Logs final model count and list

## Log Prefix Convention
All new logs use prefixes for easy filtering:
- `[PREDICT_VIDEO]` - Video prediction endpoint
- `[EXTRACT_VIDEO]` - Video vector extraction
- `[PREDICT]` - Single prediction endpoint
- `[MODEL_INIT]` - Model initialization
- `[MODEL_LOADER]` - Model retrieval
- `[REQUEST]` - Request logging
- `[RESPONSE]` - Response logging
- `[EXCEPTION_HANDLER]` - Unhandled exceptions
- `[HTTP_EXCEPTION]` - HTTP errors
- `[MIDDLEWARE_ERROR]` - Middleware errors

## How to Debug the 500 Error

1. **Check the full logs** in `logs/python_server.log`
2. **Search for these patterns** to narrow down the issue:
   - `[PREDICT_VIDEO]` - Find all video prediction logs
   - `ERROR` or `Exception` - Find all errors
   - `500` - Find 500 errors
   - `✗` - Find failures (indicated by ✗ emoji)
   - `EXTRACT_VIDEO` - If issue is in video extraction
   - `MODEL_INIT` - If issue is in model loading

3. **Follow the request flow**:
   ```
   [REQUEST] POST /api/hearing-impairment/predict-video
   → [PREDICT_VIDEO] Starting video prediction request
   → [EXTRACT_VIDEO] Starting video extraction
   → [EXTRACT_VIDEO] Video info logs
   → [EXTRACT_VIDEO] Frame processing logs
   → [MODEL_INIT] or [MODEL_LOADER] for model retrieval
   → [PREDICT_VIDEO] Prediction execution
   → [RESPONSE] Final response
   ```

## Common Issues to Look For

1. **Model file missing**: Look for "[MODEL_INIT] Model file not found"
2. **MediaPipe missing**: Look for "[EXTRACT_VIDEO] ImportError - Missing dependencies"
3. **Video can't be opened**: Look for "[EXTRACT_VIDEO] Could not open video file"
4. **No hands detected**: Look for "[EXTRACT_VIDEO] No hand landmarks detected"
5. **Model loading error**: Look for "[MODEL_INIT] Failed to load model"
6. **Prediction error**: Look for "[PREDICT_VIDEO] Prediction failed"

## Log Levels Used

- `DEBUG`: Detailed information for debugging (off by default in console, in file)
- `INFO`: General information and status updates
- `WARNING`: Warning messages for potential issues
- `ERROR`: Error messages with full stack traces

## Running the Server

After these changes, start the server:
```bash
python app.py
```

Then make a request to the video endpoint and check the logs for detailed error information.
