import joblib
import os
from typing import Dict, Any
import logging

from fastapi import Request

logger = logging.getLogger(__name__)

# Base directory for hearing impairment models
MODELS_DIR = os.path.join(
    os.path.dirname(__file__),
    "../models/hearing-impairments-models/numbers"
)

# Model level configuration
# Each level maps to a model file and its loader type
MODEL_LEVELS = {
    1: {"file": "number_sign_model_level1.pkl", "loader": "joblib"},
    2: {"file": "number_sign_model_level2.pkl", "loader": "joblib"},
    3: {"file": "number_sign_model_level3.keras", "loader": "keras"},
    4: {"file": "number_sign_model_level4.keras", "loader": "keras"},
}

# Valid levels set for quick validation
VALID_LEVELS = set(MODEL_LEVELS.keys())


def _load_single_model(level: int, config: dict):
    """Load a single model based on its configuration."""
    model_path = os.path.join(MODELS_DIR, config["file"])

    if not os.path.exists(model_path):
        logger.warning(f"[MODEL_INIT] Model file not found for level {level}: {model_path}")
        return None

    logger.info(f"[MODEL_INIT] Loading level {level} model from: {model_path}")

    if config["loader"] == "joblib":
        model = joblib.load(model_path)
    elif config["loader"] == "keras":
        from tensorflow import keras
        model = keras.models.load_model(model_path)
    else:
        raise ValueError(f"Unknown loader type: {config['loader']}")

    logger.info(f"[MODEL_INIT] Level {level} model loaded successfully (type: {type(model).__name__})")
    return model


def initialize_models() -> Dict[str, Any]:
    """
    Initialize and load all ML models.
    Returns a dictionary of loaded models keyed by name.
    
    Keys follow the pattern: hearing_impairment_level{N}
    Also sets 'hearing_impairment' as an alias for level 1 (backward compat).
    """
    models = {}

    try:
        logger.info("=" * 60)
        logger.info("[MODEL_INIT] Starting model initialization")
        logger.info(f"[MODEL_INIT] Models directory: {MODELS_DIR}")

        for level, config in MODEL_LEVELS.items():
            key = f"hearing_impairment_level{level}"
            try:
                model = _load_single_model(level, config)
                if model is not None:
                    models[key] = model
            except Exception as e:
                logger.error(
                    f"[MODEL_INIT] Failed to load level {level} model: {str(e)}",
                    exc_info=True,
                )
                # Continue loading other models even if one fails
                continue

        # Backward compatibility: alias level 1 as 'hearing_impairment'
        if "hearing_impairment_level1" in models:
            models["hearing_impairment"] = models["hearing_impairment_level1"]

        logger.info(f"[MODEL_INIT] Model initialization complete. Loaded {len(models)} model(s)")
        logger.info(f"[MODEL_INIT] Available models: {list(models.keys())}")
        logger.info("=" * 60)

    except Exception as e:
        logger.error(f"[MODEL_INIT] Error loading models: {str(e)}", exc_info=True)
        logger.error("=" * 60)
        raise

    return models


def get_model(request: Request, model_name: str):
    """
    Get a specific model by name from app.state.models.
    """
    logger.debug(f"[MODEL_LOADER] Attempting to retrieve model: {model_name}")

    models = getattr(request.app.state, 'models', {})
    logger.debug(f"[MODEL_LOADER] Available models in app.state: {list(models.keys())}")

    if model_name not in models:
        logger.error(
            f"[MODEL_LOADER] Model '{model_name}' not found or not loaded. "
            f"Available models: {list(models.keys())}"
        )
        raise ValueError(f"Model '{model_name}' not found or not loaded")

    logger.debug(f"[MODEL_LOADER] Model '{model_name}' retrieved successfully")
    return models[model_name]
