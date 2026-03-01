# Test Batch API

test_that("Batch client initializes", {
  client <- OpenAI$new(api_key = "test-key")
  expect_s3_class(client$batch, "BatchClient")
})

test_that("Batch methods exist", {
  client <- OpenAI$new(api_key = "test-key")
  
  expect_true(!is.null(client$batch$create))
  expect_true(!is.null(client$batch$list))
  expect_true(!is.null(client$batch$retrieve))
  expect_true(!is.null(client$batch$cancel))
})

test_that("Batch convenience functions exist", {
  expect_true(exists("create_batch"))
  expect_true(exists("list_batches"))
  expect_true(exists("retrieve_batch"))
  expect_true(exists("cancel_batch"))
})