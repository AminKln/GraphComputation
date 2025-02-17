# Main Application File

# Set working directory to the app's location
tryCatch({
  if (interactive()) {
    # If running in RStudio, use the source file location
    app_dir <- dirname(rstudioapi::getSourceEditorContext()$path)
    message(sprintf("[CONFIG] Setting working directory from RStudio: %s", app_dir))
  } else {
    # If running from command line or deployed, use the script's location
    app_dir <- dirname(sys.frame(1)$ofile)
    message(sprintf("[CONFIG] Setting working directory from script: %s", app_dir))
  }
  setwd(app_dir)
  message(sprintf("[CONFIG] Working directory set to: %s", getwd()))
}, error = function(e) {
  message(sprintf("[CONFIG] Error setting working directory: %s", e$message))
  message("[CONFIG] Continuing with current working directory: ", getwd())
})

# Load required libraries with error checking
required_packages <- c("shiny", "shinydashboard", "DT", "visNetwork", 
                       "shinyjs", "httr", "jsonlite", "dplyr", "later")#, 'colourpicker')

for (pkg in required_packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    message(sprintf("[CONFIG] Error: Package %s is not installed!", pkg))
    stop(sprintf("Please install package %s before running the app", pkg))
  }
  message(sprintf("[CONFIG] Successfully loaded package: %s", pkg))
}

# Enable debugging and logging
options(shiny.debug = FALSE)  # Disable default debug mode
options(shiny.trace = FALSE)  # Disable trace mode
options(shiny.fullstacktrace = TRUE)  # Keep full stack trace for errors
options(shiny.error = browser)
options(shiny.suppressMissingContextError = TRUE)  # Suppress WebSocket context errors

# Source configuration
source("config.R")

# Source UI components
source("ui/main_ui.R")

# Source server components
source("server/main_server.R")

# Configure Shiny options for better connection handling
options(shiny.maxRequestSize = 100*1024^2)  # Set max request size to 100MB
options(shiny.websocket.timeout = 3600)     # Set WebSocket timeout to 1 hour
options(shiny.autoreload = TRUE)            # Enable auto-reload on disconnect
options(shiny.launch.browser = TRUE)        # Ensure browser launches
options(shiny.reconnect = TRUE)             # Enable reconnection

# Create and run the Shiny application
app <- shinyApp(ui = ui(), server = server)

# Run with specific host and port for better stability
runApp(app, 
       host = "127.0.0.1",
       port = 3838,
       display.mode = "normal",
       launch.browser = TRUE)
