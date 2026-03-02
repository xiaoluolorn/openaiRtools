#' Chat Completions Client
#'
#' Client for OpenAI Chat Completions API. Access via `client$chat`.
#'
#' @export
ChatClient <- R6::R6Class(
  "ChatClient",
  public = list(
    client = NULL,

    # Field: completions Chat completions interface (ChatCompletionsClient)
    completions = NULL,

    # @description Initialize chat client
    # @param parent Parent OpenAI client object
    initialize = function(parent) {
      self$client <- parent
      self$completions <- ChatCompletionsClient$new(parent)
    }
  )
)

#' Chat Completions Interface
#'
#' Provides methods to create, manage and retrieve chat completions.
#' Access via `client$chat$completions`.
#'
#' @export
ChatCompletionsClient <- R6::R6Class(
  "ChatCompletionsClient",
  public = list(
    client = NULL,

    # Field: messages Sub-client for listing messages from stored completions
    messages = NULL,

    # @description Initialize completions client
    # @param parent Parent OpenAI client object
    initialize = function(parent) {
      self$client <- parent
      self$messages <- ChatCompletionsMessagesClient$new(parent)
    },

    # @description
    # Create a chat completion. This is the core method for generating text
    # using GPT models. Supports single-turn and multi-turn conversations,
    # streaming, function calling, and multimodal (vision) input.
    #
    # @param messages \strong{[Required]} A list of message objects. Each message must be a
    #   named list with at minimum role and content:
    #   \itemize{
    #     \item role: One of "system", "user", "assistant",
    #           "tool"
    #     \item content: A string, or for multimodal models a list of content parts
    #           (see \link{create_multimodal_message})
    #   }
    #   Example: list(list(role="user", content="Hello"))
    #
    # @param model \strong{[Required]} Model ID string. Common values:
    #   \itemize{
    #     \item "gpt-4o" — Latest flagship model, best quality
    #     \item "gpt-4o-mini" — Cheaper, fast
    #     \item "gpt-4" — Previous generation flagship
    #     \item "gpt-3.5-turbo" — Fast and economical
    #   }
    #   Default: "gpt-3.5-turbo"
    #
    # @param temperature Numeric in [0, 2]. Controls randomness of output.
    #   \itemize{
    #     \item 0: Nearly deterministic, best for factual tasks
    #     \item 0.7: Balanced (recommended default)
    #     \item 1.5+: Highly creative/random
    #   }
    #   Do not set both temperature and top_p. Default: NULL (API default 1).
    #
    # @param top_p Numeric in (0, 1]. Nucleus sampling threshold.
    #   Only tokens whose cumulative probability mass reaches top_p are considered.
    #   E.g. 0.1 = only top 10\% probability tokens. Alternative to temperature.
    #   Default: NULL.
    #
    # @param max_tokens Integer. Maximum number of tokens to generate (legacy parameter).
    #   Counts output tokens only. For reasoning models use max_completion_tokens.
    #   Default: NULL (model maximum).
    #
    # @param max_completion_tokens Integer. Maximum number of tokens to generate,
    #   including reasoning tokens for o-series models. Preferred over max_tokens.
    #   Default: NULL.
    #
    # @param n Integer. Number of independent completions to generate per request.
    #   All n choices are returned in response$choices. Higher values
    #   increase cost proportionally. Default: NULL (API default 1).
    #
    # @param stream Logical. If TRUE, enables Server-Sent Events (SSE) streaming.
    #   \itemize{
    #     \item With callback: calls callback(chunk) for each delta chunk
    #           as it arrives. Returns invisible(NULL).
    #     \item Without callback: assembles all chunks automatically and returns
    #           a standard response object (same structure as non-streaming).
    #   }
    #   Default: NULL (no streaming).
    #
    # @param callback Function with signature function(chunk) called for each
    #   SSE chunk when stream=TRUE. Access delta text via
    #   chunk$choices[[1]]$delta$content. Default: NULL.
    #
    # @param stop Character string or list of strings. The API stops generating when
    #   any of these sequences are encountered. Maximum 4 stop sequences.
    #   Default: NULL.
    #
    # @param frequency_penalty Numeric in [-2, 2]. Positive values penalize
    #   tokens that have already appeared frequently in the output, reducing repetition.
    #   Default: NULL (API default 0).
    #
    # @param presence_penalty Numeric in [-2, 2]. Positive values penalize
    #   tokens that have appeared at all in the output so far, encouraging new topics.
    #   Default: NULL (API default 0).
    #
    # @param logit_bias Named list mapping token IDs (as character strings) to bias
    #   values in [-100, 100]. Use -100 to ban a token completely.
    #   Example: list("50256" = -100). Default: NULL.
    #
    # @param logprobs Logical. If TRUE, include log probabilities of output tokens.
    #   Default: NULL.
    #
    # @param top_logprobs Integer in [0, 20]. Number of most likely tokens to
    #   return at each position (requires logprobs=TRUE). Default: NULL.
    #
    # @param response_format List specifying output format. Use
    #   list(type="json_object") to guarantee valid JSON output (the prompt
    #   must also instruct the model to produce JSON). Default: NULL.
    #
    # @param seed Integer. If set, the API will attempt deterministic sampling. Responses
    #   are not guaranteed to be identical but will be more consistent. Default: NULL.
    #
    # @param tools List of tool definitions for function calling. Each tool is a named
    #   list with type="function" and a function field containing
    #   name, description, and parameters (JSON Schema).
    #   Default: NULL.
    #
    # @param tool_choice Controls which tool (if any) is called. Options:
    #   \itemize{
    #     \item "none": Model generates a message, no tool called
    #     \item "auto": Model decides whether to call a tool (default when tools present)
    #     \item "required": Model must call at least one tool
    #     \item Named list: Force a specific function, e.g.
    #           list(type="function", function=list(name="my_func"))
    #   }
    #   Default: NULL.
    #
    # @param parallel_tool_calls Logical. Whether to allow the model to call multiple
    #   tools in parallel. Default: NULL (API default TRUE).
    #
    # @param user Character string. A unique identifier for the end user, used by
    #   OpenAI for abuse detection. Default: NULL.
    #
    # @param store Logical. If TRUE, the completion is stored server-side and
    #   can be retrieved later via $retrieve(), $list().
    #   Default: NULL.
    #
    # @param metadata Named list. Arbitrary key-value metadata attached to stored
    #   completions (requires store=TRUE). Default: NULL.
    #
    # @param stream_options List of options for streaming. E.g.
    #   list(include_usage=TRUE) to receive token usage in the final chunk.
    #   Default: NULL.
    #
    # @param ... Additional parameters passed directly to the API body.
    #
    # @return A named list representing the chat completion object:
    #   \describe{
    #     \item{$id}{Character. Unique completion ID, e.g. "chatcmpl-abc123".}
    #     \item{$object}{Always "chat.completion".}
    #     \item{$created}{Integer. Unix timestamp of creation.}
    #     \item{$model}{Character. Model actually used.}
    #     \item{$choices}{List of choice objects. Usually length 1 (unless n > 1).
    #       \describe{
    #         \item{$choices[[1]]$message$role}{Always "assistant".}
    #         \item{$choices[[1]]$message$content}{Character. The generated text. \strong{This is the main output.}}
    #         \item{$choices[[1]]$message$tool_calls}{List. Tool calls made by the model (if any).}
    #         \item{$choices[[1]]$finish_reason}{Why generation stopped: "stop" (natural end),
    #           "length" (hit max_tokens), "tool_calls" (function calling),
    #           "content_filter".}
    #       }
    #     }
    #     \item{$usage}{Token usage counts:
    #       \describe{
    #         \item{$usage$prompt_tokens}{Input tokens consumed.}
    #         \item{$usage$completion_tokens}{Output tokens generated.}
    #         \item{$usage$total_tokens}{Sum of above.}
    #       }
    #     }
    #   }
    #   When stream=TRUE with no callback, also includes $.stream_iterator
    #   (a StreamIterator object) for advanced chunk access.
    #
    # @examples
    # \dontrun{
    # library(openaiRtools)
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    #
    # # --- Basic single-turn chat ---
    # response <- client$chat$completions$create(
    #   messages = list(list(role = "user", content = "What is R?")),
    #   model    = "gpt-4o"
    # )
    # cat(response$choices[[1]]$message$content)
    #
    # # --- Multi-turn conversation with system prompt ---
    # response <- client$chat$completions$create(
    #   messages = list(
    #     list(role = "system",    content = "You are an econometrics expert."),
    #     list(role = "user",      content = "Explain OLS assumptions briefly."),
    #     list(role = "assistant", content = "OLS requires linearity, exogeneity..."),
    #     list(role = "user",      content = "Give an R code example.")
    #   ),
    #   model       = "gpt-4o",
    #   temperature = 0.3,
    #   max_tokens  = 500
    # )
    # cat(response$choices[[1]]$message$content)
    #
    # # --- Streaming with real-time output ---
    # client$chat$completions$create(
    #   messages = list(list(role = "user", content = "Write a haiku")),
    #   model    = "gpt-4o",
    #   stream   = TRUE,
    #   callback = function(chunk) {
    #     delta <- chunk$choices[[1]]$delta$content
    #     if (!is.null(delta)) cat(delta, sep = "")
    #   }
    # )
    #
    # # --- Streaming without callback (auto-assembled) ---
    # response <- client$chat$completions$create(
    #   messages = list(list(role = "user", content = "Tell me a story")),
    #   model    = "gpt-4o",
    #   stream   = TRUE
    # )
    # cat(response$choices[[1]]$message$content)
    #
    # # --- Force JSON output ---
    # response <- client$chat$completions$create(
    #   messages = list(
    #     list(role = "user",
    #          content = "List 3 ML algorithms in JSON with fields: name, use_case")
    #   ),
    #   model           = "gpt-4o",
    #   response_format = list(type = "json_object")
    # )
    # result <- jsonlite::fromJSON(response$choices[[1]]$message$content)
    #
    # # --- Generate N candidates ---
    # response <- client$chat$completions$create(
    #   messages    = list(list(role = "user", content = "Suggest an article title on AI")),
    #   model       = "gpt-4o",
    #   n           = 3,
    #   temperature = 1.2
    # )
    # for (i in seq_along(response$choices)) {
    #   cat(i, ":", response$choices[[i]]$message$content, "\n")
    # }
    # }
    create = function(messages, model = "gpt-3.5-turbo",
                      frequency_penalty = NULL,
                      logit_bias = NULL,
                      logprobs = NULL,
                      top_logprobs = NULL,
                      max_tokens = NULL,
                      max_completion_tokens = NULL,
                      n = NULL,
                      presence_penalty = NULL,
                      response_format = NULL,
                      seed = NULL,
                      stop = NULL,
                      stream = NULL,
                      stream_options = NULL,
                      temperature = NULL,
                      top_p = NULL,
                      tools = NULL,
                      tool_choice = NULL,
                      parallel_tool_calls = NULL,
                      user = NULL,
                      store = NULL,
                      metadata = NULL,
                      callback = NULL,
                      ...) {
      body <- list(
        messages = messages,
        model = model
      )

      # Add optional parameters
      if (!is.null(frequency_penalty)) body$frequency_penalty <- frequency_penalty
      if (!is.null(logit_bias)) body$logit_bias <- logit_bias
      if (!is.null(logprobs)) body$logprobs <- logprobs
      if (!is.null(top_logprobs)) body$top_logprobs <- top_logprobs
      if (!is.null(max_tokens)) body$max_tokens <- max_tokens
      if (!is.null(max_completion_tokens)) body$max_completion_tokens <- max_completion_tokens
      if (!is.null(n)) body$n <- n
      if (!is.null(presence_penalty)) body$presence_penalty <- presence_penalty
      if (!is.null(response_format)) body$response_format <- response_format
      if (!is.null(seed)) body$seed <- seed
      if (!is.null(stop)) body$stop <- stop
      if (!is.null(stream)) body$stream <- stream
      if (!is.null(stream_options)) body$stream_options <- stream_options
      if (!is.null(temperature)) body$temperature <- temperature
      if (!is.null(top_p)) body$top_p <- top_p
      if (!is.null(tools)) body$tools <- tools
      if (!is.null(tool_choice)) body$tool_choice <- tool_choice
      if (!is.null(parallel_tool_calls)) body$parallel_tool_calls <- parallel_tool_calls
      if (!is.null(user)) body$user <- user
      if (!is.null(store)) body$store <- store
      if (!is.null(metadata)) body$metadata <- metadata

      # Add any additional parameters from ...
      dots <- list(...)
      if (length(dots) > 0) {
        body <- c(body, dots)
      }

      # For streaming, pass callback to request method
      is_streaming <- !is.null(stream) && stream

      result <- self$client$request(
        "POST",
        "/chat/completions",
        body = body,
        stream = is_streaming,
        callback = if (is_streaming) callback else NULL
      )

      # If streaming without callback, assemble chunks into standard response format
      if (is_streaming && is.null(callback) && inherits(result, "StreamIterator")) {
        # Collect full content from all delta chunks
        full_content <- result$get_full_text()

        # Collect tool_calls if any
        tool_calls_map <- list()
        # Collect role from the first chunk that has it
        role <- "assistant"
        # Collect model, id, etc. from the first chunk
        first_chunk <- if (length(result$chunks) > 0) result$chunks[[1]] else list()

        for (chunk in result$chunks) {
          if (!is.null(chunk$choices) && length(chunk$choices) > 0) {
            delta <- chunk$choices[[1]]$delta
            if (!is.null(delta$role)) {
              role <- delta$role
            }
            # Collect tool call deltas
            if (!is.null(delta$tool_calls)) {
              for (tc in delta$tool_calls) {
                idx <- as.character(tc$index %||% 0)
                if (is.null(tool_calls_map[[idx]])) {
                  tool_calls_map[[idx]] <- list(
                    id = tc$id %||% "",
                    type = tc$type %||% "function",
                    `function` = list(name = "", arguments = "")
                  )
                }
                if (!is.null(tc$id) && tc$id != "") {
                  tool_calls_map[[idx]]$id <- tc$id
                }
                if (!is.null(tc$type) && tc$type != "") {
                  tool_calls_map[[idx]]$type <- tc$type
                }
                if (!is.null(tc$`function`$name)) {
                  tool_calls_map[[idx]]$`function`$name <- paste0(
                    tool_calls_map[[idx]]$`function`$name, tc$`function`$name
                  )
                }
                if (!is.null(tc$`function`$arguments)) {
                  tool_calls_map[[idx]]$`function`$arguments <- paste0(
                    tool_calls_map[[idx]]$`function`$arguments, tc$`function`$arguments
                  )
                }
              }
            }
          }
        }

        # Build the assembled message
        message <- list(role = role, content = full_content)
        if (length(tool_calls_map) > 0) {
          message$tool_calls <- unname(tool_calls_map)
        }

        # Get finish_reason from the last chunk that has it
        finish_reason <- NULL
        for (chunk in rev(result$chunks)) {
          if (!is.null(chunk$choices) && length(chunk$choices) > 0 &&
            !is.null(chunk$choices[[1]]$finish_reason)) {
            finish_reason <- chunk$choices[[1]]$finish_reason
            break
          }
        }

        # Build standard chat completion response
        assembled <- list(
          id = first_chunk$id %||% NULL,
          object = "chat.completion",
          created = first_chunk$created %||% NULL,
          model = first_chunk$model %||% model,
          choices = list(
            list(
              index = 0,
              message = message,
              finish_reason = finish_reason
            )
          ),
          usage = NULL
        )

        # Attach the original stream iterator for advanced users
        assembled$.stream_iterator <- result

        return(assembled)
      }

      # Return result
      result
    },

    # @description Retrieve a stored chat completion by ID.
    # @param completion_id Character. The completion ID (e.g. from response$id)
    #   of a previously created completion with store=TRUE.
    # @return A chat completion list object.
    # @examples
    # \dontrun{
    # stored <- client$chat$completions$retrieve("chatcmpl-abc123")
    # cat(stored$choices[[1]]$message$content)
    # }
    retrieve = function(completion_id) {
      self$client$request("GET", paste0("/chat/completions/", completion_id))
    },

    # @description Update the metadata of a stored chat completion.
    # @param completion_id Character. Completion ID to update.
    # @param metadata Named list. New metadata key-value pairs to attach.
    # @return Updated chat completion object.
    # @examples
    # \dontrun{
    # client$chat$completions$update(
    #   "chatcmpl-abc123",
    #   metadata = list(project = "research", version = "v2")
    # )
    # }
    update = function(completion_id, metadata = NULL) {
      body <- list()
      if (!is.null(metadata)) body$metadata <- metadata
      self$client$request("POST", paste0("/chat/completions/", completion_id), body = body)
    },

    # @description List stored chat completions with optional filters.
    # @param model Character. Filter results to a specific model ID. Default: NULL.
    # @param after Character. Pagination cursor — the ID of the last item from the
    #   previous page. Default: NULL.
    # @param limit Integer. Number of completions to return per page (1-100).
    #   Default: NULL (API default 20).
    # @param order Character. Sort order: "asc" or "desc" by creation time.
    #   Default: NULL.
    # @param metadata List. Filter by metadata key-value pairs. Default: NULL.
    # @return A list with $data (list of completion objects) and
    #   $has_more (logical).
    # @examples
    # \dontrun{
    # page <- client$chat$completions$list(model = "gpt-4o", limit = 10)
    # for (c in page$data) cat(c$id, "\n")
    # }
    list = function(model = NULL, after = NULL, limit = NULL, order = NULL, metadata = NULL) {
      query <- list()
      if (!is.null(model)) query$model <- model
      if (!is.null(after)) query$after <- after
      if (!is.null(limit)) query$limit <- limit
      if (!is.null(order)) query$order <- order
      if (!is.null(metadata)) query$metadata <- metadata

      self$client$request("GET", "/chat/completions", query = query)
    },

    # @description Delete a stored chat completion.
    # @param completion_id Character. Completion ID to delete.
    # @return A deletion status list with $deleted (logical).
    # @examples
    # \dontrun{
    # client$chat$completions$delete("chatcmpl-abc123")
    # }
    delete = function(completion_id) {
      self$client$request("DELETE", paste0("/chat/completions/", completion_id))
    }
  )
)

