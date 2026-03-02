#' Fine-tuning Client
#'
#' Top-level client for the OpenAI Fine-tuning API. Fine-tuning lets you
#' train a custom version of a GPT model on your own examples.
#' Access via `client$fine_tuning`.
#'
#' @section Sub-clients:
#' \describe{
#'   \item{`$jobs`}{[FineTuningJobsClient] — Create and manage fine-tuning jobs}
#' }
#'
#' @section Workflow:
#' 1. Upload training data (JSONL file) via `client$files$create(purpose = "fine-tune")`
#' 2. Create a fine-tuning job with `client$fine_tuning$jobs$create()`
#' 3. Monitor progress with `client$fine_tuning$jobs$retrieve()` or `$list_events()`
#' 4. Use the resulting model ID in chat completions once status is `"succeeded"`
#'
#' @export
FineTuningClient <- R6::R6Class(
  "FineTuningClient",
  public = list(
    client = NULL,

    # Field: jobs Fine-tuning jobs interface
    jobs = NULL,

    # Initialize fine-tuning client
    #
    # @param parent Parent OpenAI client
    initialize = function(parent) {
      self$client <- parent
      self$jobs <- FineTuningJobsClient$new(parent)
    }
  )
)

#' Fine-tuning Jobs Client
#'
#' Manage fine-tuning jobs — create, list, retrieve, cancel, and monitor events.
#' Access via `client$fine_tuning$jobs`.
#'
#' @export
FineTuningJobsClient <- R6::R6Class(
  "FineTuningJobsClient",
  public = list(
    client = NULL,

    # Field: checkpoints Checkpoints sub-client
    checkpoints = NULL,
    initialize = function(parent) {
      self$client <- parent
      self$checkpoints <- FineTuningCheckpointsClient$new(parent)
    },

    # @description
    # Create a fine-tuning job to train a custom version of a GPT model.
    # The training file must have been already uploaded via the Files API
    # with `purpose = "fine-tune"`.
    #
    # @param training_file Character. **Required.** The file ID of the
    #   training data JSONL file (e.g. `"file-abc123"`). Must have been
    #   uploaded with `purpose = "fine-tune"`. Each line must be in the format:
    #   \preformatted{
    #   {"messages": [{"role": "system", "content": "..."},
    #                 {"role": "user",   "content": "..."},
    #                 {"role": "assistant", "content": "..."}]}
    #   }
    #   Minimum recommended examples: 10 (ideally 50–100+).
    #
    # @param model Character. The base model to fine-tune:
    #   \itemize{
    #     \item `"gpt-3.5-turbo"` — Most cost-effective for fine-tuning
    #     \item `"gpt-4o-mini"` — Good balance of capacity and cost
    #     \item `"gpt-4o"` — Highest capability, most expensive
    #     \item `"davinci-002"`, `"babbage-002"` — Legacy base models
    #   }
    #   Default: `"gpt-3.5-turbo"`.
    #
    # @param hyperparameters List or NULL. Fine-tuning hyperparameters:
    #   \itemize{
    #     \item `$n_epochs` — Integer or `"auto"`. Number of training epochs.
    #       `"auto"` (default) selects based on dataset size.
    #     \item `$batch_size` — Integer or `"auto"`. Training batch size.
    #     \item `$learning_rate_multiplier` — Numeric or `"auto"`.
    #       Multiplier applied to the base learning rate.
    #   }
    #   Example: `list(n_epochs = 3, batch_size = "auto")`.
    #   Default: NULL (all `"auto"`).
    #
    # @param suffix Character or NULL. A suffix (1–18 lowercase alphanumeric
    #   characters) appended to the fine-tuned model name.
    #   Example: `"my-model"` → model name becomes
    #   `"ft:gpt-3.5-turbo:org:my-model:abc123"`.
    #   Default: NULL.
    #
    # @param validation_file Character or NULL. File ID of a validation
    #   JSONL file (same format as training file). If provided, metrics
    #   on the validation set are computed during training.
    #   Default: NULL.
    #
    # @param integrations List or NULL. Third-party integrations to enable
    #   during training (e.g., Weights & Biases). Default: NULL.
    #
    # @param seed Integer or NULL. Random seed for reproducibility.
    #   Default: NULL.
    #
    # @param method Character or NULL. Fine-tuning method:
    #   `"supervised"` (default) or `"dpo"` (Direct Preference Optimization).
    #   Default: NULL (API default `"supervised"`).
    #
    # @return A fine-tuning job object:
    #   \describe{
    #     \item{`$id`}{Character. Job ID (e.g. `"ftjob-abc123"`).}
    #     \item{`$status`}{Character. Current status: `"validating_files"`,
    #       `"queued"`, `"running"`, `"succeeded"`, `"failed"`, `"cancelled"`.}
    #     \item{`$model`}{Character. The base model used.}
    #     \item{`$fine_tuned_model`}{Character or NULL. The resulting model ID,
    #       set only when status is `"succeeded"`.}
    #     \item{`$created_at`}{Integer. Unix timestamp.}
    #     \item{`$trained_tokens`}{Integer or NULL. Tokens used in training.}
    #   }
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    #
    # # Step 1: Upload training data
    # file_obj <- client$files$create("training.jsonl", purpose = "fine-tune")
    # client$files$wait_for_processing(file_obj$id)
    #
    # # Step 2: Create fine-tuning job
    # job <- client$fine_tuning$jobs$create(
    #   training_file   = file_obj$id,
    #   model           = "gpt-3.5-turbo",
    #   suffix          = "economics-qa",
    #   hyperparameters = list(n_epochs = 3)
    # )
    # cat("Job ID:", job$id, "\n")
    # cat("Status:", job$status, "\n")
    #
    # # Step 3: Wait and check
    # repeat {
    #   job <- client$fine_tuning$jobs$retrieve(job$id)
    #   cat("Status:", job$status, "\n")
    #   if (job$status %in% c("succeeded", "failed", "cancelled")) break
    #   Sys.sleep(30)
    # }
    # if (job$status == "succeeded") {
    #   cat("Model ready:", job$fine_tuned_model, "\n")
    # }
    # }
    create = function(training_file, model = "gpt-3.5-turbo",
                      hyperparameters = NULL,
                      suffix = NULL,
                      validation_file = NULL,
                      integrations = NULL,
                      seed = NULL,
                      method = NULL) {
      body <- list(
        training_file = training_file,
        model = model
      )

      if (!is.null(hyperparameters)) body$hyperparameters <- hyperparameters
      if (!is.null(suffix)) body$suffix <- suffix
      if (!is.null(validation_file)) body$validation_file <- validation_file
      if (!is.null(integrations)) body$integrations <- integrations
      if (!is.null(seed)) body$seed <- seed
      if (!is.null(method)) body$method <- method

      self$client$request("POST", "/fine_tuning/jobs", body = body)
    },

    # @description
    # List fine-tuning jobs for your account, ordered by creation time
    # (most recent first).
    #
    # @param after Character or NULL. Pagination cursor — the job ID of the
    #   last item from the previous page. Default: NULL.
    #
    # @param limit Integer or NULL. Maximum number of jobs to return.
    #   Default: NULL (API default 20).
    #
    # @return A list with `$data` — a list of fine-tuning job objects.
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # jobs <- client$fine_tuning$jobs$list(limit = 10)
    # for (j in jobs$data) cat(j$id, "-", j$status, "\n")
    # }
    list = function(after = NULL, limit = NULL) {
      query <- list()
      if (!is.null(after)) query$after <- after
      if (!is.null(limit)) query$limit <- limit

      self$client$request("GET", "/fine_tuning/jobs", query = query)
    },

    # @description
    # Retrieve the current state of a specific fine-tuning job.
    # Poll this periodically to monitor training progress.
    #
    # @param fine_tuning_job_id Character. **Required.** The fine-tuning job ID
    #   (e.g. `"ftjob-abc123"`).
    #
    # @return A fine-tuning job object (see `$create()` return value).
    #   Check `$status` for progress and `$fine_tuned_model` for the
    #   resulting model ID once training completes.
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # job <- client$fine_tuning$jobs$retrieve("ftjob-abc123")
    # cat("Status:", job$status, "\n")
    # if (!is.null(job$fine_tuned_model)) {
    #   cat("Model:", job$fine_tuned_model, "\n")
    # }
    # }
    retrieve = function(fine_tuning_job_id) {
      self$client$request("GET", paste0("/fine_tuning/jobs/", fine_tuning_job_id))
    },

    # @description
    # Cancel a running or queued fine-tuning job. Cancelled jobs cannot
    # be resumed.
    #
    # @param fine_tuning_job_id Character. **Required.** The job ID to cancel.
    #
    # @return The cancelled fine-tuning job object with `$status = "cancelled"`.
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # cancelled_job <- client$fine_tuning$jobs$cancel("ftjob-abc123")
    # cat("Status:", cancelled_job$status)  # "cancelled"
    # }
    cancel = function(fine_tuning_job_id) {
      self$client$request("POST", paste0("/fine_tuning/jobs/", fine_tuning_job_id, "/cancel"))
    },

    # @description
    # List events (log entries) produced during a fine-tuning job.
    # Events include step-level training metrics (loss, learning rate)
    # and status change notifications.
    #
    # @param fine_tuning_job_id Character. **Required.** The job ID.
    #
    # @param after Character or NULL. Pagination cursor. Default: NULL.
    #
    # @param limit Integer or NULL. Maximum number of events to return.
    #   Default: NULL (API default 20).
    #
    # @return A list with `$data` — a list of event objects. Each has:
    #   \describe{
    #     \item{`$message`}{Character. Human-readable event description.}
    #     \item{`$level`}{Character. `"info"`, `"warn"`, or `"error"`.}
    #     \item{`$created_at`}{Integer. Unix timestamp.}
    #   }
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # events <- client$fine_tuning$jobs$list_events("ftjob-abc123", limit = 20)
    # for (e in events$data) cat(e$message, "\n")
    # }
    list_events = function(fine_tuning_job_id, after = NULL, limit = NULL) {
      query <- list()
      if (!is.null(after)) query$after <- after
      if (!is.null(limit)) query$limit <- limit

      self$client$request(
        "GET",
        paste0("/fine_tuning/jobs/", fine_tuning_job_id, "/events"),
        query = query
      )
    }
  )
)

