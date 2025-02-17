# Visualization Settings Handler

#' Handle visualization settings functionality
#' 
#' @param input Shiny input object
#' @param output Shiny output object
#' @param session Shiny session object
#' @param vis_settings Reactive values for visualization settings
handle_visualization_settings <- function(input, output, session, vis_settings) {
  # Observe visualization setting changes
  shiny::observe({
    shiny::req(input$node_size)
    vis_settings$node_size <- input$node_size
    session$sendCustomMessage(type = "update-node-size", 
                            message = list(size = input$node_size))
  })
  
  shiny::observe({
    shiny::req(input$level_separation)
    vis_settings$level_separation <- input$level_separation
    session$sendCustomMessage(type = "update-level-separation", 
                            message = list(separation = input$level_separation))
  })
  
  shiny::observe({
    shiny::req(input$node_color)
    vis_settings$node_color <- input$node_color
    session$sendCustomMessage(type = "update-node-color", 
                            message = list(color = input$node_color))
  })
  
  shiny::observe({
    shiny::req(input$edge_color)
    vis_settings$edge_color <- input$edge_color
    session$sendCustomMessage(type = "update-edge-color", 
                            message = list(color = input$edge_color))
  })
  
  # Render preview visualization
  output$preview_vis <- renderUI({
    # Create a simple preview network with synthetic data
    preview_nodes <- data.frame(
      id = c(1, 2, 3),
      label = c("Root", "Child 1", "Child 2"),
      stringsAsFactors = FALSE
    )
    
    preview_edges <- data.frame(
      from = c(1, 1),
      to = c(2, 3),
      arrows = "to",
      stringsAsFactors = FALSE
    )
    
    # Create the preview network
    visNetwork::visNetwork(
      preview_nodes,
      preview_edges,
      width = "100%",
      height = "200px"
    ) %>%
      visNetwork::visNodes(
        size = vis_settings$node_size,
        color = list(
          background = vis_settings$node_color,
          border = "#013848",
          highlight = list(
            background = "#FF8000",
            border = "#013848"
          )
        ),
        font = list(
          size = 16,
          color = "#000000"
        ),
        shadow = TRUE
      ) %>%
      visNetwork::visEdges(
        arrows = list(to = list(enabled = TRUE, scaleFactor = 1)),
        color = list(
          color = vis_settings$edge_color,
          highlight = "#FF8000"
        ),
        smooth = list(
          enabled = TRUE,
          type = "cubicBezier"
        ),
        shadow = TRUE
      ) %>%
      visNetwork::visLayout(
        randomSeed = 123,
        improvedLayout = TRUE,
        hierarchical = list(
          enabled = TRUE,
          direction = "UD",
          sortMethod = "directed",
          levelSeparation = vis_settings$level_separation,
          nodeSpacing = 100,
          treeSpacing = 200
        )
      ) %>%
      visNetwork::visInteraction(
        dragNodes = FALSE,
        dragView = FALSE,
        zoomView = FALSE,
        navigationButtons = FALSE
      )
  })
} 