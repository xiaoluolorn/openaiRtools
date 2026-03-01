#' Vector Stores Client (Beta)
#'
#' Client for OpenAI Vector Stores API v2.
#' Vector stores are used for file search with assistants.
#'
#' @export
VectorStoresClient <- R6::R6Class(
  "VectorStoresClient",
  public = list(
    client = NULL,
    
    #' @field files Vector store files sub-client
    files = NULL,
    
    #' @field file_batches File batches sub-client
    file_batches = NULL,
    
    #' Initialize vector stores client
    #'
    #' @param parent Parent OpenAI client
    initialize = function(parent) {
      self$client <- parent
      self$files <- VectorStoreFilesClient$new(parent)
      self$file_batches <- VectorStoreFileBatchesClient$new(parent)
    },
    
    #' Create a vector store
    #'
    #' @param name Vector store name
    #' @param file_ids List of file IDs to add
    #' @param expires_after Expiration policy
    #' @param chunking_strategy Chunking strategy
    #' @param metadata Metadata
    #' @return Vector store object
    create = function(name = NULL,
                      file_ids = NULL,
                      expires_after = NULL,
                      chunking_strategy = NULL,
                      metadata = NULL) {
      body <- list()
      
      if (!is.null(name)) body$name <- name
      if (!is.null(file_ids)) body$file_ids <- file_ids
      if (!is.null(expires_after)) body$expires_after <- expires_after
      if (!is.null(chunking_strategy)) body$chunking_strategy <- chunking_strategy
      if (!is.null(metadata)) body$metadata <- metadata
      
      self$client$request("POST", "/vector_stores", body = body)
    },
    
    #' List vector stores
    #'
    #' @param limit Number of stores
    #' @param order Sort order
    #' @param after Cursor
    #' @param before Cursor
    #' @return List of vector stores
    list = function(limit = NULL, order = NULL, after = NULL, before = NULL) {
      query <- list()
      if (!is.null(limit)) query$limit <- limit
      if (!is.null(order)) query$order <- order
      if (!is.null(after)) query$after <- after
      if (!is.null(before)) query$before <- before
      
      self$client$request("GET", "/vector_stores", query = query)
    },
    
    #' Retrieve a vector store
    #'
    #' @param vector_store_id Vector store ID
    #' @return Vector store object
    retrieve = function(vector_store_id) {
      self$client$request("GET", paste0("/vector_stores/", vector_store_id))
    },
    
    #' Update a vector store
    #'
    #' @param vector_store_id Vector store ID
    #' @param ... Fields to update
    #' @return Updated vector store
    update = function(vector_store_id, ...) {
      body <- list(...)
      self$client$request("POST", paste0("/vector_stores/", vector_store_id), body = body)
    },
    
    #' Delete a vector store
    #'
    #' @param vector_store_id Vector store ID
    #' @return Deletion status
    delete = function(vector_store_id) {
      self$client$request("DELETE", paste0("/vector_stores/", vector_store_id))
    },
    
    #' Search a vector store
    #'
    #' @param vector_store_id Vector store ID
    #' @param query Search query
    #' @param filter Filter criteria
    #' @param max_num_results Maximum results
    #' @param ranking_options Ranking options
    #' @param rewrite_query Rewrite query for better search
    #' @return Search results
    search = function(vector_store_id,
                      query,
                      filter = NULL,
                      max_num_results = NULL,
                      ranking_options = NULL,
                      rewrite_query = NULL) {
      body <- list(query = query)
      
      if (!is.null(filter)) body$filter <- filter
      if (!is.null(max_num_results)) body$max_num_results <- max_num_results
      if (!is.null(ranking_options)) body$ranking_options <- ranking_options
      if (!is.null(rewrite_query)) body$rewrite_query <- rewrite_query
      
      self$client$request("POST", paste0("/vector_stores/", vector_store_id, "/search"), body = body)
    }
  }
)