#' Fine-tuning Checkpoints Client
#'
#' Retrieves intermediate model checkpoints created during fine-tuning.
#' A checkpoint is saved after each training epoch. Access via
#' `client$fine_tuning$jobs$checkpoints`.
#'
#' @export
FineTuningCheckpointsClient <- R6::R6Class(
  "FineTuningCheckpointsClient",
  public = list(
    client = NULL,

    # Initialize checkpoints client
    #
    # @param parent Parent OpenAI client
    initialize = function(parent) {
      self$client <- parent
    },

    # @description
    # List checkpoints for a fine-tuning job.
    # Each checkpoint represents the model state after one training epoch.
    # You can use checkpoint model IDs directly for inference.
    #
    # @param fine_tuning_job_id Character. **Required.** The job ID.
    #
    # @param after Character or NULL. Pagination cursor. Default: NULL.
    #
    # @param limit Integer or NULL. Maximum number of checkpoints to return.
    #   Default: NULL (API default 10).
    #
    # @return A list with `$data` — a list of checkpoint objects. Each has:
    #   \describe{
    #     \item{`$id`}{Character. Checkpoint ID.}
    #     \item{`$fine_tuned_model_checkpoint`}{Character. Usable model ID
    #       for this checkpoint.}
    #     \item{`$step_number`}{Integer. Training step number.}
    #     \item{`$metrics`}{List. Training metrics: `$train_loss`,
    #       `$valid_loss`, `$full_valid_loss`, etc.}
    #   }
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    # cps <- client$fine_tuning$jobs$checkpoints$list("ftjob-abc123")
    # for (cp in cps$data) {
    #   cat("Step:", cp$step_number,
    #       "- Train loss:", cp$metrics$train_loss, "\n")
    # }
    # }
    list = function(fine_tuning_job_id, after = NULL, limit = NULL) {
      query <- list()
      if (!is.null(after)) query$after <- after
      if (!is.null(limit)) query$limit <- limit

      self$client$request(
        "GET",
        paste0("/fine_tuning/jobs/", fine_tuning_job_id, "/checkpoints"),
        query = query
      )
    }
  )
)

