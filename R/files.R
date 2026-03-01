#' Files Client
#'
#' Client for OpenAI Files API.
#' Files are used for fine-tuning, assistants, and batch processing.
#'
#' @export
FilesClient <- R6::R6Class(
  "FilesClient",
  public = list(
    client = NULL,

    #' Initialize files client
    #'
    #' @param parent Parent OpenAI client
    initialize = function(parent) {
      self$client <- parent
    },

    #' Upload a file
    #'
    #' @param file File path or raw content
    #' @param purpose Purpose of the file: "assistants", "batch", "fine-tune", "vision"
    #' @return File object
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

    #' List files
    #'
    #' @param purpose Filter by purpose
    #' @param limit Number of files to return (max 10000)
    #' @param after Cursor for pagination
    #' @param order Sort order: "asc" or "desc"
    #' @return List of files
    list = function(purpose = NULL, limit = NULL, after = NULL, order = NULL) {
      query <- list()
      if (!is.null(purpose)) query$purpose <- purpose
      if (!is.null(limit)) query$limit <- limit
      if (!is.null(after)) query$after <- after
      if (!is.null(order)) query$order <- order

      self$client$request("GET", "/files", query = query)
    },

    #' Retrieve a file
    #'
    #' @param file_id File ID
    #' @return File object
    retrieve = function(file_id) {
      self$client$request("GET", paste0("/files/", file_id))
    },

    #' Delete a file
    #'
    #' @param file_id File ID
    #' @return Deletion status
    delete = function(file_id) {
      self$client$request("DELETE", paste0("/files/", file_id))
    },

    #' Retrieve file content
    #'
    #' @param file_id File ID
    #' @return Raw file content
    content = function(file_id) {
      self$client$request_raw("GET", paste0("/files/", file_id, "/content"))
    },

    #' Wait for file processing
    #'
    #' @param file_id File ID
    #' @param timeout Maximum wait time in seconds
    #' @param poll_interval Seconds between polls
    #' @return File object when processed
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

#' Upload a file (convenience function)
#'
#' @param file File path or raw content
#' @param purpose Purpose of the file
#' @return File object
#' @export
upload_file <- function(file, purpose) {
  client <- OpenAI$new()
  client$files$create(file = file, purpose = purpose)
}

#' List files (convenience function)
#'
#' @param purpose Filter by purpose
#' @param ... Additional parameters
#' @return List of files
#' @export
list_files <- function(purpose = NULL, ...) {
  client <- OpenAI$new()
  client$files$list(purpose = purpose, ...)
}

#' Retrieve a file (convenience function)
#'
#' @param file_id File ID
#' @return File object
#' @export
retrieve_file <- function(file_id) {
  client <- OpenAI$new()
  client$files$retrieve(file_id)
}

#' Delete a file (convenience function)
#'
#' @param file_id File ID
#' @return Deletion status
#' @export
delete_file <- function(file_id) {
  client <- OpenAI$new()
  client$files$delete(file_id)
}

#' Retrieve file content (convenience function)
#'
#' @param file_id File ID
#' @return Raw file content
#' @export
retrieve_file_content <- function(file_id) {
  client <- OpenAI$new()
  client$files$content(file_id)
}
