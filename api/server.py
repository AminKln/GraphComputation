from flask import Flask, jsonify, request
from flask_cors import CORS
from waitress import serve

from api import create_app
from api.data.models import FileSource, GraphRequest, SQLSource
from api.services.graph_service import process_graph_data
from api.utils.logging import logger, setup_logging
from api.utils.metrics import metrics

# Initialize logging
setup_logging()

# Create Flask app using factory function
app = create_app()

# Log application startup
logger.api_logger.info("API Server starting up...")

@app.route('/process_graph', methods=['POST'])
def process_graph():
    """Handle graph processing requests."""
    try:
        # Get request data
        data = request.get_json()
        
        # Log incoming request
        logger.log_request(request, 0)  # Initial duration
        
        # Determine source type and create appropriate model
        if 'dsn' in data.get('source', {}):
            data['source'] = SQLSource(**data['source'])
        else:
            data['source'] = FileSource(**data['source'])
        
        # Validate full request
        request_data = GraphRequest(**data)
        
        # Process request
        result = process_graph_data(request_data)
        
        # Log successful processing
        logger.log_query(
            {
                "node_id": request_data.node_id,
                "source_type": "sql" if hasattr(request_data.source, "dsn") else "file",
                "result_size": len(result.get("nodes", []))
            },
            0  # Duration will be added by decorator
        )
        
        return jsonify(result)
        
    except Exception as e:
        # Error logging is handled by decorator
        return jsonify({'error': str(e)}), 400

def shutdown_server():
    """Cleanup resources before shutdown."""
    logger.api_logger.info("Server shutting down...")
    metrics.save_metrics()

if __name__ == '__main__':
    try:
        # Use waitress for Windows production server
        logger.api_logger.info("Starting server with waitress on port 5000...")
        serve(app, host='127.0.0.1', port=5000, threads=4)
    except KeyboardInterrupt:
        shutdown_server()
    except Exception as e:
        logger.api_logger.error(f"Server error: {str(e)}")
        shutdown_server() 