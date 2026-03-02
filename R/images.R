#' Images Client
#'
#' Client for OpenAI Images API (DALL-E image generation and editing).
#' Access via `client$images`.
#'
#' @section Methods:
#' \describe{
#'   \item{`$create(prompt, ...)`}{Generate a new image from a text description}
#'   \item{`$edit(image, prompt, ...)`}{Edit an existing image using a mask}
#'   \item{`$create_variation(image, ...)`}{Create variations of an existing image}
#' }
#'
#' @export
ImagesClient <- R6::R6Class(
  "ImagesClient",
  public = list(
    client = NULL,

    # Initialize images client
    #
    # @param parent Parent OpenAI client
    initialize = function(parent) {
      self$client <- parent
    },

    # @description
    # Generate one or more images from a text prompt using DALL-E.
    #
    # @param prompt Character. **Required.** A text description of the desired
    #   image(s). For DALL-E 3, the prompt can be up to 4000 characters.
    #   For DALL-E 2, the maximum is 1000 characters.
    #   Be detailed and specific for best results.
    #   Example: `"A photorealistic bar chart of GDP growth, minimalist style, white background"`
    #
    # @param model Character. The model to use:
    #   \itemize{
    #     \item `"dall-e-3"` — Latest model, supports 1024x1024, 1024x1792,
    #       1792x1024. Supports HD quality. Single image only (n must be 1).
    #     \item `"dall-e-2"` — Older model, supports 256x256, 512x512, 1024x1024.
    #       Supports n > 1.
    #   }
    #   Default: `"dall-e-3"`.
    #
    # @param n Integer or NULL. Number of images to generate.
    #   For `"dall-e-3"`, must be 1.
    #   For `"dall-e-2"`, can be 1–10.
    #   Default: NULL (API default 1).
    #
    # @param quality Character or NULL. Quality of the generated image.
    #   Only supported by `"dall-e-3"`:
    #   \itemize{
    #     \item `"standard"` — Normal quality, faster and cheaper
    #     \item `"hd"` — Higher detail and consistency, costs more
    #   }
    #   Default: NULL (API default `"standard"`).
    #
    # @param response_format Character or NULL. Format of the returned image:
    #   \itemize{
    #     \item `"url"` (default) — Returns a temporary URL (valid ~60 minutes)
    #     \item `"b64_json"` — Returns the image as a Base64-encoded JSON string
    #   }
    #   Default: NULL (API default `"url"`).
    #
    # @param size Character or NULL. Image dimensions:
    #   \itemize{
    #     \item For `"dall-e-3"`: `"1024x1024"`, `"1024x1792"`, `"1792x1024"`
    #     \item For `"dall-e-2"`: `"256x256"`, `"512x512"`, `"1024x1024"`
    #   }
    #   Default: NULL (API default `"1024x1024"`).
    #
    # @param style Character or NULL. Visual style of the generated image.
    #   Only for `"dall-e-3"`:
    #   \itemize{
    #     \item `"vivid"` — Hyper-real, dramatic. Good for illustrations.
    #     \item `"natural"` — More realistic, subtle.
    #   }
    #   Default: NULL (API default `"vivid"`).
    #
    # @param user Character or NULL. End-user identifier for abuse monitoring.
    #   Default: NULL.
    #
    # @return A named list:
    #   \describe{
    #     \item{`$created`}{Integer. Unix timestamp of generation.}
    #     \item{`$data`}{List of image objects (length = n). Each has:
    #       \describe{
    #         \item{`$data[[i]]$url`}{Character. Image URL (if `response_format = "url"`).}
    #         \item{`$data[[i]]$b64_json`}{Character. Base64 image (if `response_format = "b64_json"`).}
    #         \item{`$data[[i]]$revised_prompt`}{For DALL-E 3, the revised prompt actually used.}
    #       }
    #     }
    #   }
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    #
    # # Generate a basic image
    # resp <- client$images$create(
    #   prompt = "A scatter plot showing GDP vs life expectancy, academic style",
    #   model  = "dall-e-3"
    # )
    # cat("Image URL:", resp$data[[1]]$url, "\n")
    #
    # # HD landscape image
    # resp <- client$images$create(
    #   prompt  = "An aerial view of a smart city with data streams visualized",
    #   model   = "dall-e-3",
    #   quality = "hd",
    #   size    = "1792x1024",
    #   style   = "natural"
    # )
    # cat("URL:", resp$data[[1]]$url)
    # cat("Revised prompt:", resp$data[[1]]$revised_prompt)
    # }
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

    # @description
    # Edit an existing image based on a text prompt. Optionally provide a mask
    # image to define which area to edit. Uses DALL-E 2.
    # The image and mask must be square PNG files less than 4 MB.
    #
    # @param image Character. **Required.** Path to the local image file to edit.
    #   Must be a square PNG, less than 4 MB.
    #
    # @param prompt Character. **Required.** Text description of what to change.
    #   Example: `"Replace the background with a sunny beach"`.
    #
    # @param mask Character or NULL. Path to a mask PNG file.
    #   Transparent (alpha = 0) areas indicate where to paint the edit.
    #   Must be the same size as `image`. If NULL, the entire image is edited.
    #   Default: NULL.
    #
    # @param model Character. The model to use. Currently `"dall-e-2"` only.
    #   Default: `"dall-e-2"`.
    #
    # @param n Integer or NULL. Number of images to generate (1–10).
    #   Default: NULL (API default 1).
    #
    # @param response_format Character or NULL. `"url"` or `"b64_json"`.
    #   Default: NULL (API default `"url"`).
    #
    # @param size Character or NULL. `"256x256"`, `"512x512"`, or `"1024x1024"`.
    #   Default: NULL (API default `"1024x1024"`).
    #
    # @param user Character or NULL. End-user identifier. Default: NULL.
    #
    # @return A list with `$data` containing the edited image(s).
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    #
    # # Edit image within a masked region
    # resp <- client$images$edit(
    #   image  = "original.png",
    #   prompt = "Add a sunset sky in the background",
    #   mask   = "mask.png",
    #   size   = "1024x1024"
    # )
    # cat("Edited image URL:", resp$data[[1]]$url)
    # }
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

    # @description
    # Create one or more variations of an existing image. Uses DALL-E 2.
    # The input image must be a square PNG less than 4 MB.
    #
    # @param image Character. **Required.** Path to the local square PNG image.
    #   Must be less than 4 MB.
    #
    # @param model Character. The model to use. Currently `"dall-e-2"` only.
    #   Default: `"dall-e-2"`.
    #
    # @param n Integer or NULL. Number of variations to generate (1–10).
    #   Default: NULL (API default 1).
    #
    # @param response_format Character or NULL. `"url"` or `"b64_json"`.
    #   Default: NULL (API default `"url"`).
    #
    # @param size Character or NULL. `"256x256"`, `"512x512"`, or `"1024x1024"`.
    #   Default: NULL (API default `"1024x1024"`).
    #
    # @param user Character or NULL. End-user identifier. Default: NULL.
    #
    # @return A list with `$data` containing the variation image(s).
    #
    # @examples
    # \dontrun{
    # client <- OpenAI$new(api_key = "sk-xxxxxx")
    #
    # # Generate 3 variations of an existing image
    # resp <- client$images$create_variation(
    #   image = "logo.png",
    #   n     = 3,
    #   size  = "512x512"
    # )
    # for (img in resp$data) cat("Variation URL:", img$url, "\n")
    # }
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

#' Generate an Image from Text (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and calls `client$images$create()`.
#'
#' @param prompt Character. **Required.** Text description of the desired image.
#'   For DALL-E 3, up to 4000 characters.
#' @param model Character. Image model: `"dall-e-3"` (default) or `"dall-e-2"`.
#' @param ... Additional parameters passed to [ImagesClient]`$create()`, such
#'   as `n`, `size` (`"1024x1024"`, `"1792x1024"`, `"1024x1792"`),
#'   `quality` (`"standard"` or `"hd"`),
#'   `style` (`"vivid"` or `"natural"`),
#'   `response_format` (`"url"` or `"b64_json"`).
#'
#' @return A list with `$data[[1]]$url` containing the image URL, and
#'   `$data[[1]]$revised_prompt` with the prompt used by DALL-E 3.
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#'
#' # Generate a standard image
#' resp <- create_image("A futuristic chart showing economic data, neon style")
#' cat(resp$data[[1]]$url)
#'
#' # HD landscape
#' resp <- create_image(
#'   prompt  = "A detailed map of global trade routes",
#'   model   = "dall-e-3",
#'   size    = "1792x1024",
#'   quality = "hd",
#'   style   = "natural"
#' )
#' cat(resp$data[[1]]$url)
#' }
create_image <- function(prompt, model = "dall-e-3", ...) {
  client <- OpenAI$new()
  client$images$create(prompt = prompt, model = model, ...)
}

#' Edit an Image with DALL-E (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and calls `client$images$edit()`.
#' Edits a local PNG image based on a text prompt and optional mask.
#'
#' @param image Character. **Required.** Path to the local square PNG to edit
#'   (less than 4 MB).
#' @param prompt Character. **Required.** Description of the desired edit.
#' @param mask Character or NULL. Path to a mask PNG. Transparent pixels
#'   indicate which region to edit. Default: NULL (entire image).
#' @param ... Additional parameters passed to [ImagesClient]`$edit()`, such
#'   as `n` (number of images), `size`, `response_format`, `user`.
#'
#' @return A list with `$data` containing the edited image object(s).
#'   Access the URL via `$data[[1]]$url`.
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#'
#' resp <- create_image_edit(
#'   image  = "photo.png",
#'   prompt = "Add a mountain range in the background",
#'   mask   = "sky_mask.png"
#' )
#' cat(resp$data[[1]]$url)
#' }
create_image_edit <- function(image, prompt, mask = NULL, ...) {
  client <- OpenAI$new()
  client$images$edit(image = image, prompt = prompt, mask = mask, ...)
}

#' Create Image Variations with DALL-E (Convenience Function)
#'
#' Shortcut that creates an [OpenAI] client from the `OPENAI_API_KEY`
#' environment variable and calls `client$images$create_variation()`.
#' Generates one or more variations of an existing image.
#'
#' @param image Character. **Required.** Path to the local square PNG image
#'   (less than 4 MB).
#' @param model Character. Currently only `"dall-e-2"` is supported.
#'   Default: `"dall-e-2"`.
#' @param ... Additional parameters passed to [ImagesClient]`$create_variation()`,
#'   such as `n` (number of variations, 1–10), `size`, `response_format`.
#'
#' @return A list with `$data` containing the generated variation image(s).
#'   Access the URL via `$data[[1]]$url`.
#'
#' @export
#' @examples
#' \dontrun{
#' Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
#'
#' # Generate 2 variations of your logo
#' resp <- create_image_variation(
#'   image = "logo.png",
#'   n     = 2,
#'   size  = "512x512"
#' )
#' cat(resp$data[[1]]$url)
#' cat(resp$data[[2]]$url)
#' }
create_image_variation <- function(image, model = "dall-e-2", ...) {
  client <- OpenAI$new()
  client$images$create_variation(image = image, model = model, ...)
}
