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
    
    # Create the table from API metrics and ensure proper column types
    stats_df <- do.call(rbind.data.frame, data$metrics$node_metrics)
    
    # Convert columns to proper types
    stats_df$Node <- as.character(stats_df$Node)
    stats_df$Weight <- as.numeric(stats_df$Weight)
    stats_df$Subgraph_Weight <- as.numeric(stats_df$Subgraph_Weight)
    stats_df$Degree <- as.integer(stats_df$Degree)
    stats_df$Betweenness <- as.numeric(stats_df$Betweenness)
    stats_df$Closeness <- as.numeric(stats_df$Closeness)
    stats_df$Eigenvector <- as.numeric(stats_df$Eigenvector)
    stats_df$ClusteringCoeff <- as.numeric(stats_df$ClusteringCoeff)
    
    message("[DEBUG] Available columns in stats_df:", paste(names(stats_df), collapse = ", "))
    message("[DEBUG] First row of data:", paste(capture.output(stats_df[1,]), collapse = "\n"))
    
    # Define column order and display names
    col_order <- c("Node", "Weight", "Subgraph_Weight", "Degree", 
                   "Betweenness", "Closeness", "Eigenvector", "ClusteringCoeff")
    display_names <- c(
      "Node ID", "Weight", "Subgraph Weight", "Degree",
      "Betweenness", "Closeness", "Eigenvector", "Clustering Coeff"
    )
    
    # Reorder columns
    stats_df <- stats_df[, col_order]
    
    # Format the table
    dt <- DT::datatable(
      stats_df,
      rownames = FALSE,  # Disable row numbers at the datatable level
      options = list(
        pageLength = 25,
        scrollX = TRUE,
        order = list(list(1, 'desc')),  # Sort by Weight by default
        dom = 'Bfrtip',
        buttons = c('copy', 'csv', 'excel'),
        rownames = FALSE  # Disable row numbers at the options level
      ),
      selection = 'single',
      extensions = 'Buttons',
      colnames = display_names
    )
    
    # Format numeric columns with appropriate precision
    dt <- dt %>%
      DT::formatRound(
        columns = c('Weight', 'Subgraph_Weight'),
        digits = 2
      ) %>%
      DT::formatRound(
        columns = c('Betweenness', 'Closeness', 'Eigenvector', 'ClusteringCoeff'),
        digits = 4
      )
    
    dt
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