#' Models Client
#'
#' Client for the OpenAI Models API. Allows listing available models,
#' retrieving model details, and deleting fine-tuned models.
#' Access via `client$models`.
#'
#' @section Methods:
#' \describe{
#'   \item{`$list()`}{List all available models}
#'   \item{`$retrieve(model)`}{Get details of a specific model}
#'   \item{`$delete(model)`}{Delete a fine-tuned model you own}
#' }
#'
#' @export
ModelsClient <- R6::R6Class(
  "ModelsClient",
  public = list(
    client = NULL,

    # Initialize models client
    #
    # @param parent Parent OpenAI client
    initialize = function(parent) {
      self$client <- parent
    },

    # @description
    # List all models available to your API key, including base models
    # (e.g. gpt-4o, gpt-3.5-turbo) and any fine-tuned models you have created.
    #
    # @return A list with:
    #   \describe{
    #     \item{`$object`}{Always `"list"`.}
    #     \item{`$data`}{A list of model objects. Each has:
    #       \describe{
    #         \item{`$id`}{Character. The model ID (e.g. `"gpt-4o"`).}
    #         \item{`$object`}{Always `"model"`.}
    #         \item{`$created`}{Integer. Unix timestamp of when the model was created.}
    #         \item{`$owned_by`}{Character. Owner, e.g. `"openai"` or your org ID.}
    #       }
    #     }
    #   }
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # models <- client$models$list()
    #
    # # Print all model IDs
    # for (m in models$data) cat(m$id, "\n")
    #
    # # Filter to GPT-4 models only
    # gpt4_models <- Filter(function(m) startsWith(m$id, "gpt-4"), models$data)
    # cat(sapply(gpt4_models, `[[`, "id"), sep = "\n")
    # }
    list = function() {
      self$client$request("GET", "/models")
    },

    # @description
    # Retrieve details for a specific model by its ID.
    # Useful to confirm a model is accessible before using it.
    #
    # @param model Character. **Required.** The model ID to retrieve.
    #   Examples: `"gpt-4o"`, `"gpt-3.5-turbo"`, `"text-embedding-3-small"`,
    #   `"whisper-1"`, `"dall-e-3"`, or a fine-tuned model ID like
    #   `"ft:gpt-3.5-turbo:org:name:id"`.
    #
    # @return A named list (model object):
    #   \describe{
    #     \item{`$id`}{Character. The model ID.}
    #     \item{`$object`}{Always `"model"`.}
    #     \item{`$created`}{Integer. Unix timestamp.}
    #     \item{`$owned_by`}{Character. Who owns the model.}
    #   }
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # model_info <- client$models$retrieve("gpt-4o")
    # cat("Model:", model_info$id, "\n")
    # cat("Owned by:", model_info$owned_by, "\n")
    # cat("Created:", as.POSIXct(model_info$created, origin = "1970-01-01"), "\n")
    # }
    retrieve = function(model) {
      self$client$request("GET", paste0("/models/", model))
    },

    # @description
    # Delete a fine-tuned model that you own. You can only delete models
    # that you created via fine-tuning. Base OpenAI models cannot be deleted.
    #
    # @param model Character. **Required.** The fine-tuned model ID to delete.
    #   Format: `"ft:gpt-3.5-turbo:org:suffix:id"`.
    #
    # @return A list with:
    #   \describe{
    #     \item{`$id`}{The model ID that was deleted.}
    #     \item{`$object`}{Always `"model"`.}
    #     \item{`$deleted`}{Logical. `TRUE` if deletion was successful.}
    #   }
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # result <- client$models$delete("ft:gpt-3.5-turbo:myorg:my-model:abc123")
    # cat("Deleted:", result$deleted)
    # }
    delete = function(model) {
      self$client$request("DELETE", paste0("/models/", model))
    }
  )
)

#' List Available Models (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and returns all models available to your API key.
#'
#' @return A list with `$data` — a list of model objects, each containing
#'   `$id` (model name string), `$owned_by`, and `$created` (Unix timestamp).
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#'
#' models <- list_models()
#'
#' # Extract all model IDs as a character vector
#' model_ids <- sapply(models$data, `[[`, "id")
#' cat(model_ids, sep = "\n")
#'
#' # Find all embedding models
#' embed_models <- model_ids[grepl("embedding", model_ids)]
#' cat(embed_models, sep = "\n")
#' }
list_models <- function() {
  client <- OpenAI$new()
  client$models$list()
}

#' Retrieve a Model (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and retrieves details for a specific model.
#'
#' @param model Character. **Required.** The model ID to look up.
#'   Examples: `"gpt-4o"`, `"gpt-3.5-turbo"`, `"whisper-1"`,
#'   `"text-embedding-3-small"`, `"dall-e-3"`.
#'
#' @return A named list with model metadata: `$id`, `$object`,
#'   `$created` (Unix timestamp), `$owned_by`.
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#'
#' info <- retrieve_model("gpt-4o")
#' cat("ID:", info$id, "\n")
#' cat("Owner:", info$owned_by, "\n")
#' }
retrieve_model <- function(model) {
  client <- OpenAI$new()
  client$models$retrieve(model)
}

#' Delete a Fine-Tuned Model (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and deletes a fine-tuned model you own.
#' Only models you created via fine-tuning can be deleted.
#'
#' @param model Character. **Required.** The fine-tuned model ID to delete.
#'   Fine-tuned model IDs have the format `"ft:gpt-3.5-turbo:org:suffix:id"`.
#'
#' @return A list with `$id` (the deleted model ID) and
#'   `$deleted` (`TRUE` if successful).
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#'
#' result <- delete_model("ft:gpt-3.5-turbo:myorg:experiment:abc123")
#' if (result$deleted) cat("Model deleted successfully.\n")
#' }
delete_model <- function(model) {
  client <- OpenAI$new()
  client$models$delete(model)
}
