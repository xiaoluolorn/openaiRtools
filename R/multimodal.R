#' Helper Functions for Multimodal Content
#'
#' Functions to construct image content objects for sending images to
#' vision-capable LLMs via the Chat Completions API.
#'
#' @description
#' Most modern LLMs (GPT-4o, Claude 3, Gemini, Qwen-VL, etc.) support
#' multimodal input — you can send both text and images in the same message.
#' Images are embedded inside the `content` field of a `"user"` message
#' as a list of content parts.
#'
#' There are three ways to provide an image:
#' \enumerate{
#'   \item \strong{Image URL} — the model downloads it directly (``image_from_url``)
#'   \item \strong{Local file} — read and Base64-encoded automatically (``image_from_file``)
#'   \item \strong{R plot} — save a ggplot2 / base R figure and send it (``image_from_plot``)
#' }
#'
#' Use ``create_multimodal_message`` to combine text + multiple images
#' into a single ready-to-use message object.
#'
#' @name multimodal
#' @keywords multimodal vision image
NULL

# ---------------------------------------------------------------------------
# image_from_url
# ---------------------------------------------------------------------------

#' Create Image Content from a URL
#'
#' Builds a content part object that tells the model to fetch and analyze
#' an image from a public web URL. The URL must be directly accessible
#' (no login required).
#'
#' @param url Character. A publicly accessible image URL.
#'   Supported formats: JPEG, PNG, GIF (static), WebP.
#'   Example: `"https://example.com/chart.png"`
#'
#' @param detail Character. Controls how the model perceives the image,
#'   trading off between cost/speed and accuracy:
#'   \itemize{
#'     \item `"auto"` (default) — model chooses based on image size
#'     \item `"low"` — 85 tokens flat; fast and cheap; good for
#'           simple images, icons, or when spatial detail is unimportant
#'     \item `"high"` — tiles the image at 512px squares (up to 1105
#'           extra tokens); use for charts with small text, detailed figures,
#'           or when precise spatial understanding is needed
#'   }
#'
#' @return A named list (content part) to be placed inside a message's
#'   `content` list. Use with ``create_multimodal_message``
#'   or construct messages manually.
#'
#' @export
#' @seealso ``image_from_file``, ``image_from_plot``,
#'   ``create_multimodal_message``
#'
#' @examples
#' \dontrun{
#' library(openaiRtools)
#' client <- OpenAI$new(api_key = "sk-xxxxxx")
#'
#' # Build an image part from a URL
#' img <- image_from_url(
#'   url    = "https://example.com/photo.jpg",
#'   detail = "low"
#' )
#'
#' # Assemble a message manually
#' messages <- list(
#'   list(
#'     role = "user",
#'     content = list(
#'       list(type = "text", text = "What painting is this?"),
#'       img
#'     )
#'   )
#' )
#'
#' response <- client$chat$completions$create(
#'   messages = messages,
#'   model    = "gpt-4o"
#' )
#' cat(response$choices[[1]]$message$content)
#' }
image_from_url <- function(url, detail = "auto") {
  list(
    type      = "image_url",
    image_url = list(url = url, detail = detail)
  )
}

# ---------------------------------------------------------------------------
# image_from_file
# ---------------------------------------------------------------------------

