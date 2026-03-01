#' Uploads Client
#'
#' Client for OpenAI Uploads API.
#' Upload large files in parts.
#'
#' @export
UploadsClient <- R6::R6Class(
  "UploadsClient",
  public = list(
    client = NULL,

    #' Initialize uploads client
    #'
    #' @param parent Parent OpenAI client
    initialize = function(parent) {
      self$client <- parent
    },

    #' Create an upload
    #'
    #' @param purpose Upload purpose: "assistants", "batch", "fine-tune"
    #' @param filename Original filename
    #' @param bytes Total file size in bytes
    #' @param mime_type MIME type
    #' @return Upload object
    create = function(purpose, filename, bytes, mime_type = NULL) {
      body <- list(
        purpose = purpose,
        filename = filename,
        bytes = bytes
      )

      if (!is.null(mime_type)) body$mime_type <- mime_type

      self$client$request("POST", "/uploads", body = body)
    },

    #' Add a part to an upload
    #'
    #' @param upload_id Upload ID
    #' @param data Raw data for this part
    #' @return Upload part object
    add_part = function(upload_id, data) {
      self$client$request_multipart(
        "POST",
        paste0("/uploads/", upload_id, "/parts"),
        data = data
      )
    },

    #' Complete an upload
    #'
    #' @param upload_id Upload ID
    #' @param part_ids List of part IDs
    #' @param md5 MD5 checksum of file (optional)
    #' @return File object
    complete = function(upload_id, part_ids, md5 = NULL) {
      body <- list(
        part_ids = part_ids
      )

      if (!is.null(md5)) body$md5 <- md5

      self$client$request("POST", paste0("/uploads/", upload_id, "/complete"), body = body)
    },

    #' Cancel an upload
    #'
    #' @param upload_id Upload ID
    #' @return Cancelled upload
    cancel = function(upload_id) {
      self$client$request("POST", paste0("/uploads/", upload_id, "/cancel"))
    }
  )
)

#' Create an upload (convenience function)
#'
#' @param purpose Upload purpose
#' @param filename Filename
#' @param bytes File size
#' @param ... Additional parameters
#' @return Upload object
#' @export
create_upload <- function(purpose, filename, bytes, ...) {
  client <- OpenAI$new()
  client$uploads$create(purpose = purpose, filename = filename, bytes = bytes, ...)
}

#' Add upload part (convenience function)
#'
#' @param upload_id Upload ID
#' @param data Raw data
#' @return Upload part
#' @export
add_upload_part <- function(upload_id, data) {
  client <- OpenAI$new()
  client$uploads$add_part(upload_id = upload_id, data = data)
}

#' Complete an upload (convenience function)
#'
#' @param upload_id Upload ID
#' @param part_ids Part IDs
#' @param ... Additional parameters
#' @return File object
#' @export
complete_upload <- function(upload_id, part_ids, ...) {
  client <- OpenAI$new()
  client$uploads$complete(upload_id = upload_id, part_ids = part_ids, ...)
}

#' Cancel an upload (convenience function)
#'
#' @param upload_id Upload ID
#' @return Cancelled upload
#' @export
cancel_upload <- function(upload_id) {
  client <- OpenAI$new()
  client$uploads$cancel(upload_id)
}
