# Graph Visualization Handler

#' Handle graph visualization functionality
#' 
#' @param input Shiny input object
#' @param output Shiny output object
#' @param session Shiny session object
#' @param graph_data Reactive value for graph data
#' @param visible_graph Reactive value for visible graph data
#' @param vis_settings Reactive values for visualization settings
handle_graph_visualization <- function(input, output, session, graph_data, visible_graph, vis_settings) {
  # Add reactive values for metrics
  full_graph_metrics <- shiny::reactiveVal(NULL)
  
  # Source the modular components
  source("server/handlers/graph_visualization/metrics_handler.R")
  source("server/handlers/graph_visualization/graph_renderer.R")
  source("server/handlers/graph_visualization/event_handler.R")
  
  # Initialize metrics handlers
  handle_graph_metrics(input, output, session, graph_data, full_graph_metrics)
  setup_metrics_renderers(output, input, full_graph_metrics, graph_data, visible_graph)
  
  # Initialize graph renderer
  handle_graph_rendering(input, output, session, graph_data, visible_graph, vis_settings)
  
  # Initialize event handlers
  handle_graph_events(input, output, session, graph_data, visible_graph, full_graph_metrics)
  
  # Update current snapshot text
  output$current_snapshot <- shiny::renderText({
    shiny::req(input$snapshot)
    paste("Current Snapshot:", input$snapshot)
  })
} 