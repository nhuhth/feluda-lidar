#' @title LidaROllama: An R6 Class for Interacting with the Ollama API
#'
#' @description
#' `LidaROllama` is an R6 class for generating text using the Ollama API.
#'
#' @name LidaROllama
#' @docType class
#' @import R6
#' @import jsonlite
#' @import curl
#' @export
#' @keywords package
#' @return An instance of the `LidaROllama` class.
#' @examples
#' \dontrun{
#' api <- LidaROllama$new(
#'   model_name = "llama3:latest",
#'   temperature = 0.7,
#'   max_length = 512,
#'   sysprompt = "Feluda",
#'   api_url = "http://localhost:11434/api/generate"
#' )
#' response <- api$ollama_api("What is R?")
#' print(response)
#' }

LidaROllama <- R6Class(
  "LidaROllama",
  private = list(
    api_call = function(api_url, json_payload) {
      if (is.null(api_url)) {
        api_url <- "http://localhost:11434/api/generate"
      }
      handle <- curl::new_handle()
      curl::handle_setopt(
        handle,
        copypostfields = json_payload
      )
      curl::handle_setheaders(handle,
                              "Content-Type" = "application/json",
                              "Accept" = "application/json")
      response <- curl::curl_fetch_memory(
        api_url,
        handle = handle
      )
      # Parse the response
      parsed_response <- jsonlite::fromJSON(rawToChar(response$content))
      return(trimws(parsed_response$response))
    }
  ),
  
  public = list(
    model_name = NULL,
    temperature = NULL,
    max_length = NULL,
    sysprompt = NULL,
    api_url = NULL,
    
    initialize = function(
    model_name,
    temperature,
    max_length,
    sysprompt,
    api_url
    ) {
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
      json_payload <- jsonlite::toJSON(
        data_list,
        auto_unbox = TRUE
      )
      return(private$api_call(self$api_url, json_payload))
    }
  )
)
