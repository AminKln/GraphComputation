# Set working directory to the script's location
if (interactive()) {
  # If running in RStudio, use the source file location
  app_dir <- dirname(rstudioapi::getSourceEditorContext()$path)
  message(sprintf("[CONFIG] Setting working directory from RStudio: %s", app_dir))
  setwd(app_dir)
} else {
  # If running from command line or deployed, use the script's location
  app_dir <- dirname(sys.frame(1)$ofile)
  message(sprintf("[CONFIG] Setting working directory from script: %s", app_dir))
  setwd(app_dir)
}

# Install and load renv if not already installed
if (!require("renv", quietly = TRUE)) {
  install.packages("renv")
  library(renv)
}

# Remove existing renv files if they exist
unlink("renv", recursive = TRUE)
unlink(".Rprofile")
unlink("renv.lock")

# Initialize a new renv environment
renv::init(bare = TRUE, force = TRUE)

# Create .Rprofile with proper content
renv_profile <- sprintf('source("%s")', file.path(getwd(), "renv/activate.R"))
writeLines(renv_profile, ".Rprofile")

# Define package versions
packages <- c(
  "shiny@1.7.5",           # Core Shiny framework
  "shinydashboard@0.7.2",  # Dashboard UI components
  "DT@0.27",              # Interactive tables
  "visNetwork@2.1.2",     # Network visualization
  "colourpicker@1.2.0",   # Color selection widget
  "shinyjs@2.1.0",        # JavaScript operations in Shiny
  "httr@1.4.6",           # HTTP requests
  "jsonlite@1.8.5",       # JSON handling
  "dplyr@1.1.3",          # Data manipulation
  "webshot@0.5.5",        # Widget screenshots
  "rstudioapi@0.15.0"     # RStudio API for working directory
)

# Install packages
message("Installing required packages...")
for (package in packages) {
  message(sprintf("Installing %s...", package))
  renv::install(package, prompt = FALSE)
}

# Load all packages to verify installation
message("\nLoading packages...")
loaded_packages <- sapply(strsplit(packages, "@"), function(x) x[1])
for (package in loaded_packages) {
  message(sprintf("Loading %s...", package))
  if (!require(package, character.only = TRUE)) {
    stop(sprintf("Failed to load package: %s", package))
  }
}

# Install PhantomJS for webshot if needed
if (!webshot::is_phantomjs_installed()) {
  message("Installing PhantomJS for widget screenshots...")
  webshot::install_phantomjs()
}

# Create renv.lock file
renv::snapshot(prompt = FALSE)

# Verify renv is properly activated
if (!renv::status()$activated) {
  stop("renv environment is not properly activated!")
}

# Print environment information
message("\nEnvironment Information:")
message(sprintf("renv activated: %s", renv::status()$activated))
message(sprintf("Project directory: %s", getwd()))
message(sprintf("Library path: %s", .libPaths()[1]))

message("\nTo use this environment:")
message("1. Start R in this directory")
message("2. The environment will be automatically activated")
message("3. Run the app with: source('app.R')")
message("\nTo verify the environment is active, check that .libPaths()[1] points to:")
message(file.path(getwd(), "renv/library/R-4.3/x86_64-w64-mingw32")) 
