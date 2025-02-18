# Data Summary Box Component

#' Create a data summary box
#' 
#' @return A shinydashboard box containing data summary information
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
          DTOutput("data_summary_table")
        )
      )
    )
  )
} 