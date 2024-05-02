library(shiny)
library(R6)

# Define the EDAApp class
EDAApp <- R6Class(
  "EDAApp",
  public = list(
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
server <- app$server()
