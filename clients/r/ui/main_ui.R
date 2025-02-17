# Main UI Component

#' Import required UI components
source(file.path(getwd(), "ui/boxes/data_source_box.R"))
source(file.path(getwd(), "ui/boxes/data_summary_box.R"))
source(file.path(getwd(), "ui/boxes/graph_analysis_box.R"))
source(file.path(getwd(), "ui/boxes/node_search_box.R"))
source(file.path(getwd(), "ui/boxes/node_stats_box.R"))
source(file.path(getwd(), "ui/boxes/settings_box.R"))
source(file.path(getwd(), "ui/components/progress_bar.R"))
source(file.path(getwd(), "ui/styles/app_styles.R"))

#' Create the main UI of the application
#' 
#' @return A dashboardPage containing the complete UI
ui <- function() {
  dashboardPage(
    # Header
    dashboardHeader(title = "Graph Analysis Tool"),
    
    # Sidebar
    dashboardSidebar(
      sidebarMenu(
        menuItem("Data Loading", tabName = "data", icon = icon("database")),
        menuItem("Graph Analysis", tabName = "graph", icon = icon("project-diagram")),
        menuItem("Settings", tabName = "settings", icon = icon("cog"))
      )
    ),
    
    # Body
    dashboardBody(
      # Enable shinyjs
      shinyjs::useShinyjs(),
      
      # Add custom styles
      tags$head(
        tags$style(app_styles)
      ),
      
      # Loading indicator
      uiOutput("loading"),
      
      # Debug output for development
      verbatimTextOutput("debug_output"),
      
      tabItems(
        # Data Loading Tab
        tabItem(
          tabName = "data",
          fluidRow(
            column(
              width = 12,
              div(
                id = "data_source_container",
                data_source_box()
              ),
              div(
                id = "data_summary_container",
                data_summary_box()
              )
            )
          )
        ),
        
        # Graph Analysis Tab
        tabItem(
          tabName = "graph",
          fluidRow(
            column(
              width = 3,
              div(
                id = "node_search_container",
                node_search_box()
              ),
              div(
                id = "node_stats_container",
                node_stats_box()
              )
            ),
            column(
              width = 9,
              div(
                id = "graph_analysis_container",
                graph_analysis_box()
              )
            )
          )
        ),
        
        # Settings Tab
        tabItem(
          tabName = "settings",
          fluidRow(
            column(
              width = 12,
              div(
                id = "settings_container",
                settings_box()
              )
            )
          )
        )
      )
    )
  )
} 