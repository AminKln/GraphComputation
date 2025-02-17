# Data Loading Handler

#' Debug print function for important events only
debug_print <- function(...) {
  message(paste0("[DATA] ", paste(..., collapse = " ")))
}

#' Create a basic error div
#' @param msg Error message to display
#' @return A shiny div element
create_error_div <- function(msg) {
  shiny::tags$div(
    class = "alert alert-danger",
    msg
  )
}

#' Handle data loading functionality
#' 
#' @param input Shiny input object
#' @param output Shiny output object
#' @param session Shiny session object
#' @param graph_data Reactive value for graph data
#' @param is_loading Reactive value for loading state
#' @return List of reactive values
handle_data_loading <- function(input, output, session, graph_data, is_loading) {
  # Progress state
  progress <- shiny::reactiveVal(0)
  data_loaded <- shiny::reactiveVal(FALSE)
  
  # Progress bar UI with validation
  output$data_loading_progress <- shiny::renderUI({
    tryCatch({
      if (is_loading()) {
        create_progress_bar(
          id = "loading_progress",
          value = progress(),
          total = 100,
          title = "Loading data..."
        )
      } else {
        NULL
      }
    }, error = function(e) {
      debug_print("Error in progress bar:", e$message)
      create_error_div("Error updating progress bar. Please check the console for details.")
    })
  })
  
  # Data loading handler
  shiny::observeEvent(input$load_data, {
    debug_print("Starting data load process")
    
    # Reset states
    is_loading(TRUE)
    progress(0)
    data_loaded(FALSE)
    
    tryCatch({
      # Determine data source paths
      if (input$use_sample_data) {
        # Use sample data paths
        sample_data_dir <- base::normalizePath(base::file.path(getwd(), "sample_data"), winslash = "/", mustWork = TRUE)
        vertex_path <- base::file.path(sample_data_dir, "vertices.csv")
        edge_path <- base::file.path(sample_data_dir, "edges.csv")
        debug_print("Using sample data files:", vertex_path, "and", edge_path)
      } else {
        # Use uploaded files
        if (is.null(input$vertex_file) || is.null(input$edge_file)) {
          base::stop("Please upload both vertex and edge CSV files")
        }
        
        vertex_path <- input$vertex_file$datapath
        edge_path <- input$edge_file$datapath
        debug_print("Using uploaded files:", vertex_path, "and", edge_path)
      }
      
      progress(20)
      
      # Check if files exist with detailed error messages
      if (!base::file.exists(vertex_path)) {
        base::stop(sprintf("Vertex file not found at: %s", vertex_path))
      }
      if (!base::file.exists(edge_path)) {
        base::stop(sprintf("Edge file not found at: %s", edge_path))
      }
      
      progress(40)
      
      # Read the CSV files with validation
      vertex_data <- utils::read.csv(vertex_path, stringsAsFactors = FALSE)
      edge_data <- utils::read.csv(edge_path, stringsAsFactors = FALSE)
      
      # Validate data structure
      required_vertex_cols <- c("vertex", "weight", "snapshot")
      required_edge_cols <- c("vertex_from", "vertex_to", "snapshot")
      
      missing_vertex_cols <- base::setdiff(required_vertex_cols, base::names(vertex_data))
      missing_edge_cols <- base::setdiff(required_edge_cols, base::names(edge_data))
      
      if (base::length(missing_vertex_cols) > 0) {
        base::stop(sprintf("Missing required columns in vertex data: %s", 
                    base::paste(missing_vertex_cols, collapse = ", ")))
      }
      if (base::length(missing_edge_cols) > 0) {
        base::stop(sprintf("Missing required columns in edge data: %s", 
                    base::paste(missing_edge_cols, collapse = ", ")))
      }
      
      debug_print(sprintf("Loaded %d vertices and %d edges", 
                         base::nrow(vertex_data), base::nrow(edge_data)))
      progress(60)
      
      # Convert to the format expected by the API and visNetwork
      nodes <- base::lapply(base::seq_len(base::nrow(vertex_data)), function(i) {
        base::list(
          vertex = base::as.character(vertex_data$vertex[i]),  # Keep original vertex column
          id = base::as.character(vertex_data$vertex[i]),      # Add id for visNetwork
          weight = vertex_data$weight[i],
          snapshot = base::as.character(vertex_data$snapshot[i])
        )
      })
      
      links <- base::lapply(base::seq_len(base::nrow(edge_data)), function(i) {
        base::list(
          vertex_from = base::as.character(edge_data$vertex_from[i]),  # Keep original vertex_from column
          vertex_to = base::as.character(edge_data$vertex_to[i]),      # Keep original vertex_to column
          source = base::as.character(edge_data$vertex_from[i]),       # Add source for visNetwork
          target = base::as.character(edge_data$vertex_to[i]),         # Add target for visNetwork
          snapshot = base::as.character(edge_data$snapshot[i])
        )
      })
      
      progress(80)
      
      # Create and validate the result structure
      result <- base::list(
        nodes = nodes,
        links = links
      )
      
      if (base::length(nodes) == 0 || base::length(links) == 0) {
        base::stop("Generated empty graph structure")
      }
      
      # Store the data
      graph_data(result)
      data_loaded(TRUE)
      
      progress(90)
      
      # Update UI elements
      shiny::updateSelectInput(session, "snapshot",
                               choices = base::sort(base::unique(vertex_data$snapshot)),
                               selected = base::sort(base::unique(vertex_data$snapshot))[1])
      
      progress(100)
      debug_print("Data loading completed successfully")
      
    }, error = function(e) {
      debug_print("Error:", e$message)
      shiny::showNotification(
        base::paste("Error loading data:", e$message),
        type = "error",
        duration = NULL
      )
      # Reset states on error
      graph_data(NULL)
      data_loaded(FALSE)
    }, finally = {
      is_loading(FALSE)
    })
  }, ignoreInit = TRUE)
  
  # Return reactive values
  base::list(
    data_loaded = data_loaded,
    progress = progress
  )
} 