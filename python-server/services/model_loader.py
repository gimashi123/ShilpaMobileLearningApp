import os
from typing import Dict, Any
import logging

from fastapi import Request

logger = logging.getLogger(__name__)

# Sign language model path — H5 format for cross-version Keras compatibility
SIGN_MODEL_PATH = os.path.join(
    os.path.dirname(__file__),
    "../models/hearing-impairments-models/sign_lang_model.h5"
)

# Base directory for visual impairment models
VISUAL_MODELS_DIR = os.path.join(
    os.path.dirname(__file__),
    "../models/visual-impairements-models"
)

# Visual impairment model configuration
VISUAL_MODEL_CONFIG = {
    "braille_numbers": {
        "file": "braille_number_model.keras",
        "loader": "keras",
        "key": "visual_impairment_braille_numbers",
    }
}


def _load_sign_model(model_path: str):
    """Load the sign language Keras model for server-side inference."""
    abs_path = os.path.abspath(model_path)
    if not os.path.exists(abs_path):
        raise FileNotFoundError(
            f"[MODEL_INIT] Sign language model not found: {abs_path}\n"
            "Export it from the training notebook with: model_aug.save('sign_lang_model.h5')"
        )

    logger.info(f"[MODEL_INIT] Loading sign language Keras model from: {abs_path}")

    from tensorflow import keras
    model = keras.models.load_model(abs_path)

    logger.info(f"[MODEL_INIT] Sign language model loaded successfully")
    logger.info(f"[MODEL_INIT] Input shape:  {model.input_shape}")
    logger.info(f"[MODEL_INIT] Output shape: {model.output_shape}")

    return model


def initialize_models() -> Dict[str, Any]:
    """
    Initialize and load all ML models.
    Returns a dictionary of loaded models keyed by name.
    """
    models = {}

    try:
        logger.info("=" * 60)
        logger.info("[MODEL_INIT] Starting model initialization")

        # Load the unified sign language Keras model
        try:
            model = _load_sign_model(SIGN_MODEL_PATH)
            models["hearing_impairment_tflite"] = model
            logger.info("[MODEL_INIT] Sign language model registered as 'hearing_impairment_tflite'")
        except Exception as e:
            logger.error(f"[MODEL_INIT] Failed to load TFLite model: {str(e)}", exc_info=True)
            raise

        # Load visual impairment models
        logger.info("[MODEL_INIT] Loading visual impairment models...")
        for name, config in VISUAL_MODEL_CONFIG.items():
            model_path = os.path.join(VISUAL_MODELS_DIR, config["file"])
            key = config["key"]
            try:
                if not os.path.exists(model_path):
                    logger.warning(f"[MODEL_INIT] Visual model file not found: {model_path}")
                    continue
                logger.info(f"[MODEL_INIT] Loading visual model '{name}' from: {model_path}")
                from tensorflow import keras
                model = keras.models.load_model(model_path)
                models[key] = model
                logger.info(f"[MODEL_INIT] Visual model '{name}' loaded successfully under key '{key}'")
            except Exception as e:
                logger.error(
                    f"[MODEL_INIT] Failed to load visual model '{name}': {str(e)}",
                    exc_info=True,
                )
                continue

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
