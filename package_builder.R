library(devtools)
library(pkgbuild)
library(roxygen2)
library(this.path)

# Get the path of the currently executing script
path_to_packages <- this.path::this.dir()
path_to_packages <- file.path(path_to_packages, "LidaROllama")
print(path_to_packages)
# Set your working directory to the root of your package
setwd(path_to_packages)
# Generate documentation
roxygenize()
# Check the package
check()
# Build the package
build()

# Install the package from the built tarball
install.packages(file.path(path_to_packages, "_0.1.0.tar.gz"), repos = NULL, type = "source")
# Load the package
library(LidaROllama)

# Use the package
api <- LidaROllama$new(
  model_name = "llama3:latest",
  temperature = 0.7,
  max_length = 512,
  sysprompt = "Feluda",
  api_url = "http://localhost:11434/api/generate"
)
response <- api$ollama_api("What is R?")
print(response)

