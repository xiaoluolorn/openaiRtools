#' Threads Client (Beta)
#'
#' Client for OpenAI Threads API v2.
#' Threads are conversations with assistants.
#'
#' @export
ThreadsClient <- R6::R6Class(
  "ThreadsClient",
  public = list(
    client = NULL,
    
    #' @field runs Runs sub-client
    runs = NULL,
    
    #' @field messages Messages sub-client
    messages = NULL,
    
    #' Initialize threads client
    #'
    #' @param parent Parent OpenAI client
    initialize = function(parent) {
      self$client <- parent
      self$runs <- RunsClient$new(parent)
      self$messages <- MessagesClient$new(parent)
    },
    
    #' Create a thread
    #'
    #' @param messages List of initial messages
    #' @param tool_resources Resources for tools
    #' @param metadata Metadata object
    #' @return Thread object
    create = function(messages = NULL, tool_resources = NULL, metadata = NULL) {
      body <- list()
      
      if (!is.null(messages)) body$messages <- messages
      if (!is.null(tool_resources)) body$tool_resources <- tool_resources
      if (!is.null(metadata)) body$metadata <- metadata
      
      self$client$request("POST", "/threads", body = body)
    },
    
    #' Retrieve a thread
    #'
    #' @param thread_id Thread ID
    #' @return Thread object
    retrieve = function(thread_id) {
      self$client$request("GET", paste0("/threads/", thread_id))
    },
    
    #' Update a thread
    #'
    #' @param thread_id Thread ID
    #' @param ... Fields to update
    #' @return Updated thread
    update = function(thread_id, ...) {
      body <- list(...)
      self$client$request("POST", paste0("/threads/", thread_id), body = body)
    },
    
    #' Delete a thread
    #'
    #' @param thread_id Thread ID
    #' @return Deletion status
    delete = function(thread_id) {
      self$client$request("DELETE", paste0("/threads/", thread_id))
    },
    
    #' Create a thread and run it
    #'
    #' @param assistant_id Assistant ID
    #' @param thread Thread configuration or NULL to create new
    #' @param model Override model
    #' @param instructions Override instructions
    #' @param tools Override tools
    #' @param tool_resources Resources for tools
    #' @param metadata Metadata
    #' @param stream Whether to stream
    #' @param callback Callback for streaming
    #' @return Run object or stream
    create_and_run = function(assistant_id,
                               thread = NULL,
                               model = NULL,
                               instructions = NULL,
                               tools = NULL,
                               tool_resources = NULL,
                               metadata = NULL,
                               stream = NULL,
                               callback = NULL) {
      body <- list(assistant_id = assistant_id)
      
      if (!is.null(thread)) body$thread <- thread
      if (!is.null(model)) body$model <- model
      if (!is.null(instructions)) body$instructions <- instructions
      if (!is.null(tools)) body$tools <- tools
      if (!is.null(tool_resources)) body$tool_resources <- tool_resources
      if (!is.null(metadata)) body$metadata <- metadata
      if (!is.null(stream)) body$stream <- stream
      
      is_streaming <- !is.null(stream) && stream
      
      self$client$request(
        "POST",
        "/threads/runs",
        body = body,
        stream = is_streaming,
        callback = if (is_streaming) callback else NULL
      )
    }
  }
)

