# Data Summary Handler

#' Handle data summary functionality
#' 
#' @param input Shiny input object
#' @param output Shiny output object
#' @param session Shiny session object
#' @param graph_data Reactive value for graph data
handle_data_summary <- function(input, output, session, graph_data) {
  # Total nodes counter
  output$total_nodes <- shiny::renderText({
    shiny::req(graph_data())
    paste("Total Nodes:", length(graph_data()$nodes))
  })
  
  # Total edges counter
  output$total_edges <- shiny::renderText({
    shiny::req(graph_data())
    paste("Total Edges:", length(graph_data()$links))
  })
  
  # Total snapshots counter
  output$total_snapshots <- shiny::renderText({
    shiny::req(graph_data())
    snapshots <- unique(sapply(graph_data()$nodes, function(x) x$snapshot))
    paste("Total Snapshots:", length(snapshots))
  })
  
  # Data summary table
  output$data_summary_table <- DT::renderDT({
    shiny::req(graph_data())
    
    # Extract node information
    nodes_df <- do.call(rbind, lapply(graph_data()$nodes, function(node) {
      # Calculate incoming and outgoing degrees
      incoming <- sum(sapply(graph_data()$links, function(link) link$target == node$id))
      outgoing <- sum(sapply(graph_data()$links, function(link) link$source == node$id))
      
      # Calculate subgraph weight if not provided
      subgraph_weight <- if (!is.null(node$subgraph_weight)) {
        node$subgraph_weight
      } else {
        # Find all descendants
        descendants <- list()
        to_process <- c(node$id)
        while (length(to_process) > 0) {
          current <- to_process[1]
          to_process <- to_process[-1]
          descendants <- c(descendants, current)
          
          # Find children
          children <- sapply(graph_data()$links, function(link) {
            if (link$source == current) return(link$target)
            return(NULL)
          })
          children <- unlist(children[!sapply(children, is.null)])
          
          # Add new children to process
          to_process <- c(to_process, children[!children %in% descendants])
        }
        
        # Sum weights of all descendants
        sum(sapply(graph_data()$nodes, function(n) {
          if (n$id %in% descendants) return(n$weight)
          return(0)
        }))
      }
      
      data.frame(
        Node = node$id,
        Weight = node$weight,
        SubgraphWeight = subgraph_weight,
        Snapshot = node$snapshot,
        InDegree = incoming,
        OutDegree = outgoing,
        TotalDegree = incoming + outgoing,
        stringsAsFactors = FALSE
      )
    }))
    
    # Create an interactive table
    DT::datatable(
      nodes_df,
      rownames = FALSE,  # Disable row numbers at the datatable level
      options = list(
        pageLength = 10,
        scrollX = TRUE,
        order = list(list(2, 'desc')),  # Sort by SubgraphWeight by default
        dom = 'Bfrtip',
        buttons = c('copy', 'csv', 'excel'),
        rownames = FALSE  # Disable row numbers at the options level
      ),
      selection = 'single',  # Enable single row selection
      extensions = 'Buttons'
    ) %>%
      DT::formatRound(columns = c('Weight', 'SubgraphWeight'), digits = 2)
  })
} 