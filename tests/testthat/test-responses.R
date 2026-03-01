# Test Responses API

test_that("Responses client initializes", {
  client <- OpenAI$new(api_key = "test-key")
  expect_s3_class(client$responses, "ResponsesClient")
})

test_that("Responses methods exist", {
  client <- OpenAI$new(api_key = "test-key")
  
  expect_true(!is.null(client$responses$create))
  expect_true(!is.null(client$responses$retrieve))
  expect_true(!is.null(client$responses$delete))
  expect_true(!is.null(client$responses$cancel))
  expect_true(!is.null(client$responses$list_input_items))
})

test_that("Responses convenience functions exist", {
  expect_true(exists("create_response"))
  expect_true(exists("retrieve_response"))
  expect_true(exists("delete_response"))
  expect_true(exists("cancel_response"))
})