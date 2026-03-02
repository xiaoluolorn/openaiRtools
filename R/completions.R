#' Completions Client (Legacy)
#'
#' Client for the OpenAI Completions API (legacy text completion endpoint).
#' Access via `client$completions`.
#'
#' @description
#' **Note:** This is the legacy "instruct" style API. For most use cases,
#' use [ChatCompletionsClient] (`client$chat$completions`) instead.
#' The Completions API is suitable only for `"gpt-3.5-turbo-instruct"` and
#' `"davinci-002"`. It takes a raw text prompt and returns a completion.
#'
#' @export
CompletionsClient <- R6::R6Class(
  "CompletionsClient",
  public = list(
    client = NULL,

    # Initialize completions client
    #
    # @param parent Parent OpenAI client
    initialize = function(parent) {
      self$client <- parent
    },

    # @description
    # Create a legacy text completion. Given a prompt string, the model
    # will generate text that follows it.
    # For conversational or instruction-following tasks, prefer
    # `client$chat$completions$create()` instead.
    #
    # @param prompt **[Required]** The prompt string (or list of strings)
    #   to complete. Unlike Chat Completions, this is raw text with no
    #   role structure.
    #   Example: `"The capital of France is"` → model completes with `"Paris."`
    #
    # @param model Character. Model to use. Only specific models support
    #   this endpoint:
    #   \itemize{
    #     \item `"gpt-3.5-turbo-instruct"` — Instruction-following model
    #     \item `"davinci-002"` — Legacy base model
    #     \item `"babbage-002"` — Smaller legacy model
    #   }
    #   Default: `"gpt-3.5-turbo-instruct"`.
    #
    # @param max_tokens Integer or NULL. Maximum number of tokens to generate.
    #   Does not include the prompt tokens. Default: NULL (API default 16;
    #   set higher for longer outputs).
    #
    # @param temperature Numeric in [0, 2] or NULL. Sampling temperature.
    #   0 = deterministic, 1 = balanced, 2 = highly random.
    #   Do not set both `temperature` and `top_p`. Default: NULL (API default 1).
    #
    # @param top_p Numeric in (0, 1] or NULL. Nucleus sampling threshold.
    #   Alternative to `temperature`. Default: NULL.
    #
    # @param n Integer or NULL. Number of completions to generate per prompt.
    #   All choices returned in `$choices`. Default: NULL (API default 1).
    #
    # @param stream Logical or NULL. If `TRUE`, streams output tokens using
    #   Server-Sent Events (SSE). Use with `callback` for real-time output.
    #   Default: NULL.
    #
    # @param logprobs Integer or NULL. Include log probabilities for the top N
    #   most likely tokens at each position (max 5). Default: NULL.
    #
    # @param echo Logical or NULL. If `TRUE`, the prompt is echoed back in
    #   the response along with the completion. Default: NULL.
    #
    # @param stop Character or list or NULL. Up to 4 stop sequences.
    #   Generation stops when any is encountered. Default: NULL.
    #
    # @param presence_penalty Numeric in [-2, 2] or NULL. Positive values
    #   penalize tokens that have appeared so far, encouraging new topics.
    #   Default: NULL (API default 0).
    #
    # @param frequency_penalty Numeric in [-2, 2] or NULL. Positive values
    #   penalize tokens that already appear frequently in the output.
    #   Default: NULL (API default 0).
    #
    # @param best_of Integer or NULL. Generate `best_of` completions
    #   server-side and return only the best (highest log probability).
    #   Must be greater than `n`. Default: NULL.
    #
    # @param logit_bias Named list or NULL. Map token IDs (as character strings)
    #   to bias values in [-100, 100]. -100 bans a token completely.
    #   Default: NULL.
    #
    # @param user Character or NULL. End-user identifier for abuse detection.
    #   Default: NULL.
    #
    # @param callback Function or NULL. Called for each chunk when `stream = TRUE`.
    #   Signature: `function(chunk)`. Access text via
    #   `chunk$choices[[1]]$text`. Default: NULL.
    #
    # @return A named list (completion object):
    #   \describe{
    #     \item{`$id`}{Character. Unique completion ID.}
    #     \item{`$object`}{Always `"text_completion"`.}
    #     \item{`$choices`}{List of choice objects. Each has:
    #       \describe{
    #         \item{`$choices[[i]]$text`}{The generated text string.}
    #         \item{`$choices[[i]]$finish_reason`}{`"stop"`, `"length"`, etc.}
    #       }
    #     }
    #     \item{`$usage`}{Token usage: `$prompt_tokens`, `$completion_tokens`,
    #       `$total_tokens`.}
    #   }
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    #
    # # Basic completion
    # resp <- client$completions$create(
    #   prompt     = "Translate to French: 'The economy is growing'",
    #   model      = "gpt-3.5-turbo-instruct",
    #   max_tokens = 50
    # )
    # cat(resp$choices[[1]]$text)
    #
    # # Multiple completions
    # resp <- client$completions$create(
    #   prompt     = "An interesting fact about R programming: ",
    #   model      = "gpt-3.5-turbo-instruct",
    #   max_tokens = 80,
    #   n          = 3,
    #   temperature = 1.0
    # )
    # for (i in seq_along(resp$choices)) {
    #   cat(i, ":", resp$choices[[i]]$text, "\n\n")
    # }
    # }
    create = function(prompt, model = "gpt-3.5-turbo-instruct",
                      max_tokens = NULL,
                      temperature = NULL,
                      top_p = NULL,
                      n = NULL,
                      stream = NULL,
                      logprobs = NULL,
                      echo = NULL,
                      stop = NULL,
                      presence_penalty = NULL,
                      frequency_penalty = NULL,
                      best_of = NULL,
                      logit_bias = NULL,
                      user = NULL,
                      callback = NULL) {
      body <- list(
        prompt = prompt,
        model = model
      )

      if (!is.null(max_tokens)) body$max_tokens <- max_tokens
      if (!is.null(temperature)) body$temperature <- temperature
      if (!is.null(top_p)) body$top_p <- top_p
      if (!is.null(n)) body$n <- n
      if (!is.null(stream)) body$stream <- stream
      if (!is.null(logprobs)) body$logprobs <- logprobs
      if (!is.null(echo)) body$echo <- echo
      if (!is.null(stop)) body$stop <- stop
      if (!is.null(presence_penalty)) body$presence_penalty <- presence_penalty
      if (!is.null(frequency_penalty)) body$frequency_penalty <- frequency_penalty
      if (!is.null(best_of)) body$best_of <- best_of
      if (!is.null(logit_bias)) body$logit_bias <- logit_bias
      if (!is.null(user)) body$user <- user

      is_streaming <- !is.null(stream) && stream

      self$client$request(
        "POST",
        "/completions",
        body = body,
        stream = is_streaming,
        callback = if (is_streaming) callback else NULL
      )
    }
  )
)

