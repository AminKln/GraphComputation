# Node Statistics Handler

#' Handle node statistics functionality
#' 
#' @param input Shiny input object
#' @param output Shiny output object
#' @param session Shiny session object
#' @param graph_data Reactive value for graph data
#' @param visible_graph Reactive value for visible graph data
handle_node_statistics <- function(input, output, session, graph_data, visible_graph) {
  # Create reactive value to store current search results
  current_search_results <- shiny::reactiveVal(NULL)
  
  # Node statistics table
  output$node_stats <- DT::renderDT({
    shiny::req(visible_graph())
    
    # Get the metrics from the API response
    data <- visible_graph()
    if (is.null(data$metrics) || is.null(data$metrics$node_metrics)) {
      return(NULL)
    }
    
    # Create the table from API metrics
    stats_df <- do.call(rbind.data.frame, data$metrics$node_metrics)
    
    # Format the table
    DT::datatable(
      stats_df,
      options = list(
        pageLength = 25,
        scrollX = TRUE,
        order = list(list(2, 'desc')),  # Sort by Weight by default
        dom = 'Bfrtip',
        buttons = c('copy', 'csv', 'excel'),
        rownames = FALSE  # Remove row numbers
      ),
      selection = 'single',  # Enable single row selection
      extensions = 'Buttons'
    ) %>%
      DT::formatRound(columns = c('Weight', 'Degree', 'Betweenness', 'Closeness', 'Eigenvector', 'ClusteringCoeff'), digits = 2)
  })
  
  # Handle node statistics selection
  shiny::observeEvent(input$node_stats_rows_selected, {
    message("[DEBUG] Node stats row selected:", input$node_stats_rows_selected)
    shiny::req(visible_graph(), input$node_stats_rows_selected)
    selected_row <- input$node_stats_rows_selected
    
    if (!is.null(selected_row)) {
      data <- visible_graph()
      if (!is.null(data$metrics) && !is.null(data$metrics$node_metrics)) {
        stats_df <- do.call(rbind.data.frame, data$metrics$node_metrics)
        if (selected_row <= nrow(stats_df)) {
          selected_node <- stats_df$Node[selected_row]
          message("[DEBUG] Selected node from stats:", selected_node)
          
          # Highlight the selected node in the graph
          session$sendCustomMessage(type = "visnetwork-highlight", 
                                  message = list(node = selected_node))
        }
      }
    }
  })
  
  # Node search handler
  shiny::observeEvent(input$search_nodes, {
    message("[DEBUG] Search button clicked")
    shiny::req(graph_data(), input$node_search)
    
    data <- graph_data()
    search_pattern <- tolower(input$node_search)
    message("[DEBUG] Searching for pattern:", search_pattern)
    
    # Search nodes
    matching_nodes <- Filter(function(x) {
      grepl(search_pattern, tolower(x$id), fixed = TRUE)
    }, data$nodes)
    
    # Create search results table
    if (length(matching_nodes) > 0) {
      message("[DEBUG] Found", length(matching_nodes), "matching nodes")
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
          Snapshot = if ("snapshot" %in% names(latest)) latest$snapshot else NA
        )
      })
      
      results_df <- do.call(rbind.data.frame, results)
      
      # Store current search results
      current_search_results(results_df)
      
      # Update the search results table
      output$search_results <- DT::renderDT({
        DT::datatable(
          results_df,
          options = list(
            pageLength = 5,
            scrollX = TRUE,
            order = list(list(2, 'desc')),  # Sort by Weight by default
            rownames = FALSE  # Remove row numbers
          ),
          selection = 'single',  # Enable single row selection
          extensions = 'Buttons'
        ) %>%
          DT::formatRound(columns = c('Weight'), digits = 2)
      })
    } else {
      message("[DEBUG] No matching nodes found")
      current_search_results(NULL)
      output$search_results <- DT::renderDT(NULL)
      shiny::showNotification("No matching nodes found", type = "warning")
    }
  })
  
  # Handle search result selection
  shiny::observeEvent(input$search_results_rows_selected, {
    message("[DEBUG] Search results row selected:", input$search_results_rows_selected)
    shiny::req(input$search_results_rows_selected, current_search_results())
    selected_row <- input$search_results_rows_selected
    
    if (!is.null(selected_row)) {
      # Get the selected node from the current search results
      results_data <- current_search_results()
      if (!is.null(results_data) && selected_row <= nrow(results_data)) {
        selected_node <- results_data$Node[selected_row]
        message("[DEBUG] Selected node from search:", selected_node)
        
        # Highlight the selected node in the graph
        session$sendCustomMessage(type = "visnetwork-highlight", 
                                message = list(node = selected_node))
      }
    }
  })
  
  # Handle Set as Root button click
  shiny::observeEvent(input$set_root_node, {
    message("[DEBUG] Set as Root button clicked")
    shiny::req(input$search_results_rows_selected, current_search_results())
    selected_row <- input$search_results_rows_selected
    
    if (!is.null(selected_row)) {
      results_data <- current_search_results()
      if (!is.null(results_data) && selected_row <= nrow(results_data)) {
        selected_node <- results_data$Node[selected_row]
        message("[DEBUG] Setting root node to:", selected_node)
        
        # Update the subgraph root and trigger render
        shiny::updateTextInput(session, "subgraph_root", value = selected_node)
        shiny::updateActionButton(session, "render_graph", label = "Render Subgraph")
        session$sendCustomMessage(type = "shinyjs-click", message = "#render_graph")
      }
    }
  })
  
  # Handle highlight button click
  shiny::observeEvent(input$highlight_node, {
    message("[DEBUG] Highlight button clicked")
    shiny::req(input$search_results_rows_selected, current_search_results())
    selected_row <- input$search_results_rows_selected
    
    if (!is.null(selected_row)) {
      results_data <- current_search_results()
      if (!is.null(results_data) && selected_row <= nrow(results_data)) {
        selected_node <- results_data$Node[selected_row]
        message("[DEBUG] Highlighting node:", selected_node)
        
        # Highlight the selected node in the graph
        session$sendCustomMessage(type = "visnetwork-highlight", 
                                message = list(node = selected_node))
        
        # Focus on the node in the graph
        session$sendCustomMessage(type = "visnetwork-focus", 
                                message = list(node = selected_node))
      }
    }
  })
  
  # Add JavaScript to ensure button clicks are captured
  shiny::insertUI(
    selector = "head",
    where = "beforeEnd",
    ui = tags$script("
      $(document).ready(function() {
        // Ensure button clicks are properly handled
        $(document).on('click', '#highlight_node', function() {
          Shiny.setInputValue('highlight_node', Math.random());
        });
        
        $(document).on('click', '#set_root_node', function() {
          Shiny.setInputValue('set_root_node', Math.random());
        });
      });
      
      // Add custom message handler for focusing on nodes
      Shiny.addCustomMessageHandler('visnetwork-focus', function(message) {
        var network = document.getElementById('graph_vis').network;
        if (network && message.node) {
          network.focus(message.node, {
            scale: 1.0,
            animation: {
              duration: 500,
              easingFunction: 'easeInOutQuad'
            }
          });
        }
      });
    ")
  )
} 