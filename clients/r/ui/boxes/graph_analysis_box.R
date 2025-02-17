# Graph Analysis Box Component

#' Create a graph analysis box
#' 
#' @return A shinydashboard box containing graph analysis controls and visualization
graph_analysis_box <- function() {
  box(
    title = "Graph Analysis",
    width = 12,
    status = "primary",
    solidHeader = TRUE,
    collapsible = FALSE,
    div(
      class = "graph-controls",
      fluidRow(
        column(
          width = 4,
          selectInput(
            "snapshot",
            "Select Snapshot:",
            choices = NULL,
            selected = NULL,
            multiple = FALSE,
            width = "100%"
          )
        ),
        column(
          width = 4,
          textInput(
            "subgraph_root",
            "Root Node ID",
            value = "",
            placeholder = "Enter node ID",
            width = "100%"
          )
        ),
        column(
          width = 4,
          sliderInput(
            "max_depth",
            "Maximum Depth",
            min = 1,
            max = 10,
            value = 3,
            step = 1,
            width = "100%"
          )
        )
      ),
      fluidRow(
        column(
          width = 12,
          div(
            style = "text-align: center; margin: 15px 0;",
            actionButton(
              "render_graph",
              "Render Subgraph",
              icon = icon("project-diagram"),
              class = "btn-primary",
              width = "200px",
              style = "margin: 10px;"
            )
          )
        )
      ),
      fluidRow(
        column(
          width = 12,
          div(
            style = "text-align: center; margin-bottom: 10px; font-weight: bold;",
            textOutput("current_snapshot")
          ),
          div(
            style = "border: 1px solid #ddd; border-radius: 4px; padding: 10px; background: white;",
            visNetworkOutput("graph_vis", height = "600px")
          )
        )
      ),
      # Visualization settings
      fluidRow(
        column(
          width = 3,
          numericInput(
            "node_size",
            "Node Size",
            value = 25,
            min = 10,
            max = 50,
            step = 5,
            width = "100%"
          )
        ),
        column(
          width = 3,
          div(style = "width: 100%;",
            colourpicker::colourInput(
              "node_color",
              "Node Color",
              value = "#97C2FC"
            )
          )
        ),
        column(
          width = 3,
          div(style = "width: 100%;",
            colourpicker::colourInput(
              "edge_color",
              "Edge Color",
              value = "#2B7CE9"
            )
          )
        ),
        column(
          width = 3,
          numericInput(
            "level_separation",
            "Level Separation",
            value = 150,
            min = 50,
            max = 300,
            step = 10,
            width = "100%"
          )
        )
      )
    )
  )
} 