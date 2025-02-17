# Data Source Box Component

#' Create a data source input box
#' 
#' @param dev_mode Boolean indicating if in development mode
#' @return A shinydashboard box containing data source inputs
data_source_box <- function(dev_mode = TRUE) {
  # Default file paths for development
  project_root <- normalizePath(file.path(getwd(), "..", ".."))
  vertex_dev_path <- file.path(project_root, "sample_data", "vertices.csv")
  edge_dev_path <- file.path(project_root, "sample_data", "edges.csv")
  default_vertex_file <- if (dev_mode) {
    list(name = "vertices.csv", datapath = vertex_dev_path)
  } else NULL
  default_edge_file <- if (dev_mode) {
    list(name = "edges.csv", datapath = edge_dev_path)
  } else NULL
  
  box(
    title = "Data Source",
    width = 12,
    status = "primary",
    solidHeader = TRUE,
    
    # Debug text to show input values
    verbatimTextOutput("data_source_debug"),
    
    # Data source selection
    radioButtons(
      "data_source",
      "Select Data Source:",
      choices = list("File Upload" = "file", "SQL Query" = "sql"),
      selected = "file",
      inline = TRUE
    ),
    
    # File Upload Panel
    conditionalPanel(
      condition = "input.data_source == 'file'",
      fileInput(
        "vertex_file",
        "Upload Vertex CSV File",
        accept = c("text/csv", ".csv")
      ),
      fileInput(
        "edge_file",
        "Upload Edge CSV File",
        accept = c("text/csv", ".csv")
      ),
      checkboxInput(
        "use_sample_data",
        "Use sample data",
        value = TRUE
      )
    ),
    
    # SQL Query Panel
    conditionalPanel(
      condition = "input.data_source == 'sql'",
      textInput("dsn", "Database Connection String"),
      textAreaInput("vertex_sql", "Vertex SQL Query", rows = 3),
      textAreaInput("edge_sql", "Edge SQL Query", rows = 3)
    ),
    
    # Load Data Button
    div(
      style = "margin-top: 15px;",
      actionButton(
        "load_data",
        "Load Data",
        icon = icon("upload"),
        width = "100%",
        class = "btn-primary btn-lg"
      )
    ),
    
    # Progress Bar
    div(
      style = "margin-top: 15px;",
      uiOutput("data_loading_progress")
    ),
    
    # Debug info
    tags$script(HTML("
      $(document).ready(function() {
        $('#load_data').on('click', function() {
          console.log('Load data button clicked (jQuery)');
        });
      });
    "))
  )
} 