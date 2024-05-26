# LidaROllama

LidaROllama is an R6 class for generating text using the Ollama API.

## Installation

You can install the development version of LidaROllama from GitHub with:

```r
# install.packages("devtools")
devtools::install_github("porimol/LidaROllama")
```

## Example
```r
library(LidaROllama)

api <- LidaROllama(
  model_name = "llama3:latest",
  temperature = 0.7,
  max_length = 512,
  sysprompt = "Feluda",
  api_url = "http://localhost:11434/api/generate"
)
response <- api$ollama_api("What is R?")
print(response)
```