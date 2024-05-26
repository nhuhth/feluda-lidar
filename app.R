# Check if a package is installed, and if not, install it
check_and_install <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, dependencies = TRUE)
  }
  library(pkg, character.only = TRUE)
}

# List of required packages
packages <- c("shiny", "shinydashboard", "shinyjs", "R6", "curl",
              "jsonlite", "jsonify", "reshape2", "ggplot2", "dplyr", 
              "PerformanceAnalytics", "this.path", "Rcpp")

# Check and install each package
lapply(packages, check_and_install)
# Get the path of the currently executing script
setwd(this.path::this.dir())

# Load ui and server scripts
source("ui.R")
source("server.R")

shinyApp(ui=ui, server = server)
