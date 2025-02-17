"""Graph processing routes."""

import hashlib
import time
from typing import Dict

from flask import Blueprint, jsonify, request

from api.data.models import FileSource, GraphRequest, SQLSource
from api.services.graph_service import process_graph_data
from api.utils.logging import log_execution_time, logger
from api.utils.metrics import QueryMetrics, metrics

bp = Blueprint("graph", __name__, url_prefix="/api/v1")

def calculate_query_hash(data: Dict) -> str:
    """Calculate hash of query parameters."""
    source = data.get("source", {})
    if source.get("type") == "sql":
        query_str = f"{source.get('dsn')}:{source.get('vertex_sql')}:{source.get('edge_sql')}"
    else:
        # For file data, use the first few nodes as a hash
        vertex_data = source.get("vertex_data", [])
        query_str = str(vertex_data[:5]) if vertex_data else ""
    return hashlib.md5(query_str.encode()).hexdigest()

@bp.route("/process_graph", methods=["POST"])
@log_execution_time
def process_graph():
    """Handle graph processing requests."""
    start_time = time.time()
    
    try:
        # Get request data
        data = request.get_json()
        if not data:
            return jsonify({"error": "No JSON data provided"}), 400
            
        query_hash = calculate_query_hash(data)
        
        # Validate request data
        try:
            if data["source"]["type"] == "sql":
                data["source"] = SQLSource(**data["source"])
            else:
                data["source"] = FileSource(**data["source"])
            
            # Extract params from request data
            params = data.get('params', {})
            if params:
                # Convert max_depth to integer if present
                if 'max_depth' in params:
                    params['max_depth'] = int(params['max_depth'])
            
            # Create request data with params
            request_data = GraphRequest(
                source=data["source"],
                format=data.get("format", "json"),
                node_id=data.get("node_id"),
                params=params
            )
            
        except Exception as e:
            logger.error(f"Data validation error: {str(e)}")
            return jsonify({"error": f"Invalid request data: {str(e)}"}), 400
        
        # Process request
        result = process_graph_data(request_data)
        
        # Calculate metrics
        duration = time.time() - start_time
        graph_size = len(result.get("nodes", []))
        subgraph_size = len(result.get("links", []))
        
        # Track query metrics
        query_metrics = QueryMetrics(
            query_hash=query_hash,
            source_type=data["source"]["type"],
            graph_size=graph_size,
            subgraph_size=subgraph_size,
            execution_time=duration
        )
        metrics.track_query(query_metrics)
        
        # Log query details
        logger.log_query(
            {
                "query_hash": query_hash,
                "source_type": data["source"]["type"],
                "graph_size": graph_size,
                "duration": duration
            },
            duration
        )
        
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"Error processing graph request: {str(e)}")
        return jsonify({"error": str(e)}), 400 