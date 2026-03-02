#' Vector Stores Client (Beta)
#'
#' Client for the OpenAI Vector Stores API v2 (Beta).
#' Vector stores enable semantic file search for Assistants.
#' Access via `client$vector_stores`.
#'
#' @description
#' A vector store automatically chunks, embeds, and indexes files so that
#' an Assistant with the `file_search` tool can search over them using
#' natural language queries.
#'
#' @section Sub-clients:
#' \describe{
#'   \item{`$files`}{[VectorStoreFilesClient] — Add/remove files from a store}
#'   \item{`$file_batches`}{[VectorStoreFileBatchesClient] — Batch-add files}
#' }
#'
#' @section Typical workflow:
#' \enumerate{
#'   \item Upload files: `client$files$create(file, purpose = "assistants")`
#'   \item Create vector store: `client$vector_stores$create(name = "...")`
#'   \item Add files: `client$vector_stores$files$create(store_id, file_id)`
#'   \item Attach to assistant via `tool_resources` in `client$assistants$create()`
#' }
#'
#' @export
VectorStoresClient <- R6::R6Class(
  "VectorStoresClient",
  public = list(
    client = NULL,

    # Field: files Vector store files sub-client
    files = NULL,

    # Field: file_batches File batches sub-client
    file_batches = NULL,

    # Initialize vector stores client
    #
    # @param parent Parent OpenAI client
    initialize = function(parent) {
      self$client <- parent
      self$files <- VectorStoreFilesClient$new(parent)
      self$file_batches <- VectorStoreFileBatchesClient$new(parent)
    },

    # @description
    # Create a new vector store. You can optionally add files immediately
    # by passing `file_ids`.
    #
    # @param name Character or NULL. A display name for the vector store
    #   (e.g. `"Research Papers 2024"`). Default: NULL.
    #
    # @param file_ids List of character strings or NULL. File IDs to add
    #   immediately on creation. Files must have been uploaded with
    #   `purpose = "assistants"`. Example: `list("file-abc123", "file-def456")`.
    #   Default: NULL (empty store; add files later with `$files$create()`).
    #
    # @param expires_after List or NULL. Auto-expiration policy.
    #   Example: `list(anchor = "last_active_at", days = 7)` — expires 7 days
    #   after the vector store was last used. Default: NULL (never expires).
    #
    # @param chunking_strategy List or NULL. How to chunk files. Options:
    #   \itemize{
    #     \item `list(type = "auto")` — Automatic chunking (default)
    #     \item `list(type = "static", static = list(max_chunk_size_tokens = 800,
    #       chunk_overlap_tokens = 400))` — Custom static chunking
    #   }
    #   Default: NULL (auto).
    #
    # @param metadata Named list or NULL. Up to 16 key-value metadata pairs.
    #   Default: NULL.
    #
    # @return A vector store object:
    #   \describe{
    #     \item{`$id`}{Character. Vector store ID (e.g. `"vs_abc123"`). **Save this.**}
    #     \item{`$name`}{Character. Display name.}
    #     \item{`$status`}{Character. `"in_progress"`, `"completed"`, or `"expired"`.}
    #     \item{`$file_counts`}{List with `$total`, `$completed`, `$in_progress`,
    #       `$failed`, `$cancelled`.}
    #     \item{`$created_at`}{Integer. Unix timestamp.}
    #   }
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    #
    # # Create an empty vector store
    # vs <- client$vector_stores$create(name = "Economics Papers")
    # cat("Vector Store ID:", vs$id)
    #
    # # Create and load files at once
    # vs <- client$vector_stores$create(
    #   name     = "Macro Research",
    #   file_ids = list("file-abc123", "file-def456"),
    #   expires_after = list(anchor = "last_active_at", days = 30)
    # )
    # }
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

    # @description
    # List all vector stores.
    #
    # @param limit Integer or NULL. Max stores to return (1–100).
    #   Default: NULL (API default 20).
    #
    # @param order Character or NULL. `"asc"` or `"desc"`. Default: NULL.
    #
    # @param after Character or NULL. Pagination cursor. Default: NULL.
    #
    # @param before Character or NULL. Reverse pagination cursor. Default: NULL.
    #
    # @return A list with `$data` — a list of vector store objects.
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # stores <- client$vector_stores$list()
    # for (s in stores$data) cat(s$id, "-", s$name, "\n")
    # }
    list = function(limit = NULL, order = NULL, after = NULL, before = NULL) {
      query <- list()
      if (!is.null(limit)) query$limit <- limit
      if (!is.null(order)) query$order <- order
      if (!is.null(after)) query$after <- after
      if (!is.null(before)) query$before <- before

      self$client$request("GET", "/vector_stores", query = query)
    },

    # @description
    # Retrieve a specific vector store by its ID.
    #
    # @param vector_store_id Character. **Required.** The vector store ID
    #   (e.g. `"vs_abc123"`).
    #
    # @return A vector store object (see `$create()` return value).
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # vs <- client$vector_stores$retrieve("vs_abc123")
    # cat("Status:", vs$status)
    # cat("Files completed:", vs$file_counts$completed)
    # }
    retrieve = function(vector_store_id) {
      self$client$request("GET", paste0("/vector_stores/", vector_store_id))
    },

    # @description
    # Update a vector store's name, expiry, or metadata.
    #
    # @param vector_store_id Character. **Required.** The vector store ID.
    #
    # @param ... Named fields to update: `name`, `expires_after`, `metadata`.
    #   Example: `name = "Updated Name"` or
    #   `expires_after = list(anchor = "last_active_at", days = 14)`.
    #
    # @return The updated vector store object.
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # vs <- client$vector_stores$update("vs_abc123", name = "New Name")
    # }
    update = function(vector_store_id, ...) {
      body <- list(...)
      self$client$request("POST", paste0("/vector_stores/", vector_store_id), body = body)
    },

    # @description
    # Delete a vector store. This removes the vector index but does NOT
    # delete the underlying files from the Files API.
    #
    # @param vector_store_id Character. **Required.** The vector store ID.
    #
    # @return A list with `$deleted` (`TRUE`) and `$id`.
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # result <- client$vector_stores$delete("vs_abc123")
    # cat("Deleted:", result$deleted)
    # }
    delete = function(vector_store_id) {
      self$client$request("DELETE", paste0("/vector_stores/", vector_store_id))
    },

    # @description
    # Search a vector store with a natural language query.
    # Returns the most semantically similar file chunks.
    #
    # @param vector_store_id Character. **Required.** The vector store ID.
    #
    # @param query Character. **Required.** The natural language search query.
    #   Example: `"What are the assumptions of OLS?"`.
    #
    # @param filter List or NULL. Metadata filter criteria to narrow results.
    #   Default: NULL.
    #
    # @param max_num_results Integer or NULL. Maximum number of results to
    #   return (1–50). Default: NULL (API default 10).
    #
    # @param ranking_options List or NULL. Options for reranking results.
    #   Default: NULL.
    #
    # @param rewrite_query Logical or NULL. If TRUE, the API rewrites your
    #   query for better retrieval accuracy. Default: NULL.
    #
    # @return A list with `$data` — a list of result objects. Each has:
    #   \describe{
    #     \item{`$file_id`}{Character. Source file ID.}
    #     \item{`$filename`}{Character. Source filename.}
    #     \item{`$score`}{Numeric. Relevance score (0–1, higher is better).}
    #     \item{`$content`}{List of content chunks from the file.}
    #   }
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # results <- client$vector_stores$search(
    #   vector_store_id = "vs_abc123",
    #   query           = "instrumental variables in panel data",
    #   max_num_results = 5
    # )
    # for (r in results$data) {
    #   cat("File:", r$filename, "Score:", r$score, "\n")
    #   cat(r$content[[1]]$text, "\n\n")
    # }
    # }
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
  )
)

