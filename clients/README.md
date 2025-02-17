# Graph Computation Clients

This directory contains client applications that interact with the Graph Computation API.

## Available Clients

### R Shiny Client

Located in the `R/` directory, this is a Shiny web application that provides a user-friendly interface for graph analysis and visualization.

#### Directory Structure

```
R/
├── server/             # Server-side logic
│   ├── handlers/       # Request handlers for different features
│   └── main_server.R   # Main server implementation
├── ui/                 # User interface components
│   ├── boxes/         # UI box components
│   └── components/    # Reusable UI components
└── sample_data/       # Sample datasets for testing
```

#### Features

- Interactive graph visualization
- Node statistics and analysis
- Data source configuration
- Search functionality
- Progress tracking
- Settings management

#### Setup and Running

1. Install R and required packages:
   ```R
   install.packages(c("shiny", "shinydashboard", "httr", "jsonlite", "visNetwork"))
   ```

2. Run the Shiny application:
   ```R
   shiny::runApp("clients/R")
   ```

## Adding New Clients

To add a new client implementation:

1. Create a new directory for your client
2. Implement the necessary API calls to interact with the Graph Computation API
3. Add appropriate documentation
4. Update this README with information about your client

## Development Guidelines

- Follow the existing project structure
- Implement error handling
- Add appropriate logging
- Include sample data for testing
- Document all features and functions 