#' Runs Client
#'
#' @export
RunsClient <- R6::R6Class(
  "RunsClient",
  public = list(
    client = NULL,
    
    #' @field steps Steps sub-client
    steps = NULL,
    
    #' Initialize runs client
    #'
    #' @param parent Parent OpenAI client
    initialize = function(parent) {
      self$client <- parent
      self$steps <- RunStepsClient$new(parent)
    },
    
    #' Create a run
    #'
    #' @param thread_id Thread ID
    #' @param assistant_id Assistant ID
    #' @param model Override model
    #' @param instructions Override instructions
    #' @param additional_instructions Additional instructions
    #' @param additional_messages Additional messages
    #' @param tools Override tools
    #' @param metadata Metadata
    #' @param temperature Temperature
    #' @param top_p Top p
    #' @param max_prompt_tokens Max prompt tokens
    #' @param max_completion_tokens Max completion tokens
    #' @param truncation_strategy Truncation strategy
    #' @param tool_choice Tool choice
    #' @param parallel_tool_calls Allow parallel tool calls
    #' @param response_format Response format
    #' @param stream Stream the run
    #' @param callback Callback for streaming
    #' @return Run object
    create = function(thread_id,
                      assistant_id,
                      model = NULL,
                      instructions = NULL,
                      additional_instructions = NULL,
                      additional_messages = NULL,
                      tools = NULL,
                      metadata = NULL,
                      temperature = NULL,
                      top_p = NULL,
                      max_prompt_tokens = NULL,
                      max_completion_tokens = NULL,
                      truncation_strategy = NULL,
                      tool_choice = NULL,
                      parallel_tool_calls = NULL,
                      response_format = NULL,
                      stream = NULL,
                      callback = NULL) {
      body <- list(assistant_id = assistant_id)
      
      if (!is.null(model)) body$model <- model
      if (!is.null(instructions)) body$instructions <- instructions
      if (!is.null(additional_instructions)) body$additional_instructions <- additional_instructions
      if (!is.null(additional_messages)) body$additional_messages <- additional_messages
      if (!is.null(tools)) body$tools <- tools
      if (!is.null(metadata)) body$metadata <- metadata
      if (!is.null(temperature)) body$temperature <- temperature
      if (!is.null(top_p)) body$top_p <- top_p
      if (!is.null(max_prompt_tokens)) body$max_prompt_tokens <- max_prompt_tokens
      if (!is.null(max_completion_tokens)) body$max_completion_tokens <- max_completion_tokens
      if (!is.null(truncation_strategy)) body$truncation_strategy <- truncation_strategy
      if (!is.null(tool_choice)) body$tool_choice <- tool_choice
      if (!is.null(parallel_tool_calls)) body$parallel_tool_calls <- parallel_tool_calls
      if (!is.null(response_format)) body$response_format <- response_format
      if (!is.null(stream)) body$stream <- stream
      
      is_streaming <- !is.null(stream) && stream
      
      self$client$request(
        "POST",
        paste0("/threads/", thread_id, "/runs"),
        body = body,
        stream = is_streaming,
        callback = if (is_streaming) callback else NULL
      )
    },
    
    #' List runs
    #'
    #' @param thread_id Thread ID
    #' @param limit Number of runs
    #' @param order Sort order
    #' @param after Cursor
    #' @param before Cursor
    #' @return List of runs
    list = function(thread_id, limit = NULL, order = NULL, after = NULL, before = NULL) {
      query <- list()
      if (!is.null(limit)) query$limit <- limit
      if (!is.null(order)) query$order <- order
      if (!is.null(after)) query$after <- after
      if (!is.null(before)) query$before <- before
      
      self$client$request("GET", paste0("/threads/", thread_id, "/runs"), query = query)
    },
    
    #' Retrieve a run
    #'
    #' @param thread_id Thread ID
    #' @param run_id Run ID
    #' @return Run object
    retrieve = function(thread_id, run_id) {
      self$client$request("GET", paste0("/threads/", thread_id, "/runs/", run_id))
    },
    
    #' Update a run
    #'
    #' @param thread_id Thread ID
    #' @param run_id Run ID
    #' @param metadata Metadata to update
    #' @return Updated run
    update = function(thread_id, run_id, metadata = NULL) {
      body <- list()
      if (!is.null(metadata)) body$metadata <- metadata
      self$client$request("POST", paste0("/threads/", thread_id, "/runs/", run_id), body = body)
    },
    
    #' Cancel a run
    #'
    #' @param thread_id Thread ID
    #' @param run_id Run ID
    #' @return Cancelled run
    cancel = function(thread_id, run_id) {
      self$client$request("POST", paste0("/threads/", thread_id, "/runs/", run_id, "/cancel"))
    },
    
    #' Submit tool outputs
    #'
    #' @param thread_id Thread ID
    #' @param run_id Run ID
    #' @param tool_outputs List of tool outputs
    #' @param stream Stream the response
    #' @param callback Callback for streaming
    #' @return Run object
    submit_tool_outputs = function(thread_id, run_id, tool_outputs, stream = NULL, callback = NULL) {
      body <- list(tool_outputs = tool_outputs)
      
      if (!is.null(stream)) body$stream <- stream
      
      is_streaming <- !is.null(stream) && stream
      
      self$client$request(
        "POST",
        paste0("/threads/", thread_id, "/runs/", run_id, "/submit_tool_outputs"),
        body = body,
        stream = is_streaming,
        callback = if (is_streaming) callback else NULL
      )
    }
  }
)

#' Run Steps Client
#'
#' @export
RunStepsClient <- R6::R6Class(
  "RunStepsClient",
  public = list(
    client = NULL,
    
    #' Initialize run steps client
    #'
    #' @param parent Parent OpenAI client
    initialize = function(parent) {
      self$client <- parent
    },
    
    #' List run steps
    #'
    #' @param thread_id Thread ID
    #' @param run_id Run ID
    #' @param limit Number of steps
    #' @param order Sort order
    #' @param after Cursor
    #' @param before Cursor
    #' @return List of run steps
    list = function(thread_id, run_id, limit = NULL, order = NULL, after = NULL, before = NULL) {
      query <- list()
      if (!is.null(limit)) query$limit <- limit
      if (!is.null(order)) query$order <- order
      if (!is.null(after)) query$after <- after
      if (!is.null(before)) query$before <- before
      
      self$client$request("GET", paste0("/threads/", thread_id, "/runs/", run_id, "/steps"), query = query)
    },
    
    #' Retrieve a run step
    #'
    #' @param thread_id Thread ID
    #' @param run_id Run ID
    #' @param step_id Step ID
    #' @return Run step object
    retrieve = function(thread_id, run_id, step_id) {
      self$client$request("GET", paste0("/threads/", thread_id, "/runs/", run_id, "/steps/", step_id))
    }
  }
)