#' Vector Store Files Client
#'
#' Manages individual files within a vector store. Adding a file triggers
#' automatic chunking and embedding.
#' Access via `client$vector_stores$files`.
#'
#' @export
VectorStoreFilesClient <- R6::R6Class(
  "VectorStoreFilesClient",
  public = list(
    client = NULL,

    # Initialize vector store files client
    #
    # @param parent Parent OpenAI client
    initialize = function(parent) {
      self$client <- parent
    },

    # @description
    # Add a single file to a vector store. The file will be automatically
    # chunked and embedded (status: `"in_progress"` → `"completed"`).
    #
    # @param vector_store_id Character. **Required.** The vector store ID.
    #
    # @param file_id Character. **Required.** The file ID to add. Must have
    #   been uploaded with `purpose = "assistants"`.
    #
    # @param chunking_strategy List or NULL. Override the store's chunking
    #   strategy for this file. See [VectorStoresClient]`$create()` for options.
    #   Default: NULL (uses store default).
    #
    # @return A vector store file object:
    #   \describe{
    #     \item{`$id`}{Character. The file ID.}
    #     \item{`$vector_store_id`}{Character. The store ID.}
    #     \item{`$status`}{Character. `"in_progress"`, `"completed"`,
    #       `"cancelled"`, or `"failed"`.}
    #     \item{`$created_at`}{Integer. Unix timestamp.}
    #   }
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # vsf <- client$vector_stores$files$create(
    #   vector_store_id = "vs_abc123",
    #   file_id         = "file-abc123"
    # )
    # cat("Status:", vsf$status)  # "in_progress"
    # # Poll until "completed"
    # repeat {
    #   vsf <- client$vector_stores$files$retrieve("vs_abc123", vsf$id)
    #   if (vsf$status != "in_progress") break
    #   Sys.sleep(2)
    # }
    # }
    create = function(vector_store_id, file_id, chunking_strategy = NULL) {
      body <- list(file_id = file_id)

      if (!is.null(chunking_strategy)) body$chunking_strategy <- chunking_strategy

      self$client$request("POST", paste0("/vector_stores/", vector_store_id, "/files"), body = body)
    },

    # @description
    # List all files in a vector store.
    #
    # @param vector_store_id Character. **Required.** The vector store ID.
    # @param limit Integer or NULL. Max files to return. Default: NULL.
    # @param order Character or NULL. `"asc"` or `"desc"`. Default: NULL.
    # @param after Character or NULL. Pagination cursor. Default: NULL.
    # @param before Character or NULL. Reverse pagination cursor. Default: NULL.
    # @param filter Character or NULL. Filter by status: `"in_progress"`,
    #   `"completed"`, `"failed"`, or `"cancelled"`. Default: NULL.
    #
    # @return A list with `$data` — a list of vector store file objects.
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # files <- client$vector_stores$files$list("vs_abc123")
    # cat("Total files:", length(files$data))
    # for (f in files$data) cat(f$id, "-", f$status, "\n")
    # }
    list = function(vector_store_id, limit = NULL, order = NULL, after = NULL, before = NULL, filter = NULL) {
      query <- list()
      if (!is.null(limit)) query$limit <- limit
      if (!is.null(order)) query$order <- order
      if (!is.null(after)) query$after <- after
      if (!is.null(before)) query$before <- before
      if (!is.null(filter)) query$filter <- filter

      self$client$request("GET", paste0("/vector_stores/", vector_store_id, "/files"), query = query)
    },

    # @description
    # Retrieve a specific file within a vector store.
    #
    # @param vector_store_id Character. **Required.** The vector store ID.
    # @param file_id Character. **Required.** The file ID.
    #
    # @return A vector store file object with `$status` and metadata.
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # vsf <- client$vector_stores$files$retrieve("vs_abc123", "file-abc123")
    # cat("Status:", vsf$status)  # "completed"
    # }
    retrieve = function(vector_store_id, file_id) {
      self$client$request("GET", paste0("/vector_stores/", vector_store_id, "/files/", file_id))
    },

    # @description
    # Update metadata attributes for a file in a vector store.
    #
    # @param vector_store_id Character. **Required.** The vector store ID.
    # @param file_id Character. **Required.** The file ID.
    # @param attributes List or NULL. Metadata attributes to update.
    #   Default: NULL.
    #
    # @return The updated vector store file object.
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # client$vector_stores$files$update(
    #   "vs_abc123", "file-abc123",
    #   attributes = list(category = "macro")
    # )
    # }
    update = function(vector_store_id, file_id, attributes = NULL) {
      body <- list()
      if (!is.null(attributes)) body$attributes <- attributes
      self$client$request("POST", paste0("/vector_stores/", vector_store_id, "/files/", file_id), body = body)
    },

    # @description
    # Remove a file from a vector store. The file is unlinked from the
    # store but NOT deleted from the Files API.
    #
    # @param vector_store_id Character. **Required.** The vector store ID.
    # @param file_id Character. **Required.** The file ID to remove.
    #
    # @return A list with `$deleted` (`TRUE`) and `$id`.
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # result <- client$vector_stores$files$delete("vs_abc123", "file-abc123")
    # cat("Removed from store:", result$deleted)
    # }
    delete = function(vector_store_id, file_id) {
      self$client$request("DELETE", paste0("/vector_stores/", vector_store_id, "/files/", file_id))
    },

    # @description
    # Download the raw content of a file stored in a vector store.
    #
    # @param vector_store_id Character. **Required.** The vector store ID.
    # @param file_id Character. **Required.** The file ID.
    #
    # @return A `raw` vector of the file's binary content.
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # raw_data <- client$vector_stores$files$content("vs_abc123", "file-abc123")
    # cat(rawToChar(raw_data))
    # }
    content = function(vector_store_id, file_id) {
      self$client$request_raw(
        "GET",
        paste0("/vector_stores/", vector_store_id, "/files/", file_id, "/content")
      )
    }
  )
)

