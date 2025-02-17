# Main Server Component

# Import required packages
library(shiny)
library(shinyjs)
library(DT)
library(visNetwork)
library(httr)
library(jsonlite)
library(dplyr)

#' Import required server components
tryCatch({
  source(file.path(getwd(), "server/handlers/data_loading_handler.R"))
  source(file.path(getwd(), "server/handlers/data_summary_handler.R"))
  source(file.path(getwd(), "server/handlers/graph_visualization_handler.R"))
  source(file.path(getwd(), "server/handlers/node_statistics_handler.R"))
  source(file.path(getwd(), "server/handlers/node_search_handler.R"))
  source(file.path(getwd(), "server/handlers/visualization_settings_handler.R"))
}, error = function(e) {
  message("[SERVER] Error loading handlers:", e$message)
  stop("Failed to load required server components")
})

#' Main server function
#' 
#' @param input Shiny input object
#' @param output Shiny output object
#' @param session Shiny session object
server <- function(input, output, session) {
  # Enable shinyjs and initialize session
  shinyjs::useShinyjs()
  
  # Add connection status tracking
  session$allowReconnect(TRUE)
  
  # Handle disconnections gracefully
  onDisconnected <- function() {
    message("[SERVER] Client disconnected")
  }
  session$onSessionEnded(onDisconnected)
  
  # Initialize reactive values
  graph_data <- shiny::reactiveVal(NULL)
  visible_graph <- shiny::reactiveVal(NULL)
  is_loading <- shiny::reactiveVal(FALSE)
  
  # Initialize visualization settings
  vis_settings <- shiny::reactiveValues(
    node_size = 25,
    level_separation = 150,
    node_color = "#97C2FC",
    edge_color = "#2B7CE9"
  )
  
  # Data loading state for UI
  output$data_loaded <- shiny::reactive({
    return(!is.null(graph_data()))
  })
  shiny::outputOptions(output, "data_loaded", suspendWhenHidden = FALSE)
  
  # Initialize handlers
  handle_data_loading(input, output, session, graph_data, is_loading)
  handle_data_summary(input, output, session, graph_data)
  handle_graph_visualization(input, output, session, graph_data, visible_graph, vis_settings)
  handle_node_statistics(input, output, session, graph_data, visible_graph)
  handle_node_search(input, output, session, graph_data, visible_graph)
  handle_visualization_settings(input, output, session, vis_settings)
  
  message("[SERVER] Application initialized")
} 