#' Chat Completions Messages Client
#'
#' Lists messages from stored chat completions.
#' Access via `client$chat$completions$messages`.
#'
#' @export
ChatCompletionsMessagesClient <- R6::R6Class(
  "ChatCompletionsMessagesClient",
  public = list(
    client = NULL,

    # @description Initialize messages client
    # @param parent Parent OpenAI client object
    initialize = function(parent) {
      self$client <- parent
    },

    # @description List messages from a stored chat completion.
    # @param completion_id Character. ID of the stored chat completion.
    # @param after Character. Pagination cursor. Default: NULL.
    # @param limit Integer. Number of messages to return. Default: NULL.
    # @param order Character. "asc" or "desc". Default: NULL.
    # @return A list with $data containing message objects.
    # @examples
    # \dontrun{
    # msgs <- client$chat$completions$messages$list("chatcmpl-abc123")
    # }
    list = function(completion_id, after = NULL, limit = NULL, order = NULL) {
      query <- list()
      if (!is.null(after)) query$after <- after
      if (!is.null(limit)) query$limit <- limit
      if (!is.null(order)) query$order <- order

      self$client$request("GET", paste0("/chat/completions/", completion_id, "/messages"), query = query)
    }
  )
)

#' Create a Chat Completion (Convenience Function)
#'
#' A shortcut that automatically creates an [OpenAI] client from the
#' `OPENAI_API_KEY` environment variable and calls
#' `client$chat$completions$create()`.
#'
#' @param messages **Required.** List of message objects. Each must have
#'   `role` (`"system"`, `"user"`, `"assistant"`) and
#'   `content` fields.
#' @param model Character. Model ID. Default: `"gpt-3.5-turbo"`.
#' @param ... Additional parameters passed to
#'   [ChatCompletionsClient]`$create()`, such as
#'   `temperature`, `max_tokens`, `stream`, etc.
#'
#' @return A chat completion list object. Key fields:
#'   \itemize{
#'     \item `$choices[[1]]$message$content` — The generated text
#'     \item `$usage$total_tokens` — Total tokens consumed
#'   }
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#'
#' response <- create_chat_completion(
#'   messages = list(list(role = "user", content = "What is machine learning?")),
#'   model    = "gpt-4o"
#' )
#' cat(response$choices[[1]]$message$content)
#'
#' # With extra parameters
#' response <- create_chat_completion(
#'   messages    = list(list(role = "user", content = "Write a poem")),
#'   model       = "gpt-4o",
#'   temperature = 1.2,
#'   max_tokens  = 200
#' )
#' }
create_chat_completion <- function(messages, model = "gpt-3.5-turbo", ...) {
  client <- OpenAI$new()
  client$chat$completions$create(messages = messages, model = model, ...)
}