#' Vector Store File Batches Client
#'
#' Add multiple files to a vector store in a single batch operation.
#' More efficient than adding files one-by-one when loading many files.
#' Access via `client$vector_stores$file_batches`.
#'
#' @export
VectorStoreFileBatchesClient <- R6::R6Class(
  "VectorStoreFileBatchesClient",
  public = list(
    client = NULL,

    # Initialize vector store file batches client
    #
    # @param parent Parent OpenAI client
    initialize = function(parent) {
      self$client <- parent
    },

    # @description
    # Add multiple files to a vector store in one batch.
    # All files are processed asynchronously in parallel.
    #
    # @param vector_store_id Character. **Required.** The vector store ID.
    #
    # @param file_ids List of character strings. **Required.** IDs of files to
    #   add (must have been uploaded with `purpose = "assistants"`).
    #   Example: `list("file-abc", "file-def", "file-ghi")`.
    #
    # @param chunking_strategy List or NULL. Override chunking strategy for
    #   all files in this batch. Default: NULL (uses store default).
    #
    # @return A vector store file batch object:
    #   \describe{
    #     \item{`$id`}{Character. Batch ID.}
    #     \item{`$vector_store_id`}{Character. The store ID.}
    #     \item{`$status`}{Character. `"in_progress"`, `"completed"`,
    #       `"cancelled"`, or `"failed"`.}
    #     \item{`$file_counts`}{List with `$total`, `$completed`, `$in_progress`,
    #       `$failed`, `$cancelled`.}
    #   }
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # batch <- client$vector_stores$file_batches$create(
    #   vector_store_id = "vs_abc123",
    #   file_ids        = list("file-001", "file-002", "file-003")
    # )
    # cat("Batch ID:", batch$id, "Status:", batch$status)
    # }
    create = function(vector_store_id, file_ids, chunking_strategy = NULL) {
      body <- list(file_ids = file_ids)

      if (!is.null(chunking_strategy)) body$chunking_strategy <- chunking_strategy

      self$client$request("POST", paste0("/vector_stores/", vector_store_id, "/file_batches"), body = body)
    },

    # @description
    # Retrieve the status of a file batch.
    # Poll this until `$status == "completed"`.
    #
    # @param vector_store_id Character. **Required.** The vector store ID.
    # @param batch_id Character. **Required.** The batch ID.
    #
    # @return A vector store file batch object with `$status` and `$file_counts`.
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # batch <- client$vector_stores$file_batches$retrieve("vs_abc123", "vsfb_abc123")
    # cat("Status:", batch$status)
    # cat("Completed:", batch$file_counts$completed, "/", batch$file_counts$total)
    # }
    retrieve = function(vector_store_id, batch_id) {
      self$client$request("GET", paste0("/vector_stores/", vector_store_id, "/file_batches/", batch_id))
    },

    # @description
    # Cancel a running file batch.
    #
    # @param vector_store_id Character. **Required.** The vector store ID.
    # @param batch_id Character. **Required.** The batch ID to cancel.
    #
    # @return A file batch object with `$status = "cancelling"`.
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # client$vector_stores$file_batches$cancel("vs_abc123", "vsfb_abc123")
    # }
    cancel = function(vector_store_id, batch_id) {
      self$client$request("POST", paste0("/vector_stores/", vector_store_id, "/file_batches/", batch_id, "/cancel"))
    },

    # @description
    # List files in a vector store file batch.
    #
    # @param vector_store_id Character. **Required.** The vector store ID.
    # @param batch_id Character. **Required.** The batch ID.
    # @param limit Integer or NULL. Max files to return. Default: NULL.
    # @param order Character or NULL. `"asc"` or `"desc"`. Default: NULL.
    # @param after Character or NULL. Pagination cursor. Default: NULL.
    # @param before Character or NULL. Reverse pagination cursor. Default: NULL.
    #
    # @return A list with `$data` — vector store file objects for files in
    #   this batch.
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # files <- client$vector_stores$file_batches$list_files("vs_abc123", "vsfb_abc123")
    # for (f in files$data) cat(f$id, "-", f$status, "\n")
    # }
    list_files = function(vector_store_id, batch_id, limit = NULL, order = NULL, after = NULL, before = NULL) {
      query <- list()
      if (!is.null(limit)) query$limit <- limit
      if (!is.null(order)) query$order <- order
      if (!is.null(after)) query$after <- after
      if (!is.null(before)) query$before <- before

      self$client$request("GET", paste0("/vector_stores/", vector_store_id, "/file_batches/", batch_id, "/files"), query = query)
    }
  )
)

