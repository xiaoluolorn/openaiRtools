#' Assistants Client (Beta)
#'
#' Client for the OpenAI Assistants API v2 (Beta).
#' Assistants are AI agents that can use tools (code interpreter,
#' file search, custom functions) and maintain persistent state.
#' Access via `client$assistants`.
#'
#' @description
#' An Assistant is a configured AI entity with a model, instructions, and
#' optional tools. It operates on [ThreadsClient] (conversations) by
#' creating Runs that execute the assistant's logic.
#'
#' @section Typical workflow:
#' 1. Create an assistant: `client$assistants$create(model, instructions, tools)`
#' 2. Create a thread: `client$threads$create()`
#' 3. Add a user message: `client$threads$messages$create(thread_id, "user", "...")`
#' 4. Create a run: `client$threads$runs$create(thread_id, assistant_id)`
#' 5. Poll the run until status is `"completed"`
#' 6. Read the assistant's reply: `client$threads$messages$list(thread_id)`
#'
#' @export
AssistantsClient <- R6::R6Class(
  "AssistantsClient",
  public = list(
    client = NULL,

    # @description Initialize assistants client
    # @param parent Parent OpenAI client object
    initialize = function(parent) {
      self$client <- parent
    },

    # @description
    # Create a new AI assistant with a configured model, instructions, and tools.
    #
    # @param model Character. **Required.** The language model to power the
    #   assistant. Examples:
    #   \itemize{
    #     \item `"gpt-4o"` — Best capability, supports vision
    #     \item `"gpt-4o-mini"` — Faster and cheaper
    #     \item `"gpt-4-turbo"` — Large context window
    #   }
    #
    # @param name Character or NULL. A human-readable name for the assistant
    #   (max 256 characters). Example: `"Research Assistant"`.
    #   Default: NULL.
    #
    # @param description Character or NULL. A description of what the assistant
    #   does (max 512 characters). Default: NULL.
    #
    # @param instructions Character or NULL. The system prompt that guides the
    #   assistant's behavior (max 256,000 characters).
    #   Example: `"You are an expert econometrician. Answer questions concisely,
    #   using LaTeX for equations."`. Default: NULL.
    #
    # @param tools List or NULL. Tools the assistant can use. Supported tools:
    #   \itemize{
    #     \item `list(list(type = "code_interpreter"))` — Execute Python code
    #     \item `list(list(type = "file_search"))` — Search uploaded documents
    #     \item Function calling: `list(list(type = "function", function = list(name = "...",
    #       description = "...", parameters = list(...))))`
    #   }
    #   Default: NULL (no tools).
    #
    # @param tool_resources List or NULL. Resources for tools. For `file_search`,
    #   provide a vector store ID:
    #   `list(file_search = list(vector_store_ids = list("vs-abc123")))`.
    #   Default: NULL.
    #
    # @param metadata Named list or NULL. Up to 16 key-value pairs (both strings)
    #   for organizing assistants. Default: NULL.
    #
    # @param temperature Numeric in [0, 2] or NULL. Sampling temperature.
    #   Default: NULL (API default 1).
    #
    # @param top_p Numeric in (0, 1] or NULL. Nucleus sampling. Default: NULL.
    #
    # @param response_format List or NULL. Output format constraint.
    #   Use `list(type = "json_object")` to force JSON output.
    #   Default: NULL (text output).
    #
    # @return An assistant object:
    #   \describe{
    #     \item{`$id`}{Character. Assistant ID (e.g. `"asst_abc123"`). Save this.}
    #     \item{`$name`}{Character. The assistant's name.}
    #     \item{`$model`}{Character. The model used.}
    #     \item{`$instructions`}{Character. The system instructions.}
    #     \item{`$tools`}{List. Configured tools.}
    #     \item{`$created_at`}{Integer. Unix timestamp.}
    #   }
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    #
    # # Simple assistant without tools
    # asst <- client$assistants$create(
    #   model        = "gpt-4o",
    #   name         = "Econometrics TA",
    #   instructions = "You are a teaching assistant for econometrics.
    #     Explain concepts clearly with examples in R."
    # )
    # cat("Assistant ID:", asst$id)
    #
    # # Assistant with code interpreter and file search
    # asst <- client$assistants$create(
    #   model        = "gpt-4o",
    #   name         = "Data Analyst",
    #   instructions = "Analyze data files and answer questions.",
    #   tools        = list(
    #     list(type = "code_interpreter"),
    #     list(type = "file_search")
    #   )
    # )
    # }
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

    # @description
    # List assistants associated with your API key.
    #
    # @param limit Integer or NULL. Maximum number of assistants (1–100).
    #   Default: NULL (API default 20).
    #
    # @param order Character or NULL. Sort by creation time: `"asc"` or
    #   `"desc"`. Default: NULL (API default `"desc"`).
    #
    # @param after Character or NULL. Pagination cursor — assistant ID of
    #   the last item from a previous page. Default: NULL.
    #
    # @param before Character or NULL. Reverse pagination cursor. Default: NULL.
    #
    # @return A list with `$data` — a list of assistant objects.
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # assistants <- client$assistants$list()
    # for (a in assistants$data) cat(a$id, "-", a$name, "\n")
    # }
    list = function(limit = NULL, order = NULL, after = NULL, before = NULL) {
      query <- list()
      if (!is.null(limit)) query$limit <- limit
      if (!is.null(order)) query$order <- order
      if (!is.null(after)) query$after <- after
      if (!is.null(before)) query$before <- before
      self$client$request("GET", "/assistants", query = query)
    },

    # @description
    # Retrieve a specific assistant by its ID.
    #
    # @param assistant_id Character. **Required.** The assistant ID
    #   (e.g. `"asst_abc123"`).
    #
    # @return An assistant object (same structure as returned by `$create()`).
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # asst <- client$assistants$retrieve("asst_abc123")
    # cat("Name:", asst$name)
    # cat("Model:", asst$model)
    # }
    retrieve = function(assistant_id) {
      self$client$request("GET", paste0("/assistants/", assistant_id))
    },

    # @description
    # Update an existing assistant's configuration. Only fields you provide
    # will be changed; all other fields remain unchanged.
    #
    # @param assistant_id Character. **Required.** The assistant ID to update.
    #
    # @param ... Named arguments for fields to update. Supported fields:
    #   `name`, `description`, `instructions`, `model`, `tools`,
    #   `tool_resources`, `metadata`, `temperature`, `top_p`,
    #   `response_format`.
    #
    # @return The updated assistant object.
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    #
    # # Update instructions only
    # asst <- client$assistants$update(
    #   "asst_abc123",
    #   instructions = "You are now an expert in machine learning.",
    #   model        = "gpt-4o"
    # )
    # }
    update = function(assistant_id, ...) {
      body <- list(...)
      self$client$request("POST", paste0("/assistants/", assistant_id), body = body)
    },

    # @description
    # Delete an assistant permanently.
    #
    # @param assistant_id Character. **Required.** The assistant ID to delete.
    #
    # @return A list with `$id` (the deleted assistant ID) and
    #   `$deleted` (`TRUE` if successful).
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # result <- client$assistants$delete("asst_abc123")
    # cat("Deleted:", result$deleted)
    # }
    delete = function(assistant_id) {
      self$client$request("DELETE", paste0("/assistants/", assistant_id))
    }
  )
)

