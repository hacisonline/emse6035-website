# CLAUDE.md - emse6035-website

Standing instructions for any agent opened in this folder. Read this first, then `context-bank/` on the rendered site or in source.

## What this is

A Quarto website that tracks the EMSE 6035 (GWU, Fall 2026) team project for the semester: activities, critical path, week-by-week progress, a dev log, and a context bank of course facts. It was started on 2026-09-02 during the week 2 in-class agentic workflows exercise and is maintained all semester. It is published with GitHub Pages from the `docs/` folder of the `main` branch of this repo on GitHub, so **the repo is public**.

This repo is self-contained. It does not depend on, read from, or write to any other folder. Course facts it needs are copied into `data/*.csv` and `context-bank/*.qmd`; if something is missing, ask the owner rather than looking elsewhere.

## Layout

```
_quarto.yml            site config: output-dir docs, execute-dir project, navbar, sidebar
index.qmd              home dashboard (computed from the CSVs)
data/deadlines.csv     every dated item of the semester (date, item, kind, weight_pct, where, state, notes)
data/activities.csv    the activity list (id, phase, activity, owner, start, due, depends_on, critical, status, deliverable, notes)
data/weeks.csv         the sixteen class weeks (week, date, class_topic, quiz, homework_due, project_due, project_focus, status, progress_note)
R/helpers.R            shared R: read_data(), semester_week(), when_label(), pill(), nice_table(), deliverables()
tracker/               activities.qmd, critical-path.qmd (two mermaid blocks + computed float table), progress.qmd
devlog/                index.qmd (listing) and posts/YYYY-MM-DD-slug/index.qmd, one per work session
context-bank/          course, deadlines, project-requirements, team, conventions
styles.css, favicon.svg
.claude/skills/        project skills (my-chart-style, from the week 2 class folder); settings.local.json stays untracked
practice/week-NN/      class exercises with their data, scripts and figs; not rendered, not part of the tracker
docs/                  rendered output, committed (GitHub Pages serves it)
```

## How to run

- Render everything: `quarto render` (from the repo root; Positron terminal with this folder opened).
- Live preview while editing: `quarto preview`.
- R packages used: tidyverse, knitr, kableExtra (the course's package list covers them).
- Never change the working directory from code; never use absolute paths; read files with `file.path("data", "x.csv")`. `execute-dir: project` makes that work from every page.

## Making changes

- Class exercises live under `practice/week-NN/`, read data with `file.path("practice", "week-NN", "data", ...)` and save figures to that week's `figs/`; ggplot2 code follows `/my-chart-style`.
- Facts go in the CSVs, not in prose. A status change is a CSV edit, a render, a commit that includes `docs/`, and a push.
- Statuses: activities use Not started / In progress / Done / Blocked / Dropped; dated items and weeks use Upcoming / In progress / Submitted / Graded / Done / Missed / Dropped. `R/helpers.R` maps these to colours; do not invent new ones without adding them there.
- Every work session ends with a new dev log post (`devlog/posts/YYYY-MM-DD-slug/index.qmd`, front matter: title, description, author, date, categories) and updated activity statuses. Keep the post to what was asked, what was built, how it was verified, what is next.
- The critical-path diagrams in `tracker/critical-path.qmd` are hand-written mermaid; update them when the activity dates move. The float table beneath them is computed.
- Dates in the CSVs are ISO (`YYYY-MM-DD`). Tracked due dates are the earlier of the two dates the course materials show for a deliverable.
- After editing, always render and read the output before committing. A page that errors means `docs/` is stale and the live site shows the old version.

## Verify before you commit

- `quarto render` completes with no errors and no R warnings about missing columns.
- Counts on the home page match the CSVs (`nrow(activities)`, deliverables 7).
- No new column was added to a CSV without the page code that uses it.
- Nothing in the diff is a grade, an email address, a netID, a phone number, a token or key, or a detail about anyone's work outside the course. This site is public.

## Git

- Commit and push from the terminal in this folder: `git add -A && git commit -m "..." && git push`. Commit messages name the change ("Mark A03 done, add Sep 9 dev log").
- Commit `docs/` with the source that produced it; never commit source without re-rendering.
- Never force-push, never rewrite history, never delete the repo.
- `.gitignore` keeps out `.quarto/`, `_site/`, `.Rproj.user/`, `.Renviron`, `.env`, `.DS_Store`. Do not add `.Renviron` or any credential file, ever.