#' Messages Client
#'
#' @export
MessagesClient <- R6::R6Class(
  "MessagesClient",
  public = list(
    client = NULL,
    
    #' Initialize messages client
    #'
    #' @param parent Parent OpenAI client
    initialize = function(parent) {
      self$client <- parent
    },
    
    #' Create a message
    #'
    #' @param thread_id Thread ID
    #' @param role Message role: "user" or "assistant"
    #' @param content Message content (string or list for multimodal)
    #' @param attachments List of attachments
    #' @param metadata Metadata
    #' @return Message object
    create = function(thread_id, role, content, attachments = NULL, metadata = NULL) {
      body <- list(
        role = role,
        content = content
      )
      
      if (!is.null(attachments)) body$attachments <- attachments
      if (!is.null(metadata)) body$metadata <- metadata
      
      self$client$request("POST", paste0("/threads/", thread_id, "/messages"), body = body)
    },
    
    #' List messages
    #'
    #' @param thread_id Thread ID
    #' @param limit Number of messages
    #' @param order Sort order
    #' @param after Cursor
    #' @param before Cursor
    #' @param run_id Filter by run ID
    #' @return List of messages
    list = function(thread_id, limit = NULL, order = NULL, after = NULL, before = NULL, run_id = NULL) {
      query <- list()
      if (!is.null(limit)) query$limit <- limit
      if (!is.null(order)) query$order <- order
      if (!is.null(after)) query$after <- after
      if (!is.null(before)) query$before <- before
      if (!is.null(run_id)) query$run_id <- run_id
      
      self$client$request("GET", paste0("/threads/", thread_id, "/messages"), query = query)
    },
    
    #' Retrieve a message
    #'
    #' @param thread_id Thread ID
    #' @param message_id Message ID
    #' @return Message object
    retrieve = function(thread_id, message_id) {
      self$client$request("GET", paste0("/threads/", thread_id, "/messages/", message_id))
    },
    
    #' Update a message
    #'
    #' @param thread_id Thread ID
    #' @param message_id Message ID
    #' @param metadata Metadata to update
    #' @return Updated message
    update = function(thread_id, message_id, metadata = NULL) {
      body <- list()
      if (!is.null(metadata)) body$metadata <- metadata
      self$client$request("POST", paste0("/threads/", thread_id, "/messages/", message_id), body = body)
    },
    
    #' Delete a message
    #'
    #' @param thread_id Thread ID
    #' @param message_id Message ID
    #' @return Deletion status
    delete = function(thread_id, message_id) {
      self$client$request("DELETE", paste0("/threads/", thread_id, "/messages/", message_id))
    }
  }
)

# Convenience functions for threads

#' Create a thread (convenience function)
#' @param ... Additional parameters
#' @return Thread object
#' @export
create_thread <- function(...) {
  client <- OpenAI$new()
  client$threads$create(...)
}

#' Retrieve a thread (convenience function)
#' @param thread_id Thread ID
#' @return Thread object
#' @export
retrieve_thread <- function(thread_id) {
  client <- OpenAI$new()
  client$threads$retrieve(thread_id)
}

#' Update a thread (convenience function)
#' @param thread_id Thread ID
#' @param ... Fields to update
#' @return Updated thread
#' @export
update_thread <- function(thread_id, ...) {
  client <- OpenAI$new()
  client$threads$update(thread_id, ...)
}

#' Delete a thread (convenience function)
#' @param thread_id Thread ID
#' @return Deletion status
#' @export
delete_thread <- function(thread_id) {
  client <- OpenAI$new()
  client$threads$delete(thread_id)
}

# Convenience functions for runs

#' Create a run (convenience function)
#' @param thread_id Thread ID
#' @param assistant_id Assistant ID
#' @param ... Additional parameters
#' @return Run object
#' @export
create_run <- function(thread_id, assistant_id, ...) {
  client <- OpenAI$new()
  client$threads$runs$create(thread_id = thread_id, assistant_id = assistant_id, ...)
}

#' Retrieve a run (convenience function)
#' @param thread_id Thread ID
#' @param run_id Run ID
#' @return Run object
#' @export
retrieve_run <- function(thread_id, run_id) {
  client <- OpenAI$new()
  client$threads$runs$retrieve(thread_id, run_id)
}

#' Cancel a run (convenience function)
#' @param thread_id Thread ID
#' @param run_id Run ID
#' @return Cancelled run
#' @export
cancel_run <- function(thread_id, run_id) {
  client <- OpenAI$new()
  client$threads$runs$cancel(thread_id, run_id)
}

# Convenience functions for messages

#' Create a message (convenience function)
#' @param thread_id Thread ID
#' @param role Message role
#' @param content Message content
#' @param ... Additional parameters
#' @return Message object
#' @export
create_message <- function(thread_id, role, content, ...) {
  client <- OpenAI$new()
  client$threads$messages$create(thread_id = thread_id, role = role, content = content, ...)
}

#' List messages (convenience function)
#' @param thread_id Thread ID
#' @param ... Additional parameters
#' @return List of messages
#' @export
list_messages <- function(thread_id, ...) {
  client <- OpenAI$new()
  client$threads$messages$list(thread_id, ...)
}