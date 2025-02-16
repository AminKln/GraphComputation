# Server Components

# Graph Data Handlers
handle_data_loading <- function(input, output, session, graph_data, is_loading) {
  # Progress state
  progress <- reactiveVal(0)
  data_loaded <- reactiveVal(FALSE)
  
  # Progress bar UI
  output$data_loading_progress <- renderUI({
    if (is_loading()) {
      div(
        class = "progress-container",
        progressBar(
          id = "loading_progress",
          value = progress(),
          total = 100,
          title = "Loading data...",
          display_pct = TRUE
        )
      )
    }
  })
  
  # Data loading handler
  observeEvent(input$load_data, {
    if (is_loading()) return()
    is_loading(TRUE)
    progress(0)
    data_loaded(FALSE)
    
    # Simulate progress updates
    progress_timer <- reactiveTimer(50)  # Update every 50ms
    progress_observer <- observe({
      if (is_loading()) {
        progress_timer()
        current <- progress()
        if (current < 90) {  # Max 90% until actual completion
          progress(current + 2)
        }
      } else {
        progress_observer$destroy()
      }
    })
    
    tryCatch({
      # Update progress to indicate start
      progress(10)
      
      if (input$data_source == "file") {
        if (input$use_sample_data) {
          # Use sample data files with absolute paths
          base_dir <- 'F:/Github/GraphComputation/'
          vertex_path <- file.path(base_dir, "sample_data", "vertices.csv")
          edge_path <- file.path(base_dir, "sample_data", "edges.csv")
          
          # Check if files exist
          if (!file.exists(vertex_path)) {
            stop(paste("Sample vertex file not found:", vertex_path))
          }
          if (!file.exists(edge_path)) {
            stop(paste("Sample edge file not found:", edge_path))
          }
          
          # Create file list objects
          vertex_file <- list(
            name = "vertices.csv",
            datapath = vertex_path
          )
          edge_file <- list(
            name = "edges.csv",
            datapath = edge_path
          )
          
          # Log file paths for debugging
          message("Using sample files:")
          message("Vertex file:", vertex_path)
          message("Edge file:", edge_path)
        } else {
          # Use uploaded files
          req(input$vertex_file, input$edge_file)
          vertex_file <- input$vertex_file
          edge_file <- input$edge_file
        }
        
        tryCatch({
          # Process files and get result
          result <- process_graph_files(
            vertex_file = vertex_file,
            edge_file = edge_file,
            format = "d3"
          )
          
          # Validate result structure
          if (is.null(result) || !is.list(result)) {
            stop("Invalid response from API: result is null or not a list")
          }
          
          if (!all(c("nodes", "links") %in% names(result))) {
            stop("Invalid response from API: missing required fields (nodes, links)")
          }
          
          # Store the data
          graph_data(result)
          
          # Extract and update snapshots
          snapshots <- unique(sapply(result$nodes, function(x) x$snapshot))
          snapshots <- snapshots[!sapply(snapshots, is.null)]
          
          if (length(snapshots) > 0) {
            # Sort snapshots chronologically
            sorted_snapshots <- sort(as.character(snapshots))
            
            # Update snapshot selector
            updateSelectInput(
              session,
              "snapshot",
              choices = sorted_snapshots,
              selected = sorted_snapshots[1]
            )
            
            # Initialize root node
            if (!is.null(result$root_node)) {
              updateTextInput(
                session,
                "subgraph_root",
                value = as.character(result$root_node$id)
              )
            }
            
            # Trigger initial graph rendering
            delay(500, {
              click("render_graph")
            })
          }
          
          # Update progress and show success
          progress(100)
          data_loaded(TRUE)
          showNotification("Data loaded successfully", type = "message")
          
        }, error = function(e) {
          showNotification(
            paste("Error processing files:", e$message),
            type = "error",
            duration = NULL
          )
        })
      } else {
        req(input$dsn, input$vertex_sql, input$edge_sql)
        result <- process_graph_sql(
          dsn = input$dsn,
          vertex_sql = input$vertex_sql,
          edge_sql = input$edge_sql,
          format = "d3"
        )
        
        # Store the data
        graph_data(result)
      }
      
    }, error = function(e) {
      showNotification(
        paste("Error:", e$message),
        type = "error",
        duration = NULL
      )
    }, finally = {
      is_loading(FALSE)
    })
  })
  
  # Node search handler
  observeEvent(input$search_nodes, {
    req(graph_data(), input$node_search)
    
    data <- graph_data()
    search_pattern <- tolower(input$node_search)
    
    # Search nodes
    matching_nodes <- Filter(function(x) {
      grepl(search_pattern, tolower(x$id), fixed = TRUE)
    }, data$nodes)
    
    # Create search results table
    if (length(matching_nodes) > 0) {
      # Get unique matching nodes (latest snapshot for each)
      unique_ids <- unique(sapply(matching_nodes, function(x) x$id))
      results <- lapply(unique_ids, function(id) {
        # Get all entries for this node
        node_entries <- Filter(function(x) x$id == id, matching_nodes)
        # Get the latest entry
        latest <- node_entries[[length(node_entries)]]
        list(
          Node = latest$id,
          Weight = latest$weight,
          SubgraphWeight = latest$subgraph_weight,
          Snapshot = if ("snapshot" %in% names(latest)) latest$snapshot else NA
        )
      })
      
      results_df <- do.call(rbind.data.frame, results)
      
      # Update the search results table
      output$search_results <- renderDT({
        datatable(
          results_df,
          options = list(
            pageLength = 5,
            scrollX = TRUE,
            order = list(list(2, 'desc'))  # Sort by SubgraphWeight by default
          ),
          selection = 'single'
        ) %>%
          formatRound(columns = c('Weight', 'SubgraphWeight'), digits = 2)
      })
      
      # Handle selection of search result
      observeEvent(input$search_results_rows_selected, {
        selected_row <- input$search_results_rows_selected
        if (!is.null(selected_row)) {
          selected_node <- results_df$Node[selected_row]
          updateTextInput(session, "subgraph_root", value = selected_node)
        }
      })
    } else {
      output$search_results <- renderDT(NULL)
      showNotification("No matching nodes found", type = "warning")
    }
  })
  
  # Data summary outputs
  output$data_loaded <- reactive({
    return(!is.null(graph_data()))
  })
  outputOptions(output, "data_loaded", suspendWhenHidden = FALSE)
  
  output$total_nodes <- renderText({
    req(graph_data())
    paste("Total Nodes:", length(unique(sapply(graph_data()$nodes, function(x) x$id))))
  })
  
  output$total_edges <- renderText({
    req(graph_data())
    paste("Total Edges:", length(graph_data()$links))
  })
  
  output$total_snapshots <- renderText({
    req(graph_data())
    snapshots <- unique(sapply(graph_data()$nodes, function(x) {
      if ("snapshot" %in% names(x)) x$snapshot else NULL
    }))
    snapshots <- snapshots[!sapply(snapshots, is.null)]
    paste("Total Snapshots:", length(snapshots))
  })
  
  output$data_summary_table <- renderDT({
    req(graph_data())
    data <- graph_data()
    
    # Create comprehensive node statistics
    nodes <- data$nodes
    links <- data$links
    
    # Create a lookup for unique nodes (handling duplicates across snapshots)
    unique_nodes <- unique(sapply(nodes, function(x) x$id))
    
    # Create stats dataframe with proper atomic values
    stats_df <- do.call(rbind, lapply(unique_nodes, function(id) {
      # Get all entries for this node
      node_entries <- Filter(function(x) x$id == id, nodes)
      # Get the latest entry
      latest <- node_entries[[length(node_entries)]]
      
      # Calculate degrees
      in_degree <- sum(sapply(links, function(l) l$target == id))
      out_degree <- sum(sapply(links, function(l) l$source == id))
      
      data.frame(
        Node = id,
        Weight = as.numeric(latest$weight),
        SubgraphWeight = as.numeric(latest$subgraph_weight),
        Snapshot = if ("snapshot" %in% names(latest)) latest$snapshot else NA,
        InDegree = in_degree,
        OutDegree = out_degree,
        TotalDegree = in_degree + out_degree,
        stringsAsFactors = FALSE
      )
    }))
    
    # Format the table
    datatable(
      stats_df,
      options = list(
        pageLength = 10,
        scrollX = TRUE,
        order = list(list(2, 'desc')),  # Sort by SubgraphWeight by default
        dom = 'Bfrtip',
        buttons = c('copy', 'csv', 'excel')
      ),
      extensions = 'Buttons'
    ) %>%
      formatRound(columns = c('Weight', 'SubgraphWeight'), digits = 2)
  })
  
  # Return reactive values
  list(
    data_loaded = data_loaded,
    progress = progress
  )
}

