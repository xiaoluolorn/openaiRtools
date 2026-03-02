#' Batch Client
#'
#' Client for the OpenAI Batch API. Process large volumes of API requests
#' asynchronously at 50% lower cost than synchronous calls.
#' Access via `client$batch`.
#'
#' @description
#' The Batch API accepts a JSONL file of requests, processes them within
#' a 24-hour window, and returns the results in an output file.
#' Suitable for: bulk embeddings, offline evaluation, large-scale text
#' processing, or any task that does not require immediate results.
#'
#' @section Workflow:
#' 1. Create a JSONL file where each line is one API request (see format below)
#' 2. Upload the file: `client$files$create(file, purpose = "batch")`
#' 3. Create a batch: `client$batch$create(input_file_id, endpoint)`
#' 4. Poll status: `client$batch$retrieve(batch_id)`
#' 5. Download results: `client$files$content(batch$output_file_id)`
#'
#' @section JSONL request format:
#' Each line in the input file must be:
#' \preformatted{
#' {"custom_id": "req-1", "method": "POST",
#'  "url": "/v1/chat/completions",
#'  "body": {"model": "gpt-4o-mini",
#'           "messages": [{"role": "user", "content": "Hello!"}]}}
#' }
#'
#' @export
BatchClient <- R6::R6Class(
  "BatchClient",
  public = list(
    client = NULL,

    # Initialize batch client
    #
    # @param parent Parent OpenAI client
    initialize = function(parent) {
      self$client <- parent
    },

    # @description
    # Create a new batch job from a pre-uploaded input file.
    #
    # @param input_file_id Character. **Required.** The file ID of the
    #   uploaded JSONL batch input file. Must have been uploaded with
    #   `purpose = "batch"` via `client$files$create()`.
    #   Each line in the file defines one API request with `custom_id`,
    #   `method`, `url`, and `body`.
    #
    # @param endpoint Character. **Required.** The API endpoint to call
    #   for each request in the batch:
    #   \itemize{
    #     \item `"/v1/chat/completions"` — Chat completions
    #     \item `"/v1/embeddings"` — Text embeddings
    #     \item `"/v1/completions"` — Legacy completions
    #   }
    #
    # @param completion_window Character. The time window within which
    #   the batch will be completed. Currently only `"24h"` is supported.
    #   Default: `"24h"`.
    #
    # @param metadata Named list or NULL. Arbitrary key-value metadata
    #   to attach to the batch for tracking purposes. Default: NULL.
    #
    # @return A batch object:
    #   \describe{
    #     \item{`$id`}{Character. Batch ID (e.g. `"batch_abc123"`).}
    #     \item{`$status`}{Character. `"validating"`, `"in_progress"`,
    #       `"finalizing"`, `"completed"`, `"failed"`, `"cancelling"`,
    #       `"cancelled"`, `"expired"`.}
    #     \item{`$input_file_id`}{Character. The input file ID.}
    #     \item{`$output_file_id`}{Character or NULL. Set when completed.
    #       Use `client$files$content(batch$output_file_id)` to download.}
    #     \item{`$error_file_id`}{Character or NULL. File with error details.}
    #     \item{`$request_counts`}{List with `$total`, `$completed`, `$failed`.}
    #   }
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    #
    # # Upload input JSONL
    # file_obj <- client$files$create("requests.jsonl", purpose = "batch")
    #
    # # Create the batch
    # batch <- client$batch$create(
    #   input_file_id = file_obj$id,
    #   endpoint      = "/v1/chat/completions"
    # )
    # cat("Batch ID:", batch$id, "\n")
    # cat("Status:", batch$status, "\n")
    #
    # # Poll until done
    # repeat {
    #   batch <- client$batch$retrieve(batch$id)
    #   cat("Status:", batch$status,
    #       "- Progress:", batch$request_counts$completed, "/",
    #       batch$request_counts$total, "\n")
    #   if (batch$status %in% c("completed", "failed", "cancelled")) break
    #   Sys.sleep(60)
    # }
    #
    # # Download results
    # if (!is.null(batch$output_file_id)) {
    #   raw <- client$files$content(batch$output_file_id)
    #   writeLines(strsplit(rawToChar(raw), "\n")[[1]])
    # }
    # }
    create = function(input_file_id, endpoint, completion_window = "24h", metadata = NULL) {
      body <- list(
        input_file_id = input_file_id,
        endpoint = endpoint,
        completion_window = completion_window
      )

      if (!is.null(metadata)) body$metadata <- metadata

      self$client$request("POST", "/batches", body = body)
    },

    # @description
    # List batch jobs for your account.
    #
    # @param after Character or NULL. Pagination cursor — the batch ID of
    #   the last item from a previous page. Default: NULL.
    #
    # @param limit Integer or NULL. Maximum number of batches to return.
    #   Default: NULL (API default 20).
    #
    # @return A list with `$data` — a list of batch objects.
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # batches <- client$batch$list(limit = 10)
    # for (b in batches$data) cat(b$id, "-", b$status, "\n")
    # }
    list = function(after = NULL, limit = NULL) {
      query <- list()
      if (!is.null(after)) query$after <- after
      if (!is.null(limit)) query$limit <- limit

      self$client$request("GET", "/batches", query = query)
    },

    # @description
    # Retrieve the current status of a specific batch.
    # Poll this to check progress and get the output file ID when done.
    #
    # @param batch_id Character. **Required.** The batch ID
    #   (e.g. `"batch_abc123"`).
    #
    # @return A batch object (see `$create()` return value).
    #   When `$status == "completed"`, use `$output_file_id` to
    #   download results.
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # batch <- client$batch$retrieve("batch_abc123")
    # cat("Status:", batch$status, "\n")
    # cat("Completed:", batch$request_counts$completed, "/",
    #     batch$request_counts$total, "\n")
    # }
    retrieve = function(batch_id) {
      self$client$request("GET", paste0("/batches/", batch_id))
    },

    # @description
    # Cancel a running batch. In-progress requests may still complete.
    # The batch status will transition to `"cancelling"` then `"cancelled"`.
    #
    # @param batch_id Character. **Required.** The batch ID to cancel.
    #
    # @return The updated batch object with `$status = "cancelling"`.
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # result <- client$batch$cancel("batch_abc123")
    # cat("Status:", result$status)  # "cancelling"
    # }
    cancel = function(batch_id) {
      self$client$request("POST", paste0("/batches/", batch_id, "/cancel"))
    }
  )
)

