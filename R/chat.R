#' Chat Completions Client
#'
#' Client for OpenAI Chat Completions API.
#'
#' @export
ChatClient <- R6::R6Class(
  "ChatClient",
  public = list(
    client = NULL,
    
    #' @field completions Chat completions interface
    completions = NULL,
    
    #' Initialize chat client
    #'
    #' @param parent Parent OpenAI client
    initialize = function(parent) {
      self$client <- parent
      self$completions <- ChatCompletionsClient$new(parent)
    }
  )
)

#' Chat Completions Interface
#'
#' @export
ChatCompletionsClient <- R6::R6Class(
  "ChatCompletionsClient",
  public = list(
    client = NULL,
    
    #' Initialize completions client
    #'
    #' @param parent Parent OpenAI client
    initialize = function(parent) {
      self$client <- parent
    },
    
    #' Create a chat completion
    #'
    #' @param messages List of message objects. Each message should have 'role' and 'content'.
    #'        For multimodal (vision) models, content can be a list containing text and images.
    #'        Use [image_from_url()], [image_from_file()], or [create_multimodal_message()] for images.
    #' @param model Model to use (e.g., "gpt-4", "gpt-3.5-turbo", "gpt-4-vision-preview")
    #' @param frequency_penalty Frequency penalty (-2.0 to 2.0)
    #' @param logit_bias Modify likelihood of tokens
    #' @param logprobs Return log probabilities
    #' @param top_logprobs Number of top log probabilities to return
    #' @param max_tokens Maximum number of tokens to generate
    #' @param n Number of completions to generate
    #' @param presence_penalty Presence penalty (-2.0 to 2.0)
    #' @param response_format Response format specification
    #' @param seed Random seed
    #' @param stop Stop sequences
    #' @param stream Whether to stream partial message deltas
    #' @param stream_options Options for streaming responses
    #' @param temperature Sampling temperature (0 to 2)
    #' @param top_p Nucleus sampling parameter (0 to 1)
    #' @param tools List of tools available
    #' @param tool_choice Tool choice strategy
    #' @param user Unique identifier for end user
    #' @param callback Function to call for each stream chunk (only for streaming)
    #' @param ... Additional parameters
    #' @return Chat completion response or list of stream chunks
    #'
    #' @examples
    #' \dontrun{
    #' # Text-only chat
    #' response <- client$chat$completions$create(
    #'   messages = list(list(role = "user", content = "Hello")),
    #'   model = "gpt-3.5-turbo"
    #' )
    #' cat(response$choices[[1]]$message$content)
    #'
    #' # Multimodal chat with image URL
    #' messages <- list(
    #'   list(
    #'     role = "user",
    #'     content = list(
    #'       list(type = "text", text = "What's in this image?"),
    #'       list(type = "image_url", image_url = list(url = "https://example.com/image.jpg"))
    #'     )
    #'   )
    #' )
    #' response <- client$chat$completions$create(
    #'   messages = messages,
    #'   model = "gpt-4-vision-preview"
    #' )
    #'
    #' # Using helper functions for multimodal
    #' library(openaiR)
    #' msg <- create_multimodal_message(
    #'   text = "Describe this image",
    #'   images = list("path/to/image.jpg")
    #' )
    #' response <- client$chat$completions$create(
    #'   messages = list(msg),
    #'   model = "gpt-4-vision-preview"
    #' )
    #'
    #' # Streaming with callback
    #' client$chat$completions$create(
    #'   messages = list(list(role = "user", content = "Tell me a story")),
    #'   model = "gpt-3.5-turbo",
    #'   stream = TRUE,
    #'   callback = function(chunk) {
    #'     content <- chunk$choices[[1]]$delta$content
    #'     if (!is.null(content)) cat(content)
    #'   }
    #' )
    #' }
    create = function(messages, model = "gpt-3.5-turbo",
                      frequency_penalty = NULL,
                      logit_bias = NULL,
                      logprobs = NULL,
                      top_logprobs = NULL,
                      max_tokens = NULL,
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
                      user = NULL,
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
      if (!is.null(user)) body$user <- user
      
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
      
      # Return result
      result
    }
  )
)

#' Create a chat completion (convenience function)
#'
#' @param messages List of message objects
#' @param model Model to use
#' @param ... Additional parameters passed to chat$completions$create()
#' @return Chat completion response
#' @export
create_chat_completion <- function(messages, model = "gpt-3.5-turbo", ...) {
  client <- OpenAI$new()
  client$chat$completions$create(messages = messages, model = model, ...)
}