#' Create Image Content from a Local File
#'
#' Reads a local image file, encodes it as Base64, and wraps it in a
#' data URI so it can be sent directly to the model without hosting the
#' file anywhere. This is the recommended approach for local figures,
#' screenshots, or any image not accessible via a public URL.
#'
#' @param file_path Character. Absolute or relative path to a local image
#'   file. Supported formats: `.jpg`/`.jpeg`, `.png`,
#'   `.gif` (static), `.webp`.
#'   Maximum recommended size: \strong{20 MB} (smaller is faster).
#'
#' @param mime_type Character or `NULL`. MIME type of the image.
#'   When `NULL` (default), auto-detected from the file extension:
#'   \itemize{
#'     \item `.jpg` / `.jpeg` → `"image/jpeg"`
#'     \item `.png` → `"image/png"`
#'     \item `.gif` → `"image/gif"`
#'     \item `.webp` → `"image/webp"`
#'   }
#'   Override only if the extension is missing or wrong.
#'
#' @param detail Character. Image detail level: `"auto"` (default),
#'   `"low"`, or `"high"`. See ``image_from_url`` for
#'   full explanation.
#'
#' @return A named list (content part) ready to include in a message's
#'   `content` list.
#'
#' @export
#' @seealso ``image_from_url``, ``image_from_plot``,
#'   ``create_multimodal_message``
#'
#' @examples
#' \dontrun{
#' library(openaiRtools)
#' client <- OpenAI$new(api_key = "sk-xxxxxx")
#'
#' # Send a local chart image
#' img <- image_from_file("results/regression_plot.png", detail = "high")
#'
#' messages <- list(
#'   list(
#'     role = "user",
#'     content = list(
#'       list(
#'         type = "text",
#'         text = "This is a residuals-vs-fitted plot. Does it show heteroskedasticity?"
#'       ),
#'       img
#'     )
#'   )
#' )
#'
#' response <- client$chat$completions$create(
#'   messages = messages,
#'   model    = "gpt-4o"
#' )
#' cat(response$choices[[1]]$message$content)
#' }
image_from_file <- function(file_path, mime_type = NULL, detail = "auto") {
  if (!file.exists(file_path)) {
    stop(sprintf("Image file not found: %s", file_path))
  }

  # Auto-detect MIME type from extension
  if (is.null(mime_type)) {
    ext <- tolower(tools::file_ext(file_path))
    mime_type <- switch(ext,
      jpg  = "image/jpeg",
      jpeg = "image/jpeg",
      png  = "image/png",
      gif  = "image/gif",
      webp = "image/webp",
      "image/jpeg" # default fallback
    )
  }

  # Read binary and encode as Base64
  file_content <- readBin(file_path, "raw", file.info(file_path)$size)
  base64_data <- base64_enc(file_content)

  # Build data URI:  data:<mime>;base64,<data>
  data_url <- paste0("data:", mime_type, ";base64,", base64_data)

  list(
    type      = "image_url",
    image_url = list(url = data_url, detail = detail)
  )
}

# ---------------------------------------------------------------------------
# image_from_plot  (NEW)
# ---------------------------------------------------------------------------

#' Create Image Content from an R Plot Object
#'
#' Renders a ggplot2 plot (or any R base graphics expression) to a temporary
#' PNG file and encodes it as Base64, ready to be sent to a vision LLM.
#' This lets you analyze charts produced in R without saving them manually.
#'
#' @param plot A `ggplot` object (\pkg{ggplot2}), or `NULL` to capture
#'   the \emph{current} base-R graphics device (call your `plot()`/
#'   `hist()` etc. first, then call `image_from_plot(NULL)`).
#'
#' @param width Numeric. Width of the saved PNG in inches. Default: `7`.
#'
#' @param height Numeric. Height of the saved PNG in inches. Default: `5`.
#'
#' @param dpi Integer. Resolution in dots per inch. Higher DPI gives sharper
#'   images (important for text readability) but larger file size.
#'   Default: `150`. Use `200+` when text in plots must be legible.
#'
#' @param detail Character. Image detail level passed to the API:
#'   `"auto"` (default), `"low"`, or `"high"`.
#'
#' @return A named list (content part) ready to include in a message's
#'   `content` list.
#'
#' @export
#' @importFrom grDevices png
#' @seealso ``image_from_file``, ``create_multimodal_message``
#'
#' @examples
#' \dontrun{
#' library(openaiRtools)
#' library(ggplot2)
#' client <- OpenAI$new(api_key = "sk-xxxxxx")
#'
#' # Build a ggplot2 chart
#' p <- ggplot(mtcars, aes(x = wt, y = mpg)) +
#'   geom_point() +
#'   geom_smooth(method = "lm") +
#'   labs(title = "Car Weight vs Fuel Efficiency", x = "Weight", y = "MPG")
#'
#' # Send plot directly to GPT-4o
#' response <- client$chat$completions$create(
#'   messages = list(
#'     list(
#'       role = "user",
#'       content = list(
#'         list(
#'           type = "text",
#'           text = "Describe the relationship shown in this scatter plot."
#'         ),
#'         image_from_plot(p, dpi = 150)
#'       )
#'     )
#'   ),
#'   model = "gpt-4o"
#' )
#' cat(response$choices[[1]]$message$content)
#' }
image_from_plot <- function(plot = NULL, width = 7, height = 5,
                            dpi = 150, detail = "auto") {
  tmp <- tempfile(fileext = ".png")
  on.exit(unlink(tmp), add = TRUE)

  if (!is.null(plot)) {
    # ggplot2 object
    if (!requireNamespace("ggplot2", quietly = TRUE)) {
      stop("Package 'ggplot2' is required. Install with: install.packages('ggplot2')")
    }
    ggplot2::ggsave(tmp,
      plot = plot, width = width, height = height,
      dpi = dpi, units = "in", device = "png"
    )
  } else {
    # Capture current base-R graphics device
    grDevices::dev.copy(png,
      filename = tmp,
      width = width * dpi, height = height * dpi,
      res = dpi
    )
    grDevices::dev.off()
  }

  image_from_file(tmp, mime_type = "image/png", detail = detail)
}

