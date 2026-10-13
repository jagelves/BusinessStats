# Builds answers.qmd: every exercise answer from the chapters, collected on one page.
# Runs automatically before each full `quarto render` (see pre-render in _quarto.yml).
# Answers are copied from the <details><summary>Answer</summary> ... </details> blocks,
# so edit answers in the chapters, never in answers.qmd.

cfg <- yaml::yaml.load(paste(readLines("_quarto.yml", encoding = "UTF-8", warn = FALSE), collapse = "\n"))
flatten <- function(x) unlist(lapply(x, function(e) if (is.list(e)) flatten(e$chapters %||% e) else e))
`%||%` <- function(a, b) if (is.null(a)) b else a
files <- flatten(cfg$book$chapters)
files <- files[grepl("\\.qmd$", files) & files != "index.qmd" & files != "answers.qmd"]

out <- c(
  "# Answers to Exercises {.unnumbered #sec-answers-page}",
  "",
  "Every exercise answer in the book, collected in one place. Try each problem on your own before you look.",
  ""
)

chapnum <- 0
for (f in files) {
  lines <- readLines(f, encoding = "UTF-8", warn = FALSE)
  title_line <- grep("^# ", lines, value = TRUE)[1]
  if (is.na(title_line)) next
  unnumbered <- grepl("unnumbered", title_line)
  if (!unnumbered) chapnum <- chapnum + 1
  title <- trimws(sub("\\{.*\\}", "", sub("^# ", "", title_line)))
  page <- sub("\\.qmd$", ".html", f)

  exercise <- NULL; exercise_id <- NULL; q <- NULL
  chapter_out <- character(0)
  in_fence <- FALSE
  i <- 1
  while (i <= length(lines)) {
    ln <- lines[i]
    if (grepl("^\\s*(```|~~~)", ln)) in_fence <- !in_fence
    if (!in_fence && grepl("^#{2,4} +Exercise", ln)) {
      exercise <- trimws(sub("\\{.*\\}", "", sub("^#+ +", "", ln)))
      exercise_id <- tolower(gsub("[^A-Za-z0-9]+", "-", exercise))
      q <- NULL
    } else if (!in_fence && grepl("^#{1,2} ", ln)) {
      exercise <- NULL; q <- NULL
    } else if (!in_fence && grepl("^\\s*[0-9]+\\.\\s+\\S", ln)) {
      q <- sub("^\\s*([0-9]+)\\..*$", "\\1", ln)
    } else if (!in_fence && grepl("^\\s*<details>\\s*$", ln)) {
      indent <- nchar(sub("<details>.*$", "", ln))
      j <- i + 1
      depth <- 1
      body <- character(0)
      while (j <= length(lines)) {
        if (grepl("^\\s*<details>\\s*$", lines[j])) depth <- depth + 1
        if (grepl("^\\s*</details>\\s*$", lines[j])) { depth <- depth - 1; if (depth == 0) break }
        body <- c(body, lines[j])
        j <- j + 1
      }
      summary <- regmatches(body, regexpr("(?<=<summary>).*?(?=</summary>)", body, perl = TRUE))
      summary <- if (length(summary)) summary[1] else "Answer"
      if (!grepl("video", summary, ignore.case = TRUE) && !is.null(exercise)) {
        body <- body[!grepl("^\\s*</?summary>|<summary>.*</summary>", body)]
        if (indent > 0) body <- sub(paste0("^ {0,", indent, "}"), "", body)
        label <- if (is.null(q)) exercise else paste0(exercise, ", question ", q)
        chapter_out <- c(chapter_out,
          paste0("### ", label, " {.unnumbered .bs-answer-head}"), "",
          paste0("[Back to the question](", page, "#", exercise_id, "){.bs-answer-back}"), "",
          "::: {.bs-answer-body}", body, ":::", "")
      }
      i <- j
    }
    i <- i + 1
  }
  if (length(chapter_out)) {
    heading <- if (unnumbered) title else paste(chapnum, title)
    out <- c(out, paste0("## ", heading, " {.unnumbered}"), "",
             paste0("[Go to chapter](", page, "){.bs-answer-back}"), "", chapter_out)
  }
}

# Answers may contain R chunks: load every package the chapters use.
libs <- unique(unlist(lapply(files, function(f) {
  l <- readLines(f, encoding = "UTF-8", warn = FALSE)
  regmatches(l, regexpr("library\\([A-Za-z0-9.]+\\)", l))
})))
if (length(libs)) {
  setup <- c("```{r}", "#| include: false", "#| message: false", "#| warning: false", libs, "```", "")
  out <- append(out, setup, after = 4)
}
con <- file("answers.qmd", open = "w", encoding = "UTF-8"); writeLines(out, con); close(con)
message("answers.qmd written")
