# Main Application File

# Set working directory to the app's location
setwd(dirname(rstudioapi::getSourceEditorContext()$path))

# Load required libraries
library(shiny)
library(shinydashboard)
library(visNetwork)
library(dplyr)
library(httr)
library(jsonlite)
library(DT)
library(colourpicker)

# Set global configuration
API_BASE_URL <- "http://localhost:5000"

# Source module files
source("R/api.R")
source("R/utils.R")
source("R/ui_components.R")
source("R/server_components.R")

# Run the application
shinyApp(ui = ui(), server = server) 