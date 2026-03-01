# Test Completions API (Legacy)

test_that("Completions client initializes", {
  client <- OpenAI$new(api_key = "test-key")
  expect_s3_class(client$completions, "CompletionsClient")
})

test_that("Completions create accepts parameters", {
  client <- OpenAI$new(api_key = "test-key")
  
  expect_error(
    client$completions$create(
      prompt = "Hello",
      model = "gpt-3.5-turbo-instruct"
    ),
    NA
  )
})

test_that("create_completion convenience function exists", {
  expect_true(exists("create_completion"))
})