# ---------------------------------------------------------------------------
# text_content
# ---------------------------------------------------------------------------

#' Create a Text Content Part
#'
#' Wraps a plain text string into the content-part format required by the
#' multimodal Chat Completions API. Useful when building message `content`
#' lists manually alongside image parts.
#'
#' @param text Character. The text string to include in the message content.
#'
#' @return A named list: `list(type = "text", text = <text>)`.
#'
#' @export
#' @seealso ``image_from_url``, ``create_multimodal_message``
#'
#' @examples
#' \dontrun{
#' part <- text_content("What do you see in this image?")
#' # Result: list(type = "text", text = "What do you see in this image?")
#' }
text_content <- function(text) {
  list(type = "text", text = text)
}

# ---------------------------------------------------------------------------
# create_multimodal_message
# ---------------------------------------------------------------------------

#' Build a Multimodal User Message (Text + Images)
#'
#' Convenience function that assembles a complete `"user"` message object
#' containing both text and one or more images. Automatically handles URL vs.
#' local file detection.
#'
#' Pass the returned object (or a list of such objects) directly to
#' `client$chat$completions$create(messages = ...)`.
#'
#' @param text Character or `NULL`. The text prompt accompanying the
#'   image(s). If `NULL`, only images are sent (less common).
#'
#' @param images List of image sources. Each element can be:
#'   \itemize{
#'     \item A \strong{URL string} starting with `"http://"` or
#'           `"https://"` — passed to ``image_from_url``
#'     \item A \strong{local file path string} — passed to
#'           ``image_from_file``
#'     \item A \strong{pre-built content part} from ``image_from_url``,
#'           ``image_from_file``, or ``image_from_plot``
#'           (these are passed through as-is)
#'   }
#'   Default: `NULL` (text-only message).
#'
#' @param detail Character. Detail level applied to all images supplied
#'   as strings. Ignored for pre-built content parts.
#'   `"auto"` (default), `"low"`, or `"high"`.
#'
#' @return A named list representing a `"user"` message:
#' \preformatted{
#' list(
#'   role    = "user",
#'   content = list(
#'     list(type = "text",      text = <text>),
#'     list(type = "image_url", image_url = list(url = ..., detail = ...)),
#'     ...
#'   )
#' )
#' }
#'
#' @export
#' @seealso [image_from_url()], [image_from_file()],
#'   [image_from_plot()]
#'
#' @examples
#' \dontrun{
#' library(openaiRtools)
#' client <- OpenAI$new(api_key = "sk-xxxxxx")
#'
#' # --- URL image ---
#' msg <- create_multimodal_message(
#'   text   = "What is shown in this chart?",
#'   images = list("https://example.com/gdp_chart.png")
#' )
#' response <- client$chat$completions$create(messages = list(msg), model = "gpt-4o")
#'
#' # --- Local file ---
#' msg <- create_multimodal_message(
#'   text   = "Identify any statistical issues in this residual plot.",
#'   images = list("output/resid_plot.png"),
#'   detail = "high"
#' )
#'
#' # --- Multiple images (compare two charts) ---
#' msg <- create_multimodal_message(
#'   text   = "Compare these two regression diagnostics plots.",
#'   images = list("plot_model1.png", "plot_model2.png"),
#'   detail = "high"
#' )
#'
#' # --- Mix of pre-built parts ---
#' library(ggplot2)
#' p <- ggplot(mtcars, aes(wt, mpg)) +
#'   geom_point()
#' msg <- create_multimodal_message(
#'   text   = "Describe the scatter pattern.",
#'   images = list(image_from_plot(p, dpi = 180))
#' )
#' }
create_multimodal_message <- function(text = NULL, images = NULL,
                                      detail = "auto") {
  content <- list()

  # Add text part first
  if (!is.null(text)) {
    content[[length(content) + 1]] <- text_content(text)
  }

  # Add image parts
  if (!is.null(images) && length(images) > 0) {
    for (img in images) {
      if (is.list(img)) {
        # Already a pre-built content part — pass through as-is
        content[[length(content) + 1]] <- img
      } else if (is.character(img)) {
        if (startsWith(img, "http://") || startsWith(img, "https://")) {
          content[[length(content) + 1]] <- image_from_url(img, detail = detail)
        } else {
          content[[length(content) + 1]] <- image_from_file(img, detail = detail)
        }
      } else {
        stop("Each element of 'images' must be a URL string, a file path string, or a pre-built content part list.")
      }
    }
  }

  list(role = "user", content = content)
}

# ---------------------------------------------------------------------------
# internal helper
# ---------------------------------------------------------------------------

# Base64 encode raw bytes using jsonlite
base64_enc <- function(data) {
  jsonlite::base64_enc(data)
}
