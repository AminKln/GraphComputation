# Project Tools

This directory contains utility tools and scripts for the Graph Computation project.

## Synthetic Data Generator

The `generate_data.py` script provides a flexible way to generate synthetic hierarchical graph data for testing and demonstration purposes.

### Features

- Generates hierarchical tree-structured graphs
- Creates temporal data with multiple snapshots
- Produces both vertex and edge data in CSV format
- Configurable node weights and variations
- Reproducible output with seed option

### Data Structure

#### Vertex Data (vertices.csv)
```csv
vertex,snapshot,weight
A,2024-01-01,75.32
B,2024-01-01,45.67
A,2024-01-02,78.15
B,2024-01-02,42.89
```

- `vertex`: Node identifier (A-Z, then N1, N2, etc.)
- `snapshot`: Date of the observation
- `weight`: Node weight for that snapshot

#### Edge Data (edges.csv)
```csv
vertex_from,vertex_to,snapshot
A,B,2024-01-01
B,C,2024-01-01
A,B,2024-01-02
B,C,2024-01-02
```

- `vertex_from`: Source node
- `vertex_to`: Target node
- `snapshot`: Date of the relationship

### Usage Examples

1. Quick start with defaults:
   ```bash
   python generate_data.py
   ```

2. Generate a small test dataset:
   ```bash
   python generate_data.py --depth 2 --num-snapshots 3 --output-dir test_data
   ```

3. Generate a large dataset with high variability:
   ```bash
   python generate_data.py \
       --depth 5 \
       --min-children 3 \
       --max-children 6 \
       --weight-variation 0.4 \
       --num-snapshots 30 \
       --output-dir large_data
   ```

4. Generate reproducible data:
   ```bash
   python generate_data.py --seed 42 --output-dir reproducible_data
   ```

### Implementation Details

The generator uses the following approach:
1. Creates a random tree structure using specified depth and children parameters
2. Assigns initial random weights to each node
3. Generates temporal snapshots by varying weights within the specified range
4. Maintains the same tree structure across all snapshots
5. Outputs both vertex and edge data in CSV format

### Notes

- Node IDs start with letters (A-Z) and continue with numbered nodes (N1, N2, etc.)
- Weights vary randomly between snapshots but maintain reasonable consistency
- The tree structure remains constant across all snapshots
- All dates start from 2024-01-01 with daily increments

# Data Generator Tool

A sophisticated tool for generating synthetic hierarchical graph data with temporal aspects. The generator creates tree-structured graphs with configurable properties and provides intelligent feedback about structural possibilities.

## Key Features

### 1. Tree Structure Control
- Configurable tree depth
- Flexible branching factors (min/max children per node)
- Optional node count limits
- Support for both balanced and unbalanced trees
- Automatic validation of structural constraints

### 2. Weight Generation
- Configurable weight ranges
- Temporal variations across snapshots
- Controlled random variations
- Reproducible with seed setting

### 3. Smart Validation
- Pre-generation feasibility checks
- Detailed feedback about structural requirements
- Clear suggestions for parameter adjustments
- Runtime validation of tree properties

## Usage Examples

### 1. Basic Usage
```bash
# Generate a simple tree with default settings
python generate_data.py

# Specify output directory
python generate_data.py --output-dir my_data
```

### 2. Controlling Tree Structure
```bash
# Generate a perfect binary tree
python generate_data.py \
    --depth 4 \
    --min-children 2 \
    --max-children 2

# Generate an unbalanced tree with size limit
python generate_data.py \
    --depth 6 \
    --min-children 1 \
    --max-children 3 \
    --max-nodes 50
```

### 3. Controlling Node Weights
```bash
# Custom weight ranges and variations
python generate_data.py \
    --min-weight 10.0 \
    --max-weight 1000.0 \
    --weight-variation 0.1

# Multiple time snapshots
python generate_data.py \
    --num-snapshots 30 \
    --weight-variation 0.05
```

### 4. Reproducible Generation
```bash
# Use seed for reproducibility
python generate_data.py --seed 42
```

## Parameter Details

### Tree Structure Parameters
- `--depth`: Maximum tree depth
  - Default: 3
  - Determines the maximum number of levels in the tree
  - Actual depth might be less with max_nodes constraint

- `--min-children`: Minimum children per node
  - Default: 2
  - Must be ≤ max_children
  - Affects minimum tree size requirements

- `--max-children`: Maximum children per node
  - Default: 4
  - Must be ≥ min_children
  - Affects maximum possible tree size

- `--max-nodes`: Maximum total nodes
  - Optional
  - Limits total tree size
  - May result in unbalanced trees

### Weight Parameters
- `--min-weight`: Minimum node weight
  - Default: 1.0
  - Base weight before variations

- `--max-weight`: Maximum node weight
  - Default: 100.0
  - Base weight before variations

- `--weight-variation`: Maximum weight change
  - Default: 0.2 (20%)
  - Applied to base weights across snapshots

### Other Parameters
- `--num-snapshots`: Time points to generate
  - Default: 5
  - Each snapshot has varying weights

- `--seed`: Random seed
  - Optional
  - Ensures reproducible generation

## Output Format

### 1. Vertex Data (vertices.csv)
```csv
vertex,snapshot,weight
A,2024-01-01,75.32
B,2024-01-01,45.67
A,2024-01-02,78.15
B,2024-01-02,42.89
```

### 2. Edge Data (edges.csv)
```csv
vertex_from,vertex_to,snapshot
A,B,2024-01-01
B,C,2024-01-01
A,B,2024-01-02
B,C,2024-01-02
```

## Error Messages and Feedback

### 1. Size Constraint Violations
```
Cannot create tree of depth 5 with max_nodes=20:
- Minimum nodes needed for depth 5: 31
- Current depth 4 requires: 15-40 nodes
- To reach depth 5, increase max_nodes to at least 31
```

### 2. Level-specific Constraints
```
Cannot satisfy tree requirements:
- At level 2, need 4 nodes per parent to reach depth 5
- But can only allow 2 nodes per parent to stay under 20 total nodes
- Either increase max_nodes or decrease depth
```

## Implementation Details

### Tree Generation Algorithm
1. Validates input parameters and calculates size requirements
2. Creates nodes level by level, respecting constraints
3. Assigns unique identifiers (A-Z, then N1, N2, etc.)
4. Generates base weights and temporal variations
5. Validates final structure

### Weight Generation
1. Assigns random base weights within specified range
2. Generates variations for each snapshot
3. Ensures variations stay within specified percentage
4. Rounds weights to 2 decimal places

## Best Practices

1. **Start Small**: Begin with small trees to understand parameter effects
2. **Use Seed**: Set seed for reproducible results during testing
3. **Check Requirements**: Pay attention to feedback about minimum requirements
4. **Balance Constraints**: Adjust depth and node limits together
5. **Validate Output**: Verify generated data meets your needs 