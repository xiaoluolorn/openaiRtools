#' Responses Client
#'
#' Client for the OpenAI Responses API — a new, unified API for generating
#' text responses, managing multi-turn conversations, and using built-in tools.
#' Access via `client$responses`.
#'
#' @description
#' The Responses API is OpenAI's next-generation API that simplifies
#' multi-turn conversations (via `previous_response_id`), supports web search,
#' file search, and computer use as built-in tools, and provides a cleaner
#' interface than Chat Completions for complex agentic applications.
#'
#' @export
ResponsesClient <- R6::R6Class(
  "ResponsesClient",
  public = list(
    client = NULL,

    # Initialize responses client
    #
    # @param parent Parent OpenAI client
    initialize = function(parent) {
      self$client <- parent
    },

    # @description
    # Create a model response. Supports text, multi-turn conversation,
    # tool use, and streaming.
    #
    # @param model Character. **Required.** The model to use:
    #   \itemize{
    #     \item `"gpt-4o"` — Multimodal flagship
    #     \item `"gpt-4o-mini"` — Fast, affordable
    #     \item `"o1"`, `"o3-mini"` — Reasoning models
    #   }
    #
    # @param input **Required.** The input to the model. Can be:
    #   \itemize{
    #     \item A character string — Simple text prompt.
    #       Example: `"What is the GDP of China?"`
    #     \item A list of message objects — Multi-turn format, each with
    #       `role` (`"user"`, `"assistant"`, `"system"`) and `content`.
    #     \item (For follow-ups) — Set `previous_response_id` instead of
    #       repeating conversation history.
    #   }
    #
    # @param instructions Character or NULL. A system-level instruction that
    #   shapes the model's overall behavior throughout the conversation.
    #   Equivalent to a system message in Chat Completions.
    #   Example: `"Answer only in English. Be concise."`. Default: NULL.
    #
    # @param previous_response_id Character or NULL. The ID of a previous
    #   response to continue a multi-turn conversation without re-sending
    #   the full history. Use `$retrieve()` to get past response IDs.
    #   Default: NULL (starts a new conversation).
    #
    # @param tools List or NULL. A list of built-in or custom tools:
    #   \itemize{
    #     \item `list(list(type = "web_search_preview"))` — Web search
    #     \item `list(list(type = "file_search", vector_store_ids = list("vs-abc")))` — File search
    #     \item Function tools with `type = "function"` and a `function` spec
    #   }
    #   Default: NULL.
    #
    # @param tool_choice Character or list or NULL. Controls tool usage:
    #   `"auto"` (model decides), `"none"`, `"required"`, or a specific
    #   function: `list(type = "function", name = "my_func")`.
    #   Default: NULL.
    #
    # @param parallel_tool_calls Logical or NULL. Whether to allow the model
    #   to invoke multiple tools simultaneously. Default: NULL (API default TRUE).
    #
    # @param max_output_tokens Integer or NULL. Maximum output tokens allowed
    #   (preferred parameter for this API). Default: NULL.
    #
    # @param max_completion_tokens Integer or NULL. Legacy alias for
    #   `max_output_tokens`. Default: NULL.
    #
    # @param temperature Numeric in [0, 2] or NULL. Sampling temperature.
    #   Default: NULL (API default 1).
    #
    # @param top_p Numeric in (0, 1] or NULL. Nucleus sampling. Default: NULL.
    #
    # @param truncation Character or NULL. Truncation strategy when input
    #   exceeds context limit: `"auto"` or `"disabled"`. Default: NULL.
    #
    # @param metadata Named list or NULL. Key-value metadata attached to the
    #   response for tracking purposes. Default: NULL.
    #
    # @param reasoning List or NULL. Reasoning configuration for o-series
    #   models. Example: `list(effort = "high")`. Default: NULL.
    #
    # @param service_tier Character or NULL. Processing tier:
    #   `"auto"`, `"default"`, `"flex"`, `"scale"`. Default: NULL.
    #
    # @param prompt_cache_key Character or NULL. Cache key for prompt caching.
    #   Default: NULL.
    #
    # @param prompt_cache_retention Character or NULL. Cache retention policy.
    #   Default: NULL.
    #
    # @param include List or NULL. Additional data to include in output.
    #   Default: NULL.
    #
    # @param store Logical or NULL. If TRUE, stores the response server-side
    #   so it can be retrieved later. Default: NULL.
    #
    # @param stream Logical or NULL. If TRUE, enables streaming via
    #   Server-Sent Events. Use `callback` to handle chunks in real time.
    #   Default: NULL.
    #
    # @param callback Function or NULL. Called for each SSE chunk when
    #   `stream = TRUE`. Signature: `function(chunk)`. Default: NULL.
    #
    # @return A response object:
    #   \describe{
    #     \item{`$id`}{Character. Response ID (use in `previous_response_id`
    #       for follow-up turns).}
    #     \item{`$output`}{List. Output items from the model. Text output:
    #       `$output[[1]]$content[[1]]$text`.}
    #     \item{`$usage`}{List with `$input_tokens`, `$output_tokens`,
    #       `$total_tokens`.}
    #     \item{`$model`}{Character. Model used.}
    #   }
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    #
    # # Simple single-turn response
    # resp <- client$responses$create(
    #   model = "gpt-4o",
    #   input = "Explain instrumental variables in two sentences."
    # )
    # cat(resp$output[[1]]$content[[1]]$text)
    #
    # # Multi-turn: use previous_response_id instead of message history
    # resp1 <- client$responses$create(
    #   model        = "gpt-4o",
    #   input        = "What is heteroskedasticity?",
    #   instructions = "You are an econometrics professor."
    # )
    # resp2 <- client$responses$create(
    #   model                = "gpt-4o",
    #   input                = "How do I test for it in R?",
    #   previous_response_id = resp1$id   # no need to repeat history
    # )
    # cat(resp2$output[[1]]$content[[1]]$text)
    #
    # # With web search tool
    # resp <- client$responses$create(
    #   model = "gpt-4o",
    #   input = "What is today's USD/CNY exchange rate?",
    #   tools = list(list(type = "web_search_preview"))
    # )
    # cat(resp$output[[1]]$content[[1]]$text)
    # }
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

    # @description
    # Retrieve a stored response by its ID.
    # Only responses created with `store = TRUE` can be retrieved.
    #
    # @param response_id Character. **Required.** The response ID
    #   (e.g. `"resp_abc123"`).
    #
    # @return A response object (same structure as returned by `$create()`).
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # resp <- client$responses$retrieve("resp_abc123")
    # cat(resp$output[[1]]$content[[1]]$text)
    # }
    retrieve = function(response_id) {
      self$client$request("GET", paste0("/responses/", response_id))
    },

    # @description
    # Delete a stored response.
    #
    # @param response_id Character. **Required.** The response ID to delete.
    #
    # @return A list with `$deleted` (`TRUE` if successful).
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # result <- client$responses$delete("resp_abc123")
    # cat("Deleted:", result$deleted)
    # }
    delete = function(response_id) {
      self$client$request("DELETE", paste0("/responses/", response_id))
    },

    # @description
    # Cancel an in-progress streaming response.
    #
    # @param response_id Character. **Required.** The response ID to cancel.
    #
    # @return The cancelled response object.
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # client$responses$cancel("resp_abc123")
    # }
    cancel = function(response_id) {
      self$client$request("POST", paste0("/responses/", response_id, "/cancel"))
    },

    # @description
    # List the input items (messages, images, tool results) that were
    # sent as input to a specific response.
    #
    # @param response_id Character. **Required.** The response ID.
    #
    # @param after Character or NULL. Pagination cursor. Default: NULL.
    #
    # @param limit Integer or NULL. Max items to return. Default: NULL.
    #
    # @return A list with `$data` containing input item objects.
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # items <- client$responses$list_input_items("resp_abc123")
    # for (item in items$data) cat(item$type, "\n")
    # }
    list_input_items = function(response_id, after = NULL, limit = NULL) {
      query <- list()
      if (!is.null(after)) query$after <- after
      if (!is.null(limit)) query$limit <- limit

      self$client$request("GET", paste0("/responses/", response_id, "/input_items"), query = query)
    }
  )
)

