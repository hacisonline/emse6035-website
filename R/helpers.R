# helpers.R - shared code for every page of the tracker site.
# Sourced at the top of each .qmd with: source(file.path("R", "helpers.R"))
# _quarto.yml sets execute-dir: project, so paths are relative to the repo root.

suppressPackageStartupMessages({
  library(tidyverse)
  library(knitr)
  library(kableExtra)
})

today <- Sys.Date()

# Monday of week 1 (class 1 was Wed, Aug 26, 2026). Week 16 is the presentations week.
semester_start <- as.Date("2026-08-24")
semester_end   <- as.Date("2026-12-13")

read_data <- function(name) {
  readr::read_csv(file.path("data", name), show_col_types = FALSE)
}

semester_week <- function(d = today) {
  w <- as.integer(floor(as.numeric(as.Date(d) - semester_start) / 7)) + 1L
  pmin(pmax(w, 0L), 16L)
}

days_until <- function(d) as.integer(as.Date(d) - today)

when_label <- function(d) {
  n <- days_until(d)
  dplyr::case_when(
    is.na(n)  ~ "",
    n < -1    ~ paste0(abs(n), " days ago"),
    n == -1   ~ "yesterday",
    n == 0    ~ "today",
    n == 1    ~ "tomorrow",
    TRUE      ~ paste0("in ", n, " days")
  )
}

fmt_date <- function(d, fmt = "%a %b %e") {
  out <- format(as.Date(d), fmt)
  gsub("  ", " ", out)
}

status_slug <- function(s) {
  s <- tolower(trimws(s))
  dplyr::case_when(
    s %in% c("done", "graded", "submitted") ~ "done",
    s %in% c("in progress")                  ~ "active",
    s %in% c("blocked", "missed")            ~ "blocked",
    s %in% c("dropped")                      ~ "muted",
    TRUE                                     ~ "todo"
  )
}

pill <- function(s) {
  s <- as.character(s)
  ifelse(is.na(s) | s == "", "",
         sprintf('<span class="pill pill-%s">%s</span>', status_slug(s), s))
}

kind_pill <- function(k) {
  k <- as.character(k)
  ifelse(is.na(k) | k == "", "",
         sprintf('<span class="pill kind-%s">%s</span>', tolower(k), k))
}

nice_table <- function(df, ...) {
  knitr::kable(df, format = "html", escape = FALSE, ...) |>
    kableExtra::kable_styling(
      bootstrap_options = c("striped", "hover", "condensed"),
      full_width = TRUE,
      font_size = 14
    )
}

# Convenience: the deliverable pipeline, derived from deadlines.csv
deliverables <- function(deadlines) {
  deadlines |>
    dplyr::filter(kind == "project") |>
    dplyr::arrange(date) |>
    dplyr::mutate(n = dplyr::row_number(), .before = 1)
}
