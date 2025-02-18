# Graph Event Handler

#' Handle graph events
#' 
#' @param input Shiny input object
#' @param output Shiny output object
#' @param session Shiny session object
#' @param graph_data Reactive value for graph data
#' @param visible_graph Reactive value for visible graph data
#' @param full_graph_metrics Reactive value for full graph metrics
handle_graph_events <- function(input, output, session, graph_data, visible_graph, full_graph_metrics) {
  # Handle node selection from data table
  shiny::observeEvent(input$selected_node, {
    if (!is.null(input$selected_node)) {
      message("[DEBUG] Node selected from data table:", input$selected_node)
      # Highlight the selected node in the graph
      session$sendCustomMessage(type = "visnetwork-highlight", 
                              message = list(node = input$selected_node))
    }
  })
  
  # Handle node search selection
  shiny::observeEvent(input$search_nodes, {
    shiny::req(graph_data(), input$node_search)
    
    # Find matching nodes
    search_pattern <- tolower(input$node_search)
    matching_nodes <- Filter(function(x) {
      grepl(search_pattern, tolower(x$id), fixed = TRUE)
    }, graph_data()$nodes)
    
    if (length(matching_nodes) > 0) {
      message("[DEBUG] Found matching nodes:", length(matching_nodes))
    }
  })
  
  # Handle snapshot changes
  shiny::observeEvent(input$snapshot, {
    shiny::req(input$snapshot, input$subgraph_root)
    # Trigger graph render when snapshot changes
    shiny::updateActionButton(session, "render_graph", label = "Render Subgraph")
    session$sendCustomMessage(type = "shinyjs-click", message = "#render_graph")
  })
  
  # Handle reset graph button
  shiny::observeEvent(input$reset_graph, {
    shiny::req(graph_data(), input$snapshot, full_graph_metrics())
    
    # Get the root node from full graph metrics
    metrics <- full_graph_metrics()
    if (!is.null(metrics$root_node)) {
      message("[RESET] Using root node from metrics:", metrics$root_node)
      
      # Update the root node input
      shiny::updateTextInput(
        session,
        "subgraph_root",
        value = metrics$root_node
      )
      
      # Set max depth to a larger value to see more of the graph
      shiny::updateSliderInput(
        session,
        "max_depth",
        value = 5  # Increased depth for better overview
      )
      
      # Update button label
      shiny::updateActionButton(session, "render_graph", label = "Render Full Graph")
    } else {
      message("[RESET] No root node in metrics, showing error")
      shiny::showNotification(
        "Could not determine root node from graph metrics",
        type = "error"
      )
    }
  })
  
  # Handle node selection from search or statistics
  shiny::observeEvent(input$selected_graph_node, {
    if (!is.null(input$selected_graph_node)) {
      # Send message to highlight the node in the graph
      session$sendCustomMessage(type = "visnetwork-highlight", 
                              message = list(node = input$selected_graph_node))
    }
  })
  
  # Handle root node selection from full graph metrics
  shiny::observeEvent(input$set_root_from_full, {
    shiny::req(full_graph_metrics())
    metrics <- full_graph_metrics()
    if (!is.null(metrics$root_node)) {
      shiny::updateTextInput(
        session,
        "subgraph_root",
        value = metrics$root_node
      )
      # Trigger graph render
      shiny::updateActionButton(session, "render_graph", label = "Render Subgraph")
      session$sendCustomMessage(type = "shinyjs-click", message = "#render_graph")
    }
  })
  
  # Handle root node selection from subgraph metrics
  shiny::observeEvent(input$set_root_from_sub, {
    shiny::req(visible_graph())
    data <- visible_graph()
    if (!is.null(data$metrics) && !is.null(data$metrics$root_node)) {
      shiny::updateTextInput(
        session,
        "subgraph_root",
        value = data$metrics$root_node
      )
      # Trigger graph render
      shiny::updateActionButton(session, "render_graph", label = "Render Subgraph")
      session$sendCustomMessage(type = "shinyjs-click", message = "#render_graph")
    }
  })
} 