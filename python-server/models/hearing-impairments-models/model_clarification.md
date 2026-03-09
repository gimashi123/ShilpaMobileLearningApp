
## Number Models

number_sign_model_level1.pkl
- number from 1 to 10

number_sign_model_level2.pkl
- number from 11 to 20

number_sign_model_level3.keras
- number from 21 to 40

number_sign_model_level4.keras
- number from 45 to 70

NOTE: PUT THESE MODELS INTO /hearing-impairements-models/numbers

## API Usage

The `/api/hearing-impairment/predict-video` endpoint accepts a `level` form parameter:

| Level | Number Range | Model Format |
|-------|-------------|-------------|
| 1 (default) | 1–10 | sklearn (.pkl) |
| 2 | 11–20 | sklearn (.pkl) |
| 3 | 21–40 | Keras (.keras) |
| 4 | 45–70 | Keras (.keras) |

Example: `POST /api/hearing-impairment/predict-video` with form data `video=<file>` and `level=2`