"""Graph Computation API Package."""

__version__ = "0.1.0"

from flask import Flask
from flask_cors import CORS


def create_app(config=None):
    """Create and configure the Flask application.
    
    Args:
        config: Configuration object or dictionary
        
    Returns:
        Configured Flask application
    """
    app = Flask(__name__)
    CORS(app)
    
    # Load configuration
    if config:
        app.config.update(config)
    
    # Register blueprints
    from .routes import graph, health
    app.register_blueprint(graph.bp)
    app.register_blueprint(health.bp)
    
    return app
