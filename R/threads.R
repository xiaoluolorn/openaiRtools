#' Threads Client (Beta)
#'
#' Client for the OpenAI Threads API v2 (Beta).
#' Threads are persistent conversation containers for Assistants.
#' Access via `client$threads`.
#'
#' @description
#' A Thread stores the message history of a conversation with an Assistant.
#' Threads are persistent: they accumulate messages over multiple runs and
#' can be retrieved at any time.
#'
#' @section Sub-clients:
#' \describe{
#'   \item{`$runs`}{[RunsClient] — Create and manage runs on threads}
#'   \item{`$messages`}{[MessagesClient] — Add and read thread messages}
#' }
#'
#' @section Typical workflow:
#' \enumerate{
#'   \item Create a thread: `client$threads$create()`
#'   \item Add user message: `client$threads$messages$create(thread_id, "user", "...")`
#'   \item Create a run: `client$threads$runs$create(thread_id, assistant_id)`
#'   \item Poll run until `$status == "completed"`
#'   \item Read response: `client$threads$messages$list(thread_id)`
#' }
#'
#' @export
ThreadsClient <- R6::R6Class(
  "ThreadsClient",
  public = list(
    client = NULL,

    # Field: runs Runs sub-client
    runs = NULL,

    # Field: messages Messages sub-client
    messages = NULL,

    # Initialize threads client
    #
    # @param parent Parent OpenAI client
    initialize = function(parent) {
      self$client <- parent
      self$runs <- RunsClient$new(parent)
      self$messages <- MessagesClient$new(parent)
    },

    # @description
    # Create a new thread. Threads persist until deleted, so you can
    # return to them later by saving the thread ID.
    #
    # @param messages List or NULL. Optional list of initial messages to
    #   pre-populate the thread. Each message must be a named list with:
    #   \itemize{
    #     \item `role` — `"user"` or `"assistant"`
    #     \item `content` — Character string or list of content parts
    #   }
    #   Example:
    #   \preformatted{
    #   list(
    #     list(role = "user", content = "What is OLS?")
    #   )
    #   }
    #   Default: NULL (empty thread).
    #
    # @param tool_resources List or NULL. Resources to make available to
    #   the assistant's tools. For file search:
    #   `list(file_search = list(vector_store_ids = list("vs-abc123")))`.
    #   For code interpreter:
    #   `list(code_interpreter = list(file_ids = list("file-abc123")))`.
    #   Default: NULL.
    #
    # @param metadata Named list or NULL. Up to 16 key-value pairs for
    #   organizing threads. Default: NULL.
    #
    # @return A thread object:
    #   \describe{
    #     \item{`$id`}{Character. Thread ID (e.g. `"thread_abc123"`). **Save this.**}
    #     \item{`$object`}{Always `"thread"`.}
    #     \item{`$created_at`}{Integer. Unix timestamp.}
    #     \item{`$metadata`}{List. Your metadata.}
    #   }
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    #
    # # Create an empty thread
    # thread <- client$threads$create()
    # cat("Thread ID:", thread$id)
    #
    # # Create a thread with an initial message
    # thread <- client$threads$create(
    #   messages = list(
    #     list(role = "user", content = "Explain the Gauss-Markov theorem.")
    #   )
    # )
    # }
    create = function(messages = NULL, tool_resources = NULL, metadata = NULL) {
      body <- list()

      if (!is.null(messages)) body$messages <- messages
      if (!is.null(tool_resources)) body$tool_resources <- tool_resources
      if (!is.null(metadata)) body$metadata <- metadata

      self$client$request("POST", "/threads", body = body)
    },

    # @description
    # Retrieve a thread by its ID.
    #
    # @param thread_id Character. **Required.** The thread ID
    #   (e.g. `"thread_abc123"`).
    #
    # @return A thread object with `$id`, `$created_at`, and `$metadata`.
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # thread <- client$threads$retrieve("thread_abc123")
    # cat("Created at:", thread$created_at)
    # }
    retrieve = function(thread_id) {
      self$client$request("GET", paste0("/threads/", thread_id))
    },

    # @description
    # Update a thread's metadata.
    #
    # @param thread_id Character. **Required.** The thread ID to update.
    #
    # @param ... Named fields to update. Currently only `metadata` and
    #   `tool_resources` are updatable.
    #   Example: `metadata = list(topic = "econometrics", session = "1")`.
    #
    # @return The updated thread object.
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # thread <- client$threads$update(
    #   "thread_abc123",
    #   metadata = list(label = "session-2", user = "student-01")
    # )
    # }
    update = function(thread_id, ...) {
      body <- list(...)
      self$client$request("POST", paste0("/threads/", thread_id), body = body)
    },

    # @description
    # Delete a thread permanently. All messages in the thread are also deleted.
    #
    # @param thread_id Character. **Required.** The thread ID to delete.
    #
    # @return A list with `$deleted` (`TRUE`) and `$id`.
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # result <- client$threads$delete("thread_abc123")
    # cat("Deleted:", result$deleted)
    # }
    delete = function(thread_id) {
      self$client$request("DELETE", paste0("/threads/", thread_id))
    },

    # @description
    # Simultaneously create a thread and start a run on it.
    # A shortcut for `$create()` + `$runs$create()` in one call.
    #
    # @param assistant_id Character. **Required.** The assistant ID to run.
    #
    # @param thread List or NULL. Thread creation parameters. If NULL,
    #   creates an empty thread. To pre-populate:
    #   `list(messages = list(list(role = "user", content = "Hello")))`.
    #
    # @param model Character or NULL. Override the assistant's model.
    #   Default: NULL (uses assistant's model).
    #
    # @param instructions Character or NULL. Override the assistant's system
    #   instructions for this run. Default: NULL.
    #
    # @param tools List or NULL. Override the assistant's tools. Default: NULL.
    #
    # @param tool_resources List or NULL. Tool resources override. Default: NULL.
    #
    # @param metadata Named list or NULL. Metadata for the run. Default: NULL.
    #
    # @param stream Logical or NULL. If TRUE, streams run events.
    #   Default: NULL.
    #
    # @param callback Function or NULL. Called for each SSE chunk when
    #   streaming. Default: NULL.
    #
    # @return A run object (see [RunsClient]`$create()`).
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # run <- client$threads$create_and_run(
    #   assistant_id = "asst_abc123",
    #   thread = list(
    #     messages = list(list(role = "user", content = "What is GMM?"))
    #   )
    # )
    # cat("Thread ID:", run$thread_id)
    # cat("Run ID:", run$id)
    # }
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
  )
)

