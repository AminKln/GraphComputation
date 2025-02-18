# Configuration File

#' Global configuration settings
options(
  # Shiny options
  shiny.maxRequestSize = 100 * 1024^2,  # Set max file upload size to 100MB
  shiny.debug = FALSE,                    # Enable debugging in development
  
  # DT options
  DT.options = list(
    pageLength = 25,
    lengthMenu = list(c(10, 25, 50, -1), c('10', '25', '50', 'All')),
    dom = 'Bfrtip',
    buttons = c('copy', 'csv', 'excel')
  )
)

#' UI Configuration
UI_CONFIG <- list(
  # Graph visualization settings
  graph = list(
    node_size = list(
      default = 25,
      min = 10,
      max = 50,
      step = 5
    ),
    node_color = list(
      default = "#97C2FC",
      highlight = "#FF8000"
    ),
    edge_color = list(
      default = "#2B7CE9",
      highlight = "#FF8000"
    ),
    level_separation = list(
      default = 150,
      min = 50,
      max = 300,
      step = 10
    )
  ),
  
  # Table settings
  table = list(
    page_length = 25,
    max_rows = 1000,
    decimal_places = 2
  ),
  
  # Color scheme
  colors = list(
    primary = "#3c8dbc",
    success = "#00a65a",
    warning = "#f39c12",
    danger = "#dd4b39",
    info = "#00c0ef"
  )
)

#' Logging Configuration
LOG_CONFIG <- list(
  enabled = TRUE,
  level = "DEBUG",
  file = "logs/app.log",
  max_size = 5 * 1024^2,  # 5MB
  max_files = 5
)

#' Main Configuration
CONFIG <- list(
  # API settings
  api = list(
    base_url = "http://localhost:5000",
    timeout = 30,
    retry_attempts = 3,
    retry_delay = 1
  ),
  
  # File paths
  paths = list(
    sample_data_path = "sample_data",
    logs_path = "logs",
    temp_path = "temp"
  ),
  
  # UI settings
  ui = UI_CONFIG,
  
  # Logging settings
  logging = LOG_CONFIG
)

#' API Configuration (for backward compatibility)
API_CONFIG <- CONFIG$api

#' File paths
FILE_PATHS <- list(
  sample_data = list(
    vertices = file.path(CONFIG$paths$sample_data_path, "vertices.csv"),
    edges = file.path(CONFIG$paths$sample_data_path, "edges.csv")
  ),
  logs = CONFIG$paths$logs_path,
  temp = CONFIG$paths$temp_path
)

#' Create required directories
dir.create(FILE_PATHS$logs, showWarnings = FALSE, recursive = TRUE)
dir.create(FILE_PATHS$temp, showWarnings = FALSE, recursive = TRUE)

#' Initialize logging
if (LOG_CONFIG$enabled) {
  if (!dir.exists(dirname(LOG_CONFIG$file))) {
    dir.create(dirname(LOG_CONFIG$file), recursive = TRUE)
  }
}

#' Print configuration status
message("[CONFIG] Configuration loaded successfully")
message(sprintf("[CONFIG] API base URL: %s", API_CONFIG$base_url))
message(sprintf("[CONFIG] Logging enabled: %s", LOG_CONFIG$enabled))
message(sprintf("[CONFIG] Debug mode: %s", getOption("shiny.debug"))) 