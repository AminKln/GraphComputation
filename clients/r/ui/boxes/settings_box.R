# Settings Box Component

#' Create a settings box for visualization controls
#' 
#' @return A shinydashboard box containing visualization settings
settings_box <- function() {
  box(
    title = "Visualization Settings",
    width = 12,
    status = "primary",
    solidHeader = TRUE,
    collapsible = TRUE,
    
    # Add JavaScript for handling visualization settings
    tags$script("
      $(document).ready(function() {
        // Function to get network instance
        function getNetwork(id) {
          var elem = document.getElementById(id);
          return elem ? elem.network : null;
        }
        
        // Handle node size changes
        Shiny.addCustomMessageHandler('update-node-size', function(message) {
          var network = getNetwork('graph_vis');
          var preview = getNetwork('preview_vis');
          
          var options = {
            nodes: {
              size: message.size
            }
          };
          
          if (network) network.setOptions(options);
          if (preview) preview.setOptions(options);
        });
        
        // Handle level separation changes
        Shiny.addCustomMessageHandler('update-level-separation', function(message) {
          var network = getNetwork('graph_vis');
          var preview = getNetwork('preview_vis');
          
          var options = {
            layout: {
              hierarchical: {
                levelSeparation: message.separation
              }
            }
          };
          
          if (network) {
            network.setOptions(options);
            network.redraw();
          }
          if (preview) {
            preview.setOptions(options);
            preview.redraw();
          }
        });
        
        // Handle node color changes
        Shiny.addCustomMessageHandler('update-node-color', function(message) {
          var network = getNetwork('graph_vis');
          var preview = getNetwork('preview_vis');
          
          var options = {
            nodes: {
              color: {
                background: message.color,
                border: '#013848',
                highlight: {
                  background: '#FF8000',
                  border: '#013848'
                }
              }
            }
          };
          
          if (network) {
            network.setOptions(options);
            network.redraw();
          }
          if (preview) {
            preview.setOptions(options);
            preview.redraw();
          }
        });
        
        // Handle edge color changes
        Shiny.addCustomMessageHandler('update-edge-color', function(message) {
          var network = getNetwork('graph_vis');
          var preview = getNetwork('preview_vis');
          
          var options = {
            edges: {
              color: {
                color: message.color,
                highlight: '#FF8000'
              }
            }
          };
          
          if (network) {
            network.setOptions(options);
            network.redraw();
          }
          if (preview) {
            preview.setOptions(options);
            preview.redraw();
          }
        });
      });
    "),
    
    fluidRow(
      # Preview Visualization
      column(
        width = 12,
        div(
          style = "border: 1px solid #ddd; border-radius: 4px; padding: 10px; background: white; margin-bottom: 20px;",
          h4("Preview", style = "text-align: center; margin-bottom: 15px;"),
          uiOutput("preview_vis", height = "200px")
        )
      )
    ),
    
    fluidRow(
      # Node Settings
      column(
        width = 6,
        div(
          style = "padding: 15px;",
          h4("Node Settings"),
          numericInput(
            "node_size",
            "Node Size",
            value = 25,
            min = 10,
            max = 50,
            step = 5,
            width = "100%"
          ),
          colourpicker::colourInput(
            "node_color",
            "Node Color",
            value = "#97C2FC"
          )
        )
      ),
      
      # Layout and Edge Settings
      column(
        width = 6,
        div(
          style = "padding: 15px;",
          h4("Layout Settings"),
          numericInput(
            "level_separation",
            "Level Separation",
            value = 150,
            min = 50,
            max = 300,
            step = 10,
            width = "100%"
          ),
          colourpicker::colourInput(
            "edge_color",
            "Edge Color",
            value = "#2B7CE9"
          )
        )
      )
    )
  )
} 