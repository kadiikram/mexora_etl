import logging
import os
from datetime import datetime

def setup_logger():
    """
    Configure logging to write to both console and file logs/etl_YYYYMMDD_HHMMSS.log
    Format: "%(asctime)s — %(levelname)s — %(message)s"
    Create logs/ folder if it doesn't exist
    """
    # Create logs directory if it doesn't exist
    logs_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'logs')
    os.makedirs(logs_dir, exist_ok=True)
    
    # Generate log filename with timestamp
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_filename = f"etl_{timestamp}.log"
    log_filepath = os.path.join(logs_dir, log_filename)
    
    # Create logger
    logger = logging.getLogger('mexora_etl')
    logger.setLevel(logging.INFO)
    
    # Create formatter
    formatter = logging.Formatter("%(asctime)s — %(levelname)s — %(message)s")
    
    # Console handler
    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.INFO)
    console_handler.setFormatter(formatter)
    
    # File handler
    file_handler = logging.FileHandler(log_filepath)
    file_handler.setLevel(logging.INFO)
    file_handler.setFormatter(formatter)
    
    # Add handlers to logger
    logger.addHandler(console_handler)
    logger.addHandler(file_handler)
    
    return logger