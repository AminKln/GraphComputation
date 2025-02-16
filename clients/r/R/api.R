# API Functions

#' Process graph files through the API
#'
#' @param vertex_file The vertex CSV file
#' @param edge_file The edge CSV file
#' @param format The output format (default: "d3")
#' @return A list containing the processed graph data
process_graph_files <- function(vertex_file, edge_file, format = "d3") {
  # Validate file paths
  if (!file.exists(vertex_file$datapath)) {
    stop(paste("Vertex file not found:", vertex_file$datapath))
  }
  if (!file.exists(edge_file$datapath)) {
    stop(paste("Edge file not found:", edge_file$datapath))
  }
  
  # Read the files with error handling
  tryCatch({
    # Read CSV files with proper type conversion
    vertex_data <- read.csv(vertex_file$datapath, stringsAsFactors = FALSE)
    edge_data <- read.csv(edge_file$datapath, stringsAsFactors = FALSE)
    
    # Validate data structure
    if (!all(c("vertex", "weight", "snapshot") %in% colnames(vertex_data))) {
      stop("Vertex file must contain columns: vertex, weight, snapshot")
    }
    if (!all(c("vertex_from", "vertex_to", "snapshot") %in% colnames(edge_data))) {
      stop("Edge file must contain columns: vertex_from, vertex_to, snapshot")
    }
    
    # Convert data frames to lists - keep original column names
    vertex_list <- lapply(seq_len(nrow(vertex_data)), function(i) {
      list(
        vertex = as.character(vertex_data$vertex[i]),
        weight = as.numeric(vertex_data$weight[i]),
        snapshot = as.character(vertex_data$snapshot[i])
      )
    })
    
    edge_list <- lapply(seq_len(nrow(edge_data)), function(i) {
      list(
        vertex_from = as.character(edge_data$vertex_from[i]),
        vertex_to = as.character(edge_data$vertex_to[i]),
        snapshot = as.character(edge_data$snapshot[i])
      )
    })
    
    # Get the first vertex as the default root node
    default_root <- as.character(vertex_data$vertex[1])
    
    # Prepare the request body
    body <- list(
      source = list(
        type = "file",
        vertex_data = vertex_list,
        edge_data = edge_list
      ),
      format = format,
      node_id = default_root
    )
    
    # Convert to JSON with proper settings
    json_body <- toJSON(
      body,
      auto_unbox = TRUE,
      digits = 10,
      null = "null",
      na = "null"
    )
    
    # Make the API request
    response <- POST(
      url = paste0(API_BASE_URL, "/process_graph"),
      body = json_body,
      encode = "raw",
      content_type("application/json"),
      add_headers("Accept" = "application/json")
    )
    
    # Check response status and get content
    if (http_status(response)$category != "Success") {
      error_content <- content(response, "parsed")
      stop(paste("API request failed:", error_content$error))
    }
    
    # Parse response with explicit type handling
    result <- content(response, "parsed")
    
    # Ensure all nodes have required fields
    result$nodes <- lapply(result$nodes, function(node) {
      node$id <- as.character(node$id)
      node$weight <- as.numeric(node$weight)
      if (!is.null(node$subgraph_weight)) {
        node$subgraph_weight <- as.numeric(node$subgraph_weight)
      }
      node
    })
    
    # Ensure all links have required fields
    result$links <- lapply(result$links, function(link) {
      link$source <- as.character(link$source)
      link$target <- as.character(link$target)
      link
    })
    
    return(result)
    
  }, error = function(e) {
    stop(paste("Error processing files:", e$message))
  })
}

#' Process graph data from SQL queries through the API
#'
#' @param dsn The database connection string
#' @param vertex_sql The SQL query for vertices
#' @param edge_sql The SQL query for edges
#' @param format The output format (default: "d3")
#' @return A list containing the processed graph data
process_graph_sql <- function(dsn, vertex_sql, edge_sql, format = "d3") {
  # Prepare the request body
  body <- list(
    source = list(
      type = "sql",
      dsn = dsn,
      vertex_sql = vertex_sql,
      edge_sql = edge_sql
    ),
    format = format
  )
  
  # Make the API request
  response <- tryCatch({
    POST(
      url = paste0(API_BASE_URL, "/process_graph"),
      body = toJSON(body, auto_unbox = TRUE),
      encode = "raw",
      content_type("application/json"),
      add_headers("Accept" = "application/json")
    )
  }, error = function(e) {
    stop(paste("API request failed:", e$message))
  })
  
  # Check response status and get content
  if (http_status(response)$category != "Success") {
    error_content <- content(response, "parsed")
    stop(paste("API request failed:", error_content$error))
  }
  
  # Parse and return the response
  content(response, "parsed")
}

#' Download the processed graph data
#'
#' @param graph_data The graph data to download
#' @param format The format to download in (default: "json")
#' @return The path to the downloaded file
download_graph_data <- function(graph_data, format = "json") {
  # Create a temporary file
  temp_file <- tempfile(fileext = paste0(".", format))
  
  # Write the data to the file
  if (format == "json") {
    writeLines(toJSON(graph_data, auto_unbox = TRUE), temp_file)
  } else if (format == "csv") {
    # Write nodes
    write.csv(
      do.call(rbind, lapply(graph_data$nodes, as.data.frame)),
      file = paste0(temp_file, "_nodes.csv"),
      row.names = FALSE
    )
    # Write edges
    write.csv(
      do.call(rbind, lapply(graph_data$links, as.data.frame)),
      file = paste0(temp_file, "_edges.csv"),
      row.names = FALSE
    )
  } else {
    stop("Unsupported format")
  }
  
  temp_file
}

#' Handle API errors
#'
#' @param error The error object
#' @return A user-friendly error message
handle_api_error <- function(error) {
  if (inherits(error, "http_error")) {
    # Handle HTTP errors
    status <- http_status(error)
    paste("API Error:", status$message)
  } else if (inherits(error, "error")) {
    # Handle R errors
    paste("Error:", error$message)
  } else {
    # Handle unknown errors
    "An unknown error occurred"
  }
} 