#' Create a Legacy Text Completion (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and calls `client$completions$create()`.
#'
#' @description
#' **Note:** This is the legacy Completions API. For most tasks, use
#' [create_chat_completion()] instead, which supports system prompts,
#' conversation history, and more capable models.
#'
#' @param prompt Character. **Required.** The text prompt to complete.
#' @param model Character. Model ID. Only `"gpt-3.5-turbo-instruct"`,
#'   `"davinci-002"`, and `"babbage-002"` support this endpoint.
#'   Default: `"gpt-3.5-turbo-instruct"`.
#' @param ... Additional parameters passed to [CompletionsClient]`$create()`,
#'   such as `max_tokens`, `temperature`, `n`, `stop`, `stream`, etc.
#'
#' @return A named list. Access the generated text via
#'   `$choices[[1]]$text`.
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#'
#' # Complete a sentence
#' resp <- create_completion(
#'   prompt     = "The most important assumption of OLS regression is",
#'   model      = "gpt-3.5-turbo-instruct",
#'   max_tokens = 100
#' )
#' cat(resp$choices[[1]]$text)
#' }
create_completion <- function(prompt, model = "gpt-3.5-turbo-instruct", ...) {
  client <- OpenAI$new()
  client$completions$create(prompt = prompt, model = model, ...)
}