# ---------------------------------------------------------------------------
# Convenience functions for vector stores
# ---------------------------------------------------------------------------

#' Create a Vector Store (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and creates a new vector store.
#'
#' @param ... Parameters passed to [VectorStoresClient]`$create()`:
#'   `name`, `file_ids`, `expires_after`, `chunking_strategy`, `metadata`.
#'
#' @return A vector store object with `$id` (save this), `$name`,
#'   `$status`, and `$file_counts`.
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#'
#' vs <- create_vector_store(
#'   name     = "Economics Literature",
#'   file_ids = list("file-abc123", "file-def456")
#' )
#' cat("Vector Store ID:", vs$id)
#' }
create_vector_store <- function(...) {
  client <- OpenAI$new()
  client$vector_stores$create(...)
}

#' List Vector Stores (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and lists all vector stores.
#'
#' @param ... Parameters passed to [VectorStoresClient]`$list()`:
#'   `limit`, `order`, `after`, `before`.
#'
#' @return A list with `$data` — a list of vector store objects.
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#'
#' stores <- list_vector_stores()
#' for (s in stores$data) cat(s$id, "-", s$name, "\n")
#' }
list_vector_stores <- function(...) {
  client <- OpenAI$new()
  client$vector_stores$list(...)
}

#' Retrieve a Vector Store (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and retrieves a vector store by its ID.
#'
#' @param vector_store_id Character. **Required.** The vector store ID
#'   (e.g. `"vs_abc123"`).
#'
#' @return A vector store object with `$id`, `$name`, `$status`,
#'   and `$file_counts`.
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#'
#' vs <- retrieve_vector_store("vs_abc123")
#' cat("Name:", vs$name)
#' cat("Files:", vs$file_counts$completed, "ready")
#' }
retrieve_vector_store <- function(vector_store_id) {
  client <- OpenAI$new()
  client$vector_stores$retrieve(vector_store_id)
}

#' Delete a Vector Store (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and deletes a vector store.
#' This removes the search index but does NOT delete the underlying files.
#'
#' @param vector_store_id Character. **Required.** The vector store ID.
#'
#' @return A list with `$deleted` (`TRUE`) and `$id`.
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#'
#' result <- delete_vector_store("vs_abc123")
#' if (result$deleted) cat("Vector store deleted.")
#' }
delete_vector_store <- function(vector_store_id) {
  client <- OpenAI$new()
  client$vector_stores$delete(vector_store_id)
}
