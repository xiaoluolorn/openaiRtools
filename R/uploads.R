#' Uploads Client
#'
#' Client for the OpenAI Uploads API. Upload large files in multiple parts
#' (multipart upload) when the file exceeds the 512 MB Files API limit.
#' Access via `client$uploads`.
#'
#' @description
#' The Uploads API is designed for files larger than what the Files API
#' can handle in a single request. You split the file into parts,
#' upload each part, then finalize the upload to get a standard file object.
#'
#' @section Workflow:
#' 1. `$create()` — Initialize the upload session, get an `upload_id`
#' 2. `$add_part()` — Upload each chunk of the file (called multiple times)
#' 3. `$complete()` — Finalize and assemble the file; returns a File object
#' 4. (Optional) `$cancel()` — Abort if needed
#'
#' @export
UploadsClient <- R6::R6Class(
  "UploadsClient",
  public = list(
    client = NULL,

    # Initialize uploads client
    #
    # @param parent Parent OpenAI client
    initialize = function(parent) {
      self$client <- parent
    },

    # @description
    # Initialize a multipart upload session.
    # Returns an `upload_id` that subsequent `$add_part()` calls use.
    #
    # @param purpose Character. **Required.** Intended use of the file:
    #   `"assistants"`, `"batch"`, or `"fine-tune"`.
    #
    # @param filename Character. **Required.** The original filename of the
    #   file being uploaded (used for display purposes).
    #   Example: `"large_training_data.jsonl"`.
    #
    # @param bytes Integer. **Required.** Total size of the file in bytes.
    #   This must match the actual total bytes you will upload.
    #
    # @param mime_type Character or NULL. MIME type of the file.
    #   Examples: `"application/json"`, `"text/plain"`.
    #   If NULL, the API will attempt to detect it. Default: NULL.
    #
    # @return An upload object:
    #   \describe{
    #     \item{`$id`}{Character. Upload ID (use this in `$add_part()` and
    #       `$complete()`).}
    #     \item{`$object`}{Always `"upload"`.}
    #     \item{`$status`}{`"pending"` (in progress) or `"completed"`.}
    #     \item{`$filename`}{Character. The filename you specified.}
    #     \item{`$purpose`}{Character. The purpose you specified.}
    #     \item{`$bytes`}{Integer. Total bytes you declared.}
    #     \item{`$expires_at`}{Integer. Unix timestamp when this upload expires.}
    #   }
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # file_size <- file.info("large_data.jsonl")$size
    # upload <- client$uploads$create(
    #   purpose   = "fine-tune",
    #   filename  = "large_data.jsonl",
    #   bytes     = file_size,
    #   mime_type = "application/json"
    # )
    # cat("Upload ID:", upload$id)
    # }
    create = function(purpose, filename, bytes, mime_type = NULL) {
      body <- list(
        purpose = purpose,
        filename = filename,
        bytes = bytes
      )

      if (!is.null(mime_type)) body$mime_type <- mime_type

      self$client$request("POST", "/uploads", body = body)
    },

    # @description
    # Upload a single part (chunk) of a large file.
    # Call this repeatedly for each chunk until all bytes are uploaded.
    # Parts can be uploaded in any order; ordering is handled in `$complete()`.
    #
    # @param upload_id Character. **Required.** The upload ID returned by
    #   `$create()`.
    #
    # @param data Raw. **Required.** The raw bytes of this chunk.
    #   There is no strict minimum size per part.
    #   The recommended chunk size is 64 MB for efficiency.
    #
    # @return An upload part object:
    #   \describe{
    #     \item{`$id`}{Character. Part ID — save this for use in `$complete()`.}
    #     \item{`$object`}{Always `"upload.part"`.}
    #     \item{`$upload_id`}{Character. The parent upload ID.}
    #   }
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # con <- file("large_data.jsonl", "rb")
    # chunk_size <- 64 * 1024 * 1024  # 64 MB
    # part_ids <- character(0)
    # repeat {
    #   chunk <- readBin(con, "raw", chunk_size)
    #   if (length(chunk) == 0) break
    #   part <- client$uploads$add_part(upload$id, chunk)
    #   part_ids <- c(part_ids, part$id)
    # }
    # close(con)
    # }
    add_part = function(upload_id, data) {
      self$client$request_multipart(
        "POST",
        paste0("/uploads/", upload_id, "/parts"),
        data = data
      )
    },

    # @description
    # Complete a multipart upload after all parts have been uploaded.
    # Assembles the parts into a single file in the specified order.
    #
    # @param upload_id Character. **Required.** The upload ID from `$create()`.
    #
    # @param part_ids List of character strings. **Required.** The IDs of all
    #   uploaded parts, in the order they should appear in the final file.
    #   Example: `list("part-abc", "part-def", "part-ghi")`.
    #
    # @param md5 Character or NULL. Optional MD5 checksum of the complete file
    #   (hex string). Provided for integrity verification. Default: NULL.
    #
    # @return A standard File object (same as returned by `client$files$create()`),
    #   with `$id` that can be used in fine-tuning, assistants, or batch jobs.
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # # After uploading all parts:
    # file_obj <- client$uploads$complete(
    #   upload_id = upload$id,
    #   part_ids  = part_ids  # character vector from $add_part() calls
    # )
    # cat("File ID:", file_obj$id)
    # cat("Status:", file_obj$status)
    # }
    complete = function(upload_id, part_ids, md5 = NULL) {
      body <- list(
        part_ids = part_ids
      )

      if (!is.null(md5)) body$md5 <- md5

      self$client$request("POST", paste0("/uploads/", upload_id, "/complete"), body = body)
    },

    # @description
    # Cancel an in-progress upload. Once cancelled, the upload ID and
    # all associated parts are invalidated and cannot be used.
    #
    # @param upload_id Character. **Required.** The upload ID to cancel.
    #
    # @return The cancelled upload object with `$status = "cancelled"`.
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # result <- client$uploads$cancel("upload_abc123")
    # cat("Status:", result$status)  # "cancelled"
    # }
    cancel = function(upload_id) {
      self$client$request("POST", paste0("/uploads/", upload_id, "/cancel"))
    }
  )
)

