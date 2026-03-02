#' Moderations Client
#'
#' Client for the OpenAI Moderations API. Classifies text (and optionally
#' images) for potentially harmful content according to OpenAI's usage policies.
#' Access via `client$moderations`.
#'
#' The API returns a set of category flags and confidence scores. It is free
#' to use and does not count against your token quota.
#'
#' @section Detected categories:
#' `hate`, `hate/threatening`, `harassment`, `harassment/threatening`,
#' `self-harm`, `self-harm/intent`, `self-harm/instructions`,
#' `sexual`, `sexual/minors`, `violence`, `violence/graphic`.
#'
#' @export
ModerationsClient <- R6::R6Class(
  "ModerationsClient",
  public = list(
    client = NULL,

    # Initialize moderations client
    #
    # @param parent Parent OpenAI client
    initialize = function(parent) {
      self$client <- parent
    },

    # @description
    # Classify text (or images) for potentially harmful content.
    # Returns per-category flags and confidence scores. Free to use.
    #
    # @param input **[Required]** The content to moderate. Can be:
    #   \itemize{
    #     \item A character string — single text input.
    #     \item A list of strings — batch moderation of multiple texts.
    #     \item For `omni-moderation-latest`: a list of content objects
    #       mixing text and image parts (see OpenAI docs for multimodal format).
    #   }
    #   Example (single): `"I want to hurt someone."`
    #   Example (batch): `list("Hello!", "I hate you.")`
    #
    # @param model Character. The moderation model to use:
    #   \itemize{
    #     \item `"omni-moderation-latest"` — Latest multimodal model.
    #       Supports both text and image inputs. More accurate.
    #     \item `"text-moderation-latest"` — Text-only. Stable alias.
    #     \item `"text-moderation-stable"` — Older text-only model.
    #   }
    #   Default: `"omni-moderation-latest"`.
    #
    # @return A named list:
    #   \describe{
    #     \item{`$id`}{Character. Unique moderation request ID.}
    #     \item{`$model`}{Character. The model used.}
    #     \item{`$results`}{A list of result objects (one per input item).
    #       Each result contains:
    #       \describe{
    #         \item{`$flagged`}{Logical. `TRUE` if the content violates policy.}
    #         \item{`$categories`}{Named list of booleans for each category
    #           (e.g. `$categories$hate`, `$categories$violence`).}
    #         \item{`$category_scores`}{Named list of confidence scores (0–1)
    #           for each category. Higher = more likely harmful.}
    #       }
    #     }
    #   }
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    #
    # # Check a single text
    # result <- client$moderations$create("I want to buy a gun.")
    # cat("Flagged:", result$results[[1]]$flagged, "\n")
    # cat("Violence score:", result$results[[1]]$category_scores$violence, "\n")
    #
    # # Batch check multiple texts
    # result <- client$moderations$create(
    #   input = list("Hello, how are you?", "I will destroy everything!"),
    #   model = "omni-moderation-latest"
    # )
    # for (i in seq_along(result$results)) {
    #   cat("Text", i, "- Flagged:", result$results[[i]]$flagged, "\n")
    # }
    #
    # # Check which categories triggered
    # r <- result$results[[2]]
    # flagged_cats <- names(Filter(isTRUE, r$categories))
    # cat("Flagged categories:", paste(flagged_cats, collapse = ", "), "\n")
    # }
    create = function(input, model = "omni-moderation-latest") {
      body <- list(
        input = input,
        model = model
      )

      self$client$request("POST", "/moderations", body = body)
    }
  )
)

#' Check Content for Policy Violations (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and calls `client$moderations$create()`.
#'
#' This API is **free** and does not consume tokens. Use it to screen
#' user-generated content before passing it to other APIs.
#'
#' @param input **Required.** A character string or list of strings to moderate.
#'   Example: `"Kill all humans"` or `list("Hello", "I hate you")`.
#' @param model Character. Moderation model to use:
#'   `"omni-moderation-latest"` (default, supports images) or
#'   `"text-moderation-latest"`.
#'
#' @return A list with `$results` — a list of result objects, one per input.
#'   Each result has:
#'   \itemize{
#'     \item `$flagged` — Logical, `TRUE` if content violates policy
#'     \item `$categories` — Named list of boolean flags per category
#'     \item `$category_scores` — Named list of scores (0–1) per category
#'   }
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#'
#' # Quick single-text check
#' result <- create_moderation("I love everyone!")
#' cat("Flagged:", result$results[[1]]$flagged) # FALSE
#'
#' # Screen multiple texts from user input
#' texts <- list("normal message", "harmful content example")
#' result <- create_moderation(texts)
#' for (i in seq_along(result$results)) {
#'   cat("Text", i, "flagged:", result$results[[i]]$flagged, "\n")
#' }
#' }
create_moderation <- function(input, model = "omni-moderation-latest") {
  client <- OpenAI$new()
  client$moderations$create(input = input, model = model)
}