#' Create a Fine-tuning Job (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and calls `client$fine_tuning$jobs$create()`.
#'
#' @param training_file Character. **Required.** File ID of the uploaded
#'   training JSONL file (e.g. from `upload_file(..., purpose = "fine-tune")`).
#' @param model Character. Base model to fine-tune:
#'   `"gpt-3.5-turbo"`, `"gpt-4o-mini"`, `"gpt-4o"`, etc.
#'   Default: `"gpt-3.5-turbo"`.
#' @param ... Additional parameters passed to [FineTuningJobsClient]`$create()`,
#'   such as `suffix`, `hyperparameters` (list with `n_epochs`, `batch_size`),
#'   `validation_file`, `seed`.
#'
#' @return A fine-tuning job object with `$id` and `$status`.
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#'
#' job <- create_fine_tuning_job(
#'   training_file   = "file-abc123",
#'   model           = "gpt-3.5-turbo",
#'   suffix          = "my-assistant",
#'   hyperparameters = list(n_epochs = 3)
#' )
#' cat("Job ID:", job$id)
#' }
create_fine_tuning_job <- function(training_file, model = "gpt-3.5-turbo", ...) {
  client <- OpenAI$new()
  client$fine_tuning$jobs$create(training_file = training_file, model = model, ...)
}

