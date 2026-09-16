# helpers.R - shared code for every page of the tracker site.
# Sourced at the top of each .qmd with: source(file.path("R", "helpers.R"))
# _quarto.yml sets execute-dir: project, so paths are relative to the repo root.

suppressPackageStartupMessages({
  library(tidyverse)
  library(knitr)
  library(jsonlite)
})

today <- Sys.Date()

# Monday of week 1 (class 1 was Wed, Aug 26, 2026). Week 16 is the presentations week.
semester_start <- as.Date("2026-08-24")
semester_end   <- as.Date("2026-12-13")
project_end    <- as.Date("2026-12-09")   # last dated activity: the presentation

phase_levels <- c("Setup", "Proposal", "Survey plan", "Pilot survey",
                  "Pilot analysis", "Final survey", "Final analysis",
                  "Presentation", "Ongoing")

read_data <- function(name) {
  readr::read_csv(file.path("data", name), show_col_types = FALSE)
}

read_activities <- function() {
  read_data("activities.csv") |>
    mutate(
      start    = as.Date(start),
      due      = as.Date(due),
      deadline = as.Date(deadline),
      pct      = replace_na(as.numeric(pct), 0),
      phase    = factor(phase, levels = phase_levels)
    )
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
  out <- gsub("  ", " ", out)
  ifelse(is.na(d), "", out)
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

phase_dot <- function(p) {
  p <- as.character(p)
  slug <- tolower(gsub(" ", "-", p))
  ifelse(is.na(p) | p == "", "",
         sprintf('<span class="phase-dot phase-%s"></span>%s', slug, p))
}

float_pill <- function(tf, status) {
  slug <- status_slug(status)
  dplyr::case_when(
    slug == "done"        ~ '<span class="pill pill-done">done</span>',
    is.na(tf)             ~ '<span class="pill pill-todo">open</span>',
    tf < 0                ~ sprintf('<span class="pill pill-blocked">%d d late</span>', abs(tf)),
    tf == 0               ~ '<span class="pill pill-critical">0 d</span>',
    tf <= 3               ~ sprintf('<span class="pill pill-near">%d d</span>', tf),
    TRUE                  ~ sprintf('<span class="pill pill-todo">%d d</span>', tf)
  )
}

# Plain knitr table with Bootstrap classes, wrapped in a horizontal-scroll
# container so wide tables never force the page to scroll sideways on a phone.
# (kableExtra's kable_styling was dropped: its kePrint.js dependency expects
# jQuery, which Quarto does not load, and threw a console error on every page.)
nice_table <- function(df, ..., class = "") {
  k <- knitr::kable(
    df, format = "html", escape = FALSE,
    table.attr = sprintf('class="table table-hover table-sm nice-table %s"', class),
    ...
  )
  structure(paste0('<div class="table-wrap">', as.character(k), '</div>'),
            format = "html", class = "knitr_kable")
}

# Convenience: the deliverable pipeline, derived from deadlines.csv
deliverables <- function(deadlines) {
  deadlines |>
    dplyr::filter(kind == "project") |>
    dplyr::arrange(date) |>
    dplyr::mutate(n = dplyr::row_number(), .before = 1)
}

# ---------------------------------------------------------------------------
# Critical path method on data/activities.csv
#
# Time is in calendar days (the team works weekends). An activity occupies the
# closed interval [start, due]; duration = due - start + 1. depends_on holds
# finish-to-start predecessors. Planned start dates are start-no-earlier-than
# constraints (they encode when the course teaches what the activity needs).
# deadline is a hard finish-no-later-than constraint (the official due date).
#
# Forward pass, with today as the status date:
#   Done:        ES = start, EF = due (actuals)
#   In progress: ES = start, EF = max(due, today)
#   Not started: ES = max(start, today, EF of every predecessor + 1)
#                EF = ES + duration - 1
# Backward pass: LF = min(deadline, LS of every successor - 1), LS = LF - duration + 1.
# An activity is "constrained" if it has a deadline or any successor is
# constrained; only constrained activities get late dates and float.
# Total float: LS - ES (not started), LF - EF (in progress), NA when done.
# Free float: min(ES of successors) - EF - 1.
# Critical: total float <= 0. Near-critical: 1 to 3 days.
# ---------------------------------------------------------------------------
cpm <- function(acts, status_date = today) {
  a <- acts |>
    mutate(
      dur   = as.integer(due - start) + 1L,
      preds = map(depends_on, function(s) {
        if (is.na(s) || trimws(s) == "") character(0)
        else trimws(str_split(s, ";")[[1]])
      })
    )
  ids <- a$id
  idx <- setNames(seq_along(ids), ids)
  n <- nrow(a)

  # successors
  succs <- vector("list", n)
  for (i in seq_len(n)) succs[[i]] <- integer(0)
  for (i in seq_len(n)) {
    for (p in a$preds[[i]]) {
      if (!p %in% ids) stop("Unknown predecessor '", p, "' on ", ids[i])
      j <- idx[[p]]
      succs[[j]] <- c(succs[[j]], i)
    }
  }

  # topological order (Kahn)
  indeg <- map_int(a$preds, length)
  queue <- which(indeg == 0)
  order <- integer(0)
  while (length(queue)) {
    i <- queue[1]; queue <- queue[-1]
    order <- c(order, i)
    for (j in succs[[i]]) {
      indeg[j] <- indeg[j] - 1L
      if (indeg[j] == 0) queue <- c(queue, j)
    }
  }
  if (length(order) != n) stop("Dependency cycle in activities.csv")

  ES <- EF <- LS <- LF <- rep(as.Date(NA), n)
  slug <- status_slug(a$status)

  for (i in order) {
    if (slug[i] == "done") {
      ES[i] <- a$start[i]; EF[i] <- a$due[i]
    } else if (slug[i] == "active") {
      ES[i] <- a$start[i]; EF[i] <- max(a$due[i], status_date)
    } else {
      es <- max(a$start[i], status_date)
      for (p in a$preds[[i]]) es <- max(es, EF[idx[[p]]] + 1)
      ES[i] <- es; EF[i] <- es + a$dur[i] - 1L
    }
  }

  constrained <- logical(n)
  for (i in rev(order)) {
    constrained[i] <- !is.na(a$deadline[i]) || any(constrained[succs[[i]]])
    if (!constrained[i]) next
    lf <- if (!is.na(a$deadline[i])) a$deadline[i] else project_end
    for (j in succs[[i]]) if (!is.na(LS[j])) lf <- min(lf, LS[j] - 1)
    LF[i] <- lf
    LS[i] <- lf - a$dur[i] + 1L
  }

  TF <- ifelse(slug == "done" | !constrained, NA_integer_,
        ifelse(slug == "active", as.integer(LF - EF), as.integer(LS - ES)))
  FF <- map_int(seq_len(n), function(i) {
    if (slug[i] == "done" || length(succs[[i]]) == 0) return(NA_integer_)
    as.integer(min(ES[succs[[i]]]) - EF[i] - 1L)
  })
  succ_ids <- map_chr(succs, function(s) paste(ids[s], collapse = ";"))

  a |>
    mutate(
      es = ES, ef = EF, ls = LS, lf = LF,
      total_float = TF, free_float = FF,
      constrained = constrained,
      successors = succ_ids,
      critical = !is.na(TF) & TF <= 0,
      near_critical = !is.na(TF) & TF > 0 & TF <= 3,
      overdue = slug != "done" & due < status_date,
      slipped = !is.na(es) & es > start & slug == "todo"
    ) |>
    select(-preds)
}

# Schedule health: duration-weighted planned progress to the status date versus
# reported progress. Ongoing activities are excluded (they are always "in progress").
schedule_health <- function(sched, status_date = today) {
  s <- sched |> filter(phase != "Ongoing")
  planned_frac <- pmin(pmax(as.numeric(status_date - s$start + 1) / s$dur, 0), 1)
  planned <- sum(planned_frac * s$dur)
  earned  <- sum((s$pct / 100) * s$dur)
  list(
    planned_pct = round(100 * planned / sum(s$dur)),
    earned_pct  = round(100 * earned / sum(s$dur)),
    spi = if (planned > 0) round(earned / planned, 2) else NA_real_
  )
}

# JSON payload for the JavaScript schedule (Gantt, chain, load lane).
schedule_json <- function(sched, deadlines, weeks, status_date = today) {
  acts <- sched |>
    transmute(
      id, phase = as.character(phase), activity, owner,
      start = format(start), due = format(due),
      deadline = ifelse(is.na(deadline), NA, format(deadline)),
      es = format(es), ef = format(ef),
      ls = ifelse(is.na(ls), NA, format(ls)), lf = ifelse(is.na(lf), NA, format(lf)),
      dur, pct, status, deliverable = replace_na(deliverable, ""),
      depends_on = replace_na(depends_on, ""), successors,
      total_float, free_float, critical, near_critical, overdue, slipped,
      notes = replace_na(notes, "")
    )
  events <- deadlines |>
    filter(kind != "class") |>
    transmute(date = format(date), item, kind, state)
  wk <- weeks |> transmute(week, date = format(date), topic = class_topic, status)
  jsonlite::toJSON(list(
    today = format(status_date),
    semester_start = format(semester_start),
    semester_end = format(semester_end),
    activities = acts, events = events, weeks = wk
  ), na = "null", auto_unbox = TRUE)
}

embed_schedule <- function(sched, deadlines, weeks) {
  cat('<script type="application/json" id="schedule-data">',
      schedule_json(sched, deadlines, weeks),
      '</script>', sep = "\n")
}
