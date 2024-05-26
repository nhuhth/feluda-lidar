library(shiny)
library(shinydashboard)
library(PerformanceAnalytics)
library(R6)
library(reshape2)
library(jsonify)
library(dplyr)
library(Rcpp)

source("chat.R")
source("eda.R")
sourceCpp("corrMatrix.cpp")
# Define the LIDArApp class
LIDArApp <- R6Class(
  "LIDArApp",
  public = list(
    llm_chat = NULL,
    eda = NULL,
    
    initialize = function(sys_prompt) {
      # Initialize the LLMChat object
      self$llm_chat <- LLMChat$new(
        model_name = "llama3:latest",
        temperature = 0.7,
        max_length = 512,
        sysprompt = sys_prompt,
        api_url = "http://localhost:11434/api/generate"
      )
      # Initialize the EDA object
      self$eda <- EDA$new()
    },
    
    # Function about project contributors
    project_contributors = function(output) {
      # Data frame of contributors
      contributors_df <- data.frame(
        Fullname = c("Porimol Chandro", "Shokoufe Naseri", "Ho Thi Hoang Nhu"),
        Student.ID = c(468264, 466750, 466503),
        Email = c("p.chandro@student.uw.edu.pl", "s.naseri@student.uw.edu.pl", "t.ho2@student.uw.edu.pl"),
        stringsAsFactors = FALSE
      )
      contributors_df$Student.ID <- format(contributors_df$Student.ID, scientific = FALSE)
      
      # Render contributors table
      output$contributors_table <- renderTable({
          contributors_df
        },
        rownames = FALSE
      )
    },

    server = function() {
      function(input, output, session) {
        # call the project contributors function
        self$project_contributors(output)
        
        updateTabsetPanel(session, "eda_summary")
        
        csv_to_json_data <- reactiveVal(NULL)
        observeEvent(input$file$datapath, {
          observe({
            # Disable the "Analysis" button if no file is uploaded
            if (is.null(input$file$datapath)) {
              print("No file uploaded")
            } else {
              print("File uploaded")
              
              # Read the uploaded CSV file
              csv_data <- read.csv(input$file$datapath)
              # json_data <<- jsonify::to_json(csv_data)
              json_data <<- csv_to_json_data(jsonify::to_json(csv_data))
              
              # Render dataframe header
              output$dataframe <- DT::renderDataTable({
                if (!is.null(input$file)) {
                  DT::datatable(csv_data)
                }
              })
              
              # Render dataframe header
              output$dataframe_header <- DT::renderDataTable({
                if (!is.null(input$file)) {
                  DT::datatable(head(csv_data, 5))
                }
              })
              
              # Perform summary statistics or any other analysis you need
              summary_data <- summary(csv_data)
              # Update the output for the "Summary" tab
              output$null_values_output <- renderPrint({
                sum(is.na(csv_data))
              })
              output$analysis_summary <- renderPrint({
                summary_data
              })
              # Extract data types
              data_types <- sapply(csv_data, class)
              output$data_types_output <- renderPrint({
                data_types
              })
              # Correlation Matrix
              output$correlation_matrix <- renderPrint({
                corrMatrix(as.matrix(csv_data))
              })
              
              # Update selectInput choices based on the dataset's column names
              updateSelectInput(session, "col", choices = colnames(csv_data))
              
              # Dynamic correlation Matrix
              output$dynamic_corr_matrix <- renderPrint({
                req(input$col)  # Ensure input$col is not NULL

                selected_data <- csv_data[, input$col, drop = FALSE]
                # Correlation Matrix
                dynamic_matrix <- cor(selected_data)
                dynamic_matrix
              })

              output$correlation_plot <- renderPlot({
                req(input$col)  # Ensure input$col is not NULL
                
                selected_data <- csv_data[, input$col, drop = FALSE]
                # Correlation Matrix
                corr_matrix1 <- cor(selected_data)
                
                # Convert the correlation matrix to a long-format dataframe
                corr_df <- melt(corr_matrix1)
                
                # Plot the correlation matrix using ggplot2
                ggplot(corr_df, aes(Var2, Var1, fill = value)) +
                  geom_tile(color = "white") +
                  scale_fill_gradient2(low = "blue", high = "red", mid = "white", midpoint = 0, limit = c(-1,1), space = "Lab",
                                       name="Correlation") +
                  labs(
                    title = "Correlation color range (-1, 1)",
                    x = "X-axis Feature Variables",
                    y = "Y-axis Feature Variables"
                  ) +
                  theme_minimal() +
                  theme(axis.text.x = element_text(angle = 45, vjust = 1, size = 8, hjust = 1)) +
                  coord_fixed()
              })
              
              output$correlation_histogram_plot <- renderPlot({
                req(input$col)  # Ensure input$col is not NULL

                selected_data <- csv_data[, input$col, drop = FALSE]

                # Generate the correlation chart using PerformanceAnalytics
                chart.Correlation(selected_data, histogram=TRUE, pch=19)
                mtext("Correlation Matrix with Histogram", outer = TRUE, line = -1, cex = 1)
              })

              updateTabsetPanel(session, "eda_summary", "analysis_summary")

              data_types <- sapply(csv_data, class)
              output$data_types_output <- renderPrint({
                data_types
              })
              
              # Visualize Data
              # generate variable selectors for individual plots
              output$expXaxisVarSelector <- renderUI({
                selectInput(
                  'expXaxisVar',
                  'Variable on x-axis',
                  choices=as.list(colnames(csv_data)), selected=colnames(csv_data)[1]
                )
              })
              
              output$expYaxisVarSelector <- renderUI({
                self$eda$getYaxisVarSelector(csv_data, input$singlePlotGeom, output)
              })
              
              observeEvent(input$singlePlotGeom, {
                if (input$singlePlotGeom == "point") {
                  output$expColorVarSelector <- renderUI({
                    selectInput(
                      'expColorVar',
                      'Variable to color by',
                      choices=as.list(c(colnames(csv_data)))
                    )
                  })
                }
              })
              
              output$expSinglePlot <- renderPlot({
                self$eda$add_ggplot(csv_data, input) + self$eda$add_geom(input)
              })
            }
          })
        })
        
        # Llama Chatbot
        chat_data <- reactiveVal(data.frame())
        observeEvent(input$chat_question_btn, {
          question_input <- trimws(input$question_input)
          if (question_input != "") {
            new_data <- data.frame(source = "User", message = question_input, stringsAsFactors = FALSE)
            chat_data(rbind(chat_data(), new_data))
            gpt_res <- self$llm_chat$ollama_api(prompt = question_input)
            if (!is.null(gpt_res)) {
              gpt_data <- data.frame(source = "Feluda", message = gpt_res, stringsAsFactors = FALSE)
              chat_data(rbind(chat_data(), gpt_data))
            }
            updateTextInput(session, "question_input", value = "")
          }
        })
        
        output$chat_response_output <- renderUI({
          chatBox <- lapply(1:nrow(chat_data()), function(i) {
            text_code <- chat_data()[i, "message"]
            if (is.null(text_code) || !nzchar(text_code)) {
              return(NULL)
            }
            # Extract R code
            r_code <- self$llm_chat$extract_code(text_code)

            # Extract surrounding text
            surrounding_text <- self$llm_chat$extract_text(text_code)
            tags$div(
              class = ifelse(
                chat_data()[i, "source"] == "User",
                "alert alert-secondary",
                "alert alert-success"
              ),
              HTML(
                if (length(r_code) > 0) {
                  paste0("<b>", chat_data()[i, "source"], ":</b> ", text = surrounding_text, r_code)
                } else {
                  paste0("<b>", chat_data()[i, "source"], ":</b> ", text = surrounding_text)
                }
              )
            )
          })
          do.call(tagList, chatBox)
        })

      }
    }
  )
)

sys_prompt <- "You are a helpful assistant. Your name is Feluda and your and you're powered by Meta's open source Llama2 model.
This project is a part of the course of 'Advanced R' of the programme 'Data Science and Business Analytics' at the University of Warsaw.
Be mindfull that Porimol, Nhu and Shoku are the contributors of this project, who gave you this name.
Your main responsibility to assist users only about R programming based on the given 'CSV dataset' and related question based on the given dataset.
If users asked you to provide statistics of the dataset, please do help them by providing R code.
If users ask you about any other programming related question, politely explain them that your responsibility only about R programming and given dataset."
# sysprompt <- "You are a helpful assistant. Your name is Feluda and your and you're powered by Meta's open source Llama2 model.
# Your main responsibility to assist users only about R programming and if user ask you to perform any task on the given data do it."

# Create an instance of the LIDArApp class
app <- LIDArApp$new(sys_prompt)
server <- app$server()
