#' Helper Functions for Multimodal Content
#'
#' Functions to create image content for multimodal models.
#'
#' @name multimodal
#' @keywords multimodal
NULL

#' Create image content from URL
#'
#' @param url Image URL
#' @param detail Detail level ("low", "high", or "auto"). Default: "auto"
#' @return Image content object for messages
#' @export
#'
#' @examples
#' \dontrun{
#' # Create image content from URL
#' image_content <- image_from_url("https://example.com/image.jpg")
#'
#' # Use in message
#' messages <- list(
#'   list(
#'     role = "user",
#'     content = list(
#'       list(type = "text", text = "What's in this image?"),
#'       image_content
#'     )
#'   )
#' )
#'
#' response <- client$chat$completions$create(
#'   messages = messages,
#'   model = "gpt-4-vision-preview"
#' )
#' }
image_from_url <- function(url, detail = "auto") {
  list(
    type = "image_url",
    image_url = list(
      url = url,
      detail = detail
    )
  )
}

#' Create image content from local file (base64 encoded)
#'
#' @param file_path Path to local image file
#' @param mime_type MIME type of the image (e.g., "image/jpeg", "image/png").
#'        If NULL, will try to auto-detect from file extension.
#' @param detail Detail level ("low", "high", or "auto"). Default: "auto"
#' @return Image content object for messages
#' @export
#'
#' @examples
#' \dontrun{
#' # Create image content from local file
#' image_content <- image_from_file("path/to/image.jpg")
#'
#' # Use in message
#' messages <- list(
#'   list(
#'     role = "user",
#'     content = list(
#'       list(type = "text", text = "What's in this image?"),
#'       image_content
#'     )
#'   )
#' )
#'
#' response <- client$chat$completions$create(
#'   messages = messages,
#'   model = "gpt-4-vision-preview"
#' )
#' }
image_from_file <- function(file_path, mime_type = NULL, detail = "auto") {
  # Auto-detect MIME type if not provided
  if (is.null(mime_type)) {
    ext <- tolower(tools::file_ext(file_path))
    mime_type <- switch(ext,
      jpg = "image/jpeg",
      jpeg = "image/jpeg",
      png = "image/png",
      gif = "image/gif",
      webp = "image/webp",
      "image/jpeg"  # default
    )
  }
  
  # Read and encode file
  file_content <- readBin(file_path, "raw", file.info(file_path)$size)
  base64_data <- base64_enc(file_content)
  
  # Create data URL
  data_url <- paste0("data:", mime_type, ";base64,", base64_data)
  
  list(
    type = "image_url",
    image_url = list(
      url = data_url,
      detail = detail
    )
  )
}

#' Create text content for multimodal messages
#'
#' @param text Text content
#' @return Text content object for messages
#' @export
#'
#' @examples
#' \dontrun{
#' text_content <- text_content("What's in this image?")
#' }
text_content <- function(text) {
  list(type = "text", text = text)
}

#' Create a multimodal message with text and images
#'
#' @param text Text content (can be NULL if only images)
#' @param images List of image URLs or file paths
#' @param detail Detail level for images. Default: "auto"
#' @return Message object for chat completions
#' @export
#'
#' @examples
#' \dontrun{
#' # Message with text and image URL
#' msg <- create_multimodal_message(
#'   text = "What's in this image?",
#'   images = list("https://example.com/image.jpg")
#' )
#'
#' # Message with local image file
#' msg <- create_multimodal_message(
#'   text = "Describe this image",
#'   images = list("path/to/image.jpg")
#' )
#'
#' # Use in chat
#' response <- client$chat$completions$create(
#'   messages = list(msg),
#'   model = "gpt-4-vision-preview"
#' )
#' }
create_multimodal_message <- function(text = NULL, images = NULL, detail = "auto") {
  content <- list()
  
  # Add text if provided
  if (!is.null(text)) {
    content[[length(content) + 1]] <- text_content(text)
  }
  
  # Add images if provided
  if (!is.null(images) && length(images) > 0) {
    for (img in images) {
      if (startsWith(img, "http://") || startsWith(img, "https://")) {
        # Image URL
        content[[length(content) + 1]] <- image_from_url(img, detail = detail)
      } else {
        # Local file path
        content[[length(content) + 1]] <- image_from_file(img, detail = detail)
      }
    }
  }
  
  list(
    role = "user",
    content = content
  )
}

# Helper function for base64 encoding
base64_enc <- function(data) {
  # Use jsonlite for base64 encoding
  jsonlite::base64_enc(data)
}
