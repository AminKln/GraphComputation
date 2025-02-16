"""Enhanced logging configuration."""

import json
import logging
import os
import sys
import time
from datetime import datetime
from functools import wraps
from pathlib import Path
from typing import Any, Callable, Dict, Optional

from flask import Request, request

from ..config.settings import BASE_DIR
from .metrics import metrics

# Create logs directory structure
LOGS_DIR = BASE_DIR / "logs"
API_LOGS_DIR = LOGS_DIR / "api"
ERROR_LOGS_DIR = LOGS_DIR / "errors"
QUERY_LOGS_DIR = LOGS_DIR / "queries"

# Debug print
print(f"\nLogging Configuration:")
print(f"BASE_DIR: {BASE_DIR}")
print(f"LOGS_DIR: {LOGS_DIR}")
print(f"API_LOGS_DIR: {API_LOGS_DIR}")
print(f"ERROR_LOGS_DIR: {ERROR_LOGS_DIR}")
print(f"QUERY_LOGS_DIR: {QUERY_LOGS_DIR}\n")

# Ensure all directories exist
for directory in [LOGS_DIR, API_LOGS_DIR, ERROR_LOGS_DIR, QUERY_LOGS_DIR]:
    try:
        directory.mkdir(parents=True, exist_ok=True)
        print(f"Created/verified directory: {directory}")
    except Exception as e:
        print(f"Error creating directory {directory}: {e}")
    
# Configure logging format
LOGGING_FORMAT = "%(asctime)s [%(levelname)s] %(name)s: %(message)s"
ERROR_FORMAT = "%(asctime)s [%(levelname)s] %(name)s: %(message)s\nStack Trace:\n%(exc_info)s"

class APILogger:
    """Enhanced API logger with metrics tracking."""
    
    def __init__(self):
        # API logger
        self.api_logger = self._setup_logger(
            "graph_computation.api",
            API_LOGS_DIR / "api.log",
            LOGGING_FORMAT
        )
        
        # Error logger
        self.error_logger = self._setup_logger(
            "graph_computation.errors",
            ERROR_LOGS_DIR / "errors.log",
            ERROR_FORMAT,
            level=logging.ERROR
        )
        
        # Query logger
        self.query_logger = self._setup_logger(
            "graph_computation.queries",
            QUERY_LOGS_DIR / "queries.log",
            LOGGING_FORMAT
        )
        
        # Verify log files
        print("\nVerifying log files:")
        print(f"API log: {API_LOGS_DIR / 'api.log'}")
        print(f"Error log: {ERROR_LOGS_DIR / 'errors.log'}")
        print(f"Query log: {QUERY_LOGS_DIR / 'queries.log'}\n")
        
        # Test logging
        self.api_logger.info("API Logger initialized")
        self.error_logger.error("Error Logger initialized")
        self.query_logger.info("Query Logger initialized")
    
    def _setup_logger(
        self,
        name: str,
        log_file: Path,
        format_str: str,
        level: int = logging.INFO
    ) -> logging.Logger:
        """Set up a logger with file and console output."""
        logger = logging.getLogger(name)
        logger.setLevel(level)
        
        # Prevent propagation to parent loggers
        logger.propagate = False
        
        # Remove existing handlers
        logger.handlers.clear()
        
        try:
            # File handler (only add if not already present)
            if not any(isinstance(h, logging.FileHandler) and h.baseFilename == str(log_file) for h in logger.handlers):
                file_handler = logging.FileHandler(log_file)
                file_handler.setFormatter(logging.Formatter(format_str))
                logger.addHandler(file_handler)
                print(f"Created log file: {log_file}")
            
            # Console handler (only add if not already present)
            if not any(isinstance(h, logging.StreamHandler) and h.stream == sys.stdout for h in logger.handlers):
                console_handler = logging.StreamHandler(sys.stdout)
                console_handler.setFormatter(logging.Formatter(format_str))
                logger.addHandler(console_handler)
            
        except Exception as e:
            print(f"Error setting up logger {name}: {e}")
            raise
        
        return logger
    
    def log_request(self, req: Request, duration: float) -> None:
        """Log API request with metrics."""
        endpoint = req.endpoint or "unknown"
        message = (
            f"Request: {req.method} {req.path} - "
            f"Duration: {duration:.3f}s - "
            f"IP: {req.remote_addr}"
        )
        self.api_logger.info(message)
        metrics.track_endpoint(endpoint, duration)
    
    def log_error(self, error: Exception, endpoint: str) -> None:
        """Log error with metrics."""
        message = f"Error in {endpoint}: {str(error)}"
        self.error_logger.error(message, exc_info=True)
        metrics.track_error(type(error).__name__, endpoint)
    
    def log_query(self, query_data: Dict[str, Any], duration: float) -> None:
        """Log graph query with metrics."""
        message = (
            f"Query: {json.dumps(query_data)} - "
            f"Duration: {duration:.3f}s"
        )
        self.query_logger.info(message)

# Global logger instance
logger = APILogger()

def log_execution_time(f: Callable) -> Callable:
    """Decorator to log execution time of endpoints."""
    @wraps(f)
    def wrapper(*args, **kwargs):
        start_time = time.time()
        try:
            result = f(*args, **kwargs)
            duration = time.time() - start_time
            logger.log_request(request, duration)
            return result
        except Exception as e:
            duration = time.time() - start_time
            logger.log_error(e, request.endpoint or "unknown")
            raise
    return wrapper

def setup_logging(level: int = logging.INFO) -> None:
    """Set up basic logging configuration."""
    # Configure root logger
    root_logger = logging.getLogger()
    root_logger.setLevel(level)
    
    # Remove existing handlers
    root_logger.handlers.clear()
    
    # Add handlers only if they don't exist
    if not any(isinstance(h, logging.StreamHandler) for h in root_logger.handlers):
        root_logger.addHandler(logging.StreamHandler(sys.stdout))
    
    if not any(isinstance(h, logging.FileHandler) for h in root_logger.handlers):
        root_logger.addHandler(logging.FileHandler(LOGS_DIR / "app.log"))
    
    # Set format for all handlers
    formatter = logging.Formatter(LOGGING_FORMAT)
    for handler in root_logger.handlers:
        handler.setFormatter(formatter)
    
    # Set level for third-party loggers
    logging.getLogger("werkzeug").setLevel(logging.WARNING)
    logging.getLogger("sqlalchemy").setLevel(logging.WARNING)
    
    print(f"Logging initialized. Log files can be found in: {LOGS_DIR}") 