# Graph Visualization Handler
handle_graph_visualization <- function(input, output, session, graph_data, visible_graph) {
  # Initialize snapshot choices when data is loaded
  observe({
    req(graph_data())
    data <- graph_data()
    
    # Extract snapshots from nodes
    snapshots <- unique(sapply(data$nodes, function(x) x$snapshot))
    # Remove any NULL values
    snapshots <- snapshots[!sapply(snapshots, is.null)]
    
    if (length(snapshots) > 0) {
      # Sort snapshots chronologically
      sorted_snapshots <- sort(as.character(snapshots))
      
      # Update snapshot selector
      updateSelectInput(
        session,
        "snapshot",
        choices = sorted_snapshots,
        selected = sorted_snapshots[1]
      )
      
      # Initialize root node if not already set
      if (is.null(input$subgraph_root) || input$subgraph_root == "") {
        if (!is.null(data$root_node)) {
          updateTextInput(
            session,
            "subgraph_root",
            value = as.character(data$root_node$id)
          )
        } else if (length(data$nodes) > 0) {
          # Use first node as root if no root node specified
          first_node <- data$nodes[[1]]$id
          updateTextInput(
            session,
            "subgraph_root",
            value = as.character(first_node)
          )
        }
      }
      
      # Trigger initial render after a short delay
      delay(500, {
        click("render_graph")
      })
    }
  })
  
  # Render graph when render button is clicked or snapshot changes
  observeEvent(input$render_graph, {
    req(graph_data(), input$snapshot)
    
    data <- graph_data()
    root_id <- input$subgraph_root
    current_snapshot <- input$snapshot
    
    # Validate root node
    if (is.null(root_id) || root_id == "") {
      if (!is.null(data$root_node)) {
        root_id <- data$root_node$id
      } else if (length(data$nodes) > 0) {
        root_id <- data$nodes[[1]]$id
      }
    }
    
    # Filter nodes for current snapshot
    nodes <- Filter(function(x) {
      x$snapshot == current_snapshot
    }, data$nodes)
    
    if (length(nodes) == 0) {
      showNotification("No nodes found for selected snapshot", type = "warning")
      return()
    }
    
    # Get all descendants of the root node
    edges <- Filter(function(x) {
      x$snapshot == current_snapshot
    }, data$links)
    
    # Create a list to track visited nodes
    visited <- list()
    descendants <- list()
    
    # Helper function to find descendants
    find_descendants <- function(node_id) {
      if (!is.null(visited[[node_id]])) return()
      
      visited[[node_id]] <<- TRUE
      descendants[[node_id]] <<- TRUE
      
      # Find all child edges
      child_edges <- Filter(function(x) {
        x$source == node_id
      }, edges)
      
      # Recursively process children
      for (edge in child_edges) {
        find_descendants(edge$target)
      }
    }
    
    # Find all descendants of root node
    find_descendants(root_id)
    
    # Filter nodes to include only root and descendants
    nodes <- Filter(function(x) {
      !is.null(descendants[[x$id]])
    }, nodes)
    
    # Filter edges to include only those between selected nodes
    edges <- Filter(function(x) {
      !is.null(descendants[[x$source]]) && !is.null(descendants[[x$target]])
    }, edges)
    
    # Create nodes dataframe
    nodes_df <- do.call(rbind.data.frame, lapply(nodes, function(x) {
      data.frame(
        id = as.character(x$id),
        label = as.character(x$id),
        value = as.numeric(x$weight),
        subgraph_weight = as.numeric(x$subgraph_weight),
        title = sprintf(
          "Node: %s<br>Weight: %.2f<br>Subgraph Weight: %.2f",
          x$id, x$weight, x$subgraph_weight
        ),
        stringsAsFactors = FALSE
      )
    }))
    
    # Create edges dataframe
    edges_df <- do.call(rbind.data.frame, lapply(edges, function(x) {
      data.frame(
        from = as.character(x$source),
        to = as.character(x$target),
        stringsAsFactors = FALSE
      )
    }))
    
    # Update the visible graph
    visible_graph(list(
      nodes = nodes_df,
      edges = edges_df,
      root_id = root_id,
      snapshot = current_snapshot
    ))
  })
  
  # Also trigger graph render when snapshot changes
  observeEvent(input$snapshot, {
    if (!is.null(input$snapshot) && input$snapshot != "") {
      click("render_graph")
    }
  })
  
  # Render the graph visualization
  output$graph_vis <- renderVisNetwork({
    req(visible_graph())
    data <- visible_graph()
    
    if (nrow(data$nodes) == 0) {
      return(NULL)
    }
    
    # Create the network visualization
    visNetwork(data$nodes, data$edges, width = "100%", height = "600px") %>%
      visNodes(
        size = input$node_size,
        color = list(
          background = input$node_color,
          border = "#013848",
          highlight = "#FF8000"
        ),
        font = list(size = 16)
      ) %>%
      visEdges(
        arrows = list(to = list(enabled = TRUE, scaleFactor = 1)),
        color = list(color = input$edge_color),
        smooth = list(enabled = TRUE, type = "cubicBezier")
      ) %>%
      visOptions(
        highlightNearest = list(enabled = TRUE, degree = 1),
        nodesIdSelection = TRUE
      ) %>%
      visLayout(
        randomSeed = 123,
        improvedLayout = TRUE,
        hierarchical = list(
          enabled = TRUE,
          direction = "UD",
          sortMethod = "directed",
          levelSeparation = input$level_separation,
          nodeSpacing = input$node_spacing
        )
      ) %>%
      visPhysics(
        stabilization = list(
          enabled = TRUE,
          iterations = 200
        )
      ) %>%
      visInteraction(
        dragNodes = TRUE,
        dragView = TRUE,
        zoomView = TRUE
      )
  })
  
  # Update current snapshot text
  output$current_snapshot <- renderText({
    req(input$snapshot)
    paste("Current Snapshot:", input$snapshot)
  })
}

