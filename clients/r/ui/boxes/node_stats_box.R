# Node Statistics Box Component

#' Create a node statistics box
#' 
#' @return A shinydashboard box containing node statistics
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