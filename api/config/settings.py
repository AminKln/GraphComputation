"""Application configuration and settings."""

import os
from pathlib import Path

# Base directory of the project
BASE_DIR = Path(__file__).resolve().parent.parent.parent

# API Settings
API_VERSION = "v1"
API_PREFIX = f"/api/{API_VERSION}"
DEFAULT_PORT = 5000

# Database Settings
DEFAULT_BATCH_SIZE = 1000
CONNECTION_POOL_SIZE = 5
CONNECTION_MAX_OVERFLOW = 10

# File Storage Settings
TEMP_DIR = BASE_DIR / "temp"
UPLOAD_DIR = BASE_DIR / "uploads"

# Create necessary directories
TEMP_DIR.mkdir(exist_ok=True)
UPLOAD_DIR.mkdir(exist_ok=True)

# Graph Processing Settings
DEFAULT_GRAPH_FORMAT = "d3"
SUPPORTED_FORMATS = ["d3", "json", "csv", "networkx"]

# Development Settings
DEBUG = os.getenv("FLASK_DEBUG", "0") == "1"
TESTING = os.getenv("FLASK_TESTING", "0") == "1" 