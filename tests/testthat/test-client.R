# Test OpenAI Client Initialization

test_that("OpenAI client initializes with API key", {
  # Test with explicit API key
  client <- OpenAI$new(api_key = "test-key-123")
  expect_equal(client$api_key, "test-key-123")
  expect_equal(client$base_url, "https://api.openai.com/v1")
  expect_equal(client$timeout, 600)
  expect_equal(client$max_retries, 2)
})

test_that("OpenAI client requires API key", {
  # Temporarily unset environment variable
  old_key <- Sys.getenv("OPENAI_API_KEY", unset = NA)
  Sys.unsetenv("OPENAI_API_KEY")

  on.exit({
    if (!is.na(old_key)) {
      Sys.setenv(OPENAI_API_KEY = old_key)
    }
  })

  expect_error(OpenAI$new(), "No API key provided")
})

test_that("OpenAI client accepts custom base URL", {
  client <- OpenAI$new(api_key = "test-key", base_url = "https://custom.api.com/v1")
  expect_equal(client$base_url, "https://custom.api.com/v1")
})

test_that("OpenAI client initializes all sub-clients", {
  client <- OpenAI$new(api_key = "test-key")
  expect_s3_class(client$chat, "ChatClient")
  expect_s3_class(client$embeddings, "EmbeddingsClient")
  expect_s3_class(client$images, "ImagesClient")
  expect_s3_class(client$audio, "AudioClient")
  expect_s3_class(client$models, "ModelsClient")
  expect_s3_class(client$fine_tuning, "FineTuningClient")
  expect_s3_class(client$files, "FilesClient")
  expect_s3_class(client$moderations, "ModerationsClient")
  expect_s3_class(client$completions, "CompletionsClient")
  expect_s3_class(client$batch, "BatchClient")
  expect_s3_class(client$uploads, "UploadsClient")
  expect_s3_class(client$assistants, "AssistantsClient")
  expect_s3_class(client$threads, "ThreadsClient")
  expect_s3_class(client$vector_stores, "VectorStoresClient")
  expect_s3_class(client$responses, "ResponsesClient")
})

test_that("OpenAI client accepts organization and project", {
  client <- OpenAI$new(
    api_key = "test-key",
    organization = "org-123",
    project = "proj-456"
  )
  expect_equal(client$organization, "org-123")
  expect_equal(client$project, "proj-456")
})

test_that("OpenAI client accepts max_retries parameter", {
  client <- OpenAI$new(api_key = "test-key", max_retries = 5)
  expect_equal(client$max_retries, 5)
})

test_that("OpenAI client has request_multipart and request_raw methods", {
  client <- OpenAI$new(api_key = "test-key")
  expect_true("request_multipart" %in% names(client))
  expect_true("request_raw" %in% names(client))
  expect_true("build_headers" %in% names(client))
})

test_that("Chat completions has messages sub-client", {
  client <- OpenAI$new(api_key = "test-key")
  expect_s3_class(client$chat$completions$messages, "ChatCompletionsMessagesClient")
})

test_that("Fine-tuning jobs has checkpoints sub-client", {
  client <- OpenAI$new(api_key = "test-key")
  expect_s3_class(client$fine_tuning$jobs$checkpoints, "FineTuningCheckpointsClient")
})
