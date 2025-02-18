"""Graph processing service."""

from typing import Any, Dict

import networkx as nx
import pandas as pd

from api.data.data_manager import DataManager
from api.data.models import GraphRequest, SQLSource
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
        if isinstance(request.source, SQLSource):
            # SQL source
            data_manager.set_connection(request.source.dsn)
            vertex_df = data_manager.execute_query(request.source.vertex_sql)
            edge_df = data_manager.execute_query(request.source.edge_sql)
        else:
            # File source - handle both file paths and direct data
            if request.source.vertex_data is not None and request.source.edge_data is not None:
                # Process vertices
                vertices = []
                for node in request.source.vertex_data:
                    # Try to get vertex ID from various fields
                    vertex_id = None
                    if node.get('vertex'):
                        vertex_id = str(node['vertex'])
                    elif node.get('id'):
                        vertex_id = str(node['id'])
                    
                    # Only include nodes with a non-empty ID
                    if vertex_id and vertex_id.strip():
                        vertices.append({
                            'vertex': vertex_id.strip(),
                            'weight': float(node.get('weight', 1.0)),
                            'snapshot': str(node.get('snapshot', '')).strip()
                        })
                
                print(f"Processed {len(vertices)} valid vertices")
                vertex_df = pd.DataFrame(vertices)
                
                # Process edges
                edges = []
                for edge in request.source.edge_data:
                    # Get source and target using various possible field names
                    source = None
                    if edge.get('vertex_from'):
                        source = str(edge['vertex_from'])
                    elif edge.get('from'):
                        source = str(edge['from'])
                    elif edge.get('source'):
                        source = str(edge['source'])
                    
                    target = None
                    if edge.get('vertex_to'):
                        target = str(edge['vertex_to'])
                    elif edge.get('to'):
                        target = str(edge['to'])
                    elif edge.get('target'):
                        target = str(edge['target'])
                    
                    # Only include edges with non-empty source and target
                    if source and source.strip() and target and target.strip():
                        edges.append({
                            'vertex_from': source.strip(),
                            'vertex_to': target.strip(),
                            'snapshot': str(edge.get('snapshot', '')).strip()
                        })
                
                print(f"Processed {len(edges)} valid edges")
                edge_df = pd.DataFrame(edges)
                
            elif request.source.vertex_file is not None and request.source.edge_file is not None:
                # File path input
                vertex_df = pd.read_csv(request.source.vertex_file)
                edge_df = pd.read_csv(request.source.edge_file)
            else:
                raise ValueError("Invalid file source configuration")
        
        # Print data info
        print("\nVertex DataFrame Info:")
        print(vertex_df.info())
        print("\nFirst few vertices:")
        print(vertex_df.head())
        print("\nEdge DataFrame Info:")
        print(edge_df.info())
        print("\nFirst few edges:")
        print(edge_df.head())
        
        # Validate data
        validate_all(vertex_df, edge_df)
        
        # Create graph
        G = nx.DiGraph()
        
        # If snapshot is provided in params, filter data before creating graph
        target_snapshot = None
        if request.params and request.params.get('snapshot'):
            target_snapshot = str(request.params['snapshot']).strip()  # Ensure snapshot is string
            print(f"\nFiltering by snapshot: {target_snapshot}")
            vertex_df = vertex_df[vertex_df['snapshot'] == target_snapshot]
            edge_df = edge_df[edge_df['snapshot'] == target_snapshot]
            print(f"After filtering: {len(vertex_df)} vertices, {len(edge_df)} edges")
        
        # Add nodes with weights
        for _, row in vertex_df.iterrows():
            node_id = str(row["vertex"]).strip()  # Ensure node ID is string and trimmed
            if node_id:  # Only add non-empty node IDs
                G.add_node(
                    node_id,
                    weight=float(row["weight"]),  # Ensure weight is float
                    snapshot=str(row["snapshot"]).strip()  # Ensure snapshot is string and trimmed
                )
        
        print(f"\nAdded {len(G.nodes())} nodes to graph")
        
        # Add edges (only between existing vertices)
        invalid_edges = set()
        added_edges = 0
        for _, row in edge_df.iterrows():
            # Convert vertex IDs to strings and trim
            vertex_from = str(row["vertex_from"]).strip()
            vertex_to = str(row["vertex_to"]).strip()
            
            # Only add edges if both vertices exist and are non-empty
            if vertex_from and vertex_to:
                if G.has_node(vertex_from) and G.has_node(vertex_to):
                    G.add_edge(vertex_from, vertex_to)
                    added_edges += 1
                else:
                    missing = []
                    if not G.has_node(vertex_from):
                        missing.append(vertex_from)
                    if not G.has_node(vertex_to):
                        missing.append(vertex_to)
                    invalid_edges.add(f"({vertex_from}->{vertex_to}, missing: {missing})")
        
        print(f"Added {added_edges} edges to graph")
        
        if invalid_edges:
            error_msg = f"Edges reference non-existent vertices:\n" + "\n".join(invalid_edges)
            print(f"\nError: {error_msg}")
            raise ValueError(error_msg)
        
        # Ensure graph is not empty
        if not G.nodes():
            raise ValueError("No valid nodes found in the graph")
            
        # Check if graph is connected (one component)
        if not nx.is_weakly_connected(G):
            components = list(nx.weakly_connected_components(G))
            raise ValueError(f"Graph must have exactly one component. Found {len(components)} components.")
            
        # Get root node from params or fallback to node_id
        root_node = None
        if request.params and request.params.get('root_node'):
            root_node = str(request.params['root_node']).strip()  # Ensure root node is string and trimmed
        elif request.node_id:
            root_node = str(request.node_id).strip()  # Ensure root node is string and trimmed
        else:
            # For trees, prefer nodes with no incoming edges
            root_candidates = [n for n in G.nodes() if G.in_degree(n) == 0]
            if root_candidates:
                # If we have nodes with no incoming edges, use the one with highest out-degree
                root_node = max(root_candidates, key=lambda n: G.out_degree(n))
            else:
                # For general graphs, use node with highest out-degree
                root_node = max(G.nodes(), key=lambda n: G.out_degree(n))
        
        print(f"\nUsing root node: {root_node}")
        
        # Get subgraph for requested node
        if root_node not in G:
            raise ValueError(f"Root node {root_node} not found in graph")
            
        # Validate weights before using them
        for node in G.nodes():
            weight = G.nodes[node].get("weight")
            if weight is not None:
                try:
                    G.nodes[node]["weight"] = float(weight)
                    if G.nodes[node]["weight"] <= 0:
                        G.nodes[node]["weight"] = 1.0  # Use default weight for non-positive values
                except (ValueError, TypeError):
                    G.nodes[node]["weight"] = 1.0  # Use default weight for invalid values
            else:
                G.nodes[node]["weight"] = 1.0  # Use default weight if none provided
                
        # Get descendants up to max_depth
        descendants = set([root_node])  # Start with root node
        current_level = {root_node}
        try:
            max_depth = int(request.params.get('max_depth', float('inf'))) if request.params else float('inf')
            if max_depth < 0:
                raise ValueError("max_depth must be non-negative")
        except (ValueError, TypeError):
            raise ValueError("Invalid max_depth parameter")
            
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
        subgraph = G.subgraph(descendants).copy()  # Create a copy to avoid view issues
        
        if not subgraph.nodes():
            raise ValueError("Resulting subgraph is empty")
            
        print(f"\nCreated subgraph with {len(subgraph.nodes())} nodes and {len(subgraph.edges())} edges")
        
        # Calculate weights
        try:
            node_weight = float(G.nodes[root_node]["weight"])  # Ensure weight is float
            subgraph_weight = sum(
                float(G.nodes[n]["weight"]) for n in subgraph.nodes  # Ensure weights are floats
            )
        except (ValueError, TypeError) as e:
            raise ValueError(f"Invalid weight values in graph: {str(e)}")
            
        # Calculate subgraph metrics
        subgraph_metrics = {
            "total_nodes": subgraph.number_of_nodes(),
            "total_edges": subgraph.number_of_edges(),
            "root_node": str(root_node),  # Ensure root node is string
            "depth": depth,  # Use the actual depth from BFS
            "is_tree": nx.is_tree(subgraph.to_undirected()),  # Check if it's a tree
            "additional_metrics": {
                "density": float(nx.density(subgraph))  # Ensure density is float
            }
        }
        
        # Calculate node-level metrics
        node_metrics = []
        for node in subgraph.nodes():
            node_data = subgraph.nodes[node]
            try:
                # Get node descendants safely
                node_descendants = nx.descendants(subgraph, node).union({node})
                subgraph_weight = sum(float(subgraph.nodes[desc].get("weight", 1.0)) for desc in node_descendants)
                
                # Calculate centrality metrics with error handling
                degree = subgraph.degree(node)
                
                try:
                    betweenness = nx.betweenness_centrality(subgraph, normalized=True).get(node, 0.0)
                except:
                    betweenness = 0.0
                    
                try:
                    closeness = nx.closeness_centrality(subgraph).get(node, 0.0)
                except:
                    closeness = 0.0
                    
                try:
                    # Try different eigenvector centrality methods
                    try:
                        eigenvector = nx.eigenvector_centrality_numpy(subgraph).get(node, 0.0)
                    except:
                        eigenvector = nx.eigenvector_centrality(subgraph, max_iter=1000).get(node, 0.0)
                except:
                    # Fallback to degree centrality if eigenvector fails
                    eigenvector = nx.degree_centrality(subgraph).get(node, 0.0)
                    
                try:
                    clustering = nx.clustering(subgraph, node)
                except:
                    clustering = 0.0
                    
                node_metrics.append({
                    "Node": str(node),
                    "Weight": float(node_data.get("weight", 1.0)),
                    "Subgraph_Weight": float(subgraph_weight),
                    "Degree": int(degree),
                    "Betweenness": float(betweenness),
                    "Closeness": float(closeness),
                    "Eigenvector": float(eigenvector),
                    "ClusteringCoeff": float(clustering)
                })
            except Exception as e:
                print(f"Warning: Failed to calculate metrics for node {node}: {str(e)}")
                continue
                
        # Add node metrics to the subgraph metrics
        subgraph_metrics["node_metrics"] = node_metrics
        
        # Format response
        response = format_graph_response(
            subgraph,
            node_weight,
            subgraph_weight,
            format=request.format
        )
        
        # Update response with correct metrics
        response["metrics"] = subgraph_metrics
        
        return response
        
    finally:
        data_manager.cleanup() 