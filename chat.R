LLMChat <- R6Class(
  "LLMChat",
  private = list(
    api_call = function(api_url, json_payload) {
      if (is.null(api_url)) {
        api_url <- "http://localhost:11434/api/generate"
      }
      handle <- new_handle()
      handle_setopt(
        handle,
        copypostfields = json_payload
      )
      handle_setheaders(handle,
                        "Content-Type" = "application/json",
                        "Accept" = "application/json")
      response <- curl_fetch_memory(
        api_url,
        handle = handle
      )
      # Parse the response
      parsed_response <- fromJSON(rawToChar(response$content))
      return(trimws(parsed_response$response))
    },
    
    r_code_highlight = function(code, language = "r") {
      paste0("<pre><code class = 'language-", language, "'>", code, "</code></pre>")
    }
  ),
  
  public = list(
    model_name=NULL,
    temperature=NULL,
    max_length=NULL,
    sysprompt=NULL,
    api_url=NULL,
    
    initialize = function(
    model_name,
    temperature,
    max_length,
    sysprompt,
    api_url) {
      # defensive programming
      # check if the input is of the correct type
      stopifnot(
        is.character(model_name),
        is.numeric(temperature),
        is.numeric(max_length),
        is.character(sysprompt)
      )
      self$model_name = model_name
      self$temperature = temperature
      self$max_length = max_length
      self$sysprompt = sysprompt
      self$api_url = api_url
      
      invisible(self)
    },
    
    ollama_api = function(prompt) {
      prompt <- paste0(" Based on this data: ", json_data, ", Answer this question: ", prompt)
      data_list <- list(
        model = self$model_name, 
        prompt = prompt, 
        system = self$sysprompt,
        stream = FALSE,
        options = list(
          temperature = self$temperature,
          num_predict = self$max_length
        )
      )
      json_payload <- toJSON(
        data_list,
        auto_unbox = TRUE
      )
      private$api_call(self$api_url, json_payload)
    },
    
    # Function to extract "R" code from "Text"
    extract_R_code = function(text) {
      code <- regmatches(text, regexec("```([^`]*)```", text))[[1]][2]
      if (is.null(code) || !nzchar(code)) {
        return(NULL)
      }
      return(private$r_code_highlight(code))
    },
    
    # Function to extract "Text" surrounding R code
    extract_surrounding_text = function(text) {
      surrounding_text <- gsub("```([^`]*)```", "", text)
      if (is.null(surrounding_text) || !nzchar(surrounding_text)) {
        return(NULL)
      }
      return(trimws(surrounding_text))
    }
  )
)
