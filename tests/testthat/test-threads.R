# Test Threads API

test_that("Threads client initializes", {
  client <- OpenAI$new(api_key = "test-key")
  expect_s3_class(client$threads, "ThreadsClient")
})

test_that("Threads sub-clients initialize", {
  client <- OpenAI$new(api_key = "test-key")
  
  expect_s3_class(client$threads$runs, "RunsClient")
  expect_s3_class(client$threads$messages, "MessagesClient")
})

test_that("Runs sub-client initializes", {
  client <- OpenAI$new(api_key = "test-key")
  
  expect_s3_class(client$threads$runs$steps, "RunStepsClient")
})

test_that("Threads methods exist", {
  client <- OpenAI$new(api_key = "test-key")
  
  expect_true(!is.null(client$threads$create))
  expect_true(!is.null(client$threads$retrieve))
  expect_true(!is.null(client$threads$update))
  expect_true(!is.null(client$threads$delete))
  expect_true(!is.null(client$threads$create_and_run))
})

test_that("Runs methods exist", {
  client <- OpenAI$new(api_key = "test-key")
  
  expect_true(!is.null(client$threads$runs$create))
  expect_true(!is.null(client$threads$runs$list))
  expect_true(!is.null(client$threads$runs$retrieve))
  expect_true(!is.null(client$threads$runs$cancel))
  expect_true(!is.null(client$threads$runs$submit_tool_outputs))
})

test_that("Messages methods exist", {
  client <- OpenAI$new(api_key = "test-key")
  
  expect_true(!is.null(client$threads$messages$create))
  expect_true(!is.null(client$threads$messages$list))
  expect_true(!is.null(client$threads$messages$retrieve))
  expect_true(!is.null(client$threads$messages$update))
  expect_true(!is.null(client$threads$messages$delete))
})

test_that("Threads convenience functions exist", {
  expect_true(exists("create_thread"))
  expect_true(exists("retrieve_thread"))
  expect_true(exists("update_thread"))
  expect_true(exists("delete_thread"))
  expect_true(exists("create_run"))
  expect_true(exists("retrieve_run"))
  expect_true(exists("cancel_run"))
  expect_true(exists("create_message"))
  expect_true(exists("list_messages"))
})