#' Responses Client
#'
#' Client for OpenAI Responses API.
#' New unified API for generating text and handling complex workflows.
#'
#' @export
ResponsesClient <- R6::R6Class(
  "ResponsesClient",
  public = list(
    client = NULL,
    
    #' Initialize responses client
    #'
    #' @param parent Parent OpenAI client
    initialize = function(parent) {
      self$client <- parent
    },
    
    #' Create a response
    #'
    #' @param model Model ID (e.g., "gpt-4o", "gpt-4o-mini")
    #' @param input Input text, messages, or response ID for continuation
    #' @param instructions System instructions
    #' @param previous_response_id Previous response ID for conversation continuity
    #' @param tools List of tools
    #' @param tool_choice Tool choice strategy
    #' @param parallel_tool_calls Allow parallel tool calls
    #' @param max_output_tokens Maximum output tokens
    #' @param max_completion_tokens Maximum completion tokens (legacy)
    #' @param temperature Sampling temperature
    #' @param top_p Nucleus sampling
    #' @param truncation Truncation strategy
    #' @param metadata Metadata
    #' @param reasoning Reasoning configuration
    #' @param service_tier Service tier: "auto", "default", "flex", "scale"
    #' @param prompt_cache_key Cache key
    #' @param prompt_cache_retention Cache retention
    #' @param include Additional output data
    #' @param store Store the response
    #' @param stream Stream the response
    #' @param callback Callback for streaming
    #' @return Response object
    create = function(model,
                      input,
                      instructions = NULL,
                      previous_response_id = NULL,
                      tools = NULL,
                      tool_choice = NULL,
                      parallel_tool_calls = NULL,
                      max_output_tokens = NULL,
                      max_completion_tokens = NULL,
                      temperature = NULL,
                      top_p = NULL,
                      truncation = NULL,
                      metadata = NULL,
                      reasoning = NULL,
                      service_tier = NULL,
                      prompt_cache_key = NULL,
                      prompt_cache_retention = NULL,
                      include = NULL,
                      store = NULL,
                      stream = NULL,
                      callback = NULL) {
      body <- list(
        model = model,
        input = input
      )
      
      if (!is.null(instructions)) body$instructions <- instructions
      if (!is.null(previous_response_id)) body$previous_response_id <- previous_response_id
      if (!is.null(tools)) body$tools <- tools
      if (!is.null(tool_choice)) body$tool_choice <- tool_choice
      if (!is.null(parallel_tool_calls)) body$parallel_tool_calls <- parallel_tool_calls
      if (!is.null(max_output_tokens)) body$max_output_tokens <- max_output_tokens
      if (!is.null(max_completion_tokens)) body$max_completion_tokens <- max_completion_tokens
      if (!is.null(temperature)) body$temperature <- temperature
      if (!is.null(top_p)) body$top_p <- top_p
      if (!is.null(truncation)) body$truncation <- truncation
      if (!is.null(metadata)) body$metadata <- metadata
      if (!is.null(reasoning)) body$reasoning <- reasoning
      if (!is.null(service_tier)) body$service_tier <- service_tier
      if (!is.null(prompt_cache_key)) body$prompt_cache_key <- prompt_cache_key
      if (!is.null(prompt_cache_retention)) body$prompt_cache_retention <- prompt_cache_retention
      if (!is.null(include)) body$include <- include
      if (!is.null(store)) body$store <- store
      if (!is.null(stream)) body$stream <- stream
      
      is_streaming <- !is.null(stream) && stream
      
      self$client$request(
        "POST",
        "/responses",
        body = body,
        stream = is_streaming,
        callback = if (is_streaming) callback else NULL
      )
    },
    
    #' Retrieve a response
    #'
    #' @param response_id Response ID
    #' @return Response object
    retrieve = function(response_id) {
      self$client$request("GET", paste0("/responses/", response_id))
    },
    
    #' Delete a response
    #'
    #' @param response_id Response ID
    #' @return Deletion status
    delete = function(response_id) {
      self$client$request("DELETE", paste0("/responses/", response_id))
    },
    
    #' Cancel a response
    #'
    #' @param response_id Response ID
    #' @return Cancelled response
    cancel = function(response_id) {
      self$client$request("POST", paste0("/responses/", response_id, "/cancel"))
    },
    
    #' List input items for a response
    #'
    #' @param response_id Response ID
    #' @param after Cursor
    #' @param limit Number of items
    #' @return List of input items
    list_input_items = function(response_id, after = NULL, limit = NULL) {
      query <- list()
      if (!is.null(after)) query$after <- after
      if (!is.null(limit)) query$limit <- limit
      
      self$client$request("GET", paste0("/responses/", response_id, "/input_items"), query = query)
    }
  }
)

#' Create a response (convenience function)
#'
#' @param model Model ID
#' @param input Input
#' @param ... Additional parameters
#' @return Response object
#' @export
create_response <- function(model, input, ...) {
  client <- OpenAI$new()
  client$responses$create(model = model, input = input, ...)
}

#' Retrieve a response (convenience function)
#'
#' @param response_id Response ID
#' @return Response object
#' @export
retrieve_response <- function(response_id) {
  client <- OpenAI$new()
  client$responses$retrieve(response_id)
}

#' Delete a response (convenience function)
#'
#' @param response_id Response ID
#' @return Deletion status
#' @export
delete_response <- function(response_id) {
  client <- OpenAI$new()
  client$responses$delete(response_id)
}

#' Cancel a response (convenience function)
#'
#' @param response_id Response ID
#' @return Cancelled response
#' @export
cancel_response <- function(response_id) {
  client <- OpenAI$new()
  client$responses$cancel(response_id)
}