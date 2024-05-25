model_list <- read.table(
  text = system("ollama list", intern = TRUE),
  sep = "\t", 
  row.names = NULL
)

# tabs at the end of each model row adds an additional empty column
model_list$MODIFIED <- NULL
colnames(model_list) <- c("NAME", "ID", "SIZE", "MODIFIED")
model_list$NAME <- trimws(model_list$NAME)

# model <- "llama3:latest"
temperature <- 0.7
max_length <- 512

sysprompt <- "You are a helpful assistant. Your name is Feluda and your and you're powered by Meta's open source Llama2 model.
This project is a part of the course of 'Advanced R' of the programme 'Data Science and Business Analytics' at the University of Warsaw.
Be mindfull that Porimol, Nhu and Shoku are the contributors of this project, who gave you this name.
Your main responsibility to assist users only about R programming based on the given 'CSV dataset' and related question based on the given dataset.
If users asked you to provide statistics of the dataset, please do help them by providing R code.
If users ask you about any other programming related question, politely explain them that your responsibility only about R programming and given dataset."
# sysprompt <- "You are a helpful assistant. Your name is Feluda and your and you're powered by Meta's open source Llama2 model.
# Your main responsibility to assist users only about R programming and if user ask you to perform any task on the given data do it."

# Define the EDAApp class
EDAApp <- R6Class(
  "EDAApp",
  public = list(
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
              correlation_matrix1 <- cor(csv_data)
              output$correlation_matrix <- renderPrint({
                correlation_matrix1
              })
              # cor plot
              
              # Update selectInput choices based on the dataset's column names
              updateSelectInput(session, "col", choices = colnames(csv_data))
              
              output$correlation_plot <- renderPlot({
                req(input$col)  # Ensure input$col is not NULL
                
                selected_data <- csv_data[, input$col, drop = FALSE]
                
                # Generate the correlation chart using PerformanceAnalytics
                chart.Correlation(selected_data, histogram=TRUE, pch=19)
              })
              
              
            
              
              updateTabsetPanel(session, "eda_summary", "analysis_summary")

              data_types <- sapply(csv_data, class)
              output$data_types_output <- renderPrint({
                data_types
              })
              
              ## Explore Data
              # pairs plot - always
              output$expPairsPlot <- renderPlot({
                featurePlot(x=csv_data, 
                            y=csv_data, 
                            plot='pairs', auto.key=list(columns=2))
              })
              
              # generate variable selectors for individual plots
              output$expXaxisVarSelector <- renderUI({
                selectInput('expXaxisVar', 'Variable on x-axis', 
                            choices=as.list(colnames(csv_data)), selected=colnames(csv_data)[1])
              })
              
              getYaxisVarSelector <- function(geom) { 
                # wy = with y, wo = without y (or disable)
                widget <- selectInput('expYaxisVar', 'Variable on y-axis', 
                                      choices=as.list(colnames(csv_data)), selected=colnames(csv_data)[2])
                wy <- widget
                woy <- disable(widget)
                switch(geom,
                       point = wy,
                       boxplot = wy,
                       histogram = woy,
                       density = woy
                )
              }
              output$expYaxisVarSelector <- renderUI({
                getYaxisVarSelector(input$singlePlotGeom)
              })
              
              output$expColorVarSelector <- renderUI({
                selectInput('expColorVar', 'Variable to color by', 
                            choices=as.list(c(colnames(csv_data))))
                            #selected=input$target)
              })
              
              # create ggplot statement based on geom
              add_ggplot <- function(geom) {
                gx <- ggplot(csv_data, aes_string(x=input$expXaxisVar))
                gxy <- ggplot(csv_data, aes_string(x=input$expXaxisVar, y=input$expYaxisVar))
                switch(geom,
                       point = gxy,
                       boxplot = gxy,
                       histogram = gx,
                       density = gx
                )
              }
              
              # create ggplot geom
              add_geom <- function(geom) {
                switch(geom,
                       point = geom_point(aes_string(color=input$expColorVar)),
                       boxplot = geom_boxplot(aes_string(color=input$expColorVar)),
                       histogram = geom_histogram(aes_string(color=input$expColorVar)),
                       density = geom_density(aes_string(color=input$expColorVar))
                )
              }
              
              output$expSinglePlot <- renderPlot({
                g <- add_ggplot(input$singlePlotGeom) + add_geom(input$singlePlotGeom)
                print(g)
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
          prompt <- paste0(" Based on this data: ", json_data, ", Answer this question: ", prompt)
          # print(prompt)
          
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
        
        r_code_highlight <- function(code, language = "r") {
          paste0("<pre><code class = 'language-", language, "'>", code, "</code></pre>")
        }
        
        # Function to extract R code from text
        extract_R_code <- function(text) {
          code <- regmatches(text, regexec("```([^`]*)```", text))[[1]][2]
          if (is.null(code) || !nzchar(code)) {
            return("dddd")
          }
          return(r_code_highlight(code))
        }
        
        # Function to extract text surrounding R code
        extract_surrounding_text <- function(text) {
          surrounding_text <- gsub("```([^`]*)```", "", text)
          if (is.null(surrounding_text) || !nzchar(surrounding_text)) {
            return(NULL)
          }
          return(trimws(surrounding_text))
        }
        
        output$chat_response_output <- renderUI({
          chatBox <- lapply(1:nrow(chat_data()), function(i) {
            text_code <- chat_data()[i, "message"]
            if (is.null(text_code) || !nzchar(text_code)) {
              return(NULL)
            }
            # Extract R code
            r_code <- extract_R_code(text_code)
            extract_text <- extract_surrounding_text(text_code)
            tags$div(
              class = ifelse(
                chat_data()[i, "source"] == "User",
                "alert alert-secondary",
                "alert alert-success"
              ),
              HTML(
                paste0("<b>", chat_data()[i, "source"], ":</b> ", text = extract_text, r_code)
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
