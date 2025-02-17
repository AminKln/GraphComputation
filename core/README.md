# Graph Computation Core

The core component of the Graph Computation project, providing efficient graph processing for weighted directed graphs with temporal snapshots.

## Overview

The core module implements a `GraphProcessor` class that:
- Processes weighted directed graphs with temporal snapshots
- Calculates subgraph weights and node relationships
- Handles both file-based and DataFrame-based inputs
- Provides efficient caching of computation results

## Usage

### From CSV Files

```python
from core.graph_processor import GraphProcessor

# Initialize from CSV files
processor = GraphProcessor.from_files(
    vertex_file="path/to/vertices.csv",  # Contains: vertex,weight,snapshot
    edge_file="path/to/edges.csv"        # Contains: vertex_from,vertex_to,snapshot
)
```

### From DataFrames

```python
# Initialize with pandas DataFrames
processor = GraphProcessor()
processor.process_dataframes(
    vertex_df=vertex_dataframe,  # Columns: vertex,weight,snapshot
    edge_df=edge_dataframe      # Columns: vertex_from,vertex_to,snapshot
)
```

### Getting Results

```python
# Get node and subgraph weights
weights = processor.get_subgraph_weight(
    node_id="node1",
    snapshot="2024-02-15",
    include_structure=False  # Set to True to get full graph structure
)

# Export all results to CSV
processor.export_results(
    output_path="results.csv",
    snapshot=None  # Optional: specify snapshot, None for all
)
```

## Input Data Format

### Vertex Data
- Required columns: `vertex`, `weight`, `snapshot`
- `vertex`: Unique node identifier
- `weight`: Numerical weight of the node
- `snapshot`: Timestamp of the data point

### Edge Data
- Required columns: `vertex_from`, `vertex_to`, `snapshot`
- `vertex_from`: Source node identifier
- `vertex_to`: Target node identifier
- `snapshot`: Timestamp of the relationship

## Features

- **Temporal Processing**: Handles multiple snapshots of graph data
- **Weight Calculations**: 
  - Individual node weights
  - Subgraph total weights (node + all descendants)
  - Descendant count and relationships
- **Efficient Caching**: Results are cached per snapshot and node
- **Flexible Input**: Supports both file and DataFrame inputs
- **Data Validation**: Automatic validation of input data structure
- **Result Export**: Easy export of processed results to CSV

## Integration

The core module is primarily used by the API layer (`api/services/graph_service.py`), which exposes its functionality through REST endpoints. The R Shiny client then visualizes and analyzes the results.

## Performance

- Optimized for directed acyclic graphs (DAGs)
- Caches computation results for repeated queries
- Uses NetworkX for efficient graph operations
- Handles large datasets through pandas DataFrames

## Error Handling

The module handles several error cases:
- Invalid input data structure
- Missing nodes or snapshots
- Invalid snapshot formats
- Memory constraints for large graphs 