#' Vector Store Files Client
#'
#' @export
VectorStoreFilesClient <- R6::R6Class(
  "VectorStoreFilesClient",
  public = list(
    client = NULL,
    
    #' Initialize vector store files client
    #'
    #' @param parent Parent OpenAI client
    initialize = function(parent) {
      self$client <- parent
    },
    
    #' Create a vector store file
    #'
    #' @param vector_store_id Vector store ID
    #' @param file_id File ID
    #' @param chunking_strategy Chunking strategy
    #' @return Vector store file object
    create = function(vector_store_id, file_id, chunking_strategy = NULL) {
      body <- list(file_id = file_id)
      
      if (!is.null(chunking_strategy)) body$chunking_strategy <- chunking_strategy
      
      self$client$request("POST", paste0("/vector_stores/", vector_store_id, "/files"), body = body)
    },
    
    #' List vector store files
    #'
    #' @param vector_store_id Vector store ID
    #' @param limit Number of files
    #' @param order Sort order
    #' @param after Cursor
    #' @param before Cursor
    #' @param filter Filter by status
    #' @return List of files
    list = function(vector_store_id, limit = NULL, order = NULL, after = NULL, before = NULL, filter = NULL) {
      query <- list()
      if (!is.null(limit)) query$limit <- limit
      if (!is.null(order)) query$order <- order
      if (!is.null(after)) query$after <- after
      if (!is.null(before)) query$before <- before
      if (!is.null(filter)) query$filter <- filter
      
      self$client$request("GET", paste0("/vector_stores/", vector_store_id, "/files"), query = query)
    },
    
    #' Retrieve a vector store file
    #'
    #' @param vector_store_id Vector store ID
    #' @param file_id File ID
    #' @return Vector store file object
    retrieve = function(vector_store_id, file_id) {
      self$client$request("GET", paste0("/vector_stores/", vector_store_id, "/files/", file_id))
    },
    
    #' Update a vector store file
    #'
    #' @param vector_store_id Vector store ID
    #' @param file_id File ID
    #' @param attributes Attributes to update
    #' @return Updated vector store file
    update = function(vector_store_id, file_id, attributes = NULL) {
      body <- list()
      if (!is.null(attributes)) body$attributes <- attributes
      self$client$request("POST", paste0("/vector_stores/", vector_store_id, "/files/", file_id), body = body)
    },
    
    #' Delete a vector store file
    #'
    #' @param vector_store_id Vector store ID
    #' @param file_id File ID
    #' @return Deletion status
    delete = function(vector_store_id, file_id) {
      self$client$request("DELETE", paste0("/vector_stores/", vector_store_id, "/files/", file_id))
    },
    
    #' Retrieve vector store file content
    #'
    #' @param vector_store_id Vector store ID
    #' @param file_id File ID
    #' @return Raw file content
    content = function(vector_store_id, file_id) {
      req <- httr2::request(paste0(self$client$base_url, "/vector_stores/", vector_store_id, "/files/", file_id, "/content")) |>
        httr2::req_method("GET") |>
        httr2::req_headers("Authorization" = paste("Bearer", self$client$api_key)) |>
        httr2::req_timeout(self$client$timeout)
      
      if (!is.null(self$client$organization)) {
        req <- httr2::req_headers(req, "OpenAI-Organization" = self$client$organization)
      }
      
      resp <- httr2::req_perform(req)
      
      status_code <- httr2::resp_status(resp)
      if (status_code >= 400) {
        handle_response(resp)
      }
      
      resp$body
    }
  }
)

#' Vector Store File Batches Client
#'
#' @export
VectorStoreFileBatchesClient <- R6::R6Class(
  "VectorStoreFileBatchesClient",
  public = list(
    client = NULL,
    
    #' Initialize vector store file batches client
    #'
    #' @param parent Parent OpenAI client
    initialize = function(parent) {
      self$client <- parent
    },
    
    #' Create a vector store file batch
    #'
    #' @param vector_store_id Vector store ID
    #' @param file_ids List of file IDs
    #' @param chunking_strategy Chunking strategy
    #' @return Vector store file batch object
    create = function(vector_store_id, file_ids, chunking_strategy = NULL) {
      body <- list(file_ids = file_ids)
      
      if (!is.null(chunking_strategy)) body$chunking_strategy <- chunking_strategy
      
      self$client$request("POST", paste0("/vector_stores/", vector_store_id, "/file_batches"), body = body)
    },
    
    #' Retrieve a vector store file batch
    #'
    #' @param vector_store_id Vector store ID
    #' @param batch_id Batch ID
    #' @return Vector store file batch object
    retrieve = function(vector_store_id, batch_id) {
      self$client$request("GET", paste0("/vector_stores/", vector_store_id, "/file_batches/", batch_id))
    },
    
    #' Cancel a vector store file batch
    #'
    #' @param vector_store_id Vector store ID
    #' @param batch_id Batch ID
    #' @return Cancelled batch
    cancel = function(vector_store_id, batch_id) {
      self$client$request("POST", paste0("/vector_stores/", vector_store_id, "/file_batches/", batch_id, "/cancel"))
    },
    
    #' List files in a batch
    #'
    #' @param vector_store_id Vector store ID
    #' @param batch_id Batch ID
    #' @param limit Number of files
    #' @param order Sort order
    #' @param after Cursor
    #' @param before Cursor
    #' @return List of files
    list_files = function(vector_store_id, batch_id, limit = NULL, order = NULL, after = NULL, before = NULL) {
      query <- list()
      if (!is.null(limit)) query$limit <- limit
      if (!is.null(order)) query$order <- order
      if (!is.null(after)) query$after <- after
      if (!is.null(before)) query$before <- before
      
      self$client$request("GET", paste0("/vector_stores/", vector_store_id, "/file_batches/", batch_id, "/files"), query = query)
    }
  }
)

# Convenience functions for vector stores

#' Create a vector store (convenience function)
#' @param ... Additional parameters
#' @return Vector store object
#' @export
create_vector_store <- function(...) {
  client <- OpenAI$new()
  client$vector_stores$create(...)
}

#' List vector stores (convenience function)
#' @param ... Additional parameters
#' @return List of vector stores
#' @export
list_vector_stores <- function(...) {
  client <- OpenAI$new()
  client$vector_stores$list(...)
}

#' Retrieve a vector store (convenience function)
#' @param vector_store_id Vector store ID
#' @return Vector store object
#' @export
retrieve_vector_store <- function(vector_store_id) {
  client <- OpenAI$new()
  client$vector_stores$retrieve(vector_store_id)
}

#' Delete a vector store (convenience function)
#' @param vector_store_id Vector store ID
#' @return Deletion status
#' @export
delete_vector_store <- function(vector_store_id) {
  client <- OpenAI$new()
  client$vector_stores$delete(vector_store_id)
}