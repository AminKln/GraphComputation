# Graph Visualization Handler

#' Handle graph visualization functionality
#' 
#' @param input Shiny input object
#' @param output Shiny output object
#' @param session Shiny session object
#' @param graph_data Reactive value for graph data
#' @param visible_graph Reactive value for visible graph data
handle_graph_visualization <- function(input, output, session, graph_data, visible_graph) {
  # Initialize snapshot choices when data is loaded
  shiny::observe({
    shiny::req(graph_data())
    data <- graph_data()
    
    # Extract and validate snapshots
    snapshots <- unique(sapply(data$nodes, function(x) x$snapshot))
    snapshots <- snapshots[!sapply(snapshots, is.null)]
    
    if (length(snapshots) > 0) {
      # Sort snapshots chronologically
      sorted_snapshots <- sort(as.character(snapshots))
      
      # Update snapshot selector
      shiny::updateSelectInput(
        session,
        "snapshot",
        choices = sorted_snapshots,
        selected = sorted_snapshots[1]
      )
      
      # Set initial root node
      if (!is.null(data$root_node)) {
        initial_root <- as.character(data$root_node$id)
      } else if (length(data$nodes) > 0) {
        initial_root <- as.character(data$nodes[[1]]$id)
      }
      
      if (!is.null(initial_root)) {
        shiny::updateTextInput(
          session,
          "subgraph_root",
          value = initial_root
        )
      }
    }
  })
  
  # Handle node selection from data table
  shiny::observeEvent(input$selected_node, {
    if (!is.null(input$selected_node)) {
      message("[DEBUG] Node selected from data table:", input$selected_node)
      # Highlight the selected node in the graph
      session$sendCustomMessage(type = "visnetwork-highlight", 
                              message = list(node = input$selected_node))
    }
  })
  
  # Handle node search selection
  shiny::observeEvent(input$search_nodes, {
    shiny::req(graph_data(), input$node_search)
    
    # Find matching nodes
    search_pattern <- tolower(input$node_search)
    matching_nodes <- Filter(function(x) {
      grepl(search_pattern, tolower(x$id), fixed = TRUE)
    }, graph_data()$nodes)
    
    if (length(matching_nodes) > 0) {
      message("[DEBUG] Found matching nodes:", length(matching_nodes))
    }
  })
  
  # Handle snapshot changes
  shiny::observeEvent(input$snapshot, {
    shiny::req(input$snapshot, input$subgraph_root)
    # Trigger graph render when snapshot changes
    shiny::updateActionButton(session, "render_graph", label = "Render Subgraph")
    session$sendCustomMessage(type = "shinyjs-click", message = "#render_graph")
  })
  
  # Render graph when button is clicked
  shiny::observeEvent(input$render_graph, {
    shiny::req(graph_data(), input$snapshot, input$subgraph_root)
    
    message("[GRAPH] Rendering graph for snapshot:", input$snapshot)
    
    # Validate inputs
    if (input$subgraph_root == "") {
      shiny::showNotification("Please select a root node", type = "warning")
      return()
    }
    
    # Validate root node exists
    root_exists <- any(sapply(graph_data()$nodes, function(node) {
      node$id == input$subgraph_root && node$snapshot == input$snapshot
    }))
    
    if (!root_exists) {
      shiny::showNotification(
        paste("Root node", input$subgraph_root, "not found in snapshot", input$snapshot),
        type = "error"
      )
      return()
    }
    
    # Make API call to get processed graph data
    tryCatch({
      message("[GRAPH] Making API call with params:", 
              "\n  - snapshot:", input$snapshot,
              "\n  - root_node:", input$subgraph_root,
              "\n  - max_depth:", input$max_depth)
      
      response <- httr::POST(
        paste0(API_CONFIG$base_url, "/process_graph"),
        body = list(
          source = list(
            type = "file",
            vertex_data = graph_data()$nodes,
            edge_data = graph_data()$links
          ),
          params = list(
            snapshot = input$snapshot,
            root_node = input$subgraph_root,
            max_depth = as.numeric(input$max_depth)
          ),
          format = "d3"
        ),
        encode = "json"
      )
      
      if (httr::http_error(response)) {
        error_msg <- httr::content(response, "text", encoding = "UTF-8")
        message("[GRAPH] API error:", error_msg)
        shiny::showNotification(paste("API Error:", error_msg), type = "error")
        return(NULL)
      }
      
      # Parse response
      result <- jsonlite::fromJSON(
        httr::content(response, "text", encoding = "UTF-8"),
        simplifyVector = FALSE
      )
      
      # Validate API response
      if (is.null(result$nodes) || length(result$nodes) == 0) {
        message("[GRAPH] No nodes returned from API")
        shiny::showNotification("No nodes found for the selected parameters", type = "warning")
        return(NULL)
      }
      
      message("[GRAPH] Processing API response:",
              "\n  - Nodes:", length(result$nodes),
              "\n  - Links:", length(result$links))
      
      # Convert nodes to data frame safely
      nodes_df <- do.call(rbind, lapply(result$nodes, function(node) {
        if (is.null(node$id) || is.null(node$weight)) {
          message("[GRAPH] Invalid node data:", jsonlite::toJSON(node))
          return(NULL)
        }
        data.frame(
          id = as.character(node$id),
          label = as.character(node$id),
          title = paste("<p><b>Node:</b>", node$id,
                       "<br><b>Weight:</b>", node$weight,
                       "<br><b>Subgraph Weight:</b>", node$subgraph_weight,
                       if (!is.null(node$snapshot)) paste("<br><b>Snapshot:</b>", node$snapshot) else "",
                       "</p>"),
          weight = as.numeric(node$weight),
          subgraph_weight = as.numeric(node$subgraph_weight),
          stringsAsFactors = FALSE
        )
      }))
      
      # Remove any NULL entries from invalid nodes
      nodes_df <- nodes_df[!sapply(nodes_df$id, is.null), ]
      
      # Convert edges to data frame if they exist
      edges_df <- if (!is.null(result$links) && length(result$links) > 0) {
        do.call(rbind, lapply(result$links, function(edge) {
          if (is.null(edge$source) || is.null(edge$target)) {
            message("[GRAPH] Invalid edge data:", jsonlite::toJSON(edge))
            return(NULL)
          }
          data.frame(
            from = as.character(edge$source),
            to = as.character(edge$target),
            arrows = "to",
            stringsAsFactors = FALSE
          )
        }))
      } else {
        data.frame(
          from = character(0),
          to = character(0),
          arrows = character(0),
          stringsAsFactors = FALSE
        )
      }
      
      # Remove any NULL entries from invalid edges
      if (!is.null(edges_df) && nrow(edges_df) > 0) {
        edges_df <- edges_df[!sapply(edges_df$from, is.null), ]
      }
      
      # Update visible graph with processed data
      visible_graph(list(
        nodes = nodes_df,
        edges = edges_df,
        root_id = input$subgraph_root,
        metrics = result$metrics
      ))
      
      message("[GRAPH] Graph rendered successfully")
      
    }, error = function(e) {
      message("[GRAPH] Error rendering graph:", e$message)
      shiny::showNotification(
        paste("Error rendering graph:", e$message),
        type = "error",
        duration = NULL
      )
    })
  }, ignoreInit = TRUE)
  
  # Render the graph visualization
  output$graph_vis <- visNetwork::renderVisNetwork({
    shiny::req(visible_graph())
    data <- visible_graph()
    
    message("[DEBUG] Rendering visNetwork")
    message(sprintf("[DEBUG] Nodes: %d", nrow(data$nodes)))
    message(sprintf("[DEBUG] Edges: %d", nrow(data$edges)))
    
    if (nrow(data$nodes) == 0) {
      return(NULL)
    }
    
    # Create the network visualization
    visNetwork::visNetwork(
      data$nodes,
      data$edges,
      width = "100%",
      height = "600px",
      main = list(
        text = paste("Subgraph for Node", data$root_id),
        style = "font-family: sans-serif; font-size: 16px;"
      )
    ) %>%
      visNetwork::visNodes(
        size = input$node_size,
        color = list(
          background = input$node_color,
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
          color = input$edge_color,
          highlight = "#FF8000"
        ),
        smooth = list(
          enabled = TRUE,
          type = "cubicBezier"
        ),
        shadow = TRUE
      ) %>%
      visNetwork::visOptions(
        highlightNearest = list(
          enabled = TRUE,
          degree = 1,
          hover = TRUE
        ),
        nodesIdSelection = FALSE,  # Disable initial node selection
        manipulation = FALSE
      ) %>%
      visNetwork::visLayout(
        randomSeed = 123,
        improvedLayout = TRUE,
        hierarchical = list(
          enabled = TRUE,
          direction = "UD",
          sortMethod = "directed",
          levelSeparation = input$level_separation,
          nodeSpacing = 100,
          treeSpacing = 200
        )
      ) %>%
      visNetwork::visPhysics(
        hierarchicalRepulsion = list(
          nodeDistance = 150
        ),
        stabilization = list(
          enabled = TRUE,
          iterations = 200,
          fit = TRUE
        )
      ) %>%
      visNetwork::visInteraction(
        dragNodes = TRUE,
        dragView = TRUE,
        zoomView = TRUE,
        navigationButtons = TRUE
      ) %>%
      visNetwork::visEvents(
        selectNode = sprintf("function(nodes) {
          var selectedNode = nodes.nodes[0];
          Shiny.setInputValue('selected_graph_node', selectedNode);
          
          // Only update subgraph root if explicitly requested
          if (window.shouldUpdateRoot) {
            Shiny.setInputValue('subgraph_root', selectedNode);
            $('#render_graph').click();
          }
          
          // Reset the flag
          window.shouldUpdateRoot = false;
        }")
      )
  })
  
  # Handle node selection from search or statistics
  shiny::observeEvent(input$selected_graph_node, {
    if (!is.null(input$selected_graph_node)) {
      # Send message to highlight the node in the graph
      session$sendCustomMessage(type = "visnetwork-highlight", 
                              message = list(node = input$selected_graph_node))
    }
  })
  
  # Add JavaScript handler for node highlighting
  shiny::insertUI(
    selector = "head",
    where = "beforeEnd",
    ui = tags$script("
      Shiny.addCustomMessageHandler('visnetwork-highlight', function(message) {
        var network = document.getElementById('graph_vis').network;
        if (network && message.node) {
          network.selectNodes([message.node]);
          network.focus(message.node, {
            scale: 1.0,
            animation: true
          });
        }
      });
    ")
  )
  
  # Update current snapshot text
  output$current_snapshot <- shiny::renderText({
    shiny::req(input$snapshot)
    paste("Current Snapshot:", input$snapshot)
  })
} 