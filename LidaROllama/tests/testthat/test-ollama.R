library(testthat)
library(LidaROllama)

test_that("LidaROllama initializes correctly", {
  api <- LidaROllama$new(
    model_name = "llama3:latest",
    temperature = 0.7,
    max_length = 512,
    sysprompt = "Feluda",
    api_url = "http://localhost:11434/api/generate"
  )
  expect_true(inherits(api, "LidaROllama"))
  expect_equal(api$model_name, "llama3:latest")
  expect_equal(api$temperature, 0.7)
  expect_equal(api$max_length, 512)
  expect_equal(api$sysprompt, "Feluda")
  expect_equal(api$api_url, "http://localhost:11434/api/generate")
})