#' Runs Client
#'
#' Manages runs on threads. A run executes an assistant's logic against
#' a thread's messages and produces a response.
#' Access via `client$threads$runs`.
#'
#' @section Run status lifecycle:
#' `"queued"` → `"in_progress"` → `"completed"` (success)
#' or → `"requires_action"` (tool call needed) → `"in_progress"` (after submitting outputs)
#' or → `"failed"` / `"cancelled"` / `"expired"`
#'
#' @export
RunsClient <- R6::R6Class(
  "RunsClient",
  public = list(
    client = NULL,

    # Field: steps Steps sub-client
    steps = NULL,

    # Initialize runs client
    #
    # @param parent Parent OpenAI client
    initialize = function(parent) {
      self$client <- parent
      self$steps <- RunStepsClient$new(parent)
    },

    # @description
    # Create a run to execute an assistant against a thread.
    # After creating a run, poll with `$retrieve()` until status is
    # `"completed"`, then read the response with
    # `client$threads$messages$list(thread_id)`.
    #
    # @param thread_id Character. **Required.** The thread ID to run
    #   (e.g. `"thread_abc123"`).
    #
    # @param assistant_id Character. **Required.** The assistant ID to execute
    #   (e.g. `"asst_abc123"`).
    #
    # @param model Character or NULL. Override the assistant's model for this
    #   run only. Default: NULL (uses assistant's model).
    #
    # @param instructions Character or NULL. Override the assistant's system
    #   instructions for this run only. Default: NULL.
    #
    # @param additional_instructions Character or NULL. Append extra instructions
    #   to the assistant's system prompt for this run only. Default: NULL.
    #
    # @param additional_messages List or NULL. Append extra messages to the thread
    #   before running (without persisting them). Default: NULL.
    #
    # @param tools List or NULL. Override the assistant's tools. Default: NULL.
    #
    # @param metadata Named list or NULL. Metadata for this run. Default: NULL.
    #
    # @param temperature Numeric in [0, 2] or NULL. Override temperature.
    #   Default: NULL.
    #
    # @param top_p Numeric in (0, 1] or NULL. Override nucleus sampling.
    #   Default: NULL.
    #
    # @param max_prompt_tokens Integer or NULL. Maximum tokens for the prompt.
    #   Default: NULL.
    #
    # @param max_completion_tokens Integer or NULL. Maximum tokens for completion.
    #   Default: NULL.
    #
    # @param truncation_strategy List or NULL. How to truncate thread when context
    #   is too long. Example: `list(type = "last_messages", last_messages = 10)`.
    #   Default: NULL.
    #
    # @param tool_choice Character or list or NULL. Which tool to use:
    #   `"auto"`, `"none"`, `"required"`, or a specific tool.
    #   Default: NULL.
    #
    # @param parallel_tool_calls Logical or NULL. Allow parallel tool calls.
    #   Default: NULL (API default TRUE).
    #
    # @param response_format List or NULL. Output format constraint.
    #   Default: NULL.
    #
    # @param stream Logical or NULL. If TRUE, streams run events via SSE.
    #   Default: NULL.
    #
    # @param callback Function or NULL. Called for each SSE chunk when streaming.
    #   Default: NULL.
    #
    # @return A run object:
    #   \describe{
    #     \item{`$id`}{Character. Run ID (e.g. `"run_abc123"`).}
    #     \item{`$thread_id`}{Character. The thread this run belongs to.}
    #     \item{`$assistant_id`}{Character. The assistant used.}
    #     \item{`$status`}{Character. Current status (see status lifecycle above).}
    #     \item{`$required_action`}{List or NULL. Set when `status = "requires_action"`.
    #       Contains tool calls the assistant wants to make.}
    #     \item{`$last_error`}{List or NULL. Error details if `status = "failed"`.}
    #   }
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    #
    # # Add a user message then run
    # client$threads$messages$create(
    #   thread_id = "thread_abc123",
    #   role      = "user",
    #   content   = "What is the best way to handle multicollinearity?"
    # )
    # run <- client$threads$runs$create(
    #   thread_id    = "thread_abc123",
    #   assistant_id = "asst_abc123"
    # )
    # cat("Run ID:", run$id, "Status:", run$status)
    #
    # # Poll until done
    # repeat {
    #   run <- client$threads$runs$retrieve("thread_abc123", run$id)
    #   if (run$status %in% c("completed", "failed", "cancelled")) break
    #   Sys.sleep(2)
    # }
    # # Read response
    # msgs <- client$threads$messages$list("thread_abc123")
    # cat(msgs$data[[1]]$content[[1]]$text$value)
    # }
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

    # @description
    # List runs on a thread, ordered by creation time.
    #
    # @param thread_id Character. **Required.** The thread ID.
    #
    # @param limit Integer or NULL. Max runs to return (1–100).
    #   Default: NULL (API default 20).
    #
    # @param order Character or NULL. `"asc"` or `"desc"`. Default: NULL.
    #
    # @param after Character or NULL. Pagination cursor. Default: NULL.
    #
    # @param before Character or NULL. Reverse pagination cursor. Default: NULL.
    #
    # @return A list with `$data` — a list of run objects.
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # runs <- client$threads$runs$list("thread_abc123")
    # for (r in runs$data) cat(r$id, "-", r$status, "\n")
    # }
    list = function(thread_id, limit = NULL, order = NULL, after = NULL, before = NULL) {
      query <- list()
      if (!is.null(limit)) query$limit <- limit
      if (!is.null(order)) query$order <- order
      if (!is.null(after)) query$after <- after
      if (!is.null(before)) query$before <- before

      self$client$request("GET", paste0("/threads/", thread_id, "/runs"), query = query)
    },

    # @description
    # Retrieve the current status of a specific run. Poll this until
    # `$status` is `"completed"`, `"failed"`, `"cancelled"`, or `"expired"`.
    #
    # @param thread_id Character. **Required.** The thread ID.
    # @param run_id Character. **Required.** The run ID.
    #
    # @return A run object (see `$create()` return value).
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # run <- client$threads$runs$retrieve("thread_abc123", "run_abc123")
    # cat("Status:", run$status)
    # }
    retrieve = function(thread_id, run_id) {
      self$client$request("GET", paste0("/threads/", thread_id, "/runs/", run_id))
    },

    # @description
    # Update a run's metadata.
    #
    # @param thread_id Character. **Required.** The thread ID.
    # @param run_id Character. **Required.** The run ID.
    # @param metadata Named list or NULL. New metadata to attach. Default: NULL.
    #
    # @return The updated run object.
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # client$threads$runs$update(
    #   "thread_abc123", "run_abc123",
    #   metadata = list(label = "experiment-1")
    # )
    # }
    update = function(thread_id, run_id, metadata = NULL) {
      body <- list()
      if (!is.null(metadata)) body$metadata <- metadata
      self$client$request("POST", paste0("/threads/", thread_id, "/runs/", run_id), body = body)
    },

    # @description
    # Cancel a run that is currently `"in_progress"` or `"queued"`.
    #
    # @param thread_id Character. **Required.** The thread ID.
    # @param run_id Character. **Required.** The run ID to cancel.
    #
    # @return The run object with `$status = "cancelling"`.
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # client$threads$runs$cancel("thread_abc123", "run_abc123")
    # }
    cancel = function(thread_id, run_id) {
      self$client$request("POST", paste0("/threads/", thread_id, "/runs/", run_id, "/cancel"))
    },

    # @description
    # Submit tool call outputs to resume a run that is in
    # `"requires_action"` status. The assistant paused to call tools;
    # you execute the tools in R and submit the results here.
    #
    # @param thread_id Character. **Required.** The thread ID.
    # @param run_id Character. **Required.** The run ID.
    #
    # @param tool_outputs List. **Required.** List of tool output objects.
    #   Each must have:
    #   \itemize{
    #     \item `tool_call_id` — The ID from `run$required_action$submit_tool_outputs$tool_calls[[i]]$id`
    #     \item `output` — Character string with the tool's return value
    #   }
    #   Example:
    #   \preformatted{
    #   list(
    #     list(tool_call_id = "call_abc123", output = "42.5")
    #   )
    #   }
    #
    # @param stream Logical or NULL. If TRUE, stream the resumed run.
    #   Default: NULL.
    #
    # @param callback Function or NULL. Streaming callback. Default: NULL.
    #
    # @return The resumed run object (status will change from `"requires_action"`
    #   back to `"in_progress"`).
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # # When run$status == "requires_action":
    # tool_calls <- run$required_action$submit_tool_outputs$tool_calls
    # results <- lapply(tool_calls, function(tc) {
    #   # Execute the tool in R, then return the result
    #   list(tool_call_id = tc$id, output = "result from R function")
    # })
    # client$threads$runs$submit_tool_outputs(
    #   thread_id    = "thread_abc123",
    #   run_id       = "run_abc123",
    #   tool_outputs = results
    # )
    # }
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
  )
)

