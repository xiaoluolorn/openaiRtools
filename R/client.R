#' OpenAI Client Class
#'
#' Main client class for interacting with OpenAI API.
#' Compatible with Python OpenAI SDK interface.
#'
#' Helper function to check NULL
#'
#' @param a Value to check
#' @param b Default value
#' @return a if not NULL, otherwise b
#' @keywords internal
`%||%` <- function(a, b) if (is.null(a)) b else a

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
    
    #' Initialize OpenAI client
    #'
    #' @param api_key OpenAI API key. If NULL, will use OPENAI_API_KEY env var.
    #' @param base_url Base URL. Default: "https://api.openai.com/v1"
    #' @param organization Organization ID. Optional.
    #' @param project Project ID. Optional.
    #' @param timeout Request timeout in seconds. Default: 600
    #' @return OpenAI client object
    initialize = function(api_key = NULL, base_url = NULL, 
                          organization = NULL, project = NULL, 
                          timeout = 600) {
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
      
      # Initialize sub-clients
      self$chat <- ChatClient$new(self)
      self$embeddings <- EmbeddingsClient$new(self)
      self$images <- ImagesClient$new(self)
      self$audio <- AudioClient$new(self)
      self$models <- ModelsClient$new(self)
      self$fine_tuning <- FineTuningClient$new(self)
    },
    
    #' Make HTTP request to OpenAI API
    #'
    #' @param method HTTP method (GET, POST, DELETE)
    #' @param path API path (e.g., "/chat/completions")
    #' @param body Request body (list). Optional.
    #' @param query Query parameters (list). Optional.
    #' @param stream Whether to stream response. Default: FALSE
    #' @return Parsed JSON response or stream callback
    #' @keywords internal
    request = function(method, path, body = NULL, query = NULL, stream = FALSE) {
      url <- paste0(self$base_url, path)
      
      req <- httr2::request(url) |>
        httr2::req_method(method) |>
        httr2::req_headers(
          "Authorization" = paste("Bearer", self$api_key),
          "Content-Type" = "application/json",
          "OpenAI-Beta" = "assistants=v2"
        ) |>
        httr2::req_timeout(self$timeout)
      
      if (!is.null(self$organization)) {
        req <- httr2::req_headers(req, "OpenAI-Organization" = self$organization)
      }
      
      if (!is.null(self$project)) {
        req <- httr2::req_headers(req, "OpenAI-Project" = self$project)
      }
      
      if (!is.null(query)) {
        req <- httr2::req_url_query(req, !!!query)
      }
      
      if (!is.null(body)) {
        req <- httr2::req_body_json(req, body)
      }
      
      tryCatch(
        {
          if (stream) {
            # Handle streaming response
            handle_stream_response(req)
          } else {
            resp <- httr2::req_perform(req)
            handle_response(resp)
          }
        },
        error = function(e) {
          OpenAIConnectionError(
            sprintf("Failed to connect to OpenAI API: %s", e$message),
            parent = e
          )
        }
      )
    }
      
      # Add project header if present
      if (!is.null(self$project)) {
        req <- httr2::req_headers(req, "OpenAI-Project" = self$project)
      }
      
      # Add query parameters
      if (!is.null(query)) {
        req <- httr2::req_url_query(req, !!!query)
      }
      
      # Add body
      if (!is.null(body)) {
        req <- httr2::req_body_json(req, body)
      }
      
      # Send request
      tryCatch(
        {
          resp <- httr2::req_perform(req)
          handle_response(resp)
        },
        error = function(e) {
          OpenAIConnectionError(
            sprintf("Failed to connect to OpenAI API: %s", e$message),
            parent = e
          )
        }
      )
    }
  ),
  
  private = list(
    # Helper to check NULL
    `%||%` = function(a, b) if (is.null(a)) b else a
  )
)


