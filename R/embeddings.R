#' Embeddings Client
#'
#' Provides text embedding (vectorization) via the OpenAI Embeddings API.
#' Access via \code{client$embeddings}.
#'
#' Embeddings are numerical vector representations of text that capture semantic
#' meaning. Similar texts produce similar vectors. Common uses include semantic
#' search, clustering, classification, and recommendation systems.
#'
#' @export
EmbeddingsClient <- R6::R6Class(
  "EmbeddingsClient",
  public = list(
    client = NULL,

    #' @description Initialize embeddings client
    #' @param parent Parent \code{OpenAI} client object
    initialize = function(parent) {
      self$client <- parent
    },

    #' @description
    #' Create embedding vectors for one or more text inputs.
    #' Each text is converted to a fixed-length numerical vector that encodes
    #' its semantic meaning.
    #'
    #' @param input \strong{[Required]} The text to embed. Can be:
    #'   \itemize{
    #'     \item A single character string: \code{"Hello world"}
    #'     \item A list of strings for batch processing:
    #'           \code{list("text 1", "text 2", "text 3")}
    #'   }
    #'   Maximum input length depends on the model (e.g. 8191 tokens for
    #'   \code{text-embedding-ada-002}).
    #'
    #' @param model Character. Embedding model to use:
    #'   \itemize{
    #'     \item \code{"text-embedding-3-small"} — 1536 dimensions, faster, cheaper
    #'     \item \code{"text-embedding-3-large"} — 3072 dimensions, highest quality
    #'     \item \code{"text-embedding-ada-002"} — 1536 dimensions, legacy model
    #'   }
    #'   Default: \code{"text-embedding-ada-002"}.
    #'
    #' @param encoding_format Character. Format of the returned embedding vectors:
    #'   \itemize{
    #'     \item \code{"float"} (default) — Returns a list of floating-point numbers
    #'     \item \code{"base64"} — Returns base64-encoded compact binary string
    #'   }
    #'   Default: \code{NULL} (API default \code{"float"}).
    #'
    #' @param dimensions Integer. Number of dimensions for the output embedding.
    #'   Only supported by \code{text-embedding-3-*} models. Reduces vector size
    #'   while preserving most semantic information.
    #'   E.g. set \code{dimensions=256} to get 256-dim vectors instead of 1536.
    #'   Default: \code{NULL} (full dimensions).
    #'
    #' @param user Character. End-user identifier for abuse monitoring.
    #'   Default: \code{NULL}.
    #'
    #' @return A named list:
    #'   \describe{
    #'     \item{\code{$object}}{Always \code{"list"}.}
    #'     \item{\code{$data}}{List of embedding objects (one per input):
    #'       \describe{
    #'         \item{\code{$data[[i]]$embedding}}{Numeric vector of floats — the embedding.
    #'           Use \code{unlist()} to convert to an R numeric vector.}
    #'         \item{\code{$data[[i]]$index}}{Integer. Position of this item in the input list.}
    #'         \item{\code{$data[[i]]$object}}{Always \code{"embedding"}.}
    #'       }
    #'     }
    #'     \item{\code{$model}}{The model used.}
    #'     \item{\code{$usage$prompt_tokens}}{Tokens consumed.}
    #'     \item{\code{$usage$total_tokens}}{Total tokens.}
    #'   }
    #'
    #' @examples
    #' \dontrun{
    #' client <- OpenAI$new(api_key = "sk-xxxxxx")
    #'
    #' # --- Single text embedding ---
    #' resp <- client$embeddings$create(
    #'   input = "The impact of monetary policy on inflation",
    #'   model = "text-embedding-3-small"
    #' )
    #' vec <- unlist(resp$data[[1]]$embedding)
    #' cat("Dimensions:", length(vec), "\n")  # 1536
    #'
    #' # --- Batch embedding ---
    #' texts <- list("GDP growth", "Interest rates", "Today is sunny")
    #' resp <- client$embeddings$create(input = texts, model = "text-embedding-3-small")
    #' vecs <- lapply(resp$data, function(d) unlist(d$embedding))
    #'
    #' # Cosine similarity function
    #' cosine_sim <- function(a, b) sum(a * b) / (sqrt(sum(a^2)) * sqrt(sum(b^2)))
    #' cat("Econ similarity:", cosine_sim(vecs[[1]], vecs[[2]]), "\n")  # high
    #' cat("Topic distance:",  cosine_sim(vecs[[1]], vecs[[3]]), "\n")  # low
    #'
    #' # --- Reduced dimensions (cheaper storage) ---
    #' resp <- client$embeddings$create(
    #'   input      = "Machine learning in economics",
    #'   model      = "text-embedding-3-large",
    #'   dimensions = 256
    #' )
    #' cat("Dimensions:", length(unlist(resp$data[[1]]$embedding)), "\n")  # 256
    #' }
    create = function(input, model = "text-embedding-ada-002",
                      encoding_format = NULL,
                      dimensions = NULL,
                      user = NULL) {
      body <- list(
        input = input,
        model = model
      )

      if (!is.null(encoding_format)) body$encoding_format <- encoding_format
      if (!is.null(dimensions)) body$dimensions <- dimensions
      if (!is.null(user)) body$user <- user

      self$client$request("POST", "/embeddings", body = body)
    }
  )
)

#' Create Text Embeddings (Convenience Function)
#'
#' Shortcut that automatically creates an \code{\link{OpenAI}} client and calls
#' \code{client$embeddings$create()}. The API key is read from the
#' \code{OPENAI_API_KEY} environment variable.
#'
#' @param input \strong{[Required]} A character string or list of strings to embed.
#' @param model Character. Embedding model. Default: \code{"text-embedding-ada-002"}.
#' @param ... Additional parameters passed to \code{EmbeddingsClient$create()},
#'   such as \code{dimensions} or \code{encoding_format}.
#'
#' @return A named list with \code{$data[[i]]$embedding} containing the
#'   numeric embedding vectors.
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#'
#' # Single embedding
#' resp <- create_embedding("Hello world", model = "text-embedding-3-small")
#' vec <- unlist(resp$data[[1]]$embedding)
#' cat("Vector length:", length(vec))
#' }
create_embedding <- function(input, model = "text-embedding-ada-002", ...) {
  client <- OpenAI$new()
  client$embeddings$create(input = input, model = model, ...)
}
