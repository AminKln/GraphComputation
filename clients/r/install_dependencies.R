# Install required packages if not already installed

# Function to install packages if they're not already installed
install_if_missing <- function(package_name) {
  if (!require(package_name, character.only = TRUE)) {
    install.packages(package_name)
    library(package_name, character.only = TRUE)
  }
}

# List of required packages
required_packages <- c(
  "shiny",
  "shinydashboard",
  "visNetwork",
  "dplyr",
  "httr",
  "jsonlite",
  "DT",
  "colourpicker"
)

# Install and load each package
for (package in required_packages) {
  cat(sprintf("Installing/loading package: %s\n", package))
  install_if_missing(package)
}

cat("\nAll required packages have been installed and loaded.\n")

# Required packages
packages <- c(
  # Core packages
  "shiny",
  "visNetwork",
  "dplyr",
  "tidyr",
  "httr",
  "jsonlite",
  "DT",
  "shinydashboard",
  "shinythemes",
  "colourpicker",
  
  # Visualization packages
  "ggplot2",
  "plotly",
  "networkD3",
  "htmlwidgets",
  
  # Analysis packages
  "igraph",
  "statnet",
  "sna",
  "RColorBrewer",
  "intergraph",
  
  # Export and formatting
  "writexl",
  "openxlsx",
  "svglite",
  "webshot"
)

# Function to install missing packages
install_if_missing <- function(package) {
  if (!require(package, character.only = TRUE)) {
    message(sprintf("Installing package: %s", package))
    install.packages(package, dependencies = TRUE)
  } else {
    message(sprintf("Package already installed: %s", package))
  }
}

# Install packages
message("Checking and installing required packages...")
sapply(packages, install_if_missing)

# Install webshot PhantomJS for saving widget screenshots
if (!webshot::is_phantomjs_installed()) {
  message("Installing PhantomJS for widget screenshots...")
  webshot::install_phantomjs()
}

# Verify installations
missing_packages <- packages[!sapply(packages, require, character.only = TRUE)]

if (length(missing_packages) > 0) {
  stop(sprintf(
    "Failed to install the following packages: %s",
    paste(missing_packages, collapse = ", ")
  ))
} else {
  message("All required packages are installed successfully!")
} 
