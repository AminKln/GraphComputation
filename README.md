# Graph Computation Project

A comprehensive solution for graph data processing, analysis, and visualization.

## Project Structure

```
.
├── api/            # REST API implementation
├── clients/        # Client applications
├── core/           # Core graph processing logic
├── tools/          # Utility scripts and tools
├── metrics/        # Performance metrics storage
├── logs/           # Application logs
└── uploads/        # Temporary file storage
```

## Dependencies

### Python Dependencies
```bash
# Core dependencies
pip install flask flask-cors waitress networkx pandas numpy
pip install pydantic sqlalchemy pyodbc

# Development dependencies
pip install pytest black mypy
```

### R Dependencies
```R
# Install required R packages
install.packages(c(
    "shiny",
    "shinydashboard",
    "shinyjs",
    "DT",
    "visNetwork",
    "httr",
    "jsonlite",
    "dplyr"
))
```

## Components

### 1. API Server
The Flask-based REST API provides endpoints for:
- Graph data processing
- Node relationship analysis
- Weight calculations
- Data export

To run the API server:
```bash
python -m flask --app api/server run --port 5000 --debug
```

### 2. R Shiny Client
An interactive web interface that provides:
- Graph visualization using visNetwork
- Node statistics and analysis
- Data source configuration (SQL/File)
- Interactive node search
- Real-time progress tracking
- Customizable settings

To run the R client:
```R
# From R console
shiny::runApp("clients/R")
```

### 3. Core Processing
The core module provides:
- Temporal graph processing
- Weight calculations
- Subgraph analysis
- Data validation
See [Core Documentation](core/README.md) for details.

## Usage Examples

### 1. Process Graph Data via API
```bash
curl -X POST http://localhost:5000/process_graph \
  -H "Content-Type: application/json" \
  -d '{
    "node_id": "example_node",
    "source": {
      "file_path": "path/to/data.csv"
    }
  }'
```

### 2. Visualize in R Client
1. Start the R Shiny application
2. Upload data or configure SQL connection
3. Use the search box to find nodes
4. View graph visualizations and statistics
5. Export results as needed

## Data Formats

### Vertex Data (CSV)
```csv
vertex,weight,snapshot
node1,1.5,2024-02-15
node2,2.0,2024-02-15
```

### Edge Data (CSV)
```csv
vertex_from,vertex_to,snapshot
node1,node2,2024-02-15
node2,node3,2024-02-15
```

## Synthetic Data Generation

The project includes a sophisticated data generator tool that creates hierarchical tree-based graph data for testing and demonstration purposes. The generator supports various constraints and provides detailed feedback about data generation possibilities.

### Basic Usage

```bash
# Generate a simple tree with default parameters
python tools/generate_data.py --output-dir sample_data

# Generate a specific tree structure
python tools/generate_data.py \
    --depth 4 \
    --min-children 2 \
    --max-children 3 \
    --max-nodes 50 \
    --num-snapshots 5 \
    --output-dir custom_data
```

### Generator Features

- **Flexible Tree Structure**:
  - Control tree depth and branching factors
  - Set minimum and maximum children per node
  - Limit total number of nodes
  - Generate both balanced and unbalanced trees

- **Smart Validation**:
  - Automatically validates if requested tree structure is possible
  - Provides detailed feedback about minimum requirements
  - Suggests parameter adjustments when needed

- **Weight Generation**:
  - Configurable node weights and variations
  - Temporal weight changes across snapshots
  - Controlled random variations

### Generator Parameters

- `--depth`: Maximum depth of the tree (default: 3)
- `--min-children`: Minimum children per node (default: 2)
- `--max-children`: Maximum children per node (default: 4)
- `--max-nodes`: Maximum total nodes in tree (optional)
- `--min-weight`: Minimum node weight (default: 1.0)
- `--max-weight`: Maximum node weight (default: 100.0)
- `--weight-variation`: Maximum weight change between snapshots (default: 0.2)
- `--num-snapshots`: Number of time snapshots (default: 5)
- `--seed`: Random seed for reproducibility (optional)

### Example Use Cases

1. Generate a small test dataset:
   ```bash
   python tools/generate_data.py --depth 3 --max-nodes 20
   ```

2. Generate a large balanced tree:
   ```bash
   python tools/generate_data.py \
       --depth 8 \
       --min-children 2 \
       --max-children 2 \
       --num-snapshots 10
   ```

3. Generate an unbalanced tree with size constraints:
   ```bash
   python tools/generate_data.py \
       --depth 6 \
       --min-children 1 \
       --max-children 3 \
       --max-nodes 100
   ```

### Intelligent Feedback

The generator provides helpful feedback when parameters can't be satisfied:

```bash
# Example of attempting to create too large a tree
$ python tools/generate_data.py --depth 5 --min-children 2 --max-nodes 20

Cannot create tree of depth 5 with max_nodes=20:
- Minimum nodes needed for depth 5: 31
- Current depth 4 requires: 15-40 nodes
- To reach depth 5, increase max_nodes to at least 31
```

For more detailed information about the data generator, see [Data Generator Documentation](tools/README.md).

## Logging and Metrics

- API logs: `logs/api.log`
- Performance metrics: `metrics/`
- R client logs: `clients/R/logs/`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## Support

For issues and support:
1. Check the component-specific documentation:
   - [API Documentation](api/README.md)
   - [Client Documentation](clients/README.md)
   - [Core Documentation](core/README.md)
2. Submit an issue in the repository
3. Contact the development team