#' Images Client
#'
#' Client for OpenAI Images API (DALL-E).
#'
#' @export
ImagesClient <- R6::R6Class(
  "ImagesClient",
  public = list(
    client = NULL,

    #' Initialize images client
    #'
    #' @param parent Parent OpenAI client
    initialize = function(parent) {
      self$client <- parent
    },

    #' Create an image
    #'
    #' @param prompt Text description of the desired image
    #' @param model Model to use (e.g., "dall-e-3", "dall-e-2")
    #' @param n Number of images to generate
    #' @param quality Quality of generated image ("standard" or "hd")
    #' @param response_format Response format ("url" or "b64_json")
    #' @param size Size of generated image (e.g., "1024x1024")
    #' @param style Style of generated image ("vivid" or "natural")
    #' @param user Unique identifier for end user
    #' @return Images response
    create = function(prompt, model = "dall-e-3",
                      n = NULL,
                      quality = NULL,
                      response_format = NULL,
                      size = NULL,
                      style = NULL,
                      user = NULL) {
      body <- list(
        prompt = prompt,
        model = model
      )

      if (!is.null(n)) body$n <- n
      if (!is.null(quality)) body$quality <- quality
      if (!is.null(response_format)) body$response_format <- response_format
      if (!is.null(size)) body$size <- size
      if (!is.null(style)) body$style <- style
      if (!is.null(user)) body$user <- user

      self$client$request("POST", "/images/generations", body = body)
    },

    #' Create an edited image
    #'
    #' @param image Image file path to edit
    #' @param prompt Text description of desired edit
    #' @param mask Mask file path (optional)
    #' @param model Model to use
    #' @param n Number of images to generate
    #' @param response_format Response format
    #' @param size Size of generated image
    #' @param user Unique identifier
    #' @return Images response
    edit = function(image, prompt, mask = NULL, model = "dall-e-2",
                    n = NULL, response_format = NULL, size = NULL, user = NULL) {
      params <- list(
        image = httr2::curl_file(image),
        prompt = prompt,
        model = model
      )

      if (!is.null(mask)) params$mask <- httr2::curl_file(mask)
      if (!is.null(n)) params$n <- as.character(n)
      if (!is.null(response_format)) params$response_format <- response_format
      if (!is.null(size)) params$size <- size
      if (!is.null(user)) params$user <- user

      do.call(
        self$client$request_multipart,
        c(list(method = "POST", path = "/images/edits"), params)
      )
    },

    #' Create an image variation
    #'
    #' @param image Image file path to vary
    #' @param model Model to use
    #' @param n Number of images to generate
    #' @param response_format Response format
    #' @param size Size of generated image
    #' @param user Unique identifier
    #' @return Images response
    create_variation = function(image, model = "dall-e-2",
                                n = NULL, response_format = NULL,
                                size = NULL, user = NULL) {
      params <- list(
        image = httr2::curl_file(image),
        model = model
      )

      if (!is.null(n)) params$n <- as.character(n)
      if (!is.null(response_format)) params$response_format <- response_format
      if (!is.null(size)) params$size <- size
      if (!is.null(user)) params$user <- user

      do.call(
        self$client$request_multipart,
        c(list(method = "POST", path = "/images/variations"), params)
      )
    }
  )
)

#' Create an image (convenience function)
#'
#' @param prompt Text description
#' @param model Model to use
#' @param ... Additional parameters
#' @return Images response
#' @export
create_image <- function(prompt, model = "dall-e-3", ...) {
  client <- OpenAI$new()
  client$images$create(prompt = prompt, model = model, ...)
}

#' Create an edited image (convenience function)
#'
#' @param image Image file path
#' @param prompt Text description
#' @param mask Mask file path (optional)
#' @param ... Additional parameters
#' @return Images response
#' @export
create_image_edit <- function(image, prompt, mask = NULL, ...) {
  client <- OpenAI$new()
  client$images$edit(image = image, prompt = prompt, mask = mask, ...)
}

#' Create an image variation (convenience function)
#'
#' @param image Image file path
#' @param model Model to use
#' @param ... Additional parameters
#' @return Images response
#' @export
create_image_variation <- function(image, model = "dall-e-2", ...) {
  client <- OpenAI$new()
  client$images$create_variation(image = image, model = model, ...)
}
