# Test Vector Stores API

test_that("Vector stores client initializes", {
  client <- OpenAI$new(api_key = "test-key")
  expect_s3_class(client$vector_stores, "VectorStoresClient")
})

test_that("Vector stores sub-clients initialize", {
  client <- OpenAI$new(api_key = "test-key")
  
  expect_s3_class(client$vector_stores$files, "VectorStoreFilesClient")
  expect_s3_class(client$vector_stores$file_batches, "VectorStoreFileBatchesClient")
})

test_that("Vector stores methods exist", {
  client <- OpenAI$new(api_key = "test-key")
  
  expect_true(!is.null(client$vector_stores$create))
  expect_true(!is.null(client$vector_stores$list))
  expect_true(!is.null(client$vector_stores$retrieve))
  expect_true(!is.null(client$vector_stores$update))
  expect_true(!is.null(client$vector_stores$delete))
  expect_true(!is.null(client$vector_stores$search))
})

test_that("Vector store files methods exist", {
  client <- OpenAI$new(api_key = "test-key")
  
  expect_true(!is.null(client$vector_stores$files$create))
  expect_true(!is.null(client$vector_stores$files$list))
  expect_true(!is.null(client$vector_stores$files$retrieve))
  expect_true(!is.null(client$vector_stores$files$delete))
  expect_true(!is.null(client$vector_stores$files$content))
})

test_that("Vector store convenience functions exist", {
  expect_true(exists("create_vector_store"))
  expect_true(exists("list_vector_stores"))
  expect_true(exists("retrieve_vector_store"))
  expect_true(exists("delete_vector_store"))
})