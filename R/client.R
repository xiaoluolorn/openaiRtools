#' OpenAI Client Class
#'
#' Main client class for interacting with OpenAI API.
#' Compatible with Python OpenAI SDK interface.
#'
#' @importFrom R6 R6Class
#' @export
OpenAI <- R6Class(
  "OpenAI",
  public = list(
    #' @field api_key OpenAI API key
    api_key = NULL,

    #' @field base_url Base URL for API requests
    base_url = NULL,

    #' @field organization Organization ID (optional)
    organization = NULL,

    #' @field project Project ID (optional)
    project = NULL,

    #' @field timeout Request timeout in seconds
    timeout = NULL,

    #' @field max_retries Maximum number of retries
    max_retries = NULL,

    #' @field chat Chat completions client
    chat = NULL,

    #' @field embeddings Embeddings client
    embeddings = NULL,

    #' @field images Images client
    images = NULL,

    #' @field audio Audio client
    audio = NULL,

    #' @field models Models client
    models = NULL,

    #' @field fine_tuning Fine-tuning client
    fine_tuning = NULL,

    #' @field files Files client
    files = NULL,

    #' @field moderations Moderations client
    moderations = NULL,

    #' @field completions Completions client (legacy)
    completions = NULL,

    #' @field batch Batch client
    batch = NULL,

    #' @field uploads Uploads client
    uploads = NULL,

    #' @field assistants Assistants client (beta)
    assistants = NULL,

    #' @field threads Threads client (beta)
    threads = NULL,

    #' @field vector_stores Vector stores client (beta)
    vector_stores = NULL,

    #' @field responses Responses client
    responses = NULL,

    #' Initialize OpenAI client
    #'
    #' @param api_key OpenAI API key. If NULL, will use OPENAI_API_KEY env var.
    #' @param base_url Base URL. Default: "https://api.openai.com/v1"
    #' @param organization Organization ID. Optional.
    #' @param project Project ID. Optional.
    #' @param timeout Request timeout in seconds. Default: 600
    #' @param max_retries Maximum number of retries. Default: 2
    #' @return OpenAI client object
    initialize = function(api_key = NULL, base_url = NULL,
                          organization = NULL, project = NULL,
                          timeout = 600, max_retries = 2) {
      self$api_key <- api_key %||% Sys.getenv("OPENAI_API_KEY")
      if (self$api_key == "") {
        OpenAIError("No API key provided. Set OPENAI_API_KEY environment variable or pass api_key parameter.")
      }

      self$base_url <- base_url %||% "https://api.openai.com/v1"
      self$organization <- organization %||% Sys.getenv("OPENAI_ORG_ID", unset = NA)
      if (is.na(self$organization)) self$organization <- NULL
      self$project <- project %||% Sys.getenv("OPENAI_PROJECT_ID", unset = NA)
      if (is.na(self$project)) self$project <- NULL
      self$timeout <- timeout
      self$max_retries <- max_retries

      # Initialize sub-clients
      self$chat <- ChatClient$new(self)
      self$embeddings <- EmbeddingsClient$new(self)
      self$images <- ImagesClient$new(self)
      self$audio <- AudioClient$new(self)
      self$models <- ModelsClient$new(self)
      self$fine_tuning <- FineTuningClient$new(self)
      # New API sub-clients
      self$files <- FilesClient$new(self)
      self$moderations <- ModerationsClient$new(self)
      self$completions <- CompletionsClient$new(self)
      self$batch <- BatchClient$new(self)
      self$uploads <- UploadsClient$new(self)
      # Beta API sub-clients
      self$assistants <- AssistantsClient$new(self)
      self$threads <- ThreadsClient$new(self)
      self$vector_stores <- VectorStoresClient$new(self)
      self$responses <- ResponsesClient$new(self)
    },

    #' Build common headers for API requests
    #'
    #' @return Named list of headers
    #' @keywords internal
    build_headers = function() {
      headers <- list(
        "Authorization" = paste("Bearer", self$api_key),
        "OpenAI-Beta" = "assistants=v2"
      )

      if (!is.null(self$organization)) {
        headers[["OpenAI-Organization"]] <- self$organization
      }

      if (!is.null(self$project)) {
        headers[["OpenAI-Project"]] <- self$project
      }

      headers
    },

    #' Make HTTP request to OpenAI API
    #'
    #' @param method HTTP method (GET, POST, DELETE)
    #' @param path API path (e.g., "/chat/completions")
    #' @param body Request body (list). Optional.
    #' @param query Query parameters (list). Optional.
    #' @param stream Whether to stream response. Default: FALSE
    #' @param callback Function to call for each stream chunk (optional)
    #' @return Parsed JSON response or stream callback
    #' @keywords internal
    request = function(method, path, body = NULL, query = NULL, stream = FALSE, callback = NULL) {
      url <- paste0(self$base_url, path)

      headers <- self$build_headers()
      headers[["Content-Type"]] <- "application/json"

      req <- httr2::request(url)
      req <- httr2::req_method(req, method)
      req <- do.call(httr2::req_headers, c(list(req), headers))
      req <- httr2::req_timeout(req, self$timeout)

      # Add retry with exponential backoff
      req <- httr2::req_retry(req,
        max_tries = self$max_retries + 1,
        is_transient = function(resp) {
          httr2::resp_status(resp) %in% c(408, 429, 500, 502, 503, 504)
        }
      )

      if (!is.null(query)) {
        req <- httr2::req_url_query(req, !!!query)
      }

      if (!is.null(body)) {
        req <- httr2::req_body_json(req, body)
      }

      tryCatch(
        {
          if (stream) {
            # Handle streaming response with callback
            handle_stream_response(req, callback = callback)
          } else {
            resp <- httr2::req_perform(req)
            handle_response(resp)
          }
        },
        error = function(e) {
          if (inherits(e, "openai_error")) {
            stop(e)
          }
          OpenAIConnectionError(
            sprintf("Failed to connect to OpenAI API: %s", e$message),
            parent = e
          )
        }
      )
    },

    #' Make multipart form data request to OpenAI API
    #'
    #' @param method HTTP method
    #' @param path API path
    #' @param ... Named arguments for multipart form data
    #' @return Parsed JSON response
    #' @keywords internal
    request_multipart = function(method, path, ...) {
      url <- paste0(self$base_url, path)

      headers <- self$build_headers()
      # Don't set Content-Type for multipart - httr2 sets it automatically

      req <- httr2::request(url)
      req <- httr2::req_method(req, method)
      req <- do.call(httr2::req_headers, c(list(req), headers))
      req <- httr2::req_timeout(req, self$timeout)
      req <- httr2::req_retry(req,
        max_tries = self$max_retries + 1,
        is_transient = function(resp) {
          httr2::resp_status(resp) %in% c(408, 429, 500, 502, 503, 504)
        }
      )

      # Add all multipart fields in one call
      req <- httr2::req_body_multipart(req, ...)

      tryCatch(
        {
          resp <- httr2::req_perform(req)
          handle_response(resp)
        },
        error = function(e) {
          if (inherits(e, "openai_error")) {
            stop(e)
          }
          OpenAIConnectionError(
            sprintf("Failed to connect to OpenAI API: %s", e$message),
            parent = e
          )
        }
      )
    },

    #' Make raw (binary) request to OpenAI API
    #'
    #' @param method HTTP method
    #' @param path API path
    #' @param body Request body
    #' @return Raw response body
    #' @keywords internal
    request_raw = function(method, path, body = NULL) {
      url <- paste0(self$base_url, path)

      headers <- self$build_headers()
      headers[["Content-Type"]] <- "application/json"

      req <- httr2::request(url)
      req <- httr2::req_method(req, method)
      req <- do.call(httr2::req_headers, c(list(req), headers))
      req <- httr2::req_timeout(req, self$timeout)
      req <- httr2::req_retry(req,
        max_tries = self$max_retries + 1,
        is_transient = function(resp) {
          httr2::resp_status(resp) %in% c(408, 429, 500, 502, 503, 504)
        }
      )

      if (!is.null(body)) {
        req <- httr2::req_body_json(req, body)
      }

      tryCatch(
        {
          resp <- httr2::req_perform(req)

          status_code <- httr2::resp_status(resp)
          if (status_code >= 400) {
            handle_response(resp)
          }

          httr2::resp_body_raw(resp)
        },
        error = function(e) {
          if (inherits(e, "openai_error")) {
            stop(e)
          }
          OpenAIConnectionError(
            sprintf("Failed to connect to OpenAI API: %s", e$message),
            parent = e
          )
        }
      )
    }
  )
)
