from collections import defaultdict
from dataclasses import dataclass
from datetime import datetime
from typing import Dict, List, Optional, Union

import networkx as nx
import pandas as pd


@dataclass
class SubgraphResult:
    """Class to store subgraph computation results."""
    node_weight: float  # The weight of the node itself
    subgraph_weight: float  # Total weight of the node and all its descendants
    nodes: List[str]  # List of nodes in the subgraph
    edges: List[tuple]  # List of edges in the subgraph
    node_weights: Dict[str, float]  # Individual weights of all nodes in the subgraph

class GraphProcessor:
    def __init__(self):
        self.snapshots: Dict[datetime, nx.DiGraph] = {}
        self.vertex_weights: Dict[datetime, Dict[str, float]] = {}
        self.processed_results: Dict[datetime, Dict[str, SubgraphResult]] = {}
        
    def process_dataframes(
        self,
        vertex_df: pd.DataFrame,
        edge_df: pd.DataFrame
    ) -> None:
        """
        Process vertex and edge DataFrames directly.
        
        Args:
            vertex_df: DataFrame with columns (vertex, weight, snapshot)
            edge_df: DataFrame with columns (vertex_from, vertex_to, snapshot)
        """
        # Validate DataFrames
        self._validate_vertex_data(vertex_df)
        self._validate_edge_data(edge_df)
        
        # Convert snapshots to datetime if they're strings
        vertex_df['snapshot'] = pd.to_datetime(vertex_df['snapshot'])
        edge_df['snapshot'] = pd.to_datetime(edge_df['snapshot'])
        
        # Initialize dictionaries
        self.snapshots = {}
        self.vertex_weights = {}
        self.processed_results = {}
        
        # Process vertex data
        for snapshot, group in vertex_df.groupby('snapshot'):
            self.vertex_weights[snapshot] = {
                row['vertex']: row['weight']
                for _, row in group.iterrows()
            }
        
        # Process edge data and create graphs
        for snapshot, group in edge_df.groupby('snapshot'):
            if snapshot not in self.vertex_weights:
                continue
                
            G = nx.DiGraph()
            # Add all vertices first (including isolated vertices)
            for vertex in self.vertex_weights[snapshot]:
                G.add_node(vertex)
            # Add edges
            for _, row in group.iterrows():
                G.add_edge(row['vertex_from'], row['vertex_to'])
            self.snapshots[snapshot] = G
        
        # Process all graphs
        self._process_all_graphs()
    
    @classmethod
    def from_files(
        cls,
        vertex_file: str,
        edge_file: str
    ) -> 'GraphProcessor':
        """
        Create GraphProcessor instance from CSV files.
        
        Args:
            vertex_file: Path to vertex CSV file
            edge_file: Path to edge CSV file
            
        Returns:
            Initialized GraphProcessor instance
        """
        processor = cls()
        vertex_df = pd.read_csv(vertex_file)
        edge_df = pd.read_csv(edge_file)
        processor.process_dataframes(vertex_df, edge_df)
        return processor
    
    def _validate_vertex_data(self, df: pd.DataFrame) -> None:
        """Validate vertex DataFrame structure."""
        required_columns = {'vertex', 'weight', 'snapshot'}
        if not all(col in df.columns for col in required_columns):
            raise ValueError(f"Vertex data must contain columns: {required_columns}")
    
    def _validate_edge_data(self, df: pd.DataFrame) -> None:
        """Validate edge DataFrame structure."""
        required_columns = {'vertex_from', 'vertex_to', 'snapshot'}
        if not all(col in df.columns for col in required_columns):
            raise ValueError(f"Edge data must contain columns: {required_columns}")
    
    def _process_all_graphs(self) -> None:
        """Process all snapshots and compute subgraph weights."""
        for snapshot, graph in self.snapshots.items():
            self.processed_results[snapshot] = {}
            for node in graph.nodes():
                if node not in self.processed_results[snapshot]:
                    self._process_node(snapshot, node)
    
    def _process_node(self, snapshot: datetime, node: str) -> SubgraphResult:
        """Process a single node and compute its subgraph weights."""
        if node in self.processed_results[snapshot]:
            return self.processed_results[snapshot][node]
        
        graph = self.snapshots[snapshot]
        node_weight = self.vertex_weights[snapshot].get(node, 0.0)
        
        descendants = nx.descendants(graph, node)
        descendants.add(node)
        subgraph = graph.subgraph(descendants)
        
        node_weights = {
            n: self.vertex_weights[snapshot].get(n, 0.0)
            for n in subgraph.nodes()
        }
        
        subgraph_weight = sum(node_weights.values())
        
        result = SubgraphResult(
            node_weight=node_weight,
            subgraph_weight=subgraph_weight,
            nodes=list(subgraph.nodes()),
            edges=list(subgraph.edges()),
            node_weights=node_weights
        )
        
        self.processed_results[snapshot][node] = result
        return result
    
    def get_subgraph_weight(
        self,
        node_id: str,
        snapshot: Union[str, datetime],
        include_structure: bool = False
    ) -> Union[Dict[str, float], SubgraphResult]:
        """
        Get the weights of a node and its subgraph.
        
        Args:
            node_id: The root node of the subgraph
            snapshot: The snapshot datetime or date string
            include_structure: If True, returns full SubgraphResult
            
        Returns:
            Either a dict with node_weight and subgraph_weight or the full SubgraphResult
        """
        if isinstance(snapshot, str):
            snapshot = pd.to_datetime(snapshot)
            
        if snapshot not in self.snapshots:
            raise ValueError(f"No data for snapshot: {snapshot}")
            
        if node_id not in self.snapshots[snapshot]:
            raise ValueError(f"Node {node_id} not found in snapshot {snapshot}")
        
        result = self._process_node(snapshot, node_id)
        if include_structure:
            return result
        return {
            'node_weight': result.node_weight,
            'subgraph_weight': result.subgraph_weight
        }
    
    def export_results(
        self,
        output_path: str,
        snapshot: Optional[Union[str, datetime]] = None
    ) -> None:
        """Export processed results to CSV file."""
        if snapshot and isinstance(snapshot, str):
            snapshot = pd.to_datetime(snapshot)
        
        snapshots_to_process = [snapshot] if snapshot else list(self.snapshots.keys())
        
        rows = []
        for snap in snapshots_to_process:
            for node, result in self.processed_results[snap].items():
                rows.append({
                    'snapshot': snap,
                    'node': node,
                    'node_weight': result.node_weight,
                    'subgraph_weight': result.subgraph_weight,
                    'num_descendants': len(result.nodes) - 1
                })
        
        pd.DataFrame(rows).to_csv(output_path, index=False) 