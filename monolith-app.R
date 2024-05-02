library(shiny)
library(shinydashboard)
library(R6)


# Define the EDAApp class
EDAApp <- R6Class(
  "EDAApp",
  public = list(
    header = dashboardHeader(
      title = "Feluda Analytica",
      disable = FALSE
    ),
    
    sidebar = dashboardSidebar(
      sidebarMenu(
        menuItem(
          "Dashboard",
          tabName = "dashboard",
          icon = icon("dashboard")
        ),
        menuItem(
          "EDA",
          tabName = "eda",
          icon = icon("file"),
          selected = TRUE
        )
      )
    ),
    
    body = dashboardBody(
      tabItems(
        tabItem(
          tabName = "dashboard",
          fluidRow(
            box(
              title = "Project Title: Enhancing Data Exploration Efficiency: Developing an Automated EDA Tool with ShinyApp in R.", 
              width = 12, 
              solidHeader = TRUE, 
              tags$hr(),
              h4("Contributors:"),
              tableOutput("contributors_table"),
              p("Note: Every contributor makes an equal contribution.")
            )
          ),
          fluidRow(
            box(
              title = "Introduction",
              tags$hr(),
              width = 6, 
              solidHeader = TRUE, 
              "Exploratory Data Analysis (EDA) is one of the crucial parts of Data Science and Machine Learning projects for understanding the datasets better to detect anomalies, and guiding feature engineering in data science projects.",
              tags$br(),
              tags$br(),
              "Developing an automated EDA tool using ShinyApp in R offers efficiency, interactivity, reproducibility, scalability, and customization benefits. Automating the EDA will speed up the analysis, enhance the developer experience, and ensure EDA consistency across projects. Interactive interfaces facilitate deeper exploration of complex datasets and promote transparency in analyses. Using automated EDA tools can be tailored to meet specific project requirements and developer preferences.",
              tags$br(),
              "By focusing on EDA and automation, data scientists can derive insights more efficiently and make better-informed decisions for business."
            ),
            box(
              title = "Motivation",
              tags$hr(),
              width = 6, 
              solidHeader = TRUE, 
              "EDA is the foundation of effective data analysis and communication based on data. However, creating compelling and informative visualizations can be a time-consuming and skill-intensive process.",
              tags$br(),
              tags$br(),
              "Our project aims to streamline the visualization creation process by leveraging the power of large language models (LLMs). Drawing inspiration from the research presented in 'LIDA: A Tool for Automatic Generation of Grammar-Agnostic Visualizations and Infographics using Large Language Models' (Dibia, 2023), we aim to develop a project that will transform natural language descriptions into tailored R EDA.",
              tags$br(),
              tags$br(),
              "In summary, prioritizing EDA and developing automated tools using ShinyApp in R leads to more effective data analysis and facilitates better decision-making in various domains."
            )
          ),
          fluidRow(
            box(
              title = "References", 
              width = 12, 
              solidHeader = TRUE, 
              "Dibia, V. (2023). Lida: A tool for automatic generation of grammar-agnostic visualizations and infographics using large language models. arXiv preprint arXiv:2303.02927."
            )
          )
        ),
        tabItem(
          tabName = "eda",
          tabsetPanel(
            tabPanel(
              id = "data_uploader",
              title = "Data Uploader",
              fluidRow(
                box(
                  title = "Uplaod a CSV file!",
                  #tags$hr(),
                  width = 4, 
                  solidHeader = TRUE, 
                  fileInput(
                    "file",
                    "Please upload a CSV file to perform analysis",
                    accept = ".csv",
                    multiple = FALSE
                  )
                ),
                box(
                  id = "dataframe_header",
                  title = "Uploaded dataset as tabular format",
                  width = 8,
                  fluidRow(
                    box(
                      width = 12, 
                      solidHeader = TRUE,
                      DT::dataTableOutput("dataframe_header")
                    )
                  )
                ),
              ),
            ),
            tabPanel(
              id = "eda_summary",
              title = "EDA Summary",
              fluidRow(
                box(
                  title = "Summary of Exploratory Data Analysis",
                  width = 12, 
                  solidHeader = TRUE, 
                  verbatimTextOutput("analysis_summary"),
                  fluidRow(
                    box(
                      title = "Data Types",
                      width = 6, 
                      solidHeader = TRUE,
                      verbatimTextOutput("data_types_output")
                    ),
                    box(
                      title = "Null Values",
                      width = 6, 
                      solidHeader = TRUE,
                      verbatimTextOutput("null_values_output")
                    ),
                  )
                  
                )
              )
            ),
            tabPanel(
              id = "chat",
              title = "Chat with ChatGPT",
              fluidRow(
                box(
                  title = "Chat with your Dataset using ChatGPT",
                  width = 12, 
                  solidHeader = TRUE, 
                  verbatimTextOutput("chat_questions"),
                  fluidRow(
                    box(
                      title = "Questions",
                      width = 4, 
                      solidHeader = TRUE,
                      textAreaInput(
                        "question_input",
                        label = NULL,
                        placeholder = "Enter your question(s) here",
                        rows = 5
                      ),
                      actionButton(
                        "chat_question_btn",
                        "Ask",
                        class = "btn btn-success btn-block",
                        style="padding: 4px 8px; font-size: 12px; max-width: 100px; align:right;"
                      )
                    ),
                    box(
                      title = "ChatGPT Answers",
                      width = 7, 
                      solidHeader = TRUE,
                      htmlOutput("chat_response_output")
                    ),
                  )
                )
              )
            )
          )
        )
      )
    ),
    
    ui = function() {
      dashboardPage(header = self$header, sidebar = self$sidebar, body = self$body)
    },
    
    server = function() {
      function(input, output, session) {
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
          rownames = FALSE)
        
        updateTabsetPanel(session, "eda_summary")
        
        observeEvent(input$file$datapath, {
          observe({
            # Disable the "Analysis" button if no file is uploaded
            if (is.null(input$file$datapath)) {
              print("No file uploaded")
            } else {
              print("File uploaded")
              
              # Read the uploaded CSV file
              data <- read.csv(input$file$datapath)
              
              # Render dataframe header
              output$dataframe_header <- DT::renderDataTable({
                if (!is.null(input$file)) {
                  #DT::datatable(head(data, 100))
                  DT::datatable(data)
                }
              })
              
              # Perform summary statistics or any other analysis you need
              summary_data <- summary(data)
              # Update the output for the "Summary" tab
              output$null_values_output <- renderPrint({
                sum(is.na(data))
              })
              output$analysis_summary <- renderPrint({
                summary_data
              })
              
              # Extract data types
              data_types <- sapply(data, class)
              output$data_types_output <- renderPrint({
                data_types
              })
              
              updateTabsetPanel(session, "eda_summary", "analysis_summary")
            }
          })
        })
        
        
        # Initialize an empty list to store chat messages
        chat_messages <- reactiveValues(messages = c())
        
        # Observe the "Ask" button click event
        observeEvent(input$chat_question_btn, {
          # Get the text from the input field
          question <- input$question_input
          # Clear the text input field
          updateTextInput(session, "question_input", value = "")
          
          # Add the question to the list of chat messages
          chat_messages$messages <- c(chat_messages$messages, question)
        })
        
        # Render the chat messages
        output$chat_response_output <- renderUI({
          # Reverse the order of chat messages to display the latest one first
          reversed_messages <- rev(chat_messages$messages)
          # Get the number of chat messages
          num_messages <- length(reversed_messages)
          # Initialize an empty character vector to store formatted messages
          formatted_messages <- character(num_messages)
          
          # Iterate over the reversed messages and format them
          for (i in 1:num_messages) {
            # .....here we need to implement OpenAI's API.....
            print(reversed_messages[i])
            formatted_messages[i] <- paste("Question", num_messages - i + 1, ":", reversed_messages[i])
          }
          
          # Join the formatted messages into a single string
          formatted_chat <- paste(formatted_messages, collapse = "<br>")
          # Return the formatted chat string
          HTML(formatted_chat)
        })
        
        
      }
    }
  )
)

# Create an instance of the EDAApp class
app <- EDAApp$new()

# Run the application
shinyApp(
  ui = app$ui(), 
  server = app$server()
)


