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
#' @return List of parsed SSE data chunks
#' @keywords internal
handle_stream_response <- function(req) {
  chunks <- list()
  
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
                chunks[[length(chunks) + 1]] <<- data_json
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
  
  # Return collected chunks
  chunks
}
