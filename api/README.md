# Graph Computation API

This is the REST API component of the Graph Computation project, providing endpoints for graph processing and analysis.

## Directory Structure

```
api/
├── config/         # Configuration files and settings
├── data/          # Data models and database interfaces
├── routes/        # API route definitions
├── services/      # Business logic and service layer
├── utils/         # Utility functions and helpers
├── uploads/       # Temporary storage for uploaded files
├── server.py      # Main Flask application server
└── __init__.py    # Package initialization
```

## Setup and Running

1. Ensure you have Python 3.8+ installed
2. Install dependencies (from project root):
   ```bash
   pip install -r requirements.txt
   ```
3. Run the API server:
   ```bash
   python -m flask --app api/server run --port 5000 --debug
   ```

## API Endpoints

### POST /process_graph
Process graph data and return analysis results.

**Request Body:**
```json
{
    "node_id": "string",
    "source": {
        "dsn": "string",  // For SQL source
        // OR
        "file_path": "string"  // For file source
    }
}
```

## Configuration

The API can be configured through environment variables or configuration files in the `config/` directory.

## Logging

Logs are stored in the project's `logs/` directory. The API uses structured logging for better debugging and monitoring.

## Error Handling

The API implements comprehensive error handling with appropriate HTTP status codes and error messages.

## Security

- CORS is enabled for cross-origin requests
- Input validation is performed on all requests
- File upload restrictions are in place

## Development

To run in development mode with hot reloading:
```bash
python -m flask --app api/server run --port 5000 --debug
``` 