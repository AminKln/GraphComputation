"""Response formatting utilities."""

from typing import Any, Dict, List

import networkx as nx
import pandas as pd

from api.config.settings import SUPPORTED_FORMATS


def format_graph_response(G: nx.DiGraph, node_weight: float, subgraph_weight: float, format: str = "d3") -> Dict[str, Any]:
    """
    Format graph data for response.
    
    Args:
        G: NetworkX graph
        node_weight: Weight of the root node
        subgraph_weight: Total weight of the subgraph (including root)
        format: Output format (d3, cytoscape, etc.)
        
    Returns:
        Formatted graph data
    """
    # Normalize format string
    format = format.lower()
    
    # Validate format
    supported_formats = ["d3", "json", "csv", "networkx"]
    if format not in supported_formats:
        raise ValueError(f"Unsupported format: {format}. Supported formats are: {', '.join(supported_formats)}")
    
    if format in ["d3", "json"]:  # Support both d3 and json as the same format
        # Find the true root node (node with no incoming edges)
        root_candidates = [n for n in G.nodes() if G.in_degree(n) == 0]
        if not root_candidates:
            # If no node has 0 in-degree, use the node with highest out-degree
            root_candidates = [max(G.nodes(), key=lambda n: G.out_degree(n))]
        root_node = root_candidates[0]
        
        # Calculate depth using BFS
        depths = nx.shortest_path_length(G, root_node)
        max_depth = max(depths.values()) if depths else 0
        
        # Create nodes list with proper formatting
        nodes = []
        for n in G.nodes:
            node_data = G.nodes[n]
            descendants = nx.descendants(G, n).union({n})
            node_subgraph_weight = sum(float(G.nodes[desc].get("weight", 0.0)) for desc in descendants)
            
            # Calculate node metrics
            node = {
                "id": str(n),
                "label": str(n),  # Required by visNetwork
                "title": f"<p><b>Node:</b> {n}<br><b>Weight:</b> {node_data.get('weight', 0.0)}<br><b>Depth:</b> {depths.get(n, 0)}</p>",  # Tooltip
                "weight": float(node_data.get("weight", 0.0)),
                "subgraph_weight": node_subgraph_weight,
                "depth": depths.get(n, 0),
                "is_root": n == root_node,
                "level": depths.get(n, 0)  # For hierarchical layout
            }
            nodes.append(node)
        
        # Create edges list with proper formatting for visNetwork
        links = [
            {
                "from": str(u),  # visNetwork expects "from" instead of "source"
                "to": str(v),    # visNetwork expects "to" instead of "target"
                "arrows": "to"   # Add arrow styling
            }
            for u, v in G.edges()
        ]
        
        return {
            "nodes": nodes,
            "edges": links,  # visNetwork expects "edges" instead of "links"
            "root_node": str(root_node),
            "node_weight": node_weight,
            "subgraph_weight": subgraph_weight,
            "format": format
        }
    
    elif format == "csv":
        # Convert to CSV format
        nodes_df = pd.DataFrame([
            {
                "node": n,
                "weight": G.nodes[n].get("weight", 0.0),
                "in_degree": G.in_degree(n),
                "out_degree": G.out_degree(n)
            }
            for n in G.nodes()
        ])
        
        edges_df = pd.DataFrame([
            {
                "source": u,
                "target": v
            }
            for u, v in G.edges()
        ])
        
        return {
            "nodes": nodes_df.to_csv(index=False),
            "edges": edges_df.to_csv(index=False),
            "format": format
        }
    
    elif format == "networkx":
        # Return NetworkX compatible format
        return {
            "nodes": list(G.nodes(data=True)),
            "edges": list(G.edges(data=True)),
            "format": format
        }
    
    # Should never reach here due to format validation
    raise ValueError(f"Unsupported format: {format}")

def format_json(
    graph: nx.DiGraph,
    node_weight: float,
    subgraph_weight: float
) -> Dict[str, Any]:
    """Format graph as JSON."""
    return {
        "node_weight": node_weight,
        "subgraph_weight": subgraph_weight,
        "nodes": list(graph.nodes()),
        "edges": list(graph.edges()),
        "node_weights": {
            node: data["weight"]
            for node, data in graph.nodes(data=True)
        }
    }

def format_csv(graph: nx.DiGraph) -> str:
    """Format graph as CSV."""
    rows = []
    for node, data in graph.nodes(data=True):
        level = nx.shortest_path_length(graph, list(graph.nodes())[0], node)
        rows.append({
            "node": node,
            "weight": data["weight"],
            "level": level
        })
    return pd.DataFrame(rows).to_csv(index=False)

def format_d3(graph: nx.DiGraph) -> Dict[str, List]:
    """Format graph for D3.js visualization."""
    return {
        "nodes": [
            {"id": node, "weight": data["weight"]}
            for node, data in graph.nodes(data=True)
        ],
        "links": [
            {"source": u, "target": v}
            for u, v in graph.edges()
        ]
    }

def format_networkx(graph: nx.DiGraph) -> Dict[str, Any]:
    """Format graph in NetworkX JSON format."""
    return {
        "directed": True,
        "multigraph": False,
        "graph": {},
        "nodes": [
            {"id": node, "weight": data["weight"]}
            for node, data in graph.nodes(data=True)
        ],
        "links": [
            {"source": u, "target": v}
            for u, v in graph.edges()
        ]
    } 