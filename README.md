# openaiR

<div align="center">

**Complete R implementation of OpenAI Python SDK**

[![CRAN Status](https://www.r-pkg.org/badges/version/openaiR)](https://cran.r-project.org/package=openaiR)
[![R-CMD-check](https://github.com/xiaoluolorn/openaiR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/xiaoluolorn/openaiR/actions/workflows/R-CMD-check.yaml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

</div>

## Features

`openaiR` provides full compatibility with the OpenAI Python SDK, including:

- ✅ **Chat Completions** - GPT-4o, GPT-4, GPT-3.5-Turbo (create, retrieve, list, update, delete)
- ✅ **Embeddings** - Text embedding models
- ✅ **Images** - DALL-E 3 and DALL-E 2 (generate, edit, variation)
- ✅ **Audio** - Whisper transcriptions, translations, and TTS
- ✅ **Models** - List, retrieve, and delete models
- ✅ **Fine-tuning** - Jobs, events, and checkpoints
- ✅ **Files** - Upload, list, retrieve, delete, and content
- ✅ **Moderations** - Content moderation
- ✅ **Completions** - Legacy completions API
- ✅ **Batch** - Batch processing API
- ✅ **Uploads** - Large file upload in parts
- ✅ **Assistants** - AI assistants (Beta v2)
- ✅ **Threads** - Conversation threads with runs and messages (Beta v2)
- ✅ **Vector Stores** - File search with vector stores (Beta v2)
- ✅ **Responses** - New unified response API
- ✅ **Streaming** - Server-Sent Events (SSE) streaming
- ✅ **Multimodal** - Vision and image content helpers
- ✅ **Auto-retry** - Automatic retry with exponential backoff
- ✅ **Custom Base URL** - Compatible with OpenAI-format APIs

## Installation

### From GitHub

```r
# Install remotes if you haven't already
install.packages("remotes")

# Install openaiR from GitHub
remotes::install_github("xiaoluolorn/openaiR")
```

### From CRAN (Coming Soon)

```r
install.packages("openaiR")
```

## Quick Start

### Setup

```r
library(openaiR)

# Initialize client with API key
client <- OpenAI$new(api_key = "your-api-key-here")

# Or set environment variable (recommended)
Sys.setenv(OPENAI_API_KEY = "your-api-key-here")
client <- OpenAI$new()

# With custom options
client <- OpenAI$new(
  api_key = "your-key",
  base_url = "https://api.openai.com/v1",  # or compatible API
  organization = "org-123",
  project = "proj-456",
  timeout = 600,
  max_retries = 2
)
```

### Chat Completions

```r
# Using the client object
response <- client$chat$completions$create(
  messages = list(
    list(role = "user", content = "Hello, how are you?")
  ),
  model = "gpt-4o"
)

print(response$choices[[1]]$message$content)

# With stored completions
response <- client$chat$completions$create(
  messages = list(list(role = "user", content = "Hello")),
  model = "gpt-4o",
  store = TRUE
)

# Retrieve a stored completion
stored <- client$chat$completions$retrieve(response$id)

# List stored completions
completions <- client$chat$completions$list(model = "gpt-4o", limit = 10)

# Or using convenience function
response <- create_chat_completion(
  messages = list(
    list(role = "user", content = "What is R?")
  ),
  model = "gpt-3.5-turbo"
)
```

### Embeddings

```r
# Create embeddings
response <- client$embeddings$create(
  input = "The quick brown fox jumps over the lazy dog",
  model = "text-embedding-ada-002"
)

# Access embedding vector
embedding <- response$data[[1]]$embedding
print(length(embedding))  # Vector dimension
```

### Images (DALL-E)

```r
# Generate image
response <- client$images$create(
  prompt = "A cute baby sea otter in a spacesuit",
  model = "dall-e-3",
  size = "1024x1024",
  quality = "hd"
)

# Get image URL
print(response$data[[1]]$url)

# Edit an image
response <- client$images$edit(
  image = "original.png",
  prompt = "Add a red hat",
  mask = "mask.png"
)
```

### Audio

```r
# Transcribe audio file
transcription <- client$audio$transcriptions$create(
  file = "recording.mp3",
  model = "whisper-1"
)

print(transcription$text)

# Text-to-speech
audio_data <- client$audio$speech$create(
  input = "Hello, this is a test of text to speech.",
  model = "tts-1",
  voice = "alloy"
)

# Save audio file
writeBin(audio_data, "speech.mp3")
```

### Models

```r
# List available models
models <- client$models$list()
print(models$data)

# Get specific model details
model <- client$models$retrieve("gpt-4")
print(model)
```

### Fine-tuning

```r
# Create fine-tuning job
job <- client$fine_tuning$jobs$create(
  training_file = "file-abc123",
  model = "gpt-3.5-turbo"
)

print(job$id)

# List fine-tuning jobs
jobs <- client$fine_tuning$jobs$list()

# Get job status
job_status <- client$fine_tuning$jobs$retrieve(job$id)

# List checkpoints
checkpoints <- client$fine_tuning$jobs$checkpoints$list(job$id)
```

### Responses API (New)

```r
# Create a response
response <- client$responses$create(
  model = "gpt-4o",
  input = "Write a haiku about R programming"
)

# Multi-turn conversation
response2 <- client$responses$create(
  model = "gpt-4o",
  input = "Make it more technical",
  previous_response_id = response$id
)
```

## Advanced Usage

### Streaming Responses

```r
# Stream with callback
client$chat$completions$create(
  messages = list(
    list(role = "user", content = "Tell me a story")
  ),
  model = "gpt-4o",
  stream = TRUE,
  callback = function(chunk) {
    content <- chunk$choices[[1]]$delta$content
    if (!is.null(content)) cat(content)
  }
)

# Stream without callback - returns iterator
iter <- client$chat$completions$create(
  messages = list(list(role = "user", content = "Count to 10")),
  model = "gpt-4o",
  stream = TRUE
)

# Get full text from iterator
full_text <- iter$get_full_text()
cat(full_text)
```

### Function Calling

```r
tools <- list(
  list(
    type = "function",
    function = list(
      name = "get_weather",
      description = "Get current weather for a location",
      parameters = list(
        type = "object",
        properties = list(
          location = list(
            type = "string",
            description = "City name"
          )
        ),
        required = list("location")
      )
    )
  )
)

response <- client$chat$completions$create(
  messages = list(
    list(role = "user", content = "What's the weather in Boston?")
  ),
  model = "gpt-4o",
  tools = tools
)
```

### Multimodal (Vision)

```r
# Using helper functions
msg <- create_multimodal_message(
  text = "Describe this image",
  images = list("https://example.com/image.jpg")
)

response <- client$chat$completions$create(
  messages = list(msg),
  model = "gpt-4o"
)

# Or use local files
msg <- create_multimodal_message(
  text = "What do you see?",
  images = list("path/to/image.jpg")
)
```

### Custom Base URL (Compatible APIs)

```r
# Use with OpenAI-compatible APIs
client <- OpenAI$new(
  api_key = "your-key",
  base_url = "https://custom-api.com/v1"
)
```

## Configuration

### Environment Variables

- `OPENAI_API_KEY` - Your OpenAI API key (required)
- `OPENAI_ORG_ID` - Organization ID (optional)
- `OPENAI_PROJECT_ID` - Project ID (optional)

## Error Handling

```r
tryCatch(
  {
    response <- client$chat$completions$create(
      messages = list(list(role = "user", content = "Test")),
      model = "gpt-4"
    )
  },
  openai_api_error = function(e) {
    cat("API Error:", e$message, "\n")
    cat("Status Code:", e$status_code, "\n")
  },
  openai_connection_error = function(e) {
    cat("Connection Error:", e$message, "\n")
  },
  error = function(e) {
    cat("General Error:", e$message, "\n")
  }
)
```

## Testing

```r
# Run all tests
devtools::test()

# Run specific test file
testthat::test_file("tests/testthat/test-chat.R")
```

## Development

### Prerequisites

- R >= 4.0.0
- RStudio (recommended)

### Dependencies

- `httr2` - HTTP requests
- `jsonlite` - JSON parsing
- `rlang` - Error handling
- `glue` - String interpolation
- `R6` - Object-oriented programming

### Build from Source

```r
# Install dependencies
install.packages(c("httr2", "jsonlite", "rlang", "glue", "R6", "devtools"))

# Build package
devtools::load_all()

# Build documentation
devtools::document()

# Run checks
devtools::check()
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- OpenAI for their excellent API and Python SDK
- The R community for amazing packages

## Support

- **GitHub Issues**: [Report bugs or request features](https://github.com/xiaoluolorn/openaiR/issues)
- **Documentation**: [Full API documentation](https://xiaoluolorn.github.io/openaiR/)

## Author

**Xiaoluo Orn**
- GitHub: [@xiaoluolorn](https://github.com/xiaoluolorn)
- Email: xiaoluolorn@example.com