#' Create a Multipart Upload Session (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and initializes a multipart upload session.
#' Use this when your file exceeds the 512 MB single-upload limit.
#'
#' @param purpose Character. **Required.** The intended use:
#'   `"assistants"`, `"batch"`, or `"fine-tune"`.
#' @param filename Character. **Required.** The original name of the file.
#' @param bytes Integer. **Required.** Total file size in bytes
#'   (`file.info("myfile.jsonl")$size`).
#' @param ... Additional parameters passed to [UploadsClient]`$create()`,
#'   such as `mime_type`.
#'
#' @return An upload object with `$id` (use in `add_upload_part()` and
#'   `complete_upload()`).
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#'
#' file_size <- file.info("huge_training.jsonl")$size
#' upload <- create_upload(
#'   purpose   = "fine-tune",
#'   filename  = "huge_training.jsonl",
#'   bytes     = file_size,
#'   mime_type = "application/json"
#' )
#' cat("Upload ID:", upload$id)
#' }
create_upload <- function(purpose, filename, bytes, ...) {
  client <- OpenAI$new()
  client$uploads$create(purpose = purpose, filename = filename, bytes = bytes, ...)
}

#' Upload a File Part (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and uploads one part of a multipart upload.
#' Call this repeatedly for each chunk of your file.
#'
#' @param upload_id Character. **Required.** The upload session ID returned
#'   by [create_upload()].
#' @param data Raw. **Required.** The binary chunk to upload.
#'   Read from file with `readBin(con, "raw", n = chunk_size)`.
#'
#' @return An upload part object with `$id` — save all part IDs to use
#'   in [complete_upload()].
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#'
#' chunk <- readBin("large_file.jsonl", "raw", n = 64 * 1024 * 1024)
#' part <- add_upload_part(upload_id = upload$id, data = chunk)
#' cat("Part ID:", part$id)
#' }
add_upload_part <- function(upload_id, data) {
  client <- OpenAI$new()
  client$uploads$add_part(upload_id = upload_id, data = data)
}

#' Complete a Multipart Upload (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and finalizes a multipart upload.
#' Assembles all uploaded parts into a single file.
#'
#' @param upload_id Character. **Required.** The upload session ID.
#' @param part_ids List of character strings. **Required.** Part IDs collected
#'   from [add_upload_part()] calls, in the correct file order.
#' @param ... Additional parameters such as `md5` (integrity checksum).
#'
#' @return A standard File object with `$id` that can be used in fine-tuning,
#'   assistants, or batch API calls, just like a file from `upload_file()`.
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#'
#' # After uploading all parts, complete the upload:
#' file_obj <- complete_upload(
#'   upload_id = upload$id,
#'   part_ids  = list("part-001", "part-002", "part-003")
#' )
#' cat("File ID:", file_obj$id)
#' }
complete_upload <- function(upload_id, part_ids, ...) {
  client <- OpenAI$new()
  client$uploads$complete(upload_id = upload_id, part_ids = part_ids, ...)
}

#' Cancel a Multipart Upload (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and cancels an in-progress multipart upload.
#'
#' @param upload_id Character. **Required.** The upload session ID to cancel.
#'
#' @return An upload object with `$status = "cancelled"`.
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#'
#' result <- cancel_upload("upload_abc123")
#' cat("Status:", result$status) # "cancelled"
#' }
cancel_upload <- function(upload_id) {
  client <- OpenAI$new()
  client$uploads$cancel(upload_id)
}
