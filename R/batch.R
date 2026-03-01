#' Batch Client
#'
#' Client for OpenAI Batch API.
#' Process large numbers of requests asynchronously.
#'
#' @export
BatchClient <- R6::R6Class(
  "BatchClient",
  public = list(
    client = NULL,
    
    #' Initialize batch client
    #'
    #' @param parent Parent OpenAI client
    initialize = function(parent) {
      self$client <- parent
    },
    
    #' Create a batch
    #'
    #' @param input_file_id File ID containing batch requests
    #' @param endpoint Endpoint for batch: "/v1/chat/completions", "/v1/embeddings", "/v1/completions"
    #' @param completion_window Completion window: "24h"
    #' @param metadata Optional metadata
    #' @return Batch object
    create = function(input_file_id, endpoint, completion_window = "24h", metadata = NULL) {
      body <- list(
        input_file_id = input_file_id,
        endpoint = endpoint,
        completion_window = completion_window
      )
      
      if (!is.null(metadata)) body$metadata <- metadata
      
      self$client$request("POST", "/batches", body = body)
    },
    
    #' List batches
    #'
    #' @param after Cursor for pagination
    #' @param limit Number of batches to return
    #' @return List of batches
    list = function(after = NULL, limit = NULL) {
      query <- list()
      if (!is.null(after)) query$after <- after
      if (!is.null(limit)) query$limit <- limit
      
      self$client$request("GET", "/batches", query = query)
    },
    
    #' Retrieve a batch
    #'
    #' @param batch_id Batch ID
    #' @return Batch object
    retrieve = function(batch_id) {
      self$client$request("GET", paste0("/batches/", batch_id))
    },
    
    #' Cancel a batch
    #'
    #' @param batch_id Batch ID
    #' @return Cancelled batch
    cancel = function(batch_id) {
      self$client$request("POST", paste0("/batches/", batch_id, "/cancel"))
    }
  )
)

#' Create a batch (convenience function)
#'
#' @param input_file_id File ID
#' @param endpoint Endpoint
#' @param ... Additional parameters
#' @return Batch object
#' @export
create_batch <- function(input_file_id, endpoint, ...) {
  client <- OpenAI$new()
  client$batch$create(input_file_id = input_file_id, endpoint = endpoint, ...)
}

#' List batches (convenience function)
#'
#' @param ... Additional parameters
#' @return List of batches
#' @export
list_batches <- function(...) {
  client <- OpenAI$new()
  client$batch$list(...)
}

#' Retrieve a batch (convenience function)
#'
#' @param batch_id Batch ID
#' @return Batch object
#' @export
retrieve_batch <- function(batch_id) {
  client <- OpenAI$new()
  client$batch$retrieve(batch_id)
}

#' Cancel a batch (convenience function)
#'
#' @param batch_id Batch ID
#' @return Cancelled batch
#' @export
cancel_batch <- function(batch_id) {
  client <- OpenAI$new()
  client$batch$cancel(batch_id)
}