#' Create an Assistant (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and calls `client$assistants$create()`.
#'
#' @param model Character. **Required.** Model ID to power the assistant
#'   (e.g. `"gpt-4o"`, `"gpt-4o-mini"`).
#' @param ... Additional parameters passed to [AssistantsClient]`$create()`:
#'   `name`, `description`, `instructions`, `tools`, `tool_resources`,
#'   `metadata`, `temperature`, `top_p`, `response_format`.
#'
#' @return An assistant object with `$id` (save this for future use),
#'   `$name`, `$model`, `$instructions`, and `$tools`.
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#'
#' asst <- create_assistant(
#'   model        = "gpt-4o",
#'   name         = "Stats Helper",
#'   instructions = "You help with statistical analysis in R and Python.",
#'   tools        = list(list(type = "code_interpreter"))
#' )
#' cat("Created assistant ID:", asst$id)
#' }
create_assistant <- function(model, ...) {
  client <- OpenAI$new()
  client$assistants$create(model = model, ...)
}

#' List Assistants (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and lists all assistants.
#'
#' @param ... Additional parameters passed to [AssistantsClient]`$list()`:
#'   `limit` (max results), `order` (`"asc"`/`"desc"`), `after`, `before`.
#'
#' @return A list with `$data` — a list of assistant objects, each with
#'   `$id`, `$name`, `$model`, `$instructions`, and `$tools`.
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#'
#' assistants <- list_assistants()
#' for (a in assistants$data) {
#'   cat(a$id, "-", a$name %||% "(unnamed)", "\n")
#' }
#' }
list_assistants <- function(...) {
  client <- OpenAI$new()
  client$assistants$list(...)
}

#' Retrieve an Assistant (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and retrieves a specific assistant.
#'
#' @param assistant_id Character. **Required.** The assistant ID
#'   (e.g. `"asst_abc123"`).
#'
#' @return An assistant object with `$id`, `$name`, `$model`,
#'   `$instructions`, `$tools`, and `$created_at`.
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#'
#' asst <- retrieve_assistant("asst_abc123")
#' cat("Name:", asst$name)
#' cat("Model:", asst$model)
#' }
retrieve_assistant <- function(assistant_id) {
  client <- OpenAI$new()
  client$assistants$retrieve(assistant_id)
}

#' Update an Assistant (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and updates an existing assistant.
#'
#' @param assistant_id Character. **Required.** The ID of the assistant to update.
#' @param ... Named fields to update. Supported: `name`, `description`,
#'   `instructions`, `model`, `tools`, `tool_resources`, `metadata`,
#'   `temperature`, `response_format`.
#'
#' @return The updated assistant object.
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#'
#' updated <- update_assistant(
#'   "asst_abc123",
#'   instructions = "You are now an expert in time series analysis.",
#'   model        = "gpt-4o"
#' )
#' cat("Updated model:", updated$model)
#' }
update_assistant <- function(assistant_id, ...) {
  client <- OpenAI$new()
  client$assistants$update(assistant_id, ...)
}

#' Delete an Assistant (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and permanently deletes an assistant.
#'
#' @param assistant_id Character. **Required.** The ID of the assistant to delete.
#'
#' @return A list with `$deleted` (`TRUE` if successful) and `$id`.
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#'
#' result <- delete_assistant("asst_abc123")
#' if (result$deleted) cat("Assistant deleted.")
#' }
delete_assistant <- function(assistant_id) {
  client <- OpenAI$new()
  client$assistants$delete(assistant_id)
}
