# openaiRtools

<div align="center">

**A Complete R Implementation of the OpenAI API — On Par with the Official Python SDK**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![R >= 4.0](https://img.shields.io/badge/R-%3E%3D%204.0-blue)](https://cran.r-project.org/)

[中文文档 (Chinese Documentation)](README_cn.md)

</div>

---

## Table of Contents

1. [Feature Overview](#feature-overview)
2. [Installation](#installation)
3. [Client Initialization `OpenAI$new()`](#client-initialization)
4. [Chat Completions](#chat-completions)
5. [Streaming](#streaming)
6. [Function Calling](#function-calling)
7. [Multimodal Vision](#multimodal-vision)
8. [Embeddings](#embeddings)
9. [Images (DALL-E)](#images-dall-e)
10. [Audio](#audio)
11. [Model Management](#model-management)
12. [Fine-tuning](#fine-tuning)
13. [File Management](#file-management)
14. [Content Moderation](#content-moderation)
15. [Responses API (New)](#responses-api-new)
16. [Legacy Completions API](#legacy-completions-api)
17. [Error Handling](#error-handling)
18. [Compatibility with Third-party APIs](#compatibility-with-third-party-apis)

---

## Feature Overview

`openaiRtools` provides an R interface that directly maps to the OpenAI Python SDK, covering all major API endpoints:

| Module | Functionality |
|------|------|
| **Chat Completions** | GPT-4o/4/3.5 conversations, streaming, function calling |
| **Embeddings** | Text vectorization with batch support |
| **Images** | DALL-E 3/2 image generation, editing, and variations |
| **Audio** | Whisper speech-to-text and Text-to-Speech (TTS) |
| **Models** | List, retrieve, and delete models |
| **Fine-tuning** | Job management, event tracking, and checkpoints |
| **Files** | Upload, list, retrieve, and delete files |
| **Moderations** | Content safety moderation |
| **Responses API** | Next-gen unified response API for multi-turn conversations |
| **Legacy Completions** | Legacy text completion API |
| **Streaming** | SSE streaming support with callback functions |
| **Multimodal** | Helper functions for mixed image/text inputs |

---

## Installation

```r
# Install from GitHub
install.packages("remotes")
remotes::install_github("xiaoluolorn/openaiRtools")

# Install dependencies (if not already installed)
install.packages(c("httr2", "jsonlite", "rlang", "glue", "R6"))
```

---

## Client Initialization

### `OpenAI$new()` — Create Main Client

This is the entry point for all features. All sub-clients (chat, embeddings, etc.) are accessed through this main client.

#### Function Signature

```r
client <- OpenAI$new(
  api_key      = NULL,   # API Key
  base_url     = NULL,   # API Base URL
  organization = NULL,   # Organization ID (Optional)
  project      = NULL,   # Project ID (Optional)
  timeout      = 600,    # Request timeout (seconds)
  max_retries  = 2       # Maximum retries
)
```

#### Parameters

| Parameter | Type | Default | Description |
|------|------|--------|------|
| `api_key` | `character` | `NULL` | API Key. If NULL, automatically reads the `OPENAI_API_KEY` environment variable. |
| `base_url` | `character` | `"https://api.openai.com/v1"` | API base address. Can be replaced with compatible third-party APIs. |
| `organization` | `character` | `NULL` | OpenAI Organization ID. Corresponds to `OPENAI_ORG_ID`. |
| `project` | `character` | `NULL` | OpenAI Project ID. Corresponds to `OPENAI_PROJECT_ID`. |
| `timeout` | `numeric` | `600` | HTTP request timeout in seconds. Recommended to increase for long text generation. |
| `max_retries` | `integer` | `2` | Maximum retries for temporary errors (429/500/503) using exponential backoff. |

#### Return Value

Returns an `OpenAI` R6 object containing the following sub-client fields:

| Field | Type | Corresponding API |
|------|------|----------|
| `client$chat` | `ChatClient` | Chat Completions |
| `client$embeddings` | `EmbeddingsClient` | Text Embeddings |
| `client$images` | `ImagesClient` | Image Generation |
| `client$audio` | `AudioClient` | Audio Processing |
| `client$models` | `ModelsClient` | Model Management |
| `client$fine_tuning` | `FineTuningClient` | Fine-tuning |
| `client$files` | `FilesClient` | File Management |
| `client$moderations` | `ModerationsClient` | Content Moderation |
| `client$completions` | `CompletionsClient` | Legacy Completions |
| `client$responses` | `ResponsesClient` | Responses API |

#### Usage Example

```r
library(openaiRtools)

# Option 1: Pass key directly
client <- OpenAI$new(api_key = "sk-xxxxxx")

# Option 2: Use environment variables (Recommended)
Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
client <- OpenAI$new()

# Option 3: Connect to compatible third-party APIs (e.g., ModelScope, Azure)
client <- OpenAI$new(
  api_key  = "ms-xxxxxx",
  base_url = "https://api-inference.modelscope.cn/v1",
  timeout  = 600
)

# Option 4: Full parameter configuration
client <- OpenAI$new(
  api_key      = "sk-xxxxxx",
  base_url     = "https://api.openai.com/v1",
  organization = "org-xxxxxxxx",
  project      = "proj-xxxxxxxx",
  timeout      = 300,
  max_retries  = 3
)
```

---

## Chat Completions

> **Access Path**: `client$chat$completions`

### `$create()` — Create Chat Completion

The core function, supporting single/multi-turn conversations, streaming, function calling, and multimodal inputs.

#### Function Signature

```r
response <- client$chat$completions$create(
  messages,
  model                = "gpt-3.5-turbo",
  frequency_penalty    = NULL,
  logit_bias           = NULL,
  logprobs             = NULL,
  top_logprobs         = NULL,
  max_tokens           = NULL,
  max_completion_tokens = NULL,
  n                    = NULL,
  presence_penalty     = NULL,
  response_format      = NULL,
  seed                 = NULL,
  stop                 = NULL,
  stream               = NULL,
  stream_options       = NULL,
  temperature          = NULL,
  top_p                = NULL,
  tools                = NULL,
  tool_choice          = NULL,
  parallel_tool_calls  = NULL,
  user                 = NULL,
  store                = NULL,
  metadata             = NULL,
  callback             = NULL
)
```

#### Input Parameters

| Parameter | Type | Required | Description |
|------|------|------|------|
| `messages` | `list` | ✅ | A list of message objects, each with `role` and `content`. |
| `model` | `character` | ✅ | Model name, e.g., `"gpt-4o"`, `"gpt-4"`, `"gpt-3.5-turbo"`. |
| `temperature` | `numeric` | ❌ | Sampling temperature (0-2). Higher is more random, lower is more deterministic. |
| `top_p` | `numeric` | ❌ | Nucleus sampling (0-1). 0.1 means only tokens in the top 10% probability mass are considered. |
| `max_tokens` | `integer` | ❌ | Maximum tokens to generate (legacy parameter). |
| `max_completion_tokens` | `integer` | ❌ | Maximum tokens to generate (new parameter, includes reasoning tokens). |
| `n` | `integer` | ❌ | Number of chat completion choices to generate for each input message. |
| `stream` | `logical` | ❌ | Enable Server-Sent Events (SSE) streaming. |
| `callback` | `function` | ❌ | Callback function for each chunk in streaming mode (only for `stream=TRUE`). |
| `stop` | `character/list` | ❌ | Up to 4 sequences where the API will stop generating further tokens. |
| `frequency_penalty` | `numeric` | ❌ | Penalize new tokens based on their existing frequency in the text. |
| `presence_penalty` | `numeric` | ❌ | Penalize new tokens based on whether they appear in the text so far. |
| `logit_bias` | `list` | ❌ | Modify the likelihood of specified tokens appearing in the completion. |
| `logprobs` | `logical` | ❌ | Whether to return log probabilities of the output tokens. |
| `top_logprobs` | `integer` | ❌ | Return the N most likely tokens at each position (requires `logprobs=TRUE`). |
| `response_format` | `list` | ❌ | Specify the output format, e.g., `list(type="json_object")`. |
| `seed` | `integer` | ❌ | If specified, the system will make a best effort to sample deterministically. |
| `tools` | `list` | ❌ | A list of tools the model may call (Function Calling). |
| `tool_choice` | `character/list` | ❌ | Tool selection strategy: `"auto"`, `"none"`, `"required"`, or a specific function. |
| `parallel_tool_calls` | `logical` | ❌ | Whether to enable parallel function calling. |
| `user` | `character` | ❌ | A unique identifier representing your end-user for monitoring. |
| `store` | `logical` | ❌ | Whether to persist the completion for later retrieval. |
| `metadata` | `list` | ❌ | Metadata to attach to the stored completion. |

#### `messages` Format

```r
# Single user message
messages <- list(
  list(role = "user", content = "Hello, please introduce yourself")
)

# Multi-turn conversation (includes system prompt and history)
messages <- list(
  list(role = "system",    content = "You are a professional data analysis assistant"),
  list(role = "user",      content = "What is regression analysis?"),
  list(role = "assistant", content = "Regression analysis is a statistical method..."),
  list(role = "user",      content = "Can you provide an R example?")
)
```

#### Return Value Structure

```r
response$id                              # Completion ID, e.g., "chatcmpl-xxxxx"
response$object                          # "chat.completion"
response$created                         # Unix timestamp
response$model                           # Name of the model used
response$choices[[1]]$message$role       # "assistant"
response$choices[[1]]$message$content    # Generated text content
response$choices[[1]]$finish_reason      # Reason for completion: "stop", "length", "tool_calls", etc.
response$usage$prompt_tokens             # Tokens in input
response$usage$completion_tokens         # Tokens in output
response$usage$total_tokens              # Total tokens
```

#### Examples

**Case 1: Basic Conversation**

```r
library(openaiRtools)
client <- OpenAI$new(api_key = "sk-xxxxxx")

response <- client$chat$completions$create(
  messages = list(
    list(role = "user", content = "Explain machine learning in one sentence.")
  ),
  model = "gpt-4o"
)

cat(response$choices[[1]]$message$content)
```

**Case 2: Professional Prompt with System Role**

```r
response <- client$chat$completions$create(
  messages = list(
    list(role = "system", content = "You are an econometrics expert. Answer concisely and professionally."),
    list(role = "user",   content = "Briefly describe the Gauss-Markov assumptions for OLS.")
  ),
  model       = "gpt-4o",
  temperature = 0.3,      # Low temperature for academic accuracy
  max_tokens  = 500
)

cat(response$choices[[1]]$message$content)
```

**Case 3: JSON Output**

```r
response <- client$chat$completions$create(
  messages = list(
    list(role = "user", content = "List 3 ML algorithms in JSON format with 'name' and 'use_case' fields.")
  ),
  model           = "gpt-4o",
  response_format = list(type = "json_object")
)

# Parse JSON
result <- jsonlite::fromJSON(response$choices[[1]]$message$content)
print(result)
```

**Case 4: Multi-turn Conversation Management**

```r
# Maintain history
history <- list(
  list(role = "system", content = "You are an R programming assistant")
)

# Round 1
history <- c(history, list(list(role = "user", content = "How to read a CSV file?")))
r1 <- client$chat$completions$create(messages = history, model = "gpt-4o")
assistant_reply <- r1$choices[[1]]$message$content
history <- c(history, list(list(role = "assistant", content = assistant_reply)))
cat("Assistant:", assistant_reply, "\n")

# Round 2 (Context automatically included)
history <- c(history, list(list(role = "user", content = "What if the file is very large?")))
r2 <- client$chat$completions$create(messages = history, model = "gpt-4o")
cat("Assistant:", r2$choices[[1]]$message$content, "\n")
```

**Case 5: Generating Multiple Candidates**

```r
response <- client$chat$completions$create(
  messages = list(list(role = "user", content = "Suggest a title for an article about AI.")),
  model    = "gpt-4o",
  n        = 3,           # Generate 3 candidates
  temperature = 1.2       # High temperature for diversity
)

for (i in seq_along(response$choices)) {
  cat(sprintf("Candidate %d: %s\n", i, response$choices[[i]]$message$content))
}
```

---

### `$retrieve()` — Retrieve Stored Completion

```r
# Requires create with store=TRUE
stored <- client$chat$completions$retrieve(completion_id = "chatcmpl-xxxxx")
cat(stored$choices[[1]]$message$content)
```

---

### `$list()` — List Stored Completions

```r
completions <- client$chat$completions$list(
  model  = "gpt-4o",   # Optional filter
  limit  = 20,         # Max 100
  order  = "desc"
)

for (c in completions$data) {
  cat(c$id, "-", c$model, "\n")
}
```

---

### `$update()` — Update Metadata

```r
client$chat$completions$update(
  completion_id = "chatcmpl-xxxxx",
  metadata      = list(project = "ResearchA", version = "v2")
)
```

---

### `$delete()` — Delete Completion

```r
client$chat$completions$delete(completion_id = "chatcmpl-xxxxx")
```

---

### Convenience Function `create_chat_completion()`

Allows calling the API without manually creating a client (reads `OPENAI_API_KEY` environment variable):

```r
response <- create_chat_completion(
  messages = list(list(role = "user", content = "Hello!")),
  model    = "gpt-4o"
)
cat(response$choices[[1]]$message$content)
```

---

## Streaming

Streaming allows the model to return content word by word, improving user experience for long text generation.

### Method 1: Use `callback` (Recommended)

```r
client$chat$completions$create(
  messages = list(list(role = "user", content = "Write a 200-word tech news article.")),
  model    = "gpt-4o",
  stream   = TRUE,
  callback = function(chunk) {
    # Each chunk contains 'delta' (incremental content)
    content <- chunk$choices[[1]]$delta$content
    if (!is.null(content)) cat(content, sep = "")
  }
)
cat("\n")
```

**Chunk Structure:**

```r
chunk$id                              # Chunk ID
chunk$choices[[1]]$delta$role        # Only the first chunk contains "assistant"
chunk$choices[[1]]$delta$content     # Current incremental text
chunk$choices[[1]]$finish_reason     # Only the last chunk contains "stop" or "length"
```

### Method 2: Aggregate Without Callback

When `stream=TRUE` and no `callback` is provided, the function automatically collects all chunks and returns a response identical in format to non-streaming mode:

```r
response <- client$chat$completions$create(
  messages = list(list(role = "user", content = "Tell me a story")),
  model    = "gpt-4o",
  stream   = TRUE
)

# Same access as non-streaming
cat(response$choices[[1]]$message$content)
```

### StreamIterator Methods

| Method | Description |
|------|------|
| `iter$get_full_text()` | Concatenates all delta content into a full string. |
| `iter$next_chunk()` | Gets the next chunk. |
| `iter$has_more()` | Whether there are more chunks. |
| `iter$reset()` | Resets the iterator to the beginning. |
| `iter$as_list()` | Returns all chunks as a list. |

---

## Function Calling

Enables the model to call your predefined functions, a core mechanism for building AI Agents.

### Tool Definition Format

```r
tools <- list(
  list(
    type     = "function",
    `function` = list(
      name        = "get_gdp_data",
      description = "Get GDP data for a country and year",
      parameters  = list(
        type       = "object",
        properties = list(
          country = list(type = "string", description = "Country name, e.g., 'USA'"),
          year    = list(type = "integer", description = "Year, e.g., 2023")
        ),
        required = list("country", "year")
      )
    )
  )
)
```

### Calling Workflow

1.  **Send request with tool definitions.**
2.  **Check if the model called a tool.**
3.  **Execute the real function in R.**
4.  **Send results back to the model.**

```r
# Full workflow example available in package documentation
```

---

## Multimodal Vision

### Helper Functions

- `image_from_url(url, detail)`
- `image_from_file(file_path, mime_type, detail)`
- `create_multimodal_message(text, images, detail)`

### Analysis Example

```r
msg <- create_multimodal_message(
  text   = "Analyze the trend in this economic chart.",
  images = list("chart.png")
)

response <- client$chat$completions$create(messages = list(msg), model = "gpt-4o")
cat(response$choices[[1]]$message$content)
```

---

## Embeddings

> **Access Path**: `client$embeddings`

### `$create()` — Create Embeddings

```r
response <- client$embeddings$create(
  input = "Application of LLMs in Economics",
  model = "text-embedding-3-small"
)

vec <- response$data[[1]]$embedding
```

---

## Images (DALL-E)

> **Access Path**: `client$images`

### `$create()` — Generate Images

```r
response <- client$images$create(
  prompt = "Minimalist data visualization plot",
  model  = "dall-e-3",
  size   = "1024x1024"
)

download.file(response$data[[1]]$url, "output.png", mode = "wb")
```

---

## Audio

> **Access Path**: `client$audio`

- **Transcription**: `client$audio$transcriptions$create()`
- **Translation**: `client$audio$translations$create()`
- **Speech (TTS)**: `client$audio$speech$create()`

---

## Model Management

> **Access Path**: `client$models`

- **List**: `client$models$list()`
- **Retrieve**: `client$models$retrieve("gpt-4o")`
- **Delete**: `client$models$delete("custom-model-id")`

---

## Fine-tuning

> **Access Path**: `client$fine_tuning$jobs`

Comprehensive management for fine-tuning jobs, events, and checkpoints.

---

## File Management

> **Access Path**: `client$files`

Manage files for fine-tuning, assistants, and batch processing.

---

## Content Moderation

Detect policy violations across categories like hate, violence, and self-harm.

---

## Responses API (New)

A unified next-gen API for simplified conversation flows.

---

## Error Handling

Handles `openai_api_error` (HTTP issues) and `openai_connection_error` (network issues) with descriptive messages.

---

## Compatibility with Third-party APIs

Connect to any OpenAI-compatible API (e.g., DeepSeek, ModelScope) by simply overriding `base_url`.

---

## Author

**Chaoyang Luo**  
GitHub: [@xiaoluolorn](https://github.com/xiaoluolorn)

## License

MIT License © 2024
