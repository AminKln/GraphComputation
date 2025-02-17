"""Data validation utilities."""

from typing import Set

import pandas as pd


def validate_vertex_data(df: pd.DataFrame) -> None:
    """
    Validate vertex DataFrame structure.
    
    Args:
        df: DataFrame to validate
        
    Raises:
        ValueError: If required columns are missing
    """
    required_columns = {'vertex', 'weight', 'snapshot'}
    if not all(col in df.columns for col in required_columns):
        raise ValueError(f"Vertex data must contain columns: {required_columns}")

def validate_edge_data(df: pd.DataFrame) -> None:
    """
    Validate edge DataFrame structure.
    
    Args:
        df: DataFrame to validate
        
    Raises:
        ValueError: If required columns are missing
    """
    required_columns = {'vertex_from', 'vertex_to', 'snapshot'}
    if not all(col in df.columns for col in required_columns):
        raise ValueError(f"Edge data must contain columns: {required_columns}")

def validate_snapshots(vertex_df: pd.DataFrame, edge_df: pd.DataFrame) -> None:
    """
    Validate that vertex and edge data have matching snapshots.
    
    Args:
        vertex_df: Vertex DataFrame
        edge_df: Edge DataFrame
        
    Raises:
        ValueError: If no matching snapshots are found
    """
    vertex_snapshots = set(vertex_df['snapshot'].unique())
    edge_snapshots = set(edge_df['snapshot'].unique())
    if not vertex_snapshots.intersection(edge_snapshots):
        raise ValueError("No matching snapshots between vertex and edge data")

def validate_graph_structure(vertex_df: pd.DataFrame, edge_df: pd.DataFrame) -> None:
    """
    Validate graph structure integrity.
    
    Args:
        vertex_df: Vertex DataFrame
        edge_df: Edge DataFrame
        
    Raises:
        ValueError: If graph structure is invalid
    """
    vertices = set(vertex_df['vertex'].unique())
    edge_vertices = set(edge_df['vertex_from'].unique()) | set(edge_df['vertex_to'].unique())
    
    # Check for edges referencing non-existent vertices
    missing_vertices = edge_vertices - vertices
    if missing_vertices:
        raise ValueError(f"Edges reference non-existent vertices: {missing_vertices}")
    
    # Check for cycles (if needed)
    # This is a simple cycle check, might need more sophisticated cycle detection
    for _, edge in edge_df.iterrows():
        if edge['vertex_from'] == edge['vertex_to']:
            raise ValueError(f"Self-loop detected at vertex: {edge['vertex_from']}")

def validate_weights(vertex_df: pd.DataFrame) -> None:
    """
    Validate weight values.
    
    Args:
        vertex_df: Vertex DataFrame
        
    Raises:
        ValueError: If weight values are invalid
    """
    # Check for negative weights
    if (vertex_df['weight'] < 0).any():
        raise ValueError("Negative weights found in vertex data")
    
    # Check for non-numeric weights
    if not pd.to_numeric(vertex_df['weight'], errors='coerce').notna().all():
        raise ValueError("Non-numeric weights found in vertex data")

def validate_all(vertex_df: pd.DataFrame, edge_df: pd.DataFrame) -> None:
    """
    Run all validations on the graph data.
    
    Args:
        vertex_df: Vertex DataFrame
        edge_df: Edge DataFrame
        
    Raises:
        ValueError: If any validation fails
    """
    validate_vertex_data(vertex_df)
    validate_edge_data(edge_df)
    validate_snapshots(vertex_df, edge_df)
    validate_graph_structure(vertex_df, edge_df)
    validate_weights(vertex_df) 