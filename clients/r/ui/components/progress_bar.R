# Progress Bar Component

#' Create a progress bar component
#' 
#' @param id The ID of the progress bar
#' @param value Current progress value
#' @param total Total progress value
#' @param title Title to display above the progress bar
#' @return A div containing a styled progress bar
create_progress_bar <- function(id, value, total = 100, title = "Loading...") {
  div(
    class = "progress-container",
    h4(title),
    div(
      class = "progress",
      div(
        class = "progress-bar",
        role = "progressbar",
        style = sprintf("width: %d%%;", round(value / total * 100)),
        "aria-valuenow" = value,
        "aria-valuemin" = 0,
        "aria-valuemax" = total,
        sprintf("%d%%", round(value / total * 100))
      )
    )
  )
}

#' Create a loading indicator
#' 
#' @return A div containing a loading spinner
create_loading_spinner <- function() {
  div(
    class = "loading-container",
    style = "position: fixed; top: 50%; left: 50%; transform: translate(-50%, -50%); text-align: center;",
    tags$div(
      class = "spinner-border text-primary",
      role = "status",
      tags$span(class = "sr-only", "Loading...")
    ),
    h4("Loading...", style = "margin-top: 10px;")
  )
} 