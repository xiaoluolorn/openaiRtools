#' Audio Client
#'
#' Top-level client for the OpenAI Audio API, providing access to
#' transcription, translation, and text-to-speech services.
#' Access via `client$audio`.
#'
#' @section Sub-clients:
#' \describe{
#'   \item{`$transcriptions`}{[AudioTranscriptionsClient] — Whisper speech-to-text}
#'   \item{`$translations`}{[AudioTranslationsClient] — Whisper audio translation to English}
#'   \item{`$speech`}{[SpeechClient] — Text-to-speech (TTS)}
#' }
#'
#' @export
AudioClient <- R6::R6Class(
  "AudioClient",
  public = list(
    client = NULL,

    # Field: transcriptions Audio transcription interface
    transcriptions = NULL,

    # Field: translations Audio translation interface
    translations = NULL,

    # Field: speech Text-to-speech interface
    speech = NULL,

    # Initialize audio client
    #
    # @param parent Parent OpenAI client
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
#' Transcribes audio files to text using OpenAI's Whisper model.
#' Access via `client$audio$transcriptions`.
#'
#' @export
AudioTranscriptionsClient <- R6::R6Class(
  "AudioTranscriptionsClient",
  public = list(
    client = NULL,
    initialize = function(parent) {
      self$client <- parent
    },

    # @description
    # Transcribe an audio file to text using the Whisper model.
    #
    # @param file Character. Path to the local audio file to transcribe.
    #   Supported formats: flac, mp3, mp4, mpeg, mpga, m4a, ogg, wav, webm.
    #   Maximum file size: 25 MB.
    #
    # @param model Character. The Whisper model to use.
    #   Currently the only available model is `"whisper-1"`.
    #   Default: `"whisper-1"`.
    #
    # @param language Character or NULL. ISO-639-1 language code of the audio
    #   (e.g. `"en"` for English, `"zh"` for Chinese, `"fr"` for French).
    #   Providing this improves accuracy and reduces latency.
    #   If NULL, Whisper auto-detects the language. Default: NULL.
    #
    # @param prompt Character or NULL. Optional text to guide transcription style
    #   or provide context. Examples:
    #   \itemize{
    #     \item Provide domain-specific terminology: `"GDP, CPI, OLS, instrumental variables"`
    #     \item Indicate expected content: `"A lecture on econometrics"`
    #     \item Provide spelling for unusual names
    #   }
    #   Default: NULL.
    #
    # @param response_format Character or NULL. Format of the transcript output:
    #   \itemize{
    #     \item `"json"` (default) — Returns `list(text = "...")`.
    #     \item `"text"` — Returns a plain text string.
    #     \item `"srt"` — SubRip subtitle format with timestamps.
    #     \item `"vtt"` — WebVTT subtitle format.
    #     \item `"verbose_json"` — JSON with word-level timestamps and more metadata.
    #   }
    #   Default: NULL (API default `"json"`).
    #
    # @param temperature Numeric in [0, 1] or NULL. Sampling temperature.
    #   Higher values make output more random.
    #   0 is recommended for most transcription tasks (deterministic).
    #   Default: NULL (API default 0).
    #
    # @param timestamp_granularities List or NULL. Granularities for timestamps
    #   in `"verbose_json"` format. A list of one or both of:
    #   `"word"` and `"segment"`.
    #   Example: `list("word", "segment")`.
    #   Only used when `response_format = "verbose_json"`. Default: NULL.
    #
    # @return Depends on `response_format`:
    #   \itemize{
    #     \item `"json"` — A list with `$text` (the transcribed string).
    #     \item `"text"` — A character string.
    #     \item `"srt"` / `"vtt"` — A character string with timestamps.
    #     \item `"verbose_json"` — A list with `$text`, `$words`, `$segments`,
    #       `$language`, `$duration`.
    #   }
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    #
    # # Basic transcription
    # result <- client$audio$transcriptions$create(
    #   file  = "interview.mp3",
    #   model = "whisper-1"
    # )
    # cat(result$text)
    #
    # # Transcribe Chinese audio with language hint
    # result <- client$audio$transcriptions$create(
    #   file     = "lecture.m4a",
    #   model    = "whisper-1",
    #   language = "zh"
    # )
    # cat(result$text)
    #
    # # Get verbose output with word-level timestamps
    # result <- client$audio$transcriptions$create(
    #   file                    = "meeting.mp3",
    #   model                   = "whisper-1",
    #   response_format         = "verbose_json",
    #   timestamp_granularities = list("word")
    # )
    # # Access individual word timestamps
    # for (w in result$words) cat(w$word, "@", w$start, "s\n")
    # }
    create = function(file, model = "whisper-1",
                      language = NULL,
                      prompt = NULL,
                      response_format = NULL,
                      temperature = NULL,
                      timestamp_granularities = NULL) {
      # Build multipart params
      params <- list(
        file = httr2::curl_file(file),
        model = model
      )

      if (!is.null(language)) params$language <- language
      if (!is.null(prompt)) params$prompt <- prompt
      if (!is.null(response_format)) params$response_format <- response_format
      if (!is.null(temperature)) params$temperature <- as.character(temperature)
      if (!is.null(timestamp_granularities)) {
        params$timestamp_granularities <- I(jsonlite::toJSON(timestamp_granularities))
      }

      do.call(
        self$client$request_multipart,
        c(list(method = "POST", path = "/audio/transcriptions"), params)
      )
    }
  )
)

#' Audio Translations Client
#'
#' Translates audio from any supported language into English text using
#' Whisper. Access via `client$audio$translations`.
#'
#' @export
AudioTranslationsClient <- R6::R6Class(
  "AudioTranslationsClient",
  public = list(
    client = NULL,
    initialize = function(parent) {
      self$client <- parent
    },

    # @description
    # Translate an audio file from any supported language into English text.
    # Unlike transcription, there is no `language` parameter — the source
    # language is auto-detected and the output is always English.
    #
    # @param file Character. Path to the local audio file to translate.
    #   Supported formats: flac, mp3, mp4, mpeg, mpga, m4a, ogg, wav, webm.
    #   Maximum file size: 25 MB.
    #
    # @param model Character. The Whisper model to use.
    #   Currently the only available model is `"whisper-1"`.
    #   Default: `"whisper-1"`.
    #
    # @param prompt Character or NULL. Optional English text to guide the
    #   translation style. Useful for providing context or domain terms.
    #   Default: NULL.
    #
    # @param response_format Character or NULL. Output format:
    #   `"json"`, `"text"`, `"srt"`, `"vtt"`, or `"verbose_json"`.
    #   Default: NULL (API default `"json"`).
    #
    # @param temperature Numeric in [0, 1] or NULL. Sampling temperature.
    #   Default: NULL (API default 0).
    #
    # @return A list (for JSON formats) or character string (for `"text"`,
    #   `"srt"`, `"vtt"`) with the English translation. For `"json"`,
    #   `$text` contains the translated string.
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    #
    # # Translate a Chinese audio file to English
    # result <- client$audio$translations$create(
    #   file  = "chinese_lecture.mp3",
    #   model = "whisper-1"
    # )
    # cat(result$text)  # Always returns English
    # }
    create = function(file, model = "whisper-1",
                      prompt = NULL,
                      response_format = NULL,
                      temperature = NULL) {
      params <- list(
        file = httr2::curl_file(file),
        model = model
      )

      if (!is.null(prompt)) params$prompt <- prompt
      if (!is.null(response_format)) params$response_format <- response_format
      if (!is.null(temperature)) params$temperature <- as.character(temperature)

      do.call(
        self$client$request_multipart,
        c(list(method = "POST", path = "/audio/translations"), params)
      )
    }
  )
)

#' Speech Client (Text-to-Speech)
#'
#' Converts text to spoken audio using OpenAI's TTS models.
#' Access via `client$audio$speech`.
#'
#' @export
SpeechClient <- R6::R6Class(
  "SpeechClient",
  public = list(
    client = NULL,
    initialize = function(parent) {
      self$client <- parent
    },

    # @description
    # Generate spoken audio from text input (Text-to-Speech).
    # Returns raw binary audio data that can be written to a file.
    #
    # @param input Character. The text to convert to speech.
    #   Maximum length: 4096 characters.
    #
    # @param model Character. TTS model to use:
    #   \itemize{
    #     \item `"tts-1"` — Fast, lower quality. Recommended for real-time use.
    #     \item `"tts-1-hd"` — Slower, higher audio quality. Recommended for
    #       final output or podcast-quality audio.
    #   }
    #   Default: `"tts-1"`.
    #
    # @param voice Character. The voice to use for synthesis. Options:
    #   \itemize{
    #     \item `"alloy"` — Neutral, balanced
    #     \item `"ash"` — Warm, conversational
    #     \item `"coral"` — Clear, friendly
    #     \item `"echo"` — Smooth, resonant
    #     \item `"fable"` — Expressive, narrative
    #     \item `"onyx"` — Deep, authoritative
    #     \item `"nova"` — Bright, energetic
    #     \item `"sage"` — Calm, measured
    #     \item `"shimmer"` — Light, gentle
    #   }
    #   Default: `"alloy"`.
    #
    # @param response_format Character or NULL. Audio output format:
    #   \itemize{
    #     \item `"mp3"` (default) — Best for general use
    #     \item `"opus"` — Lower latency, good for streaming
    #     \item `"aac"` — Apple devices
    #     \item `"flac"` — Lossless compression
    #     \item `"wav"` — Uncompressed, large files
    #     \item `"pcm"` — Raw 24kHz 16-bit signed little-endian PCM
    #   }
    #   Default: NULL (API default `"mp3"`).
    #
    # @param speed Numeric in [0.25, 4.0] or NULL. Speed of generated speech.
    #   1.0 (default) is normal speed. 0.5 is half speed, 2.0 is double speed.
    #   Default: NULL (API default 1.0).
    #
    # @return A `raw` vector containing binary audio data.
    #   Save to a file with `writeBin()`. Do NOT use `cat()` on this.
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    #
    # # Generate speech and save to MP3
    # audio_data <- client$audio$speech$create(
    #   input = "Hello! Welcome to the R package for OpenAI.",
    #   model = "tts-1",
    #   voice = "nova"
    # )
    # writeBin(audio_data, "greeting.mp3")
    # cat("Saved to greeting.mp3\n")
    #
    # # High-quality output at slower speed
    # audio_data <- client$audio$speech$create(
    #   input           = "Economic growth depends on capital accumulation.",
    #   model           = "tts-1-hd",
    #   voice           = "onyx",
    #   response_format = "wav",
    #   speed           = 0.85
    # )
    # writeBin(audio_data, "lecture_snippet.wav")
    # }
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

      # Use request_raw to get binary audio data
      self$client$request_raw("POST", "/audio/speech", body = body)
    }
  )
)

#' Transcribe Audio to Text (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and calls `client$audio$transcriptions$create()`.
#'
#' @param file Character. **Required.** Path to the local audio file.
#'   Supported: flac, mp3, mp4, mpeg, mpga, m4a, ogg, wav, webm (max 25 MB).
#' @param model Character. Whisper model. Default: `"whisper-1"`.
#' @param ... Additional parameters passed to
#'   [AudioTranscriptionsClient]`$create()`, such as `language`, `prompt`,
#'   `response_format`, `temperature`, `timestamp_granularities`.
#'
#' @return A list with `$text` containing the transcribed text (for default
#'   JSON format), or a character string for `response_format = "text"`.
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#'
#' # Basic transcription
#' result <- create_transcription("meeting.mp3")
#' cat(result$text)
#'
#' # With language hint and plain text output
#' text <- create_transcription(
#'   file            = "lecture.m4a",
#'   model           = "whisper-1",
#'   language        = "en",
#'   response_format = "text"
#' )
#' cat(text)
#' }
create_transcription <- function(file, model = "whisper-1", ...) {
  client <- OpenAI$new()
  client$audio$transcriptions$create(file = file, model = model, ...)
}

#' Translate Audio to English Text (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and calls `client$audio$translations$create()`.
#' Always produces English output regardless of source language.
#'
#' @param file Character. **Required.** Path to the local audio file.
#'   Supported: flac, mp3, mp4, mpeg, mpga, m4a, ogg, wav, webm (max 25 MB).
#' @param model Character. Whisper model. Default: `"whisper-1"`.
#' @param ... Additional parameters passed to
#'   [AudioTranslationsClient]`$create()`, such as `prompt`,
#'   `response_format`, `temperature`.
#'
#' @return A list with `$text` containing the English translation (for default
#'   JSON format), or a character string for `response_format = "text"`.
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#'
#' # Translate a Chinese audio file to English
#' result <- create_translation("chinese_speech.mp3")
#' cat(result$text) # Output is always in English
#' }
create_translation <- function(file, model = "whisper-1", ...) {
  client <- OpenAI$new()
  client$audio$translations$create(file = file, model = model, ...)
}

#' Convert Text to Speech (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and calls `client$audio$speech$create()`.
#' Returns raw binary audio data that should be saved with `writeBin()`.
#'
#' @param input Character. **Required.** The text to synthesize (max 4096 chars).
#' @param model Character. TTS model: `"tts-1"` (fast) or `"tts-1-hd"`
#'   (higher quality). Default: `"tts-1"`.
#' @param voice Character. Voice style. One of: `"alloy"`, `"ash"`,
#'   `"coral"`, `"echo"`, `"fable"`, `"onyx"`, `"nova"`, `"sage"`,
#'   `"shimmer"`. Default: `"alloy"`.
#' @param ... Additional parameters passed to [SpeechClient]`$create()`,
#'   such as `response_format` (`"mp3"`, `"wav"`, `"flac"`, etc.)
#'   and `speed` (0.25–4.0).
#'
#' @return A `raw` vector of binary audio data. Save using `writeBin()`.
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#'
#' # Generate and save to MP3
#' audio <- create_speech(
#'   input = "The quick brown fox jumps over the lazy dog.",
#'   model = "tts-1",
#'   voice = "nova"
#' )
#' writeBin(audio, "output.mp3")
#'
#' # High-quality WAV with slower speed
#' audio <- create_speech(
#'   input           = "Welcome to the lecture on macroeconomics.",
#'   model           = "tts-1-hd",
#'   voice           = "onyx",
#'   response_format = "wav",
#'   speed           = 0.9
#' )
#' writeBin(audio, "lecture_intro.wav")
#' }
create_speech <- function(input, model = "tts-1", voice = "alloy", ...) {
  client <- OpenAI$new()
  client$audio$speech$create(input = input, model = model, voice = voice, ...)
}