#' Run Steps Client
#'
#' Lists and retrieves the individual steps taken during a run.
#' Each run may consist of multiple steps (e.g. thinking, tool calls,
#' message creation). Access via `client$threads$runs$steps`.
#'
#' @export
RunStepsClient <- R6::R6Class(
  "RunStepsClient",
  public = list(
    client = NULL,

    # Initialize run steps client
    #
    # @param parent Parent OpenAI client
    initialize = function(parent) {
      self$client <- parent
    },

    # @description
    # List all steps for a specific run. Steps describe what the
    # assistant did during the run (e.g. `"tool_calls"`, `"message_creation"`).
    #
    # @param thread_id Character. **Required.** The thread ID.
    # @param run_id Character. **Required.** The run ID.
    # @param limit Integer or NULL. Max steps to return. Default: NULL.
    # @param order Character or NULL. `"asc"` or `"desc"`. Default: NULL.
    # @param after Character or NULL. Pagination cursor. Default: NULL.
    # @param before Character or NULL. Reverse pagination cursor. Default: NULL.
    #
    # @return A list with `$data` — a list of run step objects. Each has:
    #   \describe{
    #     \item{`$id`}{Character. Step ID.}
    #     \item{`$type`}{Character. `"tool_calls"` or `"message_creation"`.}
    #     \item{`$status`}{Character. `"in_progress"`, `"completed"`, or `"failed"`.}
    #     \item{`$step_details`}{List. Details of what happened in this step.}
    #   }
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # steps <- client$threads$runs$steps$list("thread_abc123", "run_abc123")
    # for (s in steps$data) cat(s$type, "-", s$status, "\n")
    # }
    list = function(thread_id, run_id, limit = NULL, order = NULL, after = NULL, before = NULL) {
      query <- list()
      if (!is.null(limit)) query$limit <- limit
      if (!is.null(order)) query$order <- order
      if (!is.null(after)) query$after <- after
      if (!is.null(before)) query$before <- before

      self$client$request("GET", paste0("/threads/", thread_id, "/runs/", run_id, "/steps"), query = query)
    },

    # @description
    # Retrieve a specific run step by its ID.
    #
    # @param thread_id Character. **Required.** The thread ID.
    # @param run_id Character. **Required.** The run ID.
    # @param step_id Character. **Required.** The step ID.
    #
    # @return A run step object with `$type`, `$status`, and `$step_details`.
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # step <- client$threads$runs$steps$retrieve(
    #   "thread_abc123", "run_abc123", "step_abc123"
    # )
    # cat("Step type:", step$type)
    # }
    retrieve = function(thread_id, run_id, step_id) {
      self$client$request("GET", paste0("/threads/", thread_id, "/runs/", run_id, "/steps/", step_id))
    }
  )
)

