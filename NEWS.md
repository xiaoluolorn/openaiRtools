# NEWS.md

## openaiR 0.2.2 (2026-03-01)

### Bug Fixes

* Fixed streaming response format: `stream=TRUE` without a `callback` now
  returns a standard chat completion object so that
  `response$choices[[1]]$message$content` works correctly.
* Fixed NAMESPACE: removed spurious exports caused by roxygen2 misinterpreting
  `@field` tags in R6 class definitions.
* Fixed `DESCRIPTION`: corrected `Authors@R` field format.

### New Features

* Added `image_from_plot()`: send ggplot2 or base-R plots directly to
  vision-capable LLMs without manually saving files.
* `create_multimodal_message()` now accepts pre-built content part lists
  in addition to URL strings and local file paths.
* Added file-existence check in `image_from_file()` with a clear error message.

### Documentation

* Comprehensive roxygen2 documentation added for all major functions:
  `OpenAI$new()`, `ChatCompletionsClient$create()`, `EmbeddingsClient$create()`,
  and all multimodal helpers.
* Full parameter tables, return value descriptions, and runnable examples.

---

## openaiR 0.2.1 (2026-03-01)

### Documentation

* Added comprehensive Chinese README with detailed API reference.
* Added QUICKSTART.md guide for new users.

---

## openaiR 0.2.0 (2026-03-01)

### Initial Release

* Chat Completions API (create, retrieve, list, update, delete)
* Embeddings API
* Images API (DALL-E 3/2: generate, edit, variation)
* Audio API (Whisper transcription/translation, TTS)
* Models API (list, retrieve, delete)
* Fine-tuning API (jobs, events, checkpoints)
* Files API
* Moderations API
* Legacy Completions API
* Batch API
* Uploads API
* Assistants API (Beta v2)
* Threads API with Runs and Messages (Beta v2)
* Vector Stores API (Beta v2)
* Responses API (new unified API)
* Streaming support (SSE with callbacks)
* Multimodal helpers (vision/image content)
* Auto-retry with exponential backoff
* Custom base URL support for OpenAI-compatible APIs
