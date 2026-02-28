#!/usr/bin/env Rscript

# Build documentation for openaiR package
# Run this before releasing to GitHub

cat("=== Building openaiR Documentation ===\n\n")

# Check required packages
required_packages <- c("roxygen2", "devtools")
for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat("Installing", pkg, "...\n")
    install.packages(pkg, repos = "https://cloud.r-project.org/")
  }
  library(pkg, character.only = TRUE)
}

# Run roxygenize
cat("Running roxygen2::roxygenise()...\n")
roxygen2::roxygenise(".")

cat("\n=== Documentation Built Successfully! ===\n")
cat("\nNext steps:\n")
cat("1. Commit the generated .Rd files: git add man/\n")
cat("2. Commit NAMESPACE changes: git add NAMESPACE\n")
cat("3. Commit and push to GitHub\n")
cat("4. Reinstall: remotes::install_github('xiaoluolorn/openaiR')\n")
