# Graph Metrics Utility Functions

#' Calculate the maximum depth of a graph from a given root node
#' 
#' @param edges List of edges in the graph
#' @param root_id ID of the root node
#' @return Maximum depth from the root node
calculate_max_depth_from_root <- function(edges, root_id) {
  if (is.null(edges) || length(edges) == 0 || is.null(root_id)) {
    return(0)
  }
  
  # Initialize depth tracking
  depths <- list()
  depths[[root_id]] <- 0
  current_level <- list(root_id)
  max_depth <- 0
  
  # Perform BFS to calculate depths
  while (length(current_level) > 0) {
    next_level <- list()
    
    for (node in current_level) {
      # Find all children of current node
      children <- sapply(edges, function(e) {
        if (identical(e$from, node) || identical(e$source, node)) {
          return(if (!is.null(e$to)) e$to else e$target)
        }
        return(NULL)
      })
      children <- children[!sapply(children, is.null)]
      
      # Update depths of children
      for (child in children) {
        if (is.null(depths[[child]])) {
          current_depth <- depths[[node]] + 1
          depths[[child]] <- current_depth
          next_level <- c(next_level, child)
          max_depth <- max(max_depth, current_depth)
        }
      }
    }
    current_level <- next_level
  }
  
  return(max_depth)
}

#' Find all root nodes in a graph (nodes with no incoming edges)
#' 
#' @param nodes List of nodes in the graph
#' @param edges List of edges in the graph
#' @return Vector of root node IDs
find_root_nodes <- function(nodes, edges) {
  if (is.null(nodes) || length(nodes) == 0) {
    return(character(0))
  }
  
  # Get all node IDs
  node_ids <- sapply(nodes, function(n) n$id)
  
  # Find nodes with no incoming edges
  root_nodes <- Filter(function(node_id) {
    !any(sapply(edges, function(e) {
      target <- if (!is.null(e$to)) e$to else e$target
      identical(target, node_id)
    }))
  }, node_ids)
  
  return(root_nodes)
}

#' Calculate the maximum depth of the entire graph
#' 
#' @param nodes List of nodes in the graph
#' @param edges List of edges in the graph
#' @return Maximum depth of the graph
calculate_graph_max_depth <- function(nodes, edges) {
  if (is.null(nodes) || length(nodes) == 0) {
    return(0)
  }
  
  # Find all root nodes
  root_nodes <- find_root_nodes(nodes, edges)
  if (length(root_nodes) == 0) {
    # If no root nodes found, the graph might be cyclic
    # Use the first node as starting point
    root_nodes <- c(nodes[[1]]$id)
  }
  
  # Calculate max depth from each root node
  max_depths <- sapply(root_nodes, function(root) {
    calculate_max_depth_from_root(edges, root)
  })
  
  return(max(max_depths))
}

#' Count nodes in a specific snapshot
#' 
#' @param nodes List of nodes
#' @param snapshot Snapshot identifier
#' @return Number of nodes in the snapshot
count_snapshot_nodes <- function(nodes, snapshot) {
  if (is.null(nodes) || is.null(snapshot)) {
    return(0)
  }
  
  sum(sapply(nodes, function(node) {
    identical(node$snapshot, snapshot)
  }))
}

#' Count edges in a specific snapshot
#' 
#' @param edges List of edges
#' @param snapshot Snapshot identifier
#' @return Number of edges in the snapshot
count_snapshot_edges <- function(edges, snapshot) {
  if (is.null(edges) || is.null(snapshot)) {
    return(0)
  }
  
  sum(sapply(edges, function(edge) {
    identical(edge$snapshot, snapshot)
  }))
}

#' Calculate subgraph depth considering constraints
#' 
#' @param subgraph_data Subgraph data including nodes and edges
#' @param max_allowed_depth Maximum allowed depth
#' @param full_graph_depth Full graph depth for validation
#' @return Constrained subgraph depth
calculate_constrained_subgraph_depth <- function(subgraph_data, max_allowed_depth, full_graph_depth) {
  if (is.null(subgraph_data) || is.null(subgraph_data$nodes) || length(subgraph_data$nodes) == 0) {
    return(0)
  }
  
  # Calculate actual subgraph depth
  actual_depth <- if (!is.null(subgraph_data$root_id)) {
    calculate_max_depth_from_root(subgraph_data$edges, subgraph_data$root_id)
  } else {
    calculate_graph_max_depth(subgraph_data$nodes, subgraph_data$edges)
  }
  
  # Apply constraints
  constrained_depth <- min(actual_depth, max_allowed_depth, full_graph_depth)
  return(constrained_depth)
}

