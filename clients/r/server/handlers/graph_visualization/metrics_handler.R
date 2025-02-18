# Graph Metrics Handler

# At the top of the file, source the utility functions
source("server/utils/graph_metrics_utils.R")

#' Handle graph metrics functionality
#' 
#' @param input Shiny input object
#' @param output Shiny output object
#' @param session Shiny session object
#' @param graph_data Reactive value for graph data
#' @param full_graph_metrics Reactive value for full graph metrics
handle_graph_metrics <- function(input, output, session, graph_data, full_graph_metrics) {
  # Initialize and get full graph metrics when data is loaded
  shiny::observe({
    shiny::req(graph_data())
    data <- graph_data()
    
    # Extract and validate snapshots
    snapshots <- unique(sapply(data$nodes, function(x) x$snapshot))
    snapshots <- snapshots[!sapply(snapshots, is.null)]
    
    if (length(snapshots) > 0) {
      # Sort snapshots chronologically
      sorted_snapshots <- sort(as.character(snapshots))
      
      # Get full graph metrics from API
      tryCatch({
        message("[DEBUG] Getting initial full graph metrics")
        
        # Prepare request body
        request_body <- list(
          source = list(
            type = "file",
            vertex_data = data$nodes,
            edge_data = data$links
          ),
          snapshot = sorted_snapshots[1]
        )
        
        # Log request details (concise)
        message("[DEBUG] Making API request to:", paste0(API_CONFIG$base_url, "/api/v1/graph_metrics"))
        
        response <- httr::POST(
          paste0(API_CONFIG$base_url, "/api/v1/graph_metrics"),
          body = request_body,
          encode = "json"
        )
        
        # Log response status
        message("[DEBUG] Response status:", httr::status_code(response))
        
        if (!httr::http_error(response)) {
          metrics <- jsonlite::fromJSON(
            httr::content(response, "text", encoding = "UTF-8"),
            simplifyVector = FALSE
          )
          
          # Log only essential metrics info
          message("[DEBUG] Received metrics - Root node:", metrics$root_node,
                 "Total nodes:", metrics$total_nodes,
                 "Total edges:", metrics$total_edges)
          
          full_graph_metrics(metrics)
          
          # Set initial root node from metrics
          if (!is.null(metrics$root_node)) {
            message("[DEBUG] Setting initial root node to:", metrics$root_node)
            shiny::updateTextInput(
              session,
              "subgraph_root",
              value = metrics$root_node
            )
          }
        }
      }, error = function(e) {
        message("[METRICS] Error getting full graph metrics:", e$message)
      })
    }
  })
  
  # Update metrics when snapshot changes
  shiny::observeEvent(input$snapshot, {
    shiny::req(graph_data(), input$snapshot)
    
    # Get updated metrics for new snapshot
    tryCatch({
      message("[DEBUG] Requesting metrics for snapshot:", input$snapshot)
      
      response <- httr::POST(
        paste0(API_CONFIG$base_url, "/api/v1/graph_metrics"),
        body = list(
          source = list(
            type = "file",
            vertex_data = graph_data()$nodes,
            edge_data = graph_data()$links
          ),
          snapshot = input$snapshot
        ),
        encode = "json"
      )
      
      if (!httr::http_error(response)) {
        metrics <- jsonlite::fromJSON(
          httr::content(response, "text", encoding = "UTF-8"),
          simplifyVector = FALSE
        )
        message("[DEBUG] Received metrics:", jsonlite::toJSON(metrics, auto_unbox = TRUE))
        full_graph_metrics(metrics)
        
        # Update root node if it exists in metrics
        if (!is.null(metrics$root_node)) {
          message("[DEBUG] Updating root node to:", metrics$root_node)
          shiny::updateTextInput(
            session,
            "subgraph_root",
            value = metrics$root_node
          )
          
          # Update button label
          shiny::updateActionButton(session, "render_graph", label = "Render Subgraph")
        }
      }
    }, error = function(e) {
      message("[METRICS] Error updating metrics for new snapshot:", e$message)
    })
  })
}