#' Create a Response (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and calls `client$responses$create()`.
#'
#' The Responses API is OpenAI's newer, simpler alternative to Chat
#' Completions. It natively supports multi-turn conversations using
#' `previous_response_id` (no need to resend message history), and
#' includes built-in web search, file search, and other tools.
#'
#' @param model Character. **Required.** Model ID (e.g. `"gpt-4o"`,
#'   `"gpt-4o-mini"`, `"o1"`).
#' @param input **Required.** A text string or list of message objects
#'   as the prompt.
#' @param ... Additional parameters passed to [ResponsesClient]`$create()`,
#'   such as `instructions`, `previous_response_id` (for multi-turn),
#'   `tools`, `temperature`, `max_output_tokens`, `stream`, `store`.
#'
#' @return A response object. Access the text via
#'   `$output[[1]]$content[[1]]$text`.
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#'
#' # Simple text response
#' resp <- create_response(
#'   model = "gpt-4o",
#'   input = "What is the difference between OLS and IV?"
#' )
#' cat(resp$output[[1]]$content[[1]]$text)
#'
#' # Multi-turn: continue conversation using previous response ID
#' resp1 <- create_response("gpt-4o", "What is GMM?")
#' resp2 <- create_response(
#'   model                = "gpt-4o",
#'   input                = "Give me an R code example.",
#'   previous_response_id = resp1$id
#' )
#' cat(resp2$output[[1]]$content[[1]]$text)
#' }
create_response <- function(model, input, ...) {
  client <- OpenAI$new()
  client$responses$create(model = model, input = input, ...)
}

#' Retrieve a Response (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and retrieves a stored response by its ID.
#' Only responses created with `store = TRUE` can be retrieved.
#'
#' @param response_id Character. **Required.** The response ID
#'   (e.g. `"resp_abc123"`).
#'
#' @return A response object with `$output`, `$model`, and `$usage`.
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#'
#' resp <- retrieve_response("resp_abc123")
#' cat(resp$output[[1]]$content[[1]]$text)
#' }
retrieve_response <- function(response_id) {
  client <- OpenAI$new()
  client$responses$retrieve(response_id)
}

#' Delete a Stored Response (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and deletes a stored response.
#'
#' @param response_id Character. **Required.** The response ID to delete.
#'
#' @return A list with `$deleted` (`TRUE` if successful).
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#'
#' result <- delete_response("resp_abc123")
#' if (result$deleted) cat("Response deleted.")
#' }
delete_response <- function(response_id) {
  client <- OpenAI$new()
  client$responses$delete(response_id)
}

#' Cancel a Streaming Response (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and cancels an in-progress response.
#'
#' @param response_id Character. **Required.** The response ID to cancel.
#'
#' @return The cancelled response object.
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#' cancel_response("resp_abc123")
#' }
cancel_response <- function(response_id) {
  client <- OpenAI$new()
  client$responses$cancel(response_id)
}