#' Create a Batch Job (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and calls `client$batch$create()`.
#'
#' @param input_file_id Character. **Required.** File ID of the uploaded
#'   JSONL batch input file (uploaded with `purpose = "batch"`).
#' @param endpoint Character. **Required.** API endpoint for each request.
#'   One of `"/v1/chat/completions"`, `"/v1/embeddings"`, `"/v1/completions"`.
#' @param ... Additional parameters passed to [BatchClient]`$create()`,
#'   such as `completion_window` (default `"24h"`) and `metadata`.
#'
#' @return A batch object with `$id` and `$status`.
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#'
#' batch <- create_batch(
#'   input_file_id = "file-abc123",
#'   endpoint      = "/v1/chat/completions"
#' )
#' cat("Batch ID:", batch$id)
#' }
create_batch <- function(input_file_id, endpoint, ...) {
  client <- OpenAI$new()
  client$batch$create(input_file_id = input_file_id, endpoint = endpoint, ...)
}

#' List Batch Jobs (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and lists batch jobs.
#'
#' @param ... Additional parameters passed to [BatchClient]`$list()`,
#'   such as `limit` and `after` (pagination cursor).
#'
#' @return A list with `$data` — a list of batch objects, each containing
#'   `$id`, `$status`, `$request_counts`, and `$output_file_id`.
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#'
#' batches <- list_batches(limit = 5)
#' for (b in batches$data) cat(b$id, b$status, "\n")
#' }
list_batches <- function(...) {
  client <- OpenAI$new()
  client$batch$list(...)
}

#' Retrieve a Batch Job (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and retrieves a specific batch.
#' Use this to poll status and get the `output_file_id` when the batch
#' is complete.
#'
#' @param batch_id Character. **Required.** The batch ID (e.g. `"batch_abc123"`).
#'
#' @return A batch object with `$status`, `$request_counts`
#'   (`$total`, `$completed`, `$failed`), and `$output_file_id` (when done).
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#'
#' batch <- retrieve_batch("batch_abc123")
#' cat("Status:", batch$status)
#' if (batch$status == "completed") {
#'   raw <- retrieve_file_content(batch$output_file_id)
#'   cat(rawToChar(raw))
#' }
#' }
retrieve_batch <- function(batch_id) {
  client <- OpenAI$new()
  client$batch$retrieve(batch_id)
}

#' Cancel a Batch Job (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and cancels a batch job.
#'
#' @param batch_id Character. **Required.** The batch ID to cancel.
#'
#' @return A batch object with `$status = "cancelling"`.
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#'
#' result <- cancel_batch("batch_abc123")
#' cat("Status:", result$status)
#' }
cancel_batch <- function(batch_id) {
  client <- OpenAI$new()
  client$batch$cancel(batch_id)
}
