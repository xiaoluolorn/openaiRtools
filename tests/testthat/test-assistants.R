# Test Assistants API

test_that("Assistants client initializes", {
  client <- OpenAI$new(api_key = "test-key")
  expect_s3_class(client$assistants, "AssistantsClient")
})

test_that("Assistants methods exist", {
  client <- OpenAI$new(api_key = "test-key")
  
  expect_true(!is.null(client$assistants$create))
  expect_true(!is.null(client$assistants$list))
  expect_true(!is.null(client$assistants$retrieve))
  expect_true(!is.null(client$assistants$update))
  expect_true(!is.null(client$assistants$delete))
})

test_that("Assistants convenience functions exist", {
  expect_true(exists("create_assistant"))
  expect_true(exists("list_assistants"))
  expect_true(exists("retrieve_assistant"))
  expect_true(exists("update_assistant"))
  expect_true(exists("delete_assistant"))
})