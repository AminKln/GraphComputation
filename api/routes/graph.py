"""Graph processing routes."""

import hashlib
import time
from typing import Dict

import networkx as nx
from flask import Blueprint, jsonify, request

from api.data.models import FileSource, GraphRequest, SQLSource
from api.services.graph_service import process_graph_data
from api.utils.logging import log_execution_time, logger
from api.utils.metrics import QueryMetrics, metrics

bp = Blueprint("graph", __name__, url_prefix="/api/v1")

def calculate_query_hash(data: Dict) -> str:
    """Calculate hash of query parameters."""
    source = data.get("source", {})
    
    # Handle both dict and model inputs
    if isinstance(source, (SQLSource, FileSource)):
        if isinstance(source, SQLSource):
            query_str = f"{source.dsn}:{source.vertex_sql}:{source.edge_sql}"
        else:
            # For file data, use the first few nodes as a hash
            vertex_data = source.vertex_data or []
            query_str = str(vertex_data[:5] if vertex_data else "")
    else:
        # Handle raw dictionary input
        if source.get("type") == "sql":
            query_str = f"{source.get('dsn')}:{source.get('vertex_sql')}:{source.get('edge_sql')}"
        else:
            # For file data, use the first few nodes as a hash
            vertex_data = source.get("vertex_data", [])
            query_str = str(vertex_data[:5] if vertex_data else "")
            
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
                
                # If root_node not specified, get it from graph_metrics
                if not params.get('root_node'):
                    snapshot = params.get('snapshot')
                    if snapshot:
                        metrics_response = get_graph_metrics_internal(data["source"], snapshot)
                        if metrics_response and 'root_node' in metrics_response:
                            params['root_node'] = metrics_response['root_node']
            
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
            node_id=str(request_data.node_id) if request_data.node_id else str(result.get("root_node", "")),
            source_type=data["source"].type if isinstance(data["source"], (SQLSource, FileSource)) else data["source"]["type"],
            graph_size=graph_size,
            subgraph_size=subgraph_size,
            execution_time=duration
        )
        metrics.track_query(query_metrics)
        
        # Log query details
        logger.log_query(
            {
                "query_hash": query_hash,
                "source_type": data["source"].type if isinstance(data["source"], (SQLSource, FileSource)) else data["source"]["type"],
                "graph_size": graph_size,
                "duration": duration
            },
            duration
        )
        
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"Error processing graph request: {str(e)}")
        return jsonify({"error": str(e)}), 400

def get_graph_metrics_internal(source, snapshot):
    """Internal function to get graph metrics without HTTP request."""
    try:
        # Calculate graph metrics
        if isinstance(source, FileSource):
            nodes = source.vertex_data
            edges = source.edge_data
        else:
            nodes = source["vertex_data"]
            edges = source["edge_data"]
        
        # Filter by snapshot
        snapshot_nodes = [n for n in nodes if n.get("snapshot") == snapshot]
        snapshot_edges = [e for e in edges if e.get("snapshot") == snapshot]
        
        # Calculate node degrees
        node_degrees = {}
        for edge in snapshot_edges:
            source_node = edge.get("source") or edge.get("vertex_from")
            target_node = edge.get("target") or edge.get("vertex_to")
            
            if source_node:
                node_degrees[source_node] = node_degrees.get(source_node, 0) + 1
            if target_node:
                node_degrees[target_node] = node_degrees.get(target_node, 0) + 1
        
        # Find root node (node with highest degree)
        root_node = max(node_degrees.items(), key=lambda x: x[1])[0] if node_degrees else None
        
        return {
            "root_node": root_node,
            "total_nodes": len(snapshot_nodes),
            "total_edges": len(snapshot_edges)
        }
        
    except Exception as e:
        logger.error(f"Error calculating internal graph metrics: {str(e)}")
        return None

@bp.route("/graph_metrics", methods=["POST"])
@log_execution_time
def get_graph_metrics():
    """Calculate and return graph metrics."""
    try:
        # Get request data
        data = request.get_json()
        if not data:
            return jsonify({"error": "No JSON data provided"}), 400
            
        # Validate request data
        try:
            if data["source"]["type"] == "sql":
                data["source"] = SQLSource(**data["source"])
            else:
                data["source"] = FileSource(**data["source"])
            
            # Get snapshot from request
            snapshot = data.get("snapshot")
            if not snapshot:
                return jsonify({"error": "No snapshot provided"}), 400
                
        except Exception as e:
            logger.error(f"Data validation error: {str(e)}")
            return jsonify({"error": f"Invalid request data: {str(e)}"}), 400
        
        # Create NetworkX graph for the snapshot
        G = nx.DiGraph()
        
        # Filter nodes and edges for the snapshot
        source = data["source"]
        vertex_data = source.vertex_data if isinstance(source, FileSource) else source["vertex_data"]
        edge_data = source.edge_data if isinstance(source, FileSource) else source["edge_data"]
        
        snapshot_nodes = [n for n in vertex_data if n.get("snapshot") == snapshot]
        snapshot_edges = [e for e in edge_data if e.get("snapshot") == snapshot]
        
        # Add nodes with weights
        for node in snapshot_nodes:
            G.add_node(
                node["vertex"],
                weight=node.get("weight", 1.0)
            )
        
        # Add edges
        for edge in snapshot_edges:
            source = edge.get("source") or edge.get("vertex_from")
            target = edge.get("target") or edge.get("vertex_to")
            if source and target:
                G.add_edge(source, target)
        
        # Find root node (node with no incoming edges)
        root_candidates = [n for n in G.nodes() if G.in_degree(n) == 0]
        if not root_candidates:
            # If no node has 0 in-degree, use the node with highest out-degree
            if G.nodes():
                root_candidates = [max(G.nodes(), key=lambda n: G.out_degree(n))]
        
        root_node = root_candidates[0] if root_candidates else None
        
        # Calculate depth using BFS from root
        max_depth = 0
        if root_node:
            depths = nx.shortest_path_length(G, root_node)
            max_depth = max(depths.values()) if depths else 0
        
        # Calculate basic metrics
        total_nodes = G.number_of_nodes()
        total_edges = G.number_of_edges()
        density = nx.density(G)
        
        result = {
            "total_nodes": total_nodes,
            "total_edges": total_edges,
            "root_node": str(root_node) if root_node else None,
            "max_depth": max_depth,
            "additional_metrics": {
                "density": density
            }
        }
        
        logger.info(f"Calculated metrics for snapshot {snapshot}: {result}")
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"Error calculating graph metrics: {str(e)}")
        return jsonify({"error": str(e)}), 400 