#' Setup metrics output renderers
#' 
#' @param output Shiny output object
#' @param input Shiny input object
#' @param full_graph_metrics Reactive value for full graph metrics
#' @param graph_data Reactive value for graph data
#' @param visible_graph Reactive value for visible graph data
setup_metrics_renderers <- function(output, input, full_graph_metrics, graph_data, visible_graph) {
  # Render full graph metrics
  output$full_graph_total_nodes <- shiny::renderText({
    shiny::req(full_graph_metrics())
    metrics <- full_graph_metrics()
    metrics$total_nodes
  })
  
  output$full_graph_total_edges <- shiny::renderText({
    shiny::req(full_graph_metrics())
    metrics <- full_graph_metrics()
    metrics$total_edges
  })
  
  output$full_graph_total_depth <- shiny::renderText({
    shiny::req(full_graph_metrics(), graph_data())
    metrics <- full_graph_metrics()
    
    # Get the depth either from metrics or calculate it
    if (!is.null(metrics$max_depth)) {
      metrics$max_depth
    } else {
      calculate_graph_max_depth(graph_data()$nodes, graph_data()$links)
    }
  })
  
  output$full_graph_displayed_nodes <- shiny::renderText({
    shiny::req(visible_graph(), graph_data(), input$snapshot, input$subgraph_root, input$max_depth)
    
    # Calculate metrics with depth constraint
    metrics <- calculate_displayed_subgraph_metrics(
      graph_data()$nodes,
      graph_data()$links,
      input$subgraph_root,
      input$snapshot,
      as.numeric(input$max_depth)
    )
    metrics$nodes
  })
  
  output$full_graph_displayed_edges <- shiny::renderText({
    shiny::req(visible_graph(), graph_data(), input$snapshot, input$subgraph_root, input$max_depth)
    
    # Calculate metrics with depth constraint
    metrics <- calculate_displayed_subgraph_metrics(
      graph_data()$nodes,
      graph_data()$links,
      input$subgraph_root,
      input$snapshot,
      as.numeric(input$max_depth)
    )
    metrics$edges
  })
  
  output$full_graph_displayed_depth <- shiny::renderText({
    shiny::req(visible_graph(), graph_data(), input$snapshot, input$subgraph_root, input$max_depth)
    
    # Calculate metrics with depth constraint
    metrics <- calculate_displayed_subgraph_metrics(
      graph_data()$nodes,
      graph_data()$links,
      input$subgraph_root,
      input$snapshot,
      as.numeric(input$max_depth)
    )
    metrics$depth
  })
  
  output$full_graph_root <- shiny::renderText({
    shiny::req(full_graph_metrics())
    metrics <- full_graph_metrics()
    metrics$root_node
  })
  
  # Render subgraph metrics
  output$subgraph_total_nodes <- shiny::renderText({
    shiny::req(visible_graph(), graph_data(), input$snapshot, input$subgraph_root)
    data <- visible_graph()
    
    # Calculate full potential subgraph metrics
    metrics <- calculate_full_subgraph_metrics(
      graph_data()$nodes,
      graph_data()$links,
      input$subgraph_root,
      input$snapshot
    )
    metrics$nodes
  })
  
  output$subgraph_total_edges <- shiny::renderText({
    shiny::req(visible_graph(), graph_data(), input$snapshot, input$subgraph_root)
    data <- visible_graph()
    
    # Calculate full potential subgraph metrics
    metrics <- calculate_full_subgraph_metrics(
      graph_data()$nodes,
      graph_data()$links,
      input$subgraph_root,
      input$snapshot
    )
    metrics$edges
  })
  
  output$subgraph_total_depth <- shiny::renderText({
    shiny::req(visible_graph(), graph_data(), input$snapshot, input$subgraph_root)
    data <- visible_graph()
    
    # Calculate full potential subgraph metrics
    metrics <- calculate_full_subgraph_metrics(
      graph_data()$nodes,
      graph_data()$links,
      input$subgraph_root,
      input$snapshot
    )
    metrics$depth
  })
  
  output$subgraph_root <- shiny::renderText({
    shiny::req(visible_graph())
    data <- visible_graph()
    if (!is.null(data$metrics)) {
      data$metrics$root_node
    } else if (!is.null(data$root_id)) {
      data$root_id
    }
  })
} 