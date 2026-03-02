#' Files Client
#'
#' Client for the OpenAI Files API. Upload, list, retrieve, and delete files
#' that can be used with fine-tuning, assistants, batch processing, and more.
#' Access via `client$files`.
#'
#' @section Methods:
#' \describe{
#'   \item{`$create(file, purpose)`}{Upload a file}
#'   \item{`$list(...)`}{List uploaded files, optionally filter by purpose}
#'   \item{`$retrieve(file_id)`}{Get metadata for a specific file}
#'   \item{`$delete(file_id)`}{Delete a file}
#'   \item{`$content(file_id)`}{Download the raw content of a file}
#'   \item{`$wait_for_processing(file_id, ...)`}{Poll until a file is processed}
#' }
#'
#' @export
FilesClient <- R6::R6Class(
  "FilesClient",
  public = list(
    client = NULL,

    # Initialize files client
    #
    # @param parent Parent OpenAI client
    initialize = function(parent) {
      self$client <- parent
    },

    # @description
    # Upload a file to OpenAI. Files are used for fine-tuning, assistants,
    # batch requests, and vision inputs.
    #
    # @param file Character or raw. **Required.** Either:
    #   \itemize{
    #     \item A local file path (character string) — the file must exist.
    #     \item A `raw` vector of file bytes (for programmatically created content).
    #   }
    #   Maximum file size: 512 MB for most purposes.
    #
    # @param purpose Character. **Required.** Intended use of the uploaded file:
    #   \itemize{
    #     \item `"assistants"` — For use with Assistants and Message attachments.
    #       Accepts: txt, pdf, docx, csv, xlsx, and more.
    #     \item `"vision"` — For vision inputs in Assistants. Accepts images.
    #     \item `"batch"` — For Batch API input files (JSONL format).
    #     \item `"fine-tune"` — Training data for fine-tuning (JSONL format).
    #       Each line must be
    #       `{"messages": [{"role": "user", "content": "..."}, ...]}`
    #   }
    #
    # @return A file object (named list):
    #   \describe{
    #     \item{`$id`}{Character. File ID (starts with `"file-"`). Use this
    #       to reference the file in other API calls.}
    #     \item{`$object`}{Always `"file"`.}
    #     \item{`$bytes`}{Integer. File size in bytes.}
    #     \item{`$created_at`}{Integer. Unix timestamp.}
    #     \item{`$filename`}{Character. Original filename.}
    #     \item{`$purpose`}{Character. The purpose you specified.}
    #     \item{`$status`}{Character. Processing status: `"uploaded"`,
    #       `"processed"`, or `"error"`.}
    #   }
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    #
    # # Upload a fine-tuning JSONL file
    # file_obj <- client$files$create(
    #   file    = "training_data.jsonl",
    #   purpose = "fine-tune"
    # )
    # cat("File ID:", file_obj$id, "\n")  # e.g., "file-abc123"
    #
    # # Upload a PDF for use with an Assistant
    # file_obj <- client$files$create(
    #   file    = "annual_report.pdf",
    #   purpose = "assistants"
    # )
    # cat("File ID:", file_obj$id, "\n")
    # }
    create = function(file, purpose) {
      # Determine file parameter
      if (is.character(file) && file.exists(file)) {
        file_param <- httr2::curl_file(file)
      } else if (is.raw(file)) {
        file_param <- file
      } else {
        OpenAIError("file must be a valid file path or raw bytes")
      }

      self$client$request_multipart(
        "POST", "/files",
        file = file_param,
        purpose = purpose
      )
    },

    # @description
    # List files that have been uploaded to your account.
    #
    # @param purpose Character or NULL. Filter results to only files with
    #   this purpose. One of: `"assistants"`, `"vision"`, `"batch"`,
    #   `"fine-tune"`. If NULL, all files are returned. Default: NULL.
    #
    # @param limit Integer or NULL. Maximum number of files to return
    #   (1–10000). Default: NULL (API default 10000).
    #
    # @param after Character or NULL. Pagination cursor — the file ID of
    #   the last result from a previous page. Default: NULL.
    #
    # @param order Character or NULL. Sort order by creation time:
    #   `"asc"` or `"desc"`. Default: NULL (API default `"desc"`).
    #
    # @return A named list:
    #   \describe{
    #     \item{`$data`}{List of file objects (see `$create()` return value).}
    #     \item{`$has_more`}{Logical. Whether more results exist.}
    #   }
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    #
    # # List all files
    # files <- client$files$list()
    # cat("Total files:", length(files$data), "\n")
    # for (f in files$data) cat(f$id, "-", f$filename, "\n")
    #
    # # List only fine-tuning files
    # ft_files <- client$files$list(purpose = "fine-tune")
    # }
    list = function(purpose = NULL, limit = NULL, after = NULL, order = NULL) {
      query <- list()
      if (!is.null(purpose)) query$purpose <- purpose
      if (!is.null(limit)) query$limit <- limit
      if (!is.null(after)) query$after <- after
      if (!is.null(order)) query$order <- order

      self$client$request("GET", "/files", query = query)
    },

    # @description
    # Retrieve metadata for a specific file by its ID.
    # Does not return the file content — use `$content()` for that.
    #
    # @param file_id Character. **Required.** The file ID (starts with `"file-"`).
    #
    # @return A file object (same structure as returned by `$create()`).
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # info <- client$files$retrieve("file-abc123")
    # cat("Filename:", info$filename, "\n")
    # cat("Size:", info$bytes, "bytes\n")
    # cat("Status:", info$status, "\n")
    # }
    retrieve = function(file_id) {
      self$client$request("GET", paste0("/files/", file_id))
    },

    # @description
    # Delete an uploaded file. Files in use by a running fine-tuning job
    # cannot be deleted.
    #
    # @param file_id Character. **Required.** The file ID to delete.
    #
    # @return A list with:
    #   \describe{
    #     \item{`$id`}{Character. The deleted file ID.}
    #     \item{`$object`}{Always `"file"`.}
    #     \item{`$deleted`}{Logical. `TRUE` if deletion was successful.}
    #   }
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # result <- client$files$delete("file-abc123")
    # cat("Deleted:", result$deleted)
    # }
    delete = function(file_id) {
      self$client$request("DELETE", paste0("/files/", file_id))
    },

    # @description
    # Download the raw binary content of an uploaded file.
    # Use this to retrieve processed fine-tuning result files or batch outputs.
    #
    # @param file_id Character. **Required.** The file ID.
    #
    # @return A `raw` vector of the file's binary content.
    #   Convert to text with `rawToChar()` for text files.
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    #
    # # Download batch results
    # raw_data <- client$files$content("file-abc123")
    # text <- rawToChar(raw_data)
    # cat(text)
    #
    # # Save to disk
    # writeBin(raw_data, "output.jsonl")
    # }
    content = function(file_id) {
      self$client$request_raw("GET", paste0("/files/", file_id, "/content"))
    },

    # @description
    # Poll the file's status until it transitions from `"uploaded"` to
    # `"processed"` (or `"error"`). Useful after uploading fine-tuning data
    # before starting a fine-tuning job.
    #
    # @param file_id Character. **Required.** The file ID to wait for.
    #
    # @param timeout Numeric. Maximum number of seconds to wait before
    #   throwing a timeout error. Default: 300.
    #
    # @param poll_interval Numeric. Seconds to wait between status checks.
    #   Default: 5.
    #
    # @return The file object once status is `"processed"`.
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # file_obj <- client$files$create("training.jsonl", purpose = "fine-tune")
    # processed <- client$files$wait_for_processing(file_obj$id, timeout = 120)
    # cat("File ready:", processed$status)  # "processed"
    # }
    wait_for_processing = function(file_id, timeout = 300, poll_interval = 5) {
      start_time <- Sys.time()

      while (TRUE) {
        file <- self$retrieve(file_id)

        if (file$status == "processed") {
          return(file)
        } else if (file$status == "error") {
          OpenAIError(paste("File processing failed:", file_id))
        }

        elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
        if (elapsed >= timeout) {
          OpenAIError(paste("Timeout waiting for file processing:", file_id))
        }

        Sys.sleep(poll_interval)
      }
    }
  )
)

