import joblib
import os
from typing import Dict, Any
import logging

from fastapi import Request

logger = logging.getLogger(__name__)

# Model paths
HEARING_IMPAIRMENT_MODEL_PATH = os.path.join(
    os.path.dirname(__file__),
    "../models/hearing-impairments-models/number_sign_model_level1.pkl"
)

def initialize_models() -> Dict[str, Any]:
    """
    Initialize and load all ML models
    Returns a dictionary of loaded models
    """
    models = {}
    
    try:
        logger.info("=" * 60)
        logger.info("[MODEL_INIT] Starting model initialization")
        logger.info(f"[MODEL_INIT] Looking for model at: {HEARING_IMPAIRMENT_MODEL_PATH}")
        
        # Load hearing impairment model
        if os.path.exists(HEARING_IMPAIRMENT_MODEL_PATH):
            logger.info(f"[MODEL_INIT] Model file found at: {HEARING_IMPAIRMENT_MODEL_PATH}")
            try:
                logger.debug("[MODEL_INIT] Loading hearing impairment model with joblib...")
                models['hearing_impairment'] = joblib.load(HEARING_IMPAIRMENT_MODEL_PATH)
                logger.info("[MODEL_INIT] Hearing impairment model loaded successfully")
                logger.debug(f"[MODEL_INIT] Model type: {type(models['hearing_impairment'])}")
                logger.debug(f"[MODEL_INIT] Model attributes: {dir(models['hearing_impairment'])}")
            except Exception as e:
                logger.error(f"[MODEL_INIT] Failed to load model with joblib: {str(e)}", exc_info=True)
                raise
        else:
            logger.warning(f"[MODEL_INIT] Hearing impairment model not found at {HEARING_IMPAIRMENT_MODEL_PATH}")
            logger.warning("[MODEL_INIT] Application will continue but predictions will fail")
        
        logger.info(f"[MODEL_INIT] Model initialization complete. Loaded {len(models)} model(s)")
        logger.info(f"[MODEL_INIT] Available models: {list(models.keys())}")
        logger.info("=" * 60)
    
    except Exception as e:
        logger.error(f"[MODEL_INIT] Error loading models: {str(e)}", exc_info=True)
        logger.error("=" * 60)
        raise
    
    return models

def get_model(request: Request , model_name: str):
    """
    Get a specific model by name
    """
    logger.debug(f"[MODEL_LOADER] Attempting to retrieve model: {model_name}")

    models = getattr(request.app.state, 'models', {})
    logger.debug(f"[MODEL_LOADER] Available models in app.state: {list(models.keys())}")
    
    if model_name not in models:
        logger.error(f"[MODEL_LOADER] Model '{model_name}' not found or not loaded. Available models: {list(models.keys())}")
        raise ValueError(f"Model '{model_name}' not found or not loaded")
    
    logger.debug(f"[MODEL_LOADER] Model '{model_name}' retrieved successfully")
    return models[model_name]
