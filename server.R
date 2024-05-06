library(shiny)
library(R6)
library(curl)
library(jsonlite)


model_list <- read.table(text = system("ollama list", intern = TRUE),
                         sep = "\t", row.names = NULL)
# tabs at the end of each model row adds an additional empty column
model_list$MODIFIED <- NULL
colnames(model_list) <- c("NAME", "ID", "SIZE", "MODIFIED")
model_list$NAME <- trimws(model_list$NAME)
# print(model_list)

# model <- "llama3:latest"
temperature <- 0.7
max_length <- 512
sysprompt <- "You are a helpful assistant. Your name is Feluda and your and you're powered by Meta's open source Llama2 model.
This project is a part of the programme 'Data Science and Business Analytics' at the University of Warsaw.
Be mindfull that Porimol, Nhu and Shoku are the contributors of this project, who gave you this name.
Your main responsibility to assist users only about R programming and given dataset related question based on the given dataset by users. 
R code should be pretify and easy to understand.
If users ask any other question, you can redirect them to the appropriate resources or suggest them to ask the question in the appropriate forum.
Please answer the following questions based on the given dataset."

# Define the EDAApp class
EDAApp <- R6Class(
  "EDAApp",
  public = list(
    data = NULL,
    initialize = function(model_name = "llama2:latest") {
      # Initialize data
      self$data <- data
    },
    server = function(model_name = "llama2:latest") {
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
              self$data <- read.csv(input$file$datapath)

              # Render dataframe header
              output$dataframe_header <- DT::renderDataTable({
                if (!is.null(input$file)) {
                  DT::datatable(self$data)
                }
              })
              
              # Perform summary statistics or any other analysis you need
              summary_data <- summary(self$data)
              # Update the output for the "Summary" tab
              output$null_values_output <- renderPrint({
                sum(is.na(self$data))
              })
              output$analysis_summary <- renderPrint({
                summary_data
              })
              # Extract data types
              data_types <- sapply(self$data, class)
              output$data_types_output <- renderPrint({
                data_types
              })
              updateTabsetPanel(session, "eda_summary", "analysis_summary")
              
              data_types <- sapply(self$data, class)
              output$data_types_output <- renderPrint({
                data_types
              })
            }
          })
        })
        
        chat_data <- reactiveVal(data.frame())
        call_api_with_curl <- function(json_payload) {
          h <- new_handle()
          handle_setopt(h, copypostfields = json_payload)
          handle_setheaders(h,
                            "Content-Type" = "application/json",
                            "Accept" = "application/json")
          response <- curl_fetch_memory("http://localhost:11434/api/generate", handle = h)
          # Parse the response
          parsed_response <- fromJSON(rawToChar(response$content))
          return(trimws(parsed_response$response))
        }
        
        call_ollama_api <- function(prompt, model_name, temperature, max_length, sysprompt) {
          data_list <- list(
            model = model_name, 
            prompt = prompt, 
            system = sysprompt,
            stream = FALSE,
            options = list(
              temperature = temperature,
              num_predict = max_length
            )
          )
          json_payload <- toJSON(
            data_list,
            auto_unbox = TRUE
          )
          call_api_with_curl(json_payload)
        }
        
        observeEvent(input$chat_question_btn, {
          question_input <- trimws(input$question_input)
          if (question_input != "") {
            new_data <- data.frame(source = "User", message = question_input, stringsAsFactors = FALSE)
            chat_data(rbind(chat_data(), new_data))
            gpt_res <- call_ollama_api(prompt = question_input,
                                       model_name = model_name,
                                       temperature = temperature,
                                       max_length = max_length,
                                       sysprompt = sysprompt)
            if (!is.null(gpt_res)) {
              gpt_data <- data.frame(source = "Feluda", message = gpt_res, stringsAsFactors = FALSE)
              chat_data(rbind(chat_data(), gpt_data))
            }
            
            updateTextInput(session, "question_input", value = "")
          }
        })
        
        # Function to highlight R code within mixed_output
        highlight_R_code <- function(output) {
          output <- gsub("```r(.*?)```", "<pre><code class='r'>\\1</code></pre>", output, perl = TRUE)
          return(output)
        }
        
        output$chat_response_output <- renderUI({
          chatBox <- lapply(1:nrow(chat_data()), function(i) {
            print(highlight_R_code(chat_data()[i, "message"]))
            tags$div(
              class = ifelse(
                chat_data()[i, "source"] == "User", 
                "alert alert-secondary", 
                "alert alert-success"
              ),
              HTML(
                # paste0("<b>", chat_data()[i, "source"], ":</b> ", text = chat_data()[i, "message"])
                paste0("<b>", chat_data()[i, "source"], ":</b> ", text = highlight_R_code(chat_data()[i, "message"]))
              )
            )
          })
          do.call(tagList, chatBox)
        })
        
      }
    }
  )
)

# Create an instance of the EDAApp class
app <- EDAApp$new()
server <- app$server()