#' List Fine-tuning Jobs (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and lists fine-tuning jobs.
#'
#' @param ... Additional parameters passed to [FineTuningJobsClient]`$list()`,
#'   such as `limit` (max jobs to return) and `after` (pagination cursor).
#'
#' @return A list with `$data` — a list of fine-tuning job objects, each
#'   containing `$id`, `$status`, `$model`, `$fine_tuned_model`.
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#'
#' jobs <- list_fine_tuning_jobs(limit = 5)
#' for (j in jobs$data) cat(j$id, "-", j$status, "\n")
#' }
list_fine_tuning_jobs <- function(...) {
  client <- OpenAI$new()
  client$fine_tuning$jobs$list(...)
}

#' Retrieve a Fine-tuning Job (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and retrieves a specific fine-tuning job.
#'
#' @param fine_tuning_job_id Character. **Required.** The fine-tuning job ID
#'   (e.g. `"ftjob-abc123"`).
#'
#' @return A fine-tuning job object with `$status`, `$model`, and
#'   `$fine_tuned_model` (the resulting model ID when status is `"succeeded"`).
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#'
#' job <- retrieve_fine_tuning_job("ftjob-abc123")
#' cat("Status:", job$status)
#' if (job$status == "succeeded") cat("Model:", job$fine_tuned_model)
#' }
retrieve_fine_tuning_job <- function(fine_tuning_job_id) {
  client <- OpenAI$new()
  client$fine_tuning$jobs$retrieve(fine_tuning_job_id)
}

#' Cancel a Fine-tuning Job (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and cancels a running or queued fine-tuning job.
#'
#' @param fine_tuning_job_id Character. **Required.** The job ID to cancel.
#'
#' @return The fine-tuning job object with `$status = "cancelled"`.
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#'
#' result <- cancel_fine_tuning_job("ftjob-abc123")
#' cat("Status:", result$status) # "cancelled"
#' }
cancel_fine_tuning_job <- function(fine_tuning_job_id) {
  client <- OpenAI$new()
  client$fine_tuning$jobs$cancel(fine_tuning_job_id)
}

#' List Fine-tuning Events (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and lists training events for a fine-tuning job.
#' Events include per-step training loss metrics and status messages.
#'
#' @param fine_tuning_job_id Character. **Required.** The fine-tuning job ID.
#' @param ... Additional parameters passed to [FineTuningJobsClient]`$list_events()`,
#'   such as `limit` (max events to return) and `after` (pagination cursor).
#'
#' @return A list with `$data` — a list of event objects, each containing
#'   `$message` (description), `$level`, and `$created_at` (Unix timestamp).
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#'
#' events <- list_fine_tuning_events("ftjob-abc123", limit = 50)
#' for (e in events$data) cat(e$message, "\n")
#' }
list_fine_tuning_events <- function(fine_tuning_job_id, ...) {
  client <- OpenAI$new()
  client$fine_tuning$jobs$list_events(fine_tuning_job_id, ...)
}

#' List Fine-tuning Checkpoints (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and lists checkpoints for a fine-tuning job.
#' Checkpoints are saved after each epoch and can be used as models directly.
#'
#' @param fine_tuning_job_id Character. **Required.** The fine-tuning job ID.
#' @param ... Additional parameters passed to [FineTuningCheckpointsClient]`$list()`,
#'   such as `limit` and `after`.
#'
#' @return A list with `$data` — a list of checkpoint objects, each containing
#'   `$fine_tuned_model_checkpoint` (usable model ID), `$step_number`,
#'   and `$metrics` (list with `$train_loss`, `$valid_loss`, etc.).
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#'
#' cps <- list_fine_tuning_checkpoints("ftjob-abc123")
#' for (cp in cps$data) {
#'   cat("Step:", cp$step_number, "Loss:", cp$metrics$train_loss, "\n")
#' }
#' }
list_fine_tuning_checkpoints <- function(fine_tuning_job_id, ...) {
  client <- OpenAI$new()
  client$fine_tuning$jobs$checkpoints$list(fine_tuning_job_id, ...)
}
