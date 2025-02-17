# Application Styles

#' Create application CSS styles
#' 
#' @return A tags$head object containing CSS styles
app_styles <- tags$head(
  tags$style(HTML("
    /* Box styles */
    .box {
      border-top: 3px solid #3c8dbc;
      box-shadow: 0 1px 3px rgba(0,0,0,0.12), 0 1px 2px rgba(0,0,0,0.24);
    }
    
    /* Button styles */
    .btn-primary {
      margin-top: 10px;
    }
    
    /* Loading spinner */
    .loader {
      border: 5px solid #f3f3f3;
      border-radius: 50%;
      border-top: 5px solid #3c8dbc;
      width: 50px;
      height: 50px;
      animation: spin 1s linear infinite;
      margin: 20px auto;
    }
    
    /* Loading animation */
    @keyframes spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }
    
    /* Snapshot text */
    #current_snapshot {
      margin: 10px 0;
      font-weight: bold;
      font-size: 16px;
    }
    
    /* Graph container */
    .graph-container {
      border: 1px solid #ddd;
      border-radius: 4px;
      padding: 10px;
      background: white;
    }
    
    /* Data summary styles */
    .data-summary {
      margin-top: 15px;
    }
    
    /* Search controls */
    .search-controls {
      padding: 10px;
    }
    
    /* Graph controls */
    .graph-controls {
      padding: 15px;
    }
  "))
) 