#' Messages Client
#'
#' Manages messages within threads. Messages store the conversation history
#' between the user and the assistant.
#' Access via `client$threads$messages`.
#'
#' @export
MessagesClient <- R6::R6Class(
  "MessagesClient",
  public = list(
    client = NULL,

    # Initialize messages client
    #
    # @param parent Parent OpenAI client
    initialize = function(parent) {
      self$client <- parent
    },

    # @description
    # Add a new message to a thread. Call this before creating a run
    # to provide the user's next input.
    #
    # @param thread_id Character. **Required.** The thread ID.
    #
    # @param role Character. **Required.** The role of the message author.
    #   Must be `"user"` (or `"assistant"` for injecting assistant messages).
    #
    # @param content Character or list. **Required.** The message content.
    #   \itemize{
    #     \item Simple text: a character string.
    #       Example: `"What is Granger causality?"`
    #     \item Multimodal: a list of content parts (text + images).
    #       See [create_multimodal_message()] for helper functions.
    #   }
    #
    # @param attachments List or NULL. A list of file attachments, each
    #   specifying a `file_id` and `tools` (e.g., `list(list(type = "file_search"))`).
    #   Example:
    #   \preformatted{
    #   list(list(file_id = "file-abc123",
    #             tools = list(list(type = "file_search"))))
    #   }
    #   Default: NULL.
    #
    # @param metadata Named list or NULL. Up to 16 key-value pairs.
    #   Default: NULL.
    #
    # @return A message object:
    #   \describe{
    #     \item{`$id`}{Character. Message ID (e.g. `"msg_abc123"`).}
    #     \item{`$thread_id`}{Character. The thread this message belongs to.}
    #     \item{`$role`}{Character. `"user"` or `"assistant"`.}
    #     \item{`$content`}{List. Content parts. For text: `$content[[1]]$text$value`.}
    #     \item{`$created_at`}{Integer. Unix timestamp.}
    #   }
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    #
    # # Add a simple text message
    # msg <- client$threads$messages$create(
    #   thread_id = "thread_abc123",
    #   role      = "user",
    #   content   = "Can you explain what an instrumental variable is?"
    # )
    # cat("Message ID:", msg$id)
    #
    # # Add a message with a file attachment
    # msg <- client$threads$messages$create(
    #   thread_id   = "thread_abc123",
    #   role        = "user",
    #   content     = "Summarize the attached paper.",
    #   attachments = list(
    #     list(file_id = "file-abc123",
    #          tools   = list(list(type = "file_search")))
    #   )
    # )
    # }
    create = function(thread_id, role, content, attachments = NULL, metadata = NULL) {
      body <- list(
        role = role,
        content = content
      )

      if (!is.null(attachments)) body$attachments <- attachments
      if (!is.null(metadata)) body$metadata <- metadata

      self$client$request("POST", paste0("/threads/", thread_id, "/messages"), body = body)
    },

    # @description
    # List messages in a thread, ordered by creation time.
    # After a run completes, the assistant's reply will appear as the
    # first (newest) message when using `order = "desc"`.
    #
    # @param thread_id Character. **Required.** The thread ID.
    #
    # @param limit Integer or NULL. Max messages to return (1–100).
    #   Default: NULL (API default 20).
    #
    # @param order Character or NULL. `"asc"` (oldest first) or
    #   `"desc"` (newest first). Default: NULL (API default `"desc"`).
    #
    # @param after Character or NULL. Pagination cursor. Default: NULL.
    #
    # @param before Character or NULL. Reverse pagination cursor. Default: NULL.
    #
    # @param run_id Character or NULL. Filter to only show messages
    #   created during a specific run. Default: NULL.
    #
    # @return A list with `$data` — a list of message objects. Access
    #   the assistant's reply text via:
    #   `msgs$data[[1]]$content[[1]]$text$value`
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    #
    # # Read all messages (newest first)
    # msgs <- client$threads$messages$list("thread_abc123")
    #
    # # The assistant's latest reply is msgs$data[[1]]
    # reply <- msgs$data[[1]]$content[[1]]$text$value
    # cat("Assistant:", reply, "\n")
    #
    # # Print full conversation
    # for (m in rev(msgs$data)) {
    #   cat(m$role, ":", m$content[[1]]$text$value, "\n\n")
    # }
    # }
    list = function(thread_id, limit = NULL, order = NULL, after = NULL, before = NULL, run_id = NULL) {
      query <- list()
      if (!is.null(limit)) query$limit <- limit
      if (!is.null(order)) query$order <- order
      if (!is.null(after)) query$after <- after
      if (!is.null(before)) query$before <- before
      if (!is.null(run_id)) query$run_id <- run_id

      self$client$request("GET", paste0("/threads/", thread_id, "/messages"), query = query)
    },

    # @description
    # Retrieve a specific message by its ID.
    #
    # @param thread_id Character. **Required.** The thread ID.
    # @param message_id Character. **Required.** The message ID.
    #
    # @return A message object (see `$create()` return value).
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # msg <- client$threads$messages$retrieve("thread_abc123", "msg_abc123")
    # cat(msg$content[[1]]$text$value)
    # }
    retrieve = function(thread_id, message_id) {
      self$client$request("GET", paste0("/threads/", thread_id, "/messages/", message_id))
    },

    # @description
    # Update a message's metadata.
    #
    # @param thread_id Character. **Required.** The thread ID.
    # @param message_id Character. **Required.** The message ID.
    # @param metadata Named list or NULL. New metadata. Default: NULL.
    #
    # @return The updated message object.
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # client$threads$messages$update(
    #   "thread_abc123", "msg_abc123",
    #   metadata = list(reviewed = "true")
    # )
    # }
    update = function(thread_id, message_id, metadata = NULL) {
      body <- list()
      if (!is.null(metadata)) body$metadata <- metadata
      self$client$request("POST", paste0("/threads/", thread_id, "/messages/", message_id), body = body)
    },

    # @description
    # Delete a message from a thread.
    #
    # @param thread_id Character. **Required.** The thread ID.
    # @param message_id Character. **Required.** The message ID to delete.
    #
    # @return A list with `$deleted` (`TRUE`) and `$id`.
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # result <- client$threads$messages$delete("thread_abc123", "msg_abc123")
    # cat("Deleted:", result$deleted)
    # }
    delete = function(thread_id, message_id) {
      self$client$request("DELETE", paste0("/threads/", thread_id, "/messages/", message_id))
    }
  )
)

