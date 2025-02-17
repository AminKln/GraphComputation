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
    if format not in SUPPORTED_FORMATS:
        raise ValueError(f"Unsupported format: {format}. Supported formats are: {', '.join(SUPPORTED_FORMATS)}")
    
    if format in ["d3", "json"]:  # Support both d3 and json as the same format
        # Get node data
        nodes = [
            {
                "id": n,
                "weight": G.nodes[n]["weight"],
                "subgraph_weight": sum(
                    G.nodes[desc]["weight"] 
                    for desc in nx.descendants(G, n).union({n})
                )
            }
            for n in G.nodes
        ]
        
        # Get edge data
        links = [
            {
                "source": u,
                "target": v
            }
            for u, v in G.edges
        ]
        
        return {
            "nodes": nodes,
            "links": links,
            "root_node": {
                "id": list(G.nodes)[0],
                "weight": node_weight,
                "subgraph_weight": subgraph_weight
            }
        }
    
    elif format == "csv":
        return format_csv(G)
    elif format == "networkx":
        return format_networkx(G)
    else:
        raise ValueError(f"Format {format} is supported but not implemented")

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