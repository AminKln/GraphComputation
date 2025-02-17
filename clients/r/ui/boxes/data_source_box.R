# Data Source Box Component

#' Create a data source input box
#' 
#' @param dev_mode Boolean indicating if in development mode
#' @return A shinydashboard box containing data source inputs
data_source_box <- function(dev_mode = TRUE) {
  box(
    title = "Data Source",
    width = 12,
    status = "primary",
    solidHeader = TRUE,
    
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
      div(
        style = "border: 1px solid #ddd; padding: 15px; border-radius: 4px; margin-bottom: 15px;",
        checkboxInput(
          "use_sample_data",
          "Use sample data",
          value = TRUE
        ),
        conditionalPanel(
          condition = "!input.use_sample_data",
          div(
            style = "margin-top: 10px;",
            fileInput(
              "vertex_file",
              "Upload Vertex CSV File",
              accept = c("text/csv", ".csv"),
              buttonLabel = "Browse...",
              placeholder = "No file selected"
            ),
            fileInput(
              "edge_file",
              "Upload Edge CSV File",
              accept = c("text/csv", ".csv"),
              buttonLabel = "Browse...",
              placeholder = "No file selected"
            ),
            tags$small(
              class = "text-muted",
              "Upload CSV files with required columns: vertex, weight, snapshot for vertices; vertex_from, vertex_to, snapshot for edges"
            )
          )
        )
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
    
    # Add JavaScript for file upload validation
    tags$script("
      $(document).ready(function() {
        // Validate file uploads before loading data
        $('#load_data').on('click', function(e) {
          if ($('#data_source input:checked').val() === 'file' && !$('#use_sample_data').prop('checked')) {
            if (!$('#vertex_file').val() || !$('#edge_file').val()) {
              e.preventDefault();
              alert('Please upload both vertex and edge CSV files');
              return false;
            }
          }
        });
        
        // Clear file inputs when switching to sample data
        $('#use_sample_data').on('change', function() {
          if ($(this).prop('checked')) {
            $('#vertex_file').val('');
            $('#edge_file').val('');
          }
        });
      });
    ")
  )
} 