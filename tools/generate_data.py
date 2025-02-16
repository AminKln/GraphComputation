import argparse
import os
import random
from datetime import datetime, timedelta
from typing import List, Set, Tuple

import networkx as nx
import numpy as np
import pandas as pd


class TreeDataGenerator:
    def __init__(
        self,
        min_children: int = 2,
        max_children: int = 4,
        min_weight: float = 1.0,
        max_weight: float = 100.0,
        weight_variation: float = 0.2,
    ):
        """
        Initialize the tree data generator.
        
        Args:
            min_children: Minimum number of children per node
            max_children: Maximum number of children per node
            min_weight: Minimum initial weight for nodes
            max_weight: Maximum initial weight for nodes
            weight_variation: Maximum relative change in weights between snapshots
        """
        self.min_children = min_children
        self.max_children = max_children
        self.min_weight = min_weight
        self.max_weight = max_weight
        self.weight_variation = weight_variation
        
    def generate_tree(self, depth: int) -> nx.DiGraph:
        """Generate a random tree with specified depth."""
        G = nx.DiGraph()
        nodes = ['A']  # Start with root node
        current_letter = ord('A')
        
        for level in range(depth):
            new_nodes = []
            for parent in nodes:
                # Random number of children for this parent
                num_children = random.randint(self.min_children, self.max_children)
                for _ in range(num_children):
                    current_letter += 1
                    if current_letter > ord('Z'):
                        # If we run out of letters, use numbered nodes
                        child = f"N{current_letter - ord('Z')}"
                    else:
                        child = chr(current_letter)
                    G.add_edge(parent, child)
                    new_nodes.append(child)
            nodes = new_nodes
            if not nodes:  # No more nodes to process
                break
        return G
    
    def generate_node_weights(self, nodes: Set[str], num_snapshots: int) -> pd.DataFrame:
        """Generate weight data for nodes across snapshots."""
        # Initialize base weights
        base_weights = {
            node: random.uniform(self.min_weight, self.max_weight)
            for node in nodes
        }
        
        # Generate snapshots with varying weights
        rows = []
        start_date = datetime(2024, 1, 1)
        
        for i in range(num_snapshots):
            snapshot = start_date + timedelta(days=i)
            for node, base_weight in base_weights.items():
                # Vary weight by up to weight_variation percent
                variation = random.uniform(-self.weight_variation, self.weight_variation)
                weight = base_weight * (1 + variation)
                rows.append({
                    'vertex': node,
                    'snapshot': snapshot.strftime('%Y-%m-%d'),
                    'weight': round(weight, 2)
                })
        
        return pd.DataFrame(rows)
    
    def generate_dataset(
        self,
        depth: int,
        num_snapshots: int,
        output_dir: str
    ) -> Tuple[str, str]:
        """
        Generate a complete dataset with vertices and edges.
        
        Args:
            depth: Maximum depth of the tree
            num_snapshots: Number of time snapshots to generate
            output_dir: Directory to save the generated files
            
        Returns:
            Tuple of (vertex_file_path, edge_file_path)
        """
        # Generate tree structure
        tree = self.generate_tree(depth)
        
        # Generate vertex weights
        vertex_df = self.generate_node_weights(set(tree.nodes()), num_snapshots)
        
        # Create edge DataFrame
        edge_rows = []
        start_date = datetime(2024, 1, 1)
        
        for i in range(num_snapshots):
            snapshot = start_date + timedelta(days=i)
            for u, v in tree.edges():
                edge_rows.append({
                    'vertex_from': u,
                    'vertex_to': v,
                    'snapshot': snapshot.strftime('%Y-%m-%d')
                })
        
        edge_df = pd.DataFrame(edge_rows)
        
        # Create output directory if it doesn't exist
        os.makedirs(output_dir, exist_ok=True)
        
        # Save files
        vertex_path = os.path.join(output_dir, 'vertices.csv')
        edge_path = os.path.join(output_dir, 'edges.csv')
        
        vertex_df.to_csv(vertex_path, index=False)
        edge_df.to_csv(edge_path, index=False)
        
        return vertex_path, edge_path

def main():
    parser = argparse.ArgumentParser(description='Generate synthetic tree data')
    parser.add_argument('--depth', type=int, default=3, help='Maximum depth of the tree')
    parser.add_argument('--min-children', type=int, default=2, help='Minimum children per node')
    parser.add_argument('--max-children', type=int, default=4, help='Maximum children per node')
    parser.add_argument('--min-weight', type=float, default=1.0, help='Minimum node weight')
    parser.add_argument('--max-weight', type=float, default=100.0, help='Maximum node weight')
    parser.add_argument('--weight-variation', type=float, default=0.2,
                        help='Maximum relative change in weights between snapshots')
    parser.add_argument('--num-snapshots', type=int, default=5, help='Number of time snapshots')
    parser.add_argument('--output-dir', type=str, default='sample_data',
                        help='Output directory for generated files')
    parser.add_argument('--seed', type=int, help='Random seed for reproducibility')
    
    args = parser.parse_args()
    
    if args.seed is not None:
        random.seed(args.seed)
        np.random.seed(args.seed)
    
    generator = TreeDataGenerator(
        min_children=args.min_children,
        max_children=args.max_children,
        min_weight=args.min_weight,
        max_weight=args.max_weight,
        weight_variation=args.weight_variation
    )
    
    vertex_path, edge_path = generator.generate_dataset(
        depth=args.depth,
        num_snapshots=args.num_snapshots,
        output_dir=args.output_dir
    )
    
    print(f"Generated dataset:")
    print(f"Vertex file: {vertex_path}")
    print(f"Edge file: {edge_path}")
    
    # Print some statistics
    vertex_df = pd.read_csv(vertex_path)
    edge_df = pd.read_csv(edge_path)
    
    num_vertices = len(vertex_df['vertex'].unique())
    num_edges = len(edge_df['vertex_from'].unique())
    
    print(f"\nDataset statistics:")
    print(f"Number of vertices: {num_vertices}")
    print(f"Number of edges: {num_edges}")
    print(f"Number of snapshots: {args.num_snapshots}")
    print(f"Average weight: {vertex_df['weight'].mean():.2f}")

if __name__ == '__main__':
    main() 