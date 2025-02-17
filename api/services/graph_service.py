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
        
        # If snapshot is provided in params, filter data before creating graph
        target_snapshot = None
        if request.params and request.params.get('snapshot'):
            target_snapshot = request.params['snapshot']
            vertex_df = vertex_df[vertex_df['snapshot'] == target_snapshot]
            edge_df = edge_df[edge_df['snapshot'] == target_snapshot]
        
        # Add nodes with weights
        for _, row in vertex_df.iterrows():
            node_id = row["vertex"]
            G.add_node(
                node_id,
                weight=row["weight"],
                snapshot=row["snapshot"]
            )
        
        # Add edges
        for _, row in edge_df.iterrows():
            # Only add edges if both vertices exist (they should be in the same snapshot)
            if G.has_node(row["vertex_from"]) and G.has_node(row["vertex_to"]):
                G.add_edge(row["vertex_from"], row["vertex_to"])
        
        # Get root node from params or fallback to node_id
        root_node = None
        if request.params and request.params.get('root_node'):
            root_node = request.params['root_node']
        elif request.node_id:
            root_node = request.node_id
        else:
            root_node = list(G.nodes())[0]
        
        # Get subgraph for requested node
        if root_node not in G:
            raise ValueError(f"Root node {root_node} not found in graph")
        
        # Get descendants up to max_depth
        descendants = set([root_node])  # Start with root node
        current_level = {root_node}
        max_depth = request.params.get('max_depth', float('inf')) if request.params else float('inf')
        
        # BFS to respect max_depth
        depth = 0
        while current_level and (max_depth is None or depth < max_depth):
            next_level = set()
            for node in current_level:
                children = set(G.successors(node))
                next_level.update(children - descendants)
            descendants.update(next_level)
            current_level = next_level
            depth += 1
        
        # Create subgraph with only the nodes up to max_depth
        subgraph = G.subgraph(descendants)
        
        # Calculate weights
        node_weight = G.nodes[root_node]["weight"]
        subgraph_weight = sum(
            G.nodes[n]["weight"] for n in subgraph.nodes
        )
        
        # Calculate metrics for the subgraph
        metrics = {
            "node_metrics": []
        }
        
        # Pre-calculate all centrality metrics
        try:
            betweenness = nx.betweenness_centrality(subgraph, weight="weight")
        except:
            betweenness = {node: 0.0 for node in subgraph.nodes()}
            
        try:
            closeness = nx.closeness_centrality(subgraph, distance="weight")
        except:
            closeness = {node: 0.0 for node in subgraph.nodes()}
            
        try:
            eigenvector = nx.eigenvector_centrality(subgraph, weight="weight", max_iter=1000)
        except:
            eigenvector = {node: 0.0 for node in subgraph.nodes()}
            
        try:
            clustering = nx.clustering(subgraph)
        except:
            clustering = {node: 0.0 for node in subgraph.nodes()}
        
        # Calculate node metrics
        for node in subgraph.nodes():
            node_data = subgraph.nodes[node]
            descendants = nx.descendants(subgraph, node)
            descendants.add(node)  # Include the node itself
            
            # Calculate subgraph weight
            node_subgraph_weight = sum(subgraph.nodes[n]["weight"] for n in descendants)
            
            # Add metrics to the list
            metrics["node_metrics"].append({
                "Node": str(node),
                "Weight": float(subgraph.nodes[node]["weight"]),
                "Subgraph_Weight": float(node_subgraph_weight),
                "Degree": int(subgraph.degree(node)),
                "Betweenness": float(betweenness[node]),
                "Closeness": float(closeness[node]),
                "Eigenvector": float(eigenvector[node]),
                "ClusteringCoeff": float(clustering[node])
            })
        
        # Calculate average shortest path with error handling
        try:
            avg_shortest_path = nx.average_shortest_path_length(subgraph) if nx.is_strongly_connected(subgraph) else None
        except:
            avg_shortest_path = None
        
        metrics["network_metrics"] = {
            "total_nodes": subgraph.number_of_nodes(),
            "total_edges": subgraph.number_of_edges(),
            "average_degree": sum(dict(subgraph.degree()).values()) / subgraph.number_of_nodes(),
            "density": nx.density(subgraph),
            "average_clustering": sum(clustering.values()) / len(clustering) if clustering else 0,
            "average_shortest_path": avg_shortest_path
        }
        
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