import argparse
import math
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
        max_nodes: int = None,
    ):
        """
        Initialize the tree data generator.
        
        Args:
            min_children: Minimum number of children per node
            max_children: Maximum number of children per node
            min_weight: Minimum initial weight for nodes
            max_weight: Maximum initial weight for nodes
            weight_variation: Maximum relative change in weights between snapshots
            max_nodes: Maximum number of nodes in the tree (optional)
        """
        self.min_children = min_children
        self.max_children = max_children
        self.min_weight = min_weight
        self.max_weight = max_weight
        self.weight_variation = weight_variation
        self.max_nodes = max_nodes
        
    def calculate_min_nodes_for_depth(self, depth: int) -> int:
        """Calculate minimum nodes needed for a given depth."""
        # For a minimal tree with min_children at each level
        nodes = 1  # Root
        current_level_nodes = 1
        for _ in range(depth):
            current_level_nodes *= self.min_children
            nodes += current_level_nodes
        return nodes
        
    def calculate_max_nodes_for_depth(self, depth: int) -> int:
        """Calculate maximum possible nodes for a given depth."""
        # For a maximal tree with max_children at each level
        nodes = 1  # Root
        current_level_nodes = 1
        for _ in range(depth):
            current_level_nodes *= self.max_children
            nodes += current_level_nodes
        return nodes
        
    def find_possible_depth(self, target_nodes: int) -> Tuple[int, str]:
        """
        Find the maximum possible depth that can be achieved with target_nodes.
        Returns (depth, explanation).
        """
        depth = 0
        min_nodes = 1
        max_nodes = 1
        current_min_level = 1
        current_max_level = 1
        
        while True:
            next_min = min_nodes + (current_min_level * self.min_children)
            next_max = max_nodes + (current_max_level * self.max_children)
            
            if next_min > target_nodes:
                # Can't go deeper with min_children
                return depth, (
                    f"Cannot reach depth {depth + 1} with {target_nodes} nodes:\n"
                    f"- Minimum nodes needed for depth {depth + 1}: {next_min}\n"
                    f"- Current depth {depth} requires: {min_nodes}-{max_nodes} nodes\n"
                    f"- To reach depth {depth + 1}, increase max_nodes to at least {next_min}"
                )
            
            if target_nodes <= max_nodes:
                # We can satisfy the target_nodes at current depth
                return depth, (
                    f"Can create tree of depth {depth} with {target_nodes} nodes:\n"
                    f"- Valid node range for depth {depth}: {min_nodes}-{max_nodes}\n"
                    f"- Using {self.min_children}-{self.max_children} children per node"
                )
            
            depth += 1
            min_nodes = next_min
            max_nodes = next_max
            current_min_level *= self.min_children
            current_max_level *= self.max_children
    
    def generate_tree(self, depth: int) -> nx.DiGraph:
        """Generate a random tree with specified depth and node limit."""
        G = nx.DiGraph()
        nodes = ['A']  # Start with root node
        current_letter = ord('A')
        total_nodes = 1
        
        # Calculate minimum and maximum possible nodes
        min_nodes_needed = self.calculate_min_nodes_for_depth(depth)
        max_possible_nodes = self.calculate_max_nodes_for_depth(depth)
        
        # Validate parameters
        if self.max_nodes is not None:
            if self.max_nodes < min_nodes_needed:
                possible_depth, explanation = self.find_possible_depth(self.max_nodes)
                raise ValueError(
                    f"Cannot create tree of depth {depth} with max_nodes={self.max_nodes}.\n"
                    f"{explanation}"
                )
            target_nodes = min(self.max_nodes, max_possible_nodes)
        else:
            target_nodes = max_possible_nodes
            
        # For binary trees (min_children == max_children == 2), use simpler logic
        if self.min_children == 2 and self.max_children == 2:
            for level in range(depth):
                new_nodes = []
                for parent in nodes:
                    # Always create exactly 2 children for binary tree
                    for _ in range(2):
                        current_letter += 1
                        child = f"N{current_letter - ord('Z')}" if current_letter > ord('Z') else chr(current_letter)
                        G.add_edge(parent, child)
                        new_nodes.append(child)
                        total_nodes += 1
                nodes = new_nodes
            return G
            
        # For non-binary trees, use the more complex logic with node limits
        nodes_needed_per_level = []
        remaining_nodes = target_nodes - 1  # Subtract root
        current_level_nodes = len(nodes)
        
        # Calculate minimum nodes needed at each level to reach depth
        for level in range(depth):
            min_nodes_this_level = max(
                current_level_nodes * self.min_children,  # Minimum based on parent count
                remaining_nodes // (depth - level) if depth - level > 0 else 0  # Even distribution of remaining
            )
            nodes_needed_per_level.append(min_nodes_this_level)
            remaining_nodes -= min_nodes_this_level
            current_level_nodes = min_nodes_this_level
        
        # Generate the tree level by level
        for level in range(depth):
            new_nodes = []
            nodes_target = nodes_needed_per_level[level] if level < len(nodes_needed_per_level) else 0
            nodes_per_parent = max(
                self.min_children,
                math.ceil(nodes_target / len(nodes)) if nodes_target > 0 else 0
            )
            
            if nodes_per_parent > self.max_children:
                raise ValueError(
                    f"Cannot satisfy tree requirements:\n"
                    f"- At level {level}, need {nodes_per_parent} children per parent to reach depth {depth}\n"
                    f"- But maximum allowed children is {self.max_children}\n"
                    f"- Either increase max_children or decrease depth"
                )
            
            for parent in nodes:
                for _ in range(nodes_per_parent):
                    current_letter += 1
                    child = f"N{current_letter - ord('Z')}" if current_letter > ord('Z') else chr(current_letter)
                    G.add_edge(parent, child)
                    new_nodes.append(child)
                    total_nodes += 1
                    
                    if total_nodes >= target_nodes:
                        break
                        
                if total_nodes >= target_nodes:
                    break
                    
            nodes = new_nodes
            if not nodes or total_nodes >= target_nodes:
                break
                
        # Verify tree properties
        num_vertices = len(G.nodes())
        num_edges = len(G.edges())
        if num_edges != num_vertices - 1:
            raise ValueError(f"Invalid tree structure: {num_edges} edges for {num_vertices} vertices")
            
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
        
        # Verify tree structure
        num_vertices = len(tree.nodes())
        num_edges = len(tree.edges())
        expected_vertices = 2**(depth + 1) - 1  # Perfect binary tree
        expected_edges = expected_vertices - 1
        
        if num_vertices != expected_vertices or num_edges != expected_edges:
            raise ValueError(
                f"Tree structure invalid: Got {num_vertices} vertices and {num_edges} edges, "
                f"expected {expected_vertices} vertices and {expected_edges} edges"
            )
        
        # Generate vertex weights
        vertex_df = self.generate_node_weights(set(tree.nodes()), num_snapshots)
        
        # Create edge DataFrame - with validation
        edge_rows = []
        edges = list(tree.edges())
        start_date = datetime(2024, 1, 1)
        
        for i in range(num_snapshots):
            snapshot = start_date + timedelta(days=i)
            for u, v in edges:
                edge_rows.append({
                    'vertex_from': u,
                    'vertex_to': v,
                    'snapshot': snapshot.strftime('%Y-%m-%d')
                })
        
        edge_df = pd.DataFrame(edge_rows)
        
        # Verify row counts
        expected_vertex_rows = num_vertices * num_snapshots
        expected_edge_rows = num_edges * num_snapshots
        
        if len(vertex_df) != expected_vertex_rows:
            raise ValueError(f"Vertex row count mismatch: Got {len(vertex_df)}, expected {expected_vertex_rows}")
        
        if len(edge_df) != expected_edge_rows:
            raise ValueError(f"Edge row count mismatch: Got {len(edge_df)}, expected {expected_edge_rows}")
        
        # Create output directory if it doesn't exist
        os.makedirs(output_dir, exist_ok=True)
        
        # Save files
        vertex_path = os.path.join(output_dir, 'vertices.csv')
        edge_path = os.path.join(output_dir, 'edges.csv')
        
        vertex_df.to_csv(vertex_path, index=False)
        edge_df.to_csv(edge_path, index=False)
        
        # Print detailed statistics
        print(f"\nDetailed Dataset Statistics:")
        print(f"Tree depth: {depth}")
        print(f"Unique vertices: {num_vertices} (expected {expected_vertices})")
        print(f"Unique edges: {num_edges} (expected {expected_edges})")
        print(f"Number of snapshots: {num_snapshots}")
        print(f"Total vertex rows in CSV: {len(vertex_df)}")
        print(f"Total edge rows in CSV: {len(edge_df)}")
        print(f"Average weight: {vertex_df['weight'].mean():.2f}")
        
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
    parser.add_argument('--max-nodes', type=int, help='Maximum number of nodes in the tree')
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
        weight_variation=args.weight_variation,
        max_nodes=args.max_nodes
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
    # Fix edge counting - count unique edge combinations
    unique_edges = edge_df.groupby(['vertex_from', 'vertex_to']).size().reset_index()
    num_edges = len(unique_edges)
    
    print(f"\nDataset statistics:")
    print(f"Number of unique vertices: {num_vertices}")
    print(f"Number of unique edges: {num_edges}")
    print(f"Number of snapshots: {args.num_snapshots}")
    print(f"Total rows in vertex file: {len(vertex_df)}")
    print(f"Total rows in edge file: {len(edge_df)}")
    print(f"Average weight: {vertex_df['weight'].mean():.2f}")

if __name__ == '__main__':
    main() 