#' Fine-tuning Client
#'
#' Client for OpenAI Fine-tuning API.
#'
#' @export
FineTuningClient <- R6::R6Class(
  "FineTuningClient",
  public = list(
    client = NULL,

    #' @field jobs Fine-tuning jobs interface
    jobs = NULL,

    #' Initialize fine-tuning client
    #'
    #' @param parent Parent OpenAI client
    initialize = function(parent) {
      self$client <- parent
      self$jobs <- FineTuningJobsClient$new(parent)
    }
  )
)

#' Fine-tuning Jobs Client
#'
#' @export
FineTuningJobsClient <- R6::R6Class(
  "FineTuningJobsClient",
  public = list(
    client = NULL,

    #' @field checkpoints Checkpoints sub-client
    checkpoints = NULL,
    initialize = function(parent) {
      self$client <- parent
      self$checkpoints <- FineTuningCheckpointsClient$new(parent)
    },

    #' Create a fine-tuning job
    #'
    #' @param training_file File ID for training data
    #' @param model Model to fine-tune (e.g., "gpt-3.5-turbo")
    #' @param hyperparameters Hyperparameters for fine-tuning
    #' @param suffix Suffix for the fine-tuned model name
    #' @param validation_file File ID for validation data
    #' @param integrations List of integrations to enable
    #' @param seed Random seed
    #' @param method Fine-tuning method (e.g., "supervised", "dpo")
    #' @return Fine-tuning job object
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

    #' List fine-tuning jobs
    #'
    #' @param after Identifier for the last job from previous request
    #' @param limit Number of jobs to retrieve
    #' @return List of fine-tuning jobs
    list = function(after = NULL, limit = NULL) {
      query <- list()
      if (!is.null(after)) query$after <- after
      if (!is.null(limit)) query$limit <- limit

      self$client$request("GET", "/fine_tuning/jobs", query = query)
    },

    #' Retrieve a fine-tuning job
    #'
    #' @param fine_tuning_job_id Fine-tuning job ID
    #' @return Fine-tuning job details
    retrieve = function(fine_tuning_job_id) {
      self$client$request("GET", paste0("/fine_tuning/jobs/", fine_tuning_job_id))
    },

    #' Cancel a fine-tuning job
    #'
    #' @param fine_tuning_job_id Fine-tuning job ID
    #' @return Cancelled fine-tuning job
    cancel = function(fine_tuning_job_id) {
      self$client$request("POST", paste0("/fine_tuning/jobs/", fine_tuning_job_id, "/cancel"))
    },

    #' List fine-tuning events
    #'
    #' @param fine_tuning_job_id Fine-tuning job ID
    #' @param after Identifier for the last event from previous request
    #' @param limit Number of events to retrieve
    #' @return List of fine-tuning events
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
#' @export
FineTuningCheckpointsClient <- R6::R6Class(
  "FineTuningCheckpointsClient",
  public = list(
    client = NULL,

    #' Initialize checkpoints client
    #'
    #' @param parent Parent OpenAI client
    initialize = function(parent) {
      self$client <- parent
    },

    #' List fine-tuning job checkpoints
    #'
    #' @param fine_tuning_job_id Fine-tuning job ID
    #' @param after Identifier for the last checkpoint from previous request
    #' @param limit Number of checkpoints to retrieve
    #' @return List of checkpoints
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

#' Create a fine-tuning job (convenience function)
#'
#' @param training_file Training file ID
#' @param model Model to fine-tune
#' @param ... Additional parameters
#' @return Fine-tuning job
#' @export
create_fine_tuning_job <- function(training_file, model = "gpt-3.5-turbo", ...) {
  client <- OpenAI$new()
  client$fine_tuning$jobs$create(training_file = training_file, model = model, ...)
}

#' List fine-tuning jobs (convenience function)
#'
#' @param ... Additional parameters
#' @return List of fine-tuning jobs
#' @export
list_fine_tuning_jobs <- function(...) {
  client <- OpenAI$new()
  client$fine_tuning$jobs$list(...)
}

#' Retrieve a fine-tuning job (convenience function)
#'
#' @param fine_tuning_job_id Job ID
#' @return Job details
#' @export
retrieve_fine_tuning_job <- function(fine_tuning_job_id) {
  client <- OpenAI$new()
  client$fine_tuning$jobs$retrieve(fine_tuning_job_id)
}

#' Cancel a fine-tuning job (convenience function)
#'
#' @param fine_tuning_job_id Job ID
#' @return Cancelled job
#' @export
cancel_fine_tuning_job <- function(fine_tuning_job_id) {
  client <- OpenAI$new()
  client$fine_tuning$jobs$cancel(fine_tuning_job_id)
}

#' List fine-tuning events (convenience function)
#'
#' @param fine_tuning_job_id Job ID
#' @param ... Additional parameters
#' @return List of events
#' @export
list_fine_tuning_events <- function(fine_tuning_job_id, ...) {
  client <- OpenAI$new()
  client$fine_tuning$jobs$list_events(fine_tuning_job_id, ...)
}

#' List fine-tuning checkpoints (convenience function)
#'
#' @param fine_tuning_job_id Job ID
#' @param ... Additional parameters
#' @return List of checkpoints
#' @export
list_fine_tuning_checkpoints <- function(fine_tuning_job_id, ...) {
  client <- OpenAI$new()
  client$fine_tuning$jobs$checkpoints$list(fine_tuning_job_id, ...)
}
