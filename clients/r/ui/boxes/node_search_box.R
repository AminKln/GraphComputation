# Node Search Box Component

#' Create a node search box
#' 
#' @return A shinydashboard box containing node search functionality
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
          textInput(
            "node_search",
            "Search Nodes",
            placeholder = "Enter node ID or pattern"
          )
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
      ),
      # Add JavaScript to handle node selection
      tags$script("
        $(document).ready(function() {
          window.shouldUpdateRoot = false;
          
          // Handle click on 'Set as Root' button
          $(document).on('click', '.set-root-btn', function() {
            window.shouldUpdateRoot = true;
          });
        });
      "),
      # Add buttons for node actions
      div(
        style = "margin-top: 10px; text-align: right;",
        actionButton(
          "highlight_node",
          "Highlight Selected",
          icon = icon("highlighter"),
          class = "btn-info"
        ),
        actionButton(
          "set_root_node",
          "Set as Root",
          icon = icon("project-diagram"),
          class = "btn-primary set-root-btn"
        )
      )
    )
  )
} 