#' Upload a File (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and calls `client$files$create()`.
#'
#' @param file Character or raw. **Required.** Local file path or raw bytes.
#' @param purpose Character. **Required.** Intended use of the file:
#'   `"assistants"`, `"vision"`, `"batch"`, or `"fine-tune"`.
#'
#' @return A file object with `$id` (the file ID), `$status`, `$filename`,
#'   `$bytes`, and other metadata.
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#'
#' # Upload training data for fine-tuning
#' file_obj <- upload_file("my_training_data.jsonl", purpose = "fine-tune")
#' cat("Uploaded file ID:", file_obj$id)
#'
#' # Upload a document for an Assistant
#' file_obj <- upload_file("research_paper.pdf", purpose = "assistants")
#' cat("File ID:", file_obj$id)
#' }
upload_file <- function(file, purpose) {
  client <- OpenAI$new()
  client$files$create(file = file, purpose = purpose)
}

#' List Uploaded Files (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and calls `client$files$list()`.
#'
#' @param purpose Character or NULL. Filter by purpose:
#'   `"assistants"`, `"vision"`, `"batch"`, or `"fine-tune"`.
#'   If NULL, all files are returned. Default: NULL.
#' @param ... Additional parameters passed to [FilesClient]`$list()`,
#'   such as `limit`, `after`, `order`.
#'
#' @return A list with `$data` — a list of file objects, each containing
#'   `$id`, `$filename`, `$bytes`, `$purpose`, `$status`, and `$created_at`.
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#'
#' # List all files
#' all_files <- list_files()
#' cat("Total files:", length(all_files$data))
#'
#' # List only fine-tuning files
#' ft_files <- list_files(purpose = "fine-tune")
#' for (f in ft_files$data) cat(f$id, f$filename, "\n")
#' }
list_files <- function(purpose = NULL, ...) {
  client <- OpenAI$new()
  client$files$list(purpose = purpose, ...)
}