# Node Statistics Handler
handle_node_statistics <- function(output, graph_data, visible_graph) {
  output$node_stats <- renderDT({
    req(graph_data(), visible_graph())
    
    data <- graph_data()
    visible <- visible_graph()
    
    # Create comprehensive node statistics using lapply for proper atomic values
    stats_df <- do.call(rbind, lapply(seq_along(visible$nodes$id), function(i) {
      id <- visible$nodes$id[i]
      
      # Find matching node in original data
      node_entries <- Filter(function(x) x$id == id, data$nodes)
      latest <- node_entries[[length(node_entries)]]
      
      # Calculate degrees
      in_degree <- sum(visible$edges$to == id)
      out_degree <- sum(visible$edges$from == id)
      
      data.frame(
        Node = id,
        Weight = as.numeric(visible$nodes$value[i]),
        SubgraphWeight = as.numeric(latest$subgraph_weight),
        Snapshot = if ("snapshot" %in% names(latest)) latest$snapshot else NA,
        InDegree = in_degree,
        OutDegree = out_degree,
        TotalDegree = in_degree + out_degree,
        stringsAsFactors = FALSE
      )
    }))
    
    # Format the table
    datatable(
      stats_df,
      options = list(
        pageLength = 25,
        scrollX = TRUE,
        order = list(list(2, 'desc')),  # Sort by SubgraphWeight by default
        dom = 'Bfrtip',
        buttons = c('copy', 'csv', 'excel')
      ),
      extensions = 'Buttons'
    ) %>%
      formatRound(columns = c('Weight', 'SubgraphWeight'), digits = 2)
  })
}

# Main Server Function
server <- function(input, output, session) {
  # Reactive values
  graph_data <- reactiveVal(NULL)
  visible_graph <- reactiveVal(NULL)
  is_loading <- reactiveVal(FALSE)
  
  # Initialize handlers
  handle_data_loading(input, output, session, graph_data, is_loading)
  handle_graph_visualization(input, output, session, graph_data, visible_graph)
  handle_node_statistics(output, graph_data, visible_graph)
  
  # Loading indicator
  output$loading <- renderUI({
    if (is_loading()) {
      div(
        style = "position: fixed; top: 50%; left: 50%; transform: translate(-50%, -50%);",
        h4("Loading...", style = "text-align: center;"),
        tags$div(class = "loader")
      )
    }
  })
  
  # Display current snapshot
  output$current_snapshot <- renderText({
    req(input$snapshot)
    paste("Current Snapshot:", input$snapshot)
  })
} 