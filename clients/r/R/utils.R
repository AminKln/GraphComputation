# Utility Functions

#' Calculate the total weight of a subgraph starting from a given node
#'
#' @param node_id The starting node ID
#' @param nodes List of all nodes
#' @param links List of all links
#' @return The total weight of the subgraph
calculate_subgraph_weight <- function(node_id, nodes, links) {
  # Initialize visited nodes set
  visited <- c()
  
  # Define DFS function
  dfs <- function(current_id) {
    if (current_id %in% visited) {
      return(0)
    }
    
    visited <<- c(visited, current_id)
    
    # Get current node's weight
    current_node <- nodes[[which(sapply(nodes, function(x) x$id == current_id))]]
    weight <- current_node$weight
    
    # Get child nodes
    child_links <- links[sapply(links, function(x) x$source == current_id)]
    
    # Recursively add weights of child nodes
    for (link in child_links) {
      weight <- weight + dfs(link$target)
    }
    
    weight
  }
  
  # Start DFS from the given node
  dfs(node_id)
}

#' Calculate the level of a node in relation to the root node
#'
#' @param node_id The node ID to calculate level for
#' @param root_id The root node ID
#' @param links List of all links
#' @return The level of the node (0 for root, increases with distance from root)
calculate_node_level <- function(node_id, root_id, links) {
  if (node_id == root_id) {
    return(0)
  }
  
  # Initialize queue for BFS
  queue <- list(list(id = root_id, level = 0))
  visited <- c(root_id)
  
  while (length(queue) > 0) {
    # Get current node
    current <- queue[[1]]
    queue <- queue[-1]
    
    # Get child nodes
    child_links <- links[sapply(links, function(x) x$source == current$id)]
    
    for (link in child_links) {
      if (!(link$target %in% visited)) {
        if (link$target == node_id) {
          return(current$level + 1)
        }
        queue[[length(queue) + 1]] <- list(id = link$target, level = current$level + 1)
        visited <- c(visited, link$target)
      }
    }
  }
  
  # If node not found, return NA
  NA
}

#' Filter nodes based on snapshot
#'
#' @param nodes List of all nodes
#' @param snapshot The snapshot to filter by
#' @return Filtered list of nodes
filter_nodes_by_snapshot <- function(nodes, snapshot) {
  if (is.null(snapshot)) {
    return(nodes)
  }
  
  nodes[sapply(nodes, function(x) {
    is.null(x$snapshot) || x$snapshot == snapshot
  })]
}

#' Filter links based on available nodes
#'
#' @param links List of all links
#' @param node_ids Vector of available node IDs
#' @return Filtered list of links
filter_links_by_nodes <- function(links, node_ids) {
  links[sapply(links, function(x) {
    x$source %in% node_ids && x$target %in% node_ids
  })]
}

#' Create a tooltip for a node
#'
#' @param node The node data
#' @param subgraph_weight The calculated subgraph weight
#' @return HTML string for the tooltip
create_node_tooltip <- function(node, subgraph_weight) {
  tooltip <- paste0(
    "<strong>ID:</strong> ", node$id, "<br>",
    "<strong>Weight:</strong> ", node$weight, "<br>",
    "<strong>Subgraph Weight:</strong> ", subgraph_weight
  )
  
  if (!is.null(node$snapshot)) {
    tooltip <- paste0(tooltip, "<br><strong>Snapshot:</strong> ", node$snapshot)
  }
  
  tooltip
}

#' Generate weight distribution data
#'
#' @param nodes List of all nodes
#' @return A data frame with weight distribution
generate_weight_distribution <- function(nodes) {
  weights <- sapply(nodes, function(x) x$weight)
  data.frame(
    weight = weights,
    frequency = 1
  ) %>%
    group_by(weight) %>%
    summarise(count = sum(frequency))
}

#' Generate degree distribution data
#'
#' @param links List of all links
#' @return A data frame with degree distribution
generate_degree_distribution <- function(links) {
  # Calculate in-degree and out-degree for each node
  node_degrees <- data.frame(
    node = c(
      sapply(links, function(x) x$source),
      sapply(links, function(x) x$target)
    )
  ) %>%
    group_by(node) %>%
    summarise(degree = n()) %>%
    arrange(desc(degree))
  
  # Generate distribution
  node_degrees %>%
    group_by(degree) %>%
    summarise(count = n())
}

#' Format number for display
#'
#' @param x The number to format
#' @param digits Number of decimal places
#' @return Formatted string
format_number <- function(x, digits = 2) {
  if (is.na(x) || is.null(x)) {
    return("N/A")
  }
  
  if (x >= 1e9) {
    paste0(format(round(x/1e9, digits), nsmall = digits), "B")
  } else if (x >= 1e6) {
    paste0(format(round(x/1e6, digits), nsmall = digits), "M")
  } else if (x >= 1e3) {
    paste0(format(round(x/1e3, digits), nsmall = digits), "K")
  } else {
    format(round(x, digits), nsmall = digits)
  }
}

# Plotting Functions
generate_weight_distribution <- function(nodes) {
  ggplot(nodes, aes(x = weight)) +
    geom_histogram(bins = 30, fill = "#3c8dbc", color = "white") +
    theme_minimal() +
    labs(
      title = "Node Weight Distribution",
      x = "Weight",
      y = "Count"
    )
}

generate_degree_distribution <- function(metrics) {
  ggplot(metrics, aes(x = Degree)) +
    geom_histogram(bins = 20, fill = "#3c8dbc", color = "white") +
    theme_minimal() +
    labs(
      title = "Node Degree Distribution",
      x = "Degree",
      y = "Count"
    )
}

# Data Processing Functions
filter_nodes_by_snapshot <- function(nodes, snapshot) {
  if (is.null(snapshot)) return(nodes)
  
  Filter(function(x) {
    if ("snapshot" %in% names(x)) {
      x$snapshot == snapshot
    } else {
      TRUE
    }
  }, nodes)
}

filter_links_by_nodes <- function(links, node_ids) {
  Filter(function(x) 
    x$source %in% node_ids && x$target %in% node_ids,
    links
  )
}

create_node_tooltip <- function(node, subgraph_weight) {
  paste(
    "Node:", node$id,
    "<br>Node Weight:", round(node$weight, 2),
    "<br>Subgraph Weight:", round(subgraph_weight, 2),
    if ("snapshot" %in% names(node)) paste("<br>Snapshot:", node$snapshot) else ""
  )
} 