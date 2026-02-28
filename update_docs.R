#!/usr/bin/env Rscript

# Update documentation for openaiR package
# This script adds complete roxygen2 documentation to all R files

cat("=== Updating openaiR Documentation ===\n\n")

# Read current client.R
client_file <- "R/client.R"

# New complete client.R with full documentation
client_content <- '#\' OpenAI Client Class
#\'
#\' Main client class for interacting with OpenAI API.
#\' Compatible with Python OpenAI SDK interface.
#\'
#\' @section Features:
#\' - Chat Completions (GPT-4, GPT-3.5-Turbo)
#\' - Embeddings (text-embedding models)
#\' - Images (DALL-E 2, DALL-E 3)
#\' - Audio (Whisper transcriptions, translations, TTS)
#\' - Models (list, retrieve, delete)
#\' - Fine-tuning (create, manage jobs)
#\'
#\' @section Authentication:
#\' Set your API key using one of these methods:
#\' \\enumerate{
#\'   \\item Environment variable: `Sys.setenv(OPENAI_API_KEY = "sk-...")`
#\'   \\item Direct parameter: `OpenAI$new(api_key = "sk-...")`
#\'   \\item `.Renviron` file: Add `OPENAI_API_KEY=sk-...` (permanent)
#\' }
#\'
#\' @examples
#\' \\dontrun{
#\' # Method 1: Using environment variable (recommended)
#\' Sys.setenv(OPENAI_API_KEY = "sk-your-api-key")
#\' client <- OpenAI$new()
#\'
#\' # Method 2: Direct parameter
#\' client <- OpenAI$new(api_key = "sk-your-api-key")
#\'
#\' # Test the client
#\' print(client$base_url)
#\' print(class(client$chat))
#\' }
#\'
#\' @seealso [create_chat_completion()], [create_embedding()], [create_image()]
#\'
#\' @export
OpenAI <- R6Class(
  "OpenAI",
  public = list(
    #\' @field api_key OpenAI API key
    api_key = NULL,
    
    #\' @field base_url Base URL for API requests
    base_url = NULL,
    
    #\' @field organization Organization ID (optional)
    organization = NULL,
    
    #\' @field project Project ID (optional)
    project = NULL,
    
    #\' @field timeout Request timeout in seconds
    timeout = NULL,
    
    #\' @field chat Chat completions client
    chat = NULL,
    
    #\' @field embeddings Embeddings client
    embeddings = NULL,
    
    #\' @field images Images client
    images = NULL,
    
    #\' @field audio Audio client
    audio = NULL,
    
    #\' @field models Models client
    models = NULL,
    
    #\' @field fine_tuning Fine-tuning client
    fine_tuning = NULL,
    
    #\' Initialize OpenAI client
    #\'
    #\' @param api_key OpenAI API key. If NULL, will use OPENAI_API_KEY env var.
    #\' @param base_url Base URL. Default: "https://api.openai.com/v1"
    #\' @param organization Organization ID. Optional.
    #\' @param project Project ID. Optional.
    #\' @param timeout Request timeout in seconds. Default: 600
    #\' @return OpenAI client object
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
    
    #\' Make HTTP request to OpenAI API
    #\'
    #\' @param method HTTP method (GET, POST, DELETE)
    #\' @param path API path (e.g., "/chat/completions")
    #\' @param body Request body (list). Optional.
    #\' @param query Query parameters (list). Optional.
    #\' @param stream Whether to stream response. Default: FALSE
    #\' @return Parsed JSON response
    #\' @keywords internal
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
    `%||%` = function(a, b) if (is.null(a)) b else a
  )
)

#\' Helper function to check NULL
#\'
#\' @param a Value to check
#\' @param b Default value
#\' @return a if not NULL, otherwise b
#\' @keywords internal
`%||%` <- function(a, b) if (is.null(a)) b else a
'

# Write the file
writeLines(client_content, client_file)
cat("✓ Updated", client_file, "\n")

cat("\n=== Documentation Update Complete ===\n")
cat("\nNow run:\n")
cat("1. roxygen2::roxygenise('.')\n")
cat("2. git add man/ NAMESPACE\n")
cat("3. git commit -m 'Add complete roxygen2 documentation'\n")
cat("4. git push\n")
