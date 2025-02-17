# Settings Box Component

#' Create a settings box for visualization parameters
#' 
#' @return A shinydashboard box containing visualization settings
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
    # colourpicker::colourInput(
    #   "node_color",
    #   "Node Color",
    #   value = "#97C2FC"
    # ),
    # colourpicker::colourInput(
    #   "edge_color",
    #   "Edge Color",
    #   value = "#2B7CE9"
    # ),
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