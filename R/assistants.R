#' Assistants Client (Beta)
#'
#' Client for OpenAI Assistants API v2.
#' Build AI assistants with tools and persistent state.
#'
#' @export
AssistantsClient <- R6::R6Class(
  "AssistantsClient",
  public = list(
    client = NULL,
    
    #' Initialize assistants client
    #'
    #' @param parent Parent OpenAI client
    initialize = function(parent) {
      self$client <- parent
    },
    
    #' Create an assistant
    #'
    #' @param model Model ID (e.g., "gpt-4", "gpt-3.5-turbo")
    #' @param name Assistant name (max 256 chars)
    #' @param description Assistant description (max 512 chars)
    #' @param instructions System instructions (max 256,000 chars)
    #' @param tools List of tools: code_interpreter, file_search, function
    #' @param tool_resources Resources for tools (e.g., vector store IDs)
    #' @param metadata Metadata object (max 16 key-value pairs)
    #' @param temperature Sampling temperature
    #' @param top_p Nucleus sampling
    #' @param response_format Response format specification
    #' @return Assistant object
    create = function(model,
                      name = NULL,
                      description = NULL,
                      instructions = NULL,
                      tools = NULL,
                      tool_resources = NULL,
                      metadata = NULL,
                      temperature = NULL,
                      top_p = NULL,
                      response_format = NULL) {
      body <- list(model = model)
      
      if (!is.null(name)) body$name <- name
      if (!is.null(description)) body$description <- description
      if (!is.null(instructions)) body$instructions <- instructions
      if (!is.null(tools)) body$tools <- tools
      if (!is.null(tool_resources)) body$tool_resources <- tool_resources
      if (!is.null(metadata)) body$metadata <- metadata
      if (!is.null(temperature)) body$temperature <- temperature
      if (!is.null(top_p)) body$top_p <- top_p
      if (!is.null(response_format)) body$response_format <- response_format
      
      self$client$request("POST", "/assistants", body = body)
    },
    
    #' List assistants
    #'
    #' @param limit Number of assistants (max 100)
    #' @param order Sort order: "asc" or "desc"
    #' @param after Cursor for pagination
    #' @param before Cursor for pagination
    #' @return List of assistants
    list = function(limit = NULL, order = NULL, after = NULL, before = NULL) {
      query <- list()
      if (!is.null(limit)) query$limit <- limit
      if (!is.null(order)) query$order <- order
      if (!is.null(after)) query$after <- after
      if (!is.null(before)) query$before <- before
      
      self$client$request("GET", "/assistants", query = query)
    },
    
    #' Retrieve an assistant
    #'
    #' @param assistant_id Assistant ID
    #' @return Assistant object
    retrieve = function(assistant_id) {
      self$client$request("GET", paste0("/assistants/", assistant_id))
    },
    
    #' Update an assistant
    #'
    #' @param assistant_id Assistant ID
    #' @param ... Fields to update
    #' @return Updated assistant
    update = function(assistant_id, ...) {
      body <- list(...)
      self$client$request("POST", paste0("/assistants/", assistant_id), body = body)
    },
    
    #' Delete an assistant
    #'
    #' @param assistant_id Assistant ID
    #' @return Deletion status
    delete = function(assistant_id) {
      self$client$request("DELETE", paste0("/assistants/", assistant_id))
    }
  }
)

#' Create an assistant (convenience function)
#'
#' @param model Model ID
#' @param ... Additional parameters
#' @return Assistant object
#' @export
create_assistant <- function(model, ...) {
  client <- OpenAI$new()
  client$assistants$create(model = model, ...)
}

#' List assistants (convenience function)
#'
#' @param ... Additional parameters
#' @return List of assistants
#' @export
list_assistants <- function(...) {
  client <- OpenAI$new()
  client$assistants$list(...)
}

#' Retrieve an assistant (convenience function)
#'
#' @param assistant_id Assistant ID
#' @return Assistant object
#' @export
retrieve_assistant <- function(assistant_id) {
  client <- OpenAI$new()
  client$assistants$retrieve(assistant_id)
}

#' Update an assistant (convenience function)
#'
#' @param assistant_id Assistant ID
#' @param ... Fields to update
#' @return Updated assistant
#' @export
update_assistant <- function(assistant_id, ...) {
  client <- OpenAI$new()
  client$assistants$update(assistant_id, ...)
}

#' Delete an assistant (convenience function)
#'
#' @param assistant_id Assistant ID
#' @return Deletion status
#' @export
delete_assistant <- function(assistant_id) {
  client <- OpenAI$new()
  client$assistants$delete(assistant_id)
}