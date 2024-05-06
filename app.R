library(shiny)

source("ui.R")
source("server.R")

model_name <- "llama3:latest"
shinyApp(ui = ui, server = server)
