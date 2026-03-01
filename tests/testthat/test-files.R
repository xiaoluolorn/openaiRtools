# Test Files API

test_that("Files client initializes", {
  client <- OpenAI$new(api_key = "test-key")
  expect_s3_class(client$files, "FilesClient")
})

test_that("Files create accepts parameters", {
  client <- OpenAI$new(api_key = "test-key")
  
  # Test that method exists
  expect_true(!is.null(client$files$create))
  expect_true(!is.null(client$files$list))
  expect_true(!is.null(client$files$retrieve))
  expect_true(!is.null(client$files$delete))
  expect_true(!is.null(client$files$content))
})

test_that("Files convenience functions exist", {
  expect_true(exists("upload_file"))
  expect_true(exists("list_files"))
  expect_true(exists("retrieve_file"))
  expect_true(exists("delete_file"))
  expect_true(exists("retrieve_file_content"))
})