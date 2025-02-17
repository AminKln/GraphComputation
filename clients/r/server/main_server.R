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
  
  # Data loading state for UI
  output$data_loaded <- shiny::reactive({
    return(!is.null(graph_data()))
  })
  shiny::outputOptions(output, "data_loaded", suspendWhenHidden = FALSE)
  
  # Initialize handlers
  handle_data_loading(input, output, session, graph_data, is_loading)
  handle_data_summary(input, output, session, graph_data)
  handle_graph_visualization(input, output, session, graph_data, visible_graph)
  handle_node_statistics(input, output, session, graph_data, visible_graph)
  
  message("[SERVER] Application initialized")
} 