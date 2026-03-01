#' OpenAI Error Classes
#'
#' Error classes for OpenAI API errors.
#'
#' @name OpenAIError
#' @rdname OpenAIError
#' @keywords internal
NULL

#' Base OpenAI Error
#'
#' @param message Error message
#' @param ... Additional arguments passed to [rlang::abort()]
#' @export
OpenAIError <- function(message, ...) {
  rlang::abort(message, class = "openai_error", ...)
}

#' OpenAI Connection Error
#'
#' @param message Error message
#' @param ... Additional arguments
#' @export
OpenAIConnectionError <- function(message, ...) {
  rlang::abort(message, class = c("openai_connection_error", "openai_error"), ...)
}

#' OpenAI API Error
#'
#' @param message Error message
#' @param status_code HTTP status code
#' @param response Raw response object
#' @param ... Additional arguments
#' @export
OpenAIAPIError <- function(message, status_code = NULL, response = NULL, ...) {
  rlang::abort(
    message,
    class = c("openai_api_error", "openai_error"),
    status_code = status_code,
    response = response,
    ...
  )
}

#' Check if value is NULL and return default
#'
#' @param a Value to check
#' @param b Default value
#' @return a if not NULL, otherwise b
#' @keywords internal
`%||%` <- function(a, b) if (is.null(a)) b else a

#' Handle HTTP response and raise appropriate errors
#'
#' @param resp HTTP response object from httr2
#' @return Parsed response content
#' @keywords internal
handle_response <- function(resp) {
  status_code <- httr2::resp_status(resp)
  
  if (status_code >= 400) {
    body <- tryCatch(
      jsonlite::fromJSON(rawToChar(resp$body), simplifyVector = FALSE),
      error = function(e) NULL
    )
    
    error_message <- if (!is.null(body) && !is.null(body$error$message)) {
      body$error$message
    } else {
      httr2::resp_status_desc(resp) %||% "Unknown error"
    }
    
    OpenAIAPIError(
      message = sprintf("OpenAI API error: %s (HTTP %d)", error_message, status_code),
      status_code = status_code,
      response = resp
    )
  }
  
  # Parse JSON response
  jsonlite::fromJSON(rawToChar(resp$body), simplifyVector = FALSE)
}

#' Handle streaming response from OpenAI API
#'
#' @param req httr2 request object
#' @param callback Function to call for each chunk (optional)
#' @return If callback is provided, returns invisible(NULL). Otherwise returns an R6 iterator object.
#' @keywords internal
handle_stream_response <- function(req, callback = NULL) {
  chunks <- list()
  has_callback <- !is.null(callback)
  
  # Perform streaming request using httr2's streaming API
  resp <- httr2::req_perform_stream(
    req,
    callback = function(chunk) {
      if (length(chunk) > 0) {
        text <- rawToChar(chunk)
        lines <- strsplit(text, "\n")[[1]]
        
        for (line in lines) {
          # Skip empty lines
          if (trimws(line) == "") next
          
          # Parse SSE data lines
          if (startsWith(line, "data: ")) {
            data_str <- substring(line, 7)
            
            # Check for end of stream
            if (trimws(data_str) == "[DONE]") {
              return(invisible(FALSE))  # Stop streaming
            }
            
            # Parse JSON
            tryCatch(
              {
                data_json <- jsonlite::fromJSON(data_str, simplifyVector = FALSE)
                
                if (!has_callback) {
                  chunks[[length(chunks) + 1]] <<- data_json
                }
                
                # Call user callback if provided
                if (has_callback) {
                  callback(data_json)
                }
              },
              error = function(e) {
                # Skip invalid JSON
              }
            )
          }
        }
      }
      invisible(TRUE)  # Continue streaming
    }
  )
  
  # Return appropriate result
  if (has_callback) {
    invisible(NULL)
  } else {
    # Create an iterator-like object for chunks
    StreamIterator$new(chunks)
  }
}

#' Stream Iterator Class
#'
#' R6 class for iterating over streaming response chunks.
#'
#' @export
StreamIterator <- R6::R6Class(
  "StreamIterator",
  public = list(
    #' @field chunks List of all chunks
    chunks = NULL,
    
    #' @field current_index Current position in iteration
    current_index = 0,
    
    #' Initialize stream iterator
    #' @param chunks List of parsed SSE chunks
    initialize = function(chunks) {
      self$chunks <- chunks
      self$current_index <- 0
    },
    
    #' Get next chunk
    #' @return Next chunk or NULL if end of stream
    next_chunk = function() {
      self$current_index <- self$current_index + 1
      if (self$current_index > length(self$chunks)) {
        return(NULL)
      }
      self$chunks[[self$current_index]]
    },
    
    #' Check if there are more chunks
    #' @return TRUE if more chunks available
    has_more = function() {
      self$current_index < length(self$chunks)
    },
    
    #' Reset iterator to beginning
    reset = function() {
      self$current_index <- 0
    },
    
    #' Get all chunks as list
    #' @return List of all chunks
    as_list = function() {
      self$chunks
    },
    
    #' Get full text by concatenating all content deltas
    #' @return Complete text content
    get_full_text = function() {
      full_text <- ""
      for (chunk in self$chunks) {
        if (!is.null(chunk$choices) && length(chunk$choices) > 0) {
          delta <- chunk$choices[[1]]$delta
          if (!is.null(delta$content)) {
            full_text <- paste0(full_text, delta$content)
          }
        }
      }
      full_text
    }
  )
)