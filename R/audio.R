#' Audio Client
#'
#' Client for OpenAI Audio API (transcription, translation, speech).
#'
#' @export
AudioClient <- R6::R6Class(
  "AudioClient",
  public = list(
    client = NULL,
    
    #' @field transcriptions Audio transcription interface
    transcriptions = NULL,
    
    #' @field translations Audio translation interface
    translations = NULL,
    
    #' @field speech Text-to-speech interface
    speech = NULL,
    
    #' Initialize audio client
    #'
    #' @param parent Parent OpenAI client
    initialize = function(parent) {
      self$client <- parent
      self$transcriptions <- AudioTranscriptionsClient$new(parent)
      self$translations <- AudioTranslationsClient$new(parent)
      self$speech <- SpeechClient$new(parent)
    }
  )
)

#' Audio Transcriptions Client
#'
#' @export
AudioTranscriptionsClient <- R6::R6Class(
  "AudioTranscriptionsClient",
  public = list(
    client = NULL,
    
    initialize = function(parent) {
      self$client <- parent
    },
    
    #' Transcribe audio to text
    #'
    #' @param file Audio file path
    #' @param model Model to use (e.g., "whisper-1")
    #' @param language Language code (ISO-639-1)
    #' @param prompt Optional text to guide transcription
    #' @param response_format Response format ("json", "text", "srt", "verbose_json", "vtt")
    #' @param temperature Sampling temperature
    #' @param timestamp_granularies List of timestamp granularities
    #' @return Transcription response
    create = function(file, model = "whisper-1",
                      language = NULL,
                      prompt = NULL,
                      response_format = NULL,
                      temperature = NULL,
                      timestamp_granularities = NULL) {
      req <- httr2::request(paste0(self$client$base_url, "/audio/transcriptions"))
      req <- httr2::req_method(req, "POST")
      req <- httr2::req_headers(req,
        "Authorization" = paste("Bearer", self$client$api_key),
        "OpenAI-Beta" = "assistants=v2"
      )
      
      if (!is.null(self$client$organization)) {
        req <- httr2::req_headers(req, "OpenAI-Organization" = self$client$organization)
      }
      
      # Add audio file
      req <- httr2::req_body_multipart(req, file = httr2::curl_file(file))
      req <- httr2::req_body_multipart(req, model = model)
      
      # Add optional parameters
      if (!is.null(language)) {
        req <- httr2::req_body_multipart(req, language = language)
      }
      if (!is.null(prompt)) {
        req <- httr2::req_body_multipart(req, prompt = prompt)
      }
      if (!is.null(response_format)) {
        req <- httr2::req_body_multipart(req, response_format = response_format)
      }
      if (!is.null(temperature)) {
        req <- httr2::req_body_multipart(req, temperature = as.character(temperature))
      }
      if (!is.null(timestamp_granularities)) {
        req <- httr2::req_body_multipart(req, timestamp_granularities = I(jsonlite::toJSON(timestamp_granularities)))
      }
      
      resp <- httr2::req_perform(req)
      handle_response(resp)
    }
  )
)

#' Audio Translations Client
#'
#' @export
AudioTranslationsClient <- R6::R6Class(
  "AudioTranslationsClient",
  public = list(
    client = NULL,
    
    initialize = function(parent) {
      self$client <- parent
    },
    
    #' Translate audio to English text
    #'
    #' @param file Audio file path
    #' @param model Model to use (e.g., "whisper-1")
    #' @param prompt Optional text to guide translation
    #' @param response_format Response format
    #' @param temperature Sampling temperature
    #' @return Translation response
    create = function(file, model = "whisper-1",
                      prompt = NULL,
                      response_format = NULL,
                      temperature = NULL) {
      req <- httr2::request(paste0(self$client$base_url, "/audio/translations"))
      req <- httr2::req_method(req, "POST")
      req <- httr2::req_headers(req,
        "Authorization" = paste("Bearer", self$client$api_key),
        "OpenAI-Beta" = "assistants=v2"
      )
      
      if (!is.null(self$client$organization)) {
        req <- httr2::req_headers(req, "OpenAI-Organization" = self$client$organization)
      }
      
      # Add audio file
      req <- httr2::req_body_multipart(req, file = httr2::curl_file(file))
      req <- httr2::req_body_multipart(req, model = model)
      
      # Add optional parameters
      if (!is.null(prompt)) {
        req <- httr2::req_body_multipart(req, prompt = prompt)
      }
      if (!is.null(response_format)) {
        req <- httr2::req_body_multipart(req, response_format = response_format)
      }
      if (!is.null(temperature)) {
        req <- httr2::req_body_multipart(req, temperature = as.character(temperature))
      }
      
      resp <- httr2::req_perform(req)
      handle_response(resp)
    }
  )
)

#' Speech Client
#'
#' @export
SpeechClient <- R6::R6Class(
  "SpeechClient",
  public = list(
    client = NULL,
    
    initialize = function(parent) {
      self$client <- parent
    },
    
    #' Generate speech from text
    #'
    #' @param input Text to synthesize
    #' @param model Model to use (e.g., "tts-1", "tts-1-hd")
    #' @param voice Voice to use ("alloy", "echo", "fable", "onyx", "nova", "shimmer")
    #' @param response_format Response format ("mp3", "opus", "aac", "flac", "wav", "pcm")
    #' @param speed Speech speed (0.25 to 4.0)
    #' @return Raw audio data (not parsed as JSON)
    create = function(input, model = "tts-1",
                      voice = "alloy",
                      response_format = NULL,
                      speed = NULL) {
      body <- list(
        input = input,
        model = model,
        voice = voice
      )
      
      if (!is.null(response_format)) body$response_format <- response_format
      if (!is.null(speed)) body$speed <- speed
      
      req <- httr2::request(paste0(self$client$base_url, "/audio/speech"))
      req <- httr2::req_method(req, "POST")
      req <- httr2::req_headers(req,
        "Authorization" = paste("Bearer", self$client$api_key),
        "Content-Type" = "application/json",
        "OpenAI-Beta" = "assistants=v2"
      )
      
      if (!is.null(self$client$organization)) {
        req <- httr2::req_headers(req, "OpenAI-Organization" = self$client$organization)
      }
      
      req <- httr2::req_body_json(req, body)
      
      resp <- tryCatch(
        {
          httr2::req_perform(req)
        },
        error = function(e) {
          OpenAIConnectionError(
            sprintf("Failed to connect to OpenAI API: %s", e$message),
            parent = e
          )
        }
      )
      
      # Return raw content for audio
      resp$body
    }
  )
)

#' Create transcription (convenience function)
#'
#' @param file Audio file path
#' @param model Model to use
#' @param ... Additional parameters
#' @return Transcription response
#' @export
create_transcription <- function(file, model = "whisper-1", ...) {
  client <- OpenAI$new()
  client$audio$transcriptions$create(file = file, model = model, ...)
}

#' Create translation (convenience function)
#'
#' @param file Audio file path
#' @param model Model to use
#' @param ... Additional parameters
#' @return Translation response
#' @export
create_translation <- function(file, model = "whisper-1", ...) {
  client <- OpenAI$new()
  client$audio$translations$create(file = file, model = model, ...)
}

#' Create speech (convenience function)
#'
#' @param input Text to synthesize
#' @param model Model to use
#' @param voice Voice to use
#' @param ... Additional parameters
#' @return Raw audio data
#' @export
create_speech <- function(input, model = "tts-1", voice = "alloy", ...) {
  client <- OpenAI$new()
  client$audio$speech$create(input = input, model = model, voice = voice, ...)
}