# Add new function to calculate full subgraph metrics
#' Calculate the complete subgraph metrics from a root node without depth constraints
#' 
#' @param nodes List of nodes in the graph
#' @param edges List of edges in the graph
#' @param root_id Root node ID
#' @param snapshot Current snapshot
#' @return List containing subgraph metrics
calculate_full_subgraph_metrics <- function(nodes, edges, root_id, snapshot) {
  if (is.null(nodes) || length(nodes) == 0 || is.null(root_id)) {
    return(list(nodes = 0, edges = 0, depth = 0))
  }
  
  # Filter for current snapshot
  snapshot_nodes <- Filter(function(node) node$snapshot == snapshot, nodes)
  snapshot_edges <- Filter(function(edge) edge$snapshot == snapshot, edges)
  
  # Initialize tracking
  visited_nodes <- list()
  visited_edges <- list()
  depths <- list()
  depths[[root_id]] <- 0
  current_level <- list(root_id)
  max_depth <- 0
  
  # Perform BFS to find all reachable nodes and edges
  while (length(current_level) > 0) {
    next_level <- list()
    
    for (node in current_level) {
      visited_nodes[[node]] <- TRUE
      
      # Find all children of current node
      for (edge in snapshot_edges) {
        source <- if (!is.null(edge$from)) edge$from else edge$source
        target <- if (!is.null(edge$to)) edge$to else edge$target
        
        if (identical(source, node)) {
          # Mark edge as visited
          edge_key <- paste(source, target, sep = "->")
          visited_edges[[edge_key]] <- TRUE
          
          if (is.null(depths[[target]])) {
            current_depth <- depths[[node]] + 1
            depths[[target]] <- current_depth
            next_level <- c(next_level, target)
            max_depth <- max(max_depth, current_depth)
          }
        }
      }
    }
    current_level <- next_level
  }
  
  return(list(
    nodes = length(visited_nodes),
    edges = length(visited_edges),
    depth = max_depth
  ))
}

#' Calculate the displayed subgraph metrics with depth constraint
#' 
#' @param nodes List of nodes in the graph
#' @param edges List of edges in the graph
#' @param root_id Root node ID
#' @param snapshot Current snapshot
#' @param max_depth Maximum depth to display
#' @return List containing displayed metrics
calculate_displayed_subgraph_metrics <- function(nodes, edges, root_id, snapshot, max_depth) {
  if (is.null(nodes) || length(nodes) == 0 || is.null(root_id)) {
    return(list(nodes = 0, edges = 0, depth = 0))
  }
  
  # Filter for current snapshot
  snapshot_nodes <- Filter(function(node) node$snapshot == snapshot, nodes)
  snapshot_edges <- Filter(function(edge) edge$snapshot == snapshot, edges)
  
  # Initialize tracking
  visited_nodes <- list()
  visited_edges <- list()
  depths <- list()
  depths[[root_id]] <- 0
  current_level <- list(root_id)
  actual_max_depth <- 0
  
  # Perform BFS with depth constraint
  while (length(current_level) > 0) {
    next_level <- list()
    
    for (node in current_level) {
      visited_nodes[[node]] <- TRUE
      current_depth <- depths[[node]]
      
      # Only process children if we haven't reached max depth
      if (current_depth < max_depth) {
        # Find all children of current node
        for (edge in snapshot_edges) {
          source <- if (!is.null(edge$from)) edge$from else edge$source
          target <- if (!is.null(edge$to)) edge$to else edge$target
          
          if (identical(source, node)) {
            # Mark edge as visited
            edge_key <- paste(source, target, sep = "->")
            visited_edges[[edge_key]] <- TRUE
            
            if (is.null(depths[[target]])) {
              next_depth <- current_depth + 1
              depths[[target]] <- next_depth
              next_level <- c(next_level, target)
              actual_max_depth <- max(actual_max_depth, next_depth)
            }
          }
        }
      }
    }
    current_level <- next_level
  }
  
  return(list(
    nodes = length(visited_nodes),
    edges = length(visited_edges),
    depth = min(actual_max_depth, max_depth)
  ))
} 