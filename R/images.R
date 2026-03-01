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
    #' @param image Image to edit (file path or raw)
    #' @param prompt Text description of desired edit
    #' @param mask Mask for the edit (file path or raw)
    #' @param model Model to use
    #' @param n Number of images to generate
    #' @param response_format Response format
    #' @param size Size of generated image
    #' @param user Unique identifier
    #' @return Images response
    edit = function(image, prompt, mask = NULL, model = "dall-e-2",
                    n = NULL, response_format = NULL, size = NULL, user = NULL) {
      # This would need multipart form data support
      OpenAIError("Image editing requires multipart form data. Use create_image_edit() function.")
    },
    
    #' Create an image variation
    #'
    #' @param image Image to vary (file path or raw)
    #' @param model Model to use
    #' @param n Number of images to generate
    #' @param response_format Response format
    #' @param size Size of generated image
    #' @param user Unique identifier
    #' @return Images response
    create_variation = function(image, model = "dall-e-2",
                                 n = NULL, response_format = NULL, 
                                 size = NULL, user = NULL) {
      # This would need multipart form data support
      OpenAIError("Image variation requires multipart form data. Use create_image_variation() function.")
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
  
  body <- list(
    prompt = prompt,
    model = "dall-e-2"
  )
  
  # Add optional parameters
  dots <- list(...)
  if (length(dots) > 0) {
    body <- c(body, dots)
  }
  
  # Create multipart request
  req <- httr2::request(paste0(client$base_url, "/images/edits"))
  req <- httr2::req_method(req, "POST")
  req <- httr2::req_headers(req,
    "Authorization" = paste("Bearer", client$api_key),
    "OpenAI-Beta" = "assistants=v2"
  )
  
  if (!is.null(client$organization)) {
    req <- httr2::req_headers(req, "OpenAI-Organization" = client$organization)
  }
  
  # Add image file
  req <- httr2::req_body_multipart(req, image = httr2::curl_file(image))
  
  # Add mask if provided
  if (!is.null(mask)) {
    req <- httr2::req_body_multipart(req, mask = httr2::curl_file(mask))
  }
  
  # Add other parameters
  for (param in names(body)) {
    if (!is.null(body[[param]])) {
      req <- httr2::req_body_multipart(req, !!param := as.character(body[[param]]))
    }
  }
  
  resp <- httr2::req_perform(req)
  handle_response(resp)
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
  
  body <- list(model = model)
  
  # Add optional parameters
  dots <- list(...)
  if (length(dots) > 0) {
    body <- c(body, dots)
  }
  
# Create multipart request
  req <- httr2::request(paste0(client$base_url, "/images/variations"))
  req <- httr2::req_method(req, "POST")
  req <- httr2::req_headers(req,
    "Authorization" = paste("Bearer", client$api_key),
    "OpenAI-Beta" = "assistants=v2"
  )
  
  if (!is.null(client$organization)) {
    req <- httr2::req_headers(req, "OpenAI-Organization" = client$organization)
  }
  
  # Add image file
  req <- httr2::req_body_multipart(req, image = httr2::curl_file(image))
  
  # Add other parameters
  for (param in names(body)) {
    if (!is.null(body[[param]])) {
      req <- httr2::req_body_multipart(req, !!param := as.character(body[[param]]))
    }
  }
  
  resp <- httr2::req_perform(req)
  handle_response(resp)
}
