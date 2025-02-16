# Load required libraries
library(shiny)
library(visNetwork)
library(dplyr)
library(tidyr)
library(httr)
library(jsonlite)
library(DT)
library(shinydashboard)
library(shinythemes)
library(ggplot2)
library(plotly)
library(igraph)
library(networkD3)
library(htmlwidgets)
library(colourpicker)

# Global Configuration
API_BASE_URL <- "http://localhost:5000"

# Source helper functions and modules
source("R/api.R")
source("R/utils.R")
source("R/ui_components.R")
source("R/server_components.R") 