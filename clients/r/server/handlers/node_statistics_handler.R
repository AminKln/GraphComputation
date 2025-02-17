# Node Statistics Handler

#' Handle node statistics functionality
#' 
#' @param input Shiny input object
#' @param output Shiny output object
#' @param session Shiny session object
#' @param graph_data Reactive value for graph data
#' @param visible_graph Reactive value for visible graph data
handle_node_statistics <- function(input, output, session, graph_data, visible_graph) {
  # Node statistics table
  output$node_stats <- DT::renderDT({
    shiny::req(visible_graph())
    
    # Get the metrics from the API response
    data <- visible_graph()
    if (is.null(data$metrics) || is.null(data$metrics$node_metrics)) {
      return(NULL)
    }
    
    # Create the table from API metrics
    stats_df <- do.call(rbind.data.frame, data$metrics$node_metrics)
    
    message("[DEBUG] Available columns in stats_df:", paste(names(stats_df), collapse = ", "))
    
    # Format the table
    DT::datatable(
      stats_df,
      options = list(
        pageLength = 25,
        scrollX = TRUE,
        order = list(list(1, 'desc')),  # Sort by Weight by default
        dom = 'Bfrtip',
        buttons = c('copy', 'csv', 'excel'),
        rownames = FALSE  # Remove row numbers
      ),
      selection = 'single',  # Enable single row selection
      extensions = 'Buttons',
      colnames = c(
        "Node ID", "Weight", "Betweenness", "Closeness", 
        "Clustering Coeff", "Degree", "Eigenvector"
      )
    ) %>%
      DT::formatRound(
        columns = c('Weight', 'Betweenness', 'Closeness', 
                   'ClusteringCoeff', 'Degree', 'Eigenvector'),
        digits = 2
      )
  })
  
  # Handle node statistics selection
  shiny::observeEvent(input$node_stats_rows_selected, {
    message("[DEBUG] Node stats row selected:", input$node_stats_rows_selected)
    shiny::req(visible_graph(), input$node_stats_rows_selected)
    selected_row <- input$node_stats_rows_selected
    
    if (!is.null(selected_row)) {
      data <- visible_graph()
      if (!is.null(data$metrics) && !is.null(data$metrics$node_metrics)) {
        stats_df <- do.call(rbind.data.frame, data$metrics$node_metrics)
        if (selected_row <= nrow(stats_df)) {
          selected_node <- stats_df$Node[selected_row]
          message("[DEBUG] Selected node from stats:", selected_node)
          
          # Highlight the selected node in the graph
          session$sendCustomMessage(type = "visnetwork-highlight-node", 
                                  message = list(
                                    nodeId = selected_node,
                                    color = "#FF8000"
                                  ))
        }
      }
    }
  })
  
  # Handle statistics download
  output$download_stats <- downloadHandler(
    filename = function() {
      paste("node_statistics_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".csv", sep = "")
    },
    content = function(file) {
      shiny::req(visible_graph())
      data <- visible_graph()
      if (!is.null(data$metrics) && !is.null(data$metrics$node_metrics)) {
        stats_df <- do.call(rbind.data.frame, data$metrics$node_metrics)
        write.csv(stats_df, file, row.names = FALSE)
      }
    }
  )
} 