#' Retrieve File Metadata (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and retrieves metadata for a specific file.
#'
#' @param file_id Character. **Required.** The file ID (e.g. `"file-abc123"`).
#'
#' @return A file object with `$id`, `$filename`, `$bytes`, `$purpose`,
#'   `$status`, and `$created_at`.
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#'
#' info <- retrieve_file("file-abc123")
#' cat("Filename:", info$filename)
#' cat("Status:", info$status) # "processed"
#' }
retrieve_file <- function(file_id) {
  client <- OpenAI$new()
  client$files$retrieve(file_id)
}

#' Delete an Uploaded File (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and deletes a file.
#'
#' @param file_id Character. **Required.** The file ID to delete.
#'
#' @return A list with `$deleted` (`TRUE` if successful) and `$id`.
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#'
#' result <- delete_file("file-abc123")
#' if (result$deleted) cat("File deleted successfully.")
#' }
delete_file <- function(file_id) {
  client <- OpenAI$new()
  client$files$delete(file_id)
}

#' Retrieve File Content (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and downloads the raw content of a file.
#'
#' @param file_id Character. **Required.** The file ID to download.
#'
#' @return A `raw` vector of binary content.
#'   Use `rawToChar()` for text, or `writeBin()` to save to disk.
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#'
#' # Download batch output file
#' raw_data <- retrieve_file_content("file-abc123")
#' text <- rawToChar(raw_data)
#' cat(text)
#'
#' # Save to file
#' writeBin(raw_data, "batch_results.jsonl")
#' }
retrieve_file_content <- function(file_id) {
  client <- OpenAI$new()
  client$files$content(file_id)
}
