# Week 2 practice: see the difference a skill makes

Class-2 exercise (not part of the tracker site; nothing here is rendered).
`data/` holds the class `flights.csv` (10,000 flights from the 2013 NYC data) and
`airlines.csv` (carrier code to name). Charts go in `figs/`, scripts beside this file.

Steps from the deck:

1. The `my-chart-style` skill is in `.claude/skills/my-chart-style/SKILL.md` (copied
   from the class folder; the untouched copy is `SKILL.md.original`, gitignored).
2. Pick a chart on `flights.csv`.
3. Ask Claude for it without the skill (`chart-plain.R`), then with `/my-chart-style`
   (`chart-styled.R`).
4. Modify the skill, then make the chart again (`chart-modified.R`). Done 2026-09-02:
   the skill's palette became the house teal/amber/grey with red reserved for a mark
   the chart warns about, and a new "Honest aggregates" section makes the sample-size
   and exclusion rules mandatory instead of a per-chart judgement call.

Paths are relative to the repo folder opened in Positron:
`file.path("practice", "week-02", "data", "flights.csv")`.

## Source and license

`data/flights.csv`, `data/airlines.csv` and `.claude/skills/my-chart-style/SKILL.md`
are the professor's class-2 materials, taken from the public course repository
<https://github.com/emse-madd-gwu/2026-Fall> (`class/2-agentic-workflows/`) and the
class page <https://madd.seas.gwu.edu/2026-Fall/class/2-agentic-workflows.html>.
Course materials are CC-BY-SA 4.0, John Paul Helveston, EMSE 6035, GWU, Fall 2026;
they are redistributed here under that license with attribution. `SKILL.md` HAS BEEN
MODIFIED from the original as part of step 4 above, and says so in its own header;
the unmodified copy is kept beside it as `SKILL.md.original` (gitignored). The
scripts and figures in this folder are my own coursework. Assignment and quiz solutions are
proprietary per the syllabus and are not kept here.
