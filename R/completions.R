#' Completions Client (Legacy)
#'
#' Client for OpenAI Completions API (legacy).
#' For most use cases, use Chat Completions instead.
#'
#' @export
CompletionsClient <- R6::R6Class(
  "CompletionsClient",
  public = list(
    client = NULL,
    
    #' Initialize completions client
    #'
    #' @param parent Parent OpenAI client
    initialize = function(parent) {
      self$client <- parent
    },
    
    #' Create a completion (legacy)
    #'
    #' @param prompt Text prompt or array of prompts
    #' @param model Model to use (e.g., "gpt-3.5-turbo-instruct", "davinci-002")
    #' @param max_tokens Maximum tokens to generate
    #' @param temperature Sampling temperature (0-2)
    #' @param top_p Nucleus sampling parameter
    #' @param n Number of completions
    #' @param stream Whether to stream response
    #' @param logprobs Include log probabilities
    #' @param echo Echo back the prompt
    #' @param stop Stop sequences
    #' @param presence_penalty Presence penalty
    #' @param frequency_penalty Frequency penalty
    #' @param best_of Generate best of n completions
    #' @param logit_bias Token bias
    #' @param user User identifier
    #' @param callback Callback for streaming
    #' @return Completion response
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

#' Create a completion (convenience function)
#'
#' @param prompt Text prompt
#' @param model Model to use
#' @param ... Additional parameters
#' @return Completion response
#' @export
create_completion <- function(prompt, model = "gpt-3.5-turbo-instruct", ...) {
  client <- OpenAI$new()
  client$completions$create(prompt = prompt, model = model, ...)
}