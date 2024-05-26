library(R6)
# Install the package from the built tarball
if (!requireNamespace("LidaROllama", quietly = TRUE)) {
  install.packages("LidaROllama_0.1.0.tar.gz", repos = NULL, type = "source")
}
# Load the package
library(LidaROllama)


LLMChat <- R6Class(
  "LLMChat",
  inherit = LidaROllama::LidaROllama,
  private = list(
    r_code_highlight = function(code, language = "r") {
      paste0("<pre><code class = 'language-", language, "'>", code, "</code></pre>")
    }
  ),
  
  public = list(
    # Function to extract R code from text
    extract_code = function(text) {
      code <- regmatches(text, regexec("```([^`]*)```", text))[[1]][2]
      if (!is.na(code)) {
        return(private$r_code_highlight(code))
      }
    },
    
    # Function to extract "Text" surrounding R code
    extract_text = function(text) {
      surrounding_text <- gsub("```([^`]*)```", "", text)
      if (is.null(surrounding_text) || !nzchar(surrounding_text)) {
        return(NULL)
      }
      return(trimws(surrounding_text))
    }
  )
)