# ---------------------------------------------------------------------------
# Convenience functions for threads
# ---------------------------------------------------------------------------

#' Create a Thread (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and creates a new thread.
#'
#' @param ... Parameters passed to [ThreadsClient]`$create()`:
#'   `messages` (list of initial messages), `tool_resources`, `metadata`.
#'
#' @return A thread object with `$id` (save this for subsequent calls).
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#'
#' thread <- create_thread()
#' cat("Thread ID:", thread$id)
#'
#' # With an initial message
#' thread <- create_thread(
#'   messages = list(list(role = "user", content = "Hello!"))
#' )
#' }
create_thread <- function(...) {
  client <- OpenAI$new()
  client$threads$create(...)
}

#' Retrieve a Thread (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and retrieves a thread.
#'
#' @param thread_id Character. **Required.** The thread ID to retrieve.
#'
#' @return A thread object with `$id`, `$created_at`, and `$metadata`.
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#' thread <- retrieve_thread("thread_abc123")
#' cat("Created at:", thread$created_at)
#' }
retrieve_thread <- function(thread_id) {
  client <- OpenAI$new()
  client$threads$retrieve(thread_id)
}

#' Update a Thread (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and updates a thread's metadata.
#'
#' @param thread_id Character. **Required.** The thread ID.
#' @param ... Named fields to update, e.g. `metadata = list(label = "session-2")`.
#'
#' @return The updated thread object.
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#' update_thread("thread_abc123", metadata = list(topic = "GMM lecture"))
#' }
update_thread <- function(thread_id, ...) {
  client <- OpenAI$new()
  client$threads$update(thread_id, ...)
}

