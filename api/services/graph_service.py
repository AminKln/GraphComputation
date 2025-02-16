"""Graph processing service."""

from typing import Any, Dict

import networkx as nx
import pandas as pd

from api.data.data_manager import DataManager
from api.data.models import GraphRequest
from api.data.validators import validate_all
from api.utils.formatters import format_graph_response


def process_graph_data(request: GraphRequest) -> Dict[str, Any]:
    """
    Process graph data according to request.
    
    Args:
        request: Validated graph request
        
    Returns:
        Processed graph data in requested format
    """
    # Initialize data manager
    data_manager = DataManager()
    
    try:
        # Load data based on source type
        if hasattr(request.source, "dsn"):
            # SQL source
            data_manager.set_connection(request.source.dsn)
            vertex_df = data_manager.execute_query(request.source.vertex_sql)
            edge_df = data_manager.execute_query(request.source.edge_sql)
        else:
            # File source - handle both file paths and direct data
            if hasattr(request.source, "vertex_data") and hasattr(request.source, "edge_data"):
                # Direct data input
                vertex_df = pd.DataFrame(request.source.vertex_data)
                edge_df = pd.DataFrame(request.source.edge_data)
            else:
                # File path input
                vertex_df = pd.read_csv(request.source.vertex_file)
                edge_df = pd.read_csv(request.source.edge_file)
        
        # Validate data
        validate_all(vertex_df, edge_df)
        
        # Create graph
        G = nx.DiGraph()
        
        # Add nodes with weights
        for _, row in vertex_df.iterrows():
            G.add_node(row["vertex"], weight=row["weight"])
        
        # Add edges
        for _, row in edge_df.iterrows():
            G.add_edge(row["vertex_from"], row["vertex_to"])
        
        # If no node_id is provided, use the first node
        if not request.node_id:
            request.node_id = list(G.nodes())[0]
        
        # Get subgraph for requested node
        if request.node_id not in G:
            raise ValueError(f"Node {request.node_id} not found in graph")
            
        # Get all descendants including the root node
        descendants = nx.descendants(G, request.node_id)
        descendants.add(request.node_id)  # Include root node
        subgraph = G.subgraph(descendants)
        
        # Calculate weights
        node_weight = G.nodes[request.node_id]["weight"]
        subgraph_weight = sum(
            G.nodes[n]["weight"] for n in subgraph.nodes
        )
        
        # Calculate metrics for the subgraph
        try:
            eigenvector_centrality = list(nx.eigenvector_centrality(subgraph, weight="weight", max_iter=1000).values())
        except:
            # If eigenvector centrality fails, use degree centrality as a fallback
            eigenvector_centrality = list(nx.degree_centrality(subgraph).values())
        
        # Calculate clustering coefficients with error handling
        try:
            clustering_coeffs = list(nx.clustering(subgraph).values())
        except:
            clustering_coeffs = [0] * subgraph.number_of_nodes()
        
        # Calculate average shortest path with error handling
        try:
            avg_shortest_path = nx.average_shortest_path_length(subgraph) if nx.is_strongly_connected(subgraph) else None
        except:
            avg_shortest_path = None
        
        metrics = {
            "node_metrics": {
                "Node": list(subgraph.nodes()),
                "Weight": [subgraph.nodes[n]["weight"] for n in subgraph.nodes()],
                "Degree": list(dict(subgraph.degree()).values()),
                "Betweenness": list(nx.betweenness_centrality(subgraph, weight="weight").values()),
                "Closeness": list(nx.closeness_centrality(subgraph, distance="weight").values()),
                "Eigenvector": eigenvector_centrality,
                "ClusteringCoeff": clustering_coeffs
            },
            "network_metrics": {
                "total_nodes": subgraph.number_of_nodes(),
                "total_edges": subgraph.number_of_edges(),
                "average_degree": sum(dict(subgraph.degree()).values()) / subgraph.number_of_nodes(),
                "density": nx.density(subgraph),
                "average_clustering": sum(clustering_coeffs) / len(clustering_coeffs) if clustering_coeffs else 0,
                "average_shortest_path": avg_shortest_path
            }
        }
        
        # Convert node_metrics to a list of dictionaries for easier handling in R
        metrics["node_metrics"] = pd.DataFrame(metrics["node_metrics"]).to_dict("records")
        
        # Format response
        response = format_graph_response(
            subgraph,
            node_weight,
            subgraph_weight,
            format=request.format
        )
        
        # Add metrics to response
        response["metrics"] = metrics
        
        return response
        
    finally:
        data_manager.cleanup() 