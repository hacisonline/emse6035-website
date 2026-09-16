# CLAUDE.md - emse6035-website

Standing instructions for any agent opened in this folder. Read this first, then `context-bank/` on the rendered site or in source.

## What this is

A Quarto website that tracks the EMSE 6035 (GWU, Fall 2026) team project for the semester: a computed schedule (critical path method over the activity list), a Gantt chart, a risk register, week-by-week progress, a dev log, and a context bank of course facts. It was started on 2026-09-02 during the week 2 in-class agentic workflows exercise, replanned on 2026-09-16 once the team and topic existed, and is maintained all semester. It is published with GitHub Pages from the `docs/` folder of the `main` branch of this repo on GitHub, so **the repo is public**.

This repo is self-contained. It does not depend on, read from, or write to any other folder. Course facts it needs are copied into `data/*.csv` and `context-bank/*.qmd`; if something is missing, ask the owner rather than looking elsewhere.

## Layout

```
_quarto.yml            site config: output-dir docs, execute-dir project, navbar, theme, the script include
theme.scss             Bootstrap variable overrides on top of cosmo (font, colours, navbar)
styles.css             the visual system: tokens, pills, cards, tables, Gantt and chain styling
index.qmd              home dashboard (next deadline, schedule health, zero-float count, four-week Gantt, chain)
data/activities.csv    the work breakdown (id, phase, activity, owner, start, due, deadline, depends_on, status, pct, deliverable, notes)
data/deadlines.csv     every dated item of the semester (date, item, kind, weight_pct, where, state, notes)
data/weeks.csv         the sixteen class weeks (week, date, class_topic, quiz, homework_due, project_due, project_focus, status, progress_note)
data/risks.csv         the risk register (id, risk, phase, likelihood, impact, trigger, response, owner, status, activities)
R/helpers.R            shared R: read_activities(), cpm(), schedule_health(), embed_schedule(), pills, tables
assets/tracker.html    the client-side schedule views (Gantt, deliverable chain) as one inline <script>, included on every page
tracker/               schedule.qmd (full Gantt), critical-path.qmd (chain, critical-only Gantt, float table),
                       activities.qmd (planned vs computed dates), risks.qmd (matrix and register), progress.qmd (weeks)
devlog/                index.qmd (listing) and posts/YYYY-MM-DD-slug/index.qmd, one per work session
context-bank/          course, deadlines, project-requirements, team, conventions
favicon.svg
.claude/skills/        project skills (my-chart-style, from the week 2 class folder); settings.local.json stays untracked
practice/week-NN/      class exercises with their data, scripts and figs; not rendered, not part of the tracker
docs/                  rendered output, committed (GitHub Pages serves it)
```

## How the schedule is computed

`cpm()` in `R/helpers.R` runs on every render with today as the status date. Durations are calendar days (`due - start + 1`). `depends_on` holds finish-to-start predecessors separated by `;`. Planned `start` is a start-no-earlier-than constraint. `deadline` is a hard finish-no-later-than constraint (the official due date) and belongs only on the submission activity of each deliverable. Forward pass: Done keeps its actual dates; In progress starts on its start date and finishes on its due date or today, whichever is later; Not started begins at the latest of its planned start, today, and every predecessor's early finish plus one. Backward pass from the deadlines gives late dates; total float is late start minus early start (late finish minus early finish while in progress); critical is float zero or less, near-critical one to three days. Activities with no deadline downstream are open-ended and get no float. The JSON that `embed_schedule()` writes into a page is what `assets/tracker.html` draws.

To move the plan, change dates or dependencies in `activities.csv`; never edit computed numbers by hand. If two activities really overlap, do not chain them (finish-to-start means the successor waits); depend on the earlier activity instead.

## How to run

- Render everything: `quarto render` (from the repo root; a Positron terminal with this folder opened, or any native shell).
- Live preview while editing: `quarto preview`.
- R packages used: tidyverse, knitr, jsonlite (all in the course's package list). kableExtra is deliberately not used: its kePrint.js expects jQuery and errors in the console.
- Never change the working directory from code; never use absolute paths; read files with `file.path("data", "x.csv")`. `execute-dir: project` makes that work from every page.

## Making changes

- Facts go in the CSVs, not in prose. A status change is a CSV edit (status and pct), a render, a commit that includes `docs/`, and a push.
- Statuses: activities use Not started / In progress / Done / Blocked / Dropped; dated items and weeks use Upcoming / In progress / Submitted / Graded / Done / Missed / Dropped; risks use Open / Closed. `R/helpers.R` maps these to colours; do not invent new ones without adding them there.
- Every work session ends with a new dev log post (`devlog/posts/YYYY-MM-DD-slug/index.qmd`, front matter: title, description, author, date, categories) and updated activity statuses. Keep the post to what was asked, what was built, how it was verified, what is next.
- Adding a page that needs the Gantt or the chain: source `R/helpers.R`, compute `sched <- cpm(read_activities())`, call `embed_schedule(sched, deadlines, weeks)` once inside a `results: asis` chunk, then print `<div data-tracker="gantt" ...>` or `<div data-tracker="chain">`. Gantt attributes: `data-mode` (all, open, critical, phase:Name), `data-window` (semester, next4), `data-controls`, `data-load`, `data-legend` (true/false).
- Chart colours follow the eight-slot categorical palette in `styles.css` in its fixed order (Setup to Presentation); status colours (critical red, warning amber) are never reused for a phase. Text never wears a phase colour.
- Dates in the CSVs are ISO (`YYYY-MM-DD`). Tracked due dates are the earlier of the two dates the course materials show for a deliverable.
- After editing, always render and read the output before committing. A page that errors means `docs/` is stale and the live site shows the old version.

## Verify before you commit

- `quarto render` completes with no errors and no R warnings about missing columns or unknown predecessors (`cpm()` stops on an unknown id or a cycle).
- Counts on the home page match the CSVs (`nrow(activities)`, deliverables 7).
- No new column was added to a CSV without the page code that uses it.
- Nothing in the diff is a grade, an email address, a netID, a GitHub username, a phone number, a token or key, or a detail about anyone's work outside the course. This site is public; the team page carries first names only.

## Git

- Commit and push from a native terminal in this folder: `git add -A && git commit -m "..." && git push`. Commit messages name the change ("Mark P08 done, add Sep 20 dev log").
- Commit `docs/` with the source that produced it; never commit source without re-rendering.
- Never force-push, never rewrite history, never delete the repo.
- `.gitignore` keeps out `.quarto/`, `_site/`, `.Rproj.user/`, `.Renviron`, `.env`, `.DS_Store` and `*.quarto_ipynb` (Quarto appends that last line itself on render; leave it). Do not add `.Renviron` or any credential file, ever.
