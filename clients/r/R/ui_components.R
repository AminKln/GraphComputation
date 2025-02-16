# UI Components

# Data Source Box
data_source_box <- function() {
  # Development mode flag
  DEV_MODE <- TRUE
  
  # Default file paths for development
  default_vertex_file <- if (DEV_MODE) list(name = "vertices.csv", datapath = "sample_data/vertices.csv") else NULL
  default_edge_file <- if (DEV_MODE) list(name = "edges.csv", datapath = "sample_data/edges.csv") else NULL
  
  box(
    title = "Data Source",
    width = 12,
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
      # Add a checkbox for using sample data
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
    
    actionButton(
      "load_data",
      "Load Data",
      icon = icon("upload"),
      class = "btn-primary"
    ),
    
    # Progress Bar
    uiOutput("data_loading_progress")
  )
}

# Data Summary Box
data_summary_box <- function() {
  box(
    title = "Data Summary",
    width = 12,
    conditionalPanel(
      condition = "output.data_loaded",
      div(
        class = "data-summary",
        div(
          style = "display: flex; justify-content: space-between; margin-bottom: 15px;",
          div(textOutput("total_nodes")),
          div(textOutput("total_edges")),
          div(textOutput("total_snapshots"))
        ),
        div(
          style = "overflow-x: auto;",
          dataTableOutput("data_summary_table")
        )
      )
    )
  )
}

# Graph Analysis Box
graph_analysis_box <- function() {
  box(
    title = "Graph Analysis",
    width = 12,
    div(
      class = "graph-controls",
      div(
        style = "display: flex; gap: 10px; margin-bottom: 15px;",
        div(
          style = "flex: 1;",
          selectInput(
            "snapshot",
            "Select Snapshot:",
            choices = NULL,
            selected = NULL,
            multiple = FALSE,
            width = "100%"
          )
        ),
        div(
          style = "flex: 1;",
          textInput(
            "subgraph_root",
            "Root Node ID",
            value = "",
            placeholder = "Enter node ID to visualize",
            width = "100%"
          )
        ),
        div(
          style = "flex: 1;",
          sliderInput(
            "max_depth",
            "Maximum Depth",
            min = 1,
            max = 10,
            value = 3,
            width = "100%"
          )
        )
      ),
      div(
        style = "display: flex; justify-content: center; margin-bottom: 15px;",
        actionButton(
          "render_graph",
          "Render Subgraph",
          icon = icon("project-diagram"),
          class = "btn-primary",
          width = "200px"
        )
      ),
      div(
        style = "margin-top: 15px;",
        div(
          style = "text-align: center; margin-bottom: 10px;",
          textOutput("current_snapshot")
        ),
        div(
          style = "border: 1px solid #ddd; padding: 10px; border-radius: 4px;",
          visNetworkOutput("graph_vis", height = "600px")
        )
      )
    )
  )
}

# Node Search Box
node_search_box <- function() {
  box(
    title = "Node Search",
    width = 12,
    div(
      class = "search-controls",
      div(
        style = "display: flex; gap: 10px; margin-bottom: 15px;",
        div(
          style = "flex: 1;",
          textInput("node_search", "Search Nodes", placeholder = "Enter node ID or pattern")
        ),
        div(
          style = "flex: 0;",
          actionButton(
            "search_nodes",
            "Search",
            icon = icon("search"),
            class = "btn-primary"
          )
        )
      ),
      div(
        style = "max-height: 300px; overflow-y: auto;",
        dataTableOutput("search_results")
      )
    )
  )
}

# Node Statistics Box
node_stats_box <- function() {
  box(
    title = "Node Statistics",
    width = 12,
    div(
      style = "overflow-x: auto;",
      dataTableOutput("node_stats")
    ),
    downloadButton("download_stats", "Download Statistics")
  )
}

# Settings Box
settings_box <- function() {
  box(
    title = "Visualization Settings",
    width = 12,
    sliderInput(
      "node_size",
      "Node Size",
      min = 10,
      max = 50,
      value = 25
    ),
    colourInput(
      "node_color",
      "Node Color",
      value = "#97C2FC"
    ),
    colourInput(
      "edge_color",
      "Edge Color",
      value = "#2B7CE9"
    ),
    sliderInput(
      "level_separation",
      "Level Separation",
      min = 50,
      max = 300,
      value = 150
    ),
    sliderInput(
      "node_spacing",
      "Node Spacing",
      min = 50,
      max = 200,
      value = 100
    )
  )
}

# CSS Styles
app_styles <- tags$head(
  tags$style(HTML("
    .box {
      border-top: 3px solid #3c8dbc;
      box-shadow: 0 1px 3px rgba(0,0,0,0.12), 0 1px 2px rgba(0,0,0,0.24);
    }
    .btn-primary {
      margin-top: 10px;
    }
    .loader {
      border: 5px solid #f3f3f3;
      border-radius: 50%;
      border-top: 5px solid #3c8dbc;
      width: 50px;
      height: 50px;
      animation: spin 1s linear infinite;
      margin: 20px auto;
    }
    @keyframes spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }
    #current_snapshot {
      margin: 10px 0;
      font-weight: bold;
      font-size: 16px;
    }
  "))
)

# Main UI Function
ui <- function() {
  dashboardPage(
    dashboardHeader(title = "Graph Analysis Tool"),
    dashboardSidebar(
      sidebarMenu(
        menuItem("Data Loading", tabName = "data", icon = icon("database")),
        menuItem("Graph Analysis", tabName = "graph", icon = icon("project-diagram")),
        menuItem("Settings", tabName = "settings", icon = icon("cog"))
      )
    ),
    dashboardBody(
      app_styles,
      uiOutput("loading"),
      tabItems(
        # Data Loading Tab
        tabItem(
          tabName = "data",
          fluidRow(
            column(
              width = 12,
              data_source_box(),
              data_summary_box()
            )
          )
        ),
        
        # Graph Analysis Tab
        tabItem(
          tabName = "graph",
          fluidRow(
            column(
              width = 3,
              node_search_box(),
              node_stats_box()
            ),
            column(
              width = 9,
              graph_analysis_box()
            )
          )
        ),
        
        # Settings Tab
        tabItem(
          tabName = "settings",
          fluidRow(
            column(
              width = 12,
              settings_box()
            )
          )
        )
      )
    )
  )
} 