#' Delete a Thread (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and permanently deletes a thread.
#'
#' @param thread_id Character. **Required.** The thread ID to delete.
#'
#' @return A list with `$deleted` (`TRUE`) and `$id`.
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#' result <- delete_thread("thread_abc123")
#' if (result$deleted) cat("Thread deleted.")
#' }
delete_thread <- function(thread_id) {
  client <- OpenAI$new()
  client$threads$delete(thread_id)
}

# ---------------------------------------------------------------------------
# Convenience functions for runs
# ---------------------------------------------------------------------------

#' Create a Run (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and creates a run on a thread.
#' Poll the run with [retrieve_run()] until status is `"completed"`.
#'
#' @param thread_id Character. **Required.** The thread ID.
#' @param assistant_id Character. **Required.** The assistant ID to run.
#' @param ... Additional parameters passed to [RunsClient]`$create()`,
#'   such as `instructions`, `model`, `tools`, `stream`, `callback`.
#'
#' @return A run object with `$id` and `$status`.
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#'
#' run <- create_run(
#'   thread_id    = "thread_abc123",
#'   assistant_id = "asst_abc123"
#' )
#' cat("Run ID:", run$id, "Status:", run$status)
#'
#' # Poll until done
#' repeat {
#'   run <- retrieve_run("thread_abc123", run$id)
#'   if (run$status %in% c("completed", "failed", "cancelled")) break
#'   Sys.sleep(2)
#' }
#' }
create_run <- function(thread_id, assistant_id, ...) {
  client <- OpenAI$new()
  client$threads$runs$create(thread_id = thread_id, assistant_id = assistant_id, ...)
}

