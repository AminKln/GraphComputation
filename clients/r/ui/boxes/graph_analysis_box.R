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
            div(
              style = "display: inline-flex; gap: 10px; justify-content: center;",
              actionButton(
                "render_graph",
                "Render Subgraph",
                icon = icon("project-diagram"),
                class = "btn-primary",
                width = "200px"
              ),
              actionButton(
                "reset_graph",
                "Reset Graph",
                icon = icon("undo"),
                class = "btn-secondary",
                width = "200px"
              )
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
      # Consolidated Graph Metrics Box
      fluidRow(
        column(
          width = 12,
          div(
            class = "metrics-box",
            style = "padding: 20px; border: 1px solid #ddd; border-radius: 4px; background-color: #f8f9fa; margin-top: 20px;",
            h3("Graph Metrics", style = "margin-top: 0; color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 8px;"),
            div(
              style = "display: grid; grid-template-columns: repeat(3, 1fr); gap: 20px;",
              # Full Graph Metrics
              div(
                class = "metric-section",
                style = "background: white; padding: 15px; border-radius: 4px; border: 1px solid #e0e0e0;",
                h4("Total Graph", style = "color: #2c3e50; margin: 0 0 15px 0; font-weight: bold; text-align: center; font-size: 16px;"),
                div(
                  style = "display: grid; gap: 8px;",
                  div(
                    class = "metric-row",
                    style = "display: flex; justify-content: space-between; align-items: center; padding: 4px 8px; background: #f8f9fa; border-radius: 4px;",
                    div(strong("Nodes:"), style = "color: #2c3e50; margin-right: 10px;"),
                    textOutput("full_graph_total_nodes", inline = TRUE)
                  ),
                  div(
                    class = "metric-row",
                    style = "display: flex; justify-content: space-between; align-items: center; padding: 4px 8px; background: #f8f9fa; border-radius: 4px;",
                    div(strong("Edges:"), style = "color: #2c3e50; margin-right: 10px;"),
                    textOutput("full_graph_total_edges", inline = TRUE)
                  ),
                  div(
                    class = "metric-row",
                    style = "display: flex; justify-content: space-between; align-items: center; padding: 4px 8px; background: #f8f9fa; border-radius: 4px;",
                    div(strong("Max Depth:"), style = "color: #2c3e50; margin-right: 10px;"),
                    textOutput("full_graph_total_depth", inline = TRUE)
                  ),
                  div(
                    class = "metric-row",
                    style = "display: flex; justify-content: space-between; align-items: center; padding: 4px 8px; background: #f8f9fa; border-radius: 4px;",
                    div(strong("Root Node:"), style = "color: #2c3e50; margin-right: 10px;"),
                    div(
                      style = "cursor: pointer; color: #3498db; text-decoration: underline;",
                      onclick = "Shiny.setInputValue('set_root_from_full', true)",
                      textOutput("full_graph_root", inline = TRUE)
                    )
                  )
                )
              ),
              # Subgraph Metrics
              div(
                class = "metric-section",
                style = "background: white; padding: 15px; border-radius: 4px; border: 1px solid #e0e0e0;",
                h4("Current Subgraph", style = "color: #2c3e50; margin: 0 0 15px 0; font-weight: bold; text-align: center; font-size: 16px;"),
                div(
                  style = "display: grid; gap: 8px;",
                  div(
                    class = "metric-row",
                    style = "display: flex; justify-content: space-between; align-items: center; padding: 4px 8px; background: #f8f9fa; border-radius: 4px;",
                    div(strong("Nodes:"), style = "color: #2c3e50; margin-right: 10px;"),
                    textOutput("subgraph_total_nodes", inline = TRUE)
                  ),
                  div(
                    class = "metric-row",
                    style = "display: flex; justify-content: space-between; align-items: center; padding: 4px 8px; background: #f8f9fa; border-radius: 4px;",
                    div(strong("Edges:"), style = "color: #2c3e50; margin-right: 10px;"),
                    textOutput("subgraph_total_edges", inline = TRUE)
                  ),
                  div(
                    class = "metric-row",
                    style = "display: flex; justify-content: space-between; align-items: center; padding: 4px 8px; background: #f8f9fa; border-radius: 4px;",
                    div(strong("Depth:"), style = "color: #2c3e50; margin-right: 10px;"),
                    textOutput("subgraph_total_depth", inline = TRUE)
                  ),
                  div(
                    class = "metric-row",
                    style = "display: flex; justify-content: space-between; align-items: center; padding: 4px 8px; background: #f8f9fa; border-radius: 4px;",
                    div(strong("Root Node:"), style = "color: #2c3e50; margin-right: 10px;"),
                    div(
                      style = "cursor: pointer; color: #3498db; text-decoration: underline;",
                      onclick = "Shiny.setInputValue('set_root_from_sub', true)",
                      textOutput("subgraph_root", inline = TRUE)
                    )
                  )
                )
              ),
              # Currently Displayed Metrics
              div(
                class = "metric-section",
                style = "background: white; padding: 15px; border-radius: 4px; border: 1px solid #e0e0e0;",
                h4("Currently Displayed", style = "color: #2c3e50; margin: 0 0 15px 0; font-weight: bold; text-align: center; font-size: 16px;"),
                div(
                  style = "display: grid; gap: 8px;",
                  div(
                    class = "metric-row",
                    style = "display: flex; justify-content: space-between; align-items: center; padding: 4px 8px; background: #f8f9fa; border-radius: 4px;",
                    div(strong("Nodes:"), style = "color: #2c3e50; margin-right: 10px;"),
                    textOutput("full_graph_displayed_nodes", inline = TRUE)
                  ),
                  div(
                    class = "metric-row",
                    style = "display: flex; justify-content: space-between; align-items: center; padding: 4px 8px; background: #f8f9fa; border-radius: 4px;",
                    div(strong("Edges:"), style = "color: #2c3e50; margin-right: 10px;"),
                    textOutput("full_graph_displayed_edges", inline = TRUE)
                  ),
                  div(
                    class = "metric-row",
                    style = "display: flex; justify-content: space-between; align-items: center; padding: 4px 8px; background: #f8f9fa; border-radius: 4px;",
                    div(strong("Depth:"), style = "color: #2c3e50; margin-right: 10px;"),
                    textOutput("full_graph_displayed_depth", inline = TRUE)
                  )
                )
              )
            )
          )
        )
      )
    )
  )
} 