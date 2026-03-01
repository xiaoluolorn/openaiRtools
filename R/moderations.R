#' Moderations Client
#'
#' Client for OpenAI Moderations API.
#' Classifies text as potentially harmful.
#'
#' @export
ModerationsClient <- R6::R6Class(
  "ModerationsClient",
  public = list(
    client = NULL,
    
    #' Initialize moderations client
    #'
    #' @param parent Parent OpenAI client
    initialize = function(parent) {
      self$client <- parent
    },
    
    #' Create a moderation
    #'
    #' @param input Text or array of texts to moderate
    #' @param model Moderation model: "omni-moderation-latest" or "text-moderation-latest"
    #' @return Moderation response
    create = function(input, model = "omni-moderation-latest") {
      body <- list(
        input = input,
        model = model
      )
      
      self$client$request("POST", "/moderations", body = body)
    }
  )
)

#' Create a moderation (convenience function)
#'
#' @param input Text or texts to moderate
#' @param model Moderation model
#' @return Moderation response
#' @export
create_moderation <- function(input, model = "omni-moderation-latest") {
  client <- OpenAI$new()
  client$moderations$create(input = input, model = model)
}