#' Retrieve a Run (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and retrieves a run's current status.
#'
#' @param thread_id Character. **Required.** The thread ID.
#' @param run_id Character. **Required.** The run ID.
#'
#' @return A run object with `$status` (`"queued"`, `"in_progress"`,
#'   `"completed"`, `"requires_action"`, `"failed"`, etc.).
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#' run <- retrieve_run("thread_abc123", "run_abc123")
#' cat("Status:", run$status)
#' }
retrieve_run <- function(thread_id, run_id) {
  client <- OpenAI$new()
  client$threads$runs$retrieve(thread_id, run_id)
}

#' Cancel a Run (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and cancels a running or queued run.
#'
#' @param thread_id Character. **Required.** The thread ID.
#' @param run_id Character. **Required.** The run ID to cancel.
#'
#' @return A run object with `$status = "cancelling"`.
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#' cancel_run("thread_abc123", "run_abc123")
#' }
cancel_run <- function(thread_id, run_id) {
  client <- OpenAI$new()
  client$threads$runs$cancel(thread_id, run_id)
}

# ---------------------------------------------------------------------------
# Convenience functions for messages
# ---------------------------------------------------------------------------

#' Add a Message to a Thread (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and adds a message to a thread.
#'
#' @param thread_id Character. **Required.** The thread ID.
#' @param role Character. **Required.** `"user"` or `"assistant"`.
#' @param content Character or list. **Required.** The message text, or a
#'   list of content parts for multimodal messages.
#' @param ... Additional parameters passed to [MessagesClient]`$create()`,
#'   such as `attachments` and `metadata`.
#'
#' @return A message object with `$id` and `$content`.
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#'
#' msg <- create_message(
#'   thread_id = "thread_abc123",
#'   role      = "user",
#'   content   = "What is the difference between FE and RE estimators?"
#' )
#' cat("Message ID:", msg$id)
#' }
create_message <- function(thread_id, role, content, ...) {
  client <- OpenAI$new()
  client$threads$messages$create(thread_id = thread_id, role = role, content = content, ...)
}

#' List Messages in a Thread (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and lists messages in a thread.
#' After a run completes, the assistant's reply appears in this list.
#'
#' @param thread_id Character. **Required.** The thread ID.
#' @param ... Additional parameters passed to [MessagesClient]`$list()`,
#'   such as `limit`, `order` (`"asc"`/`"desc"`), `after`, `run_id`.
#'
#' @return A list with `$data` — a list of message objects, newest first
#'   (by default). Access reply text via:
#'   `msgs$data[[1]]$content[[1]]$text$value`.
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#'
#' # Read latest messages (newest first)
#' msgs <- list_messages("thread_abc123")
#' cat("Assistant reply:", msgs$data[[1]]$content[[1]]$text$value)
#'
#' # Print full conversation chronologically
#' msgs <- list_messages("thread_abc123", order = "asc")
#' for (m in msgs$data) {
#'   cat(toupper(m$role), ":", m$content[[1]]$text$value, "\n\n")
#' }
#' }
list_messages <- function(thread_id, ...) {
  client <- OpenAI$new()
  client$threads$messages$list(thread_id, ...)
}
