---
name: my-chart-style
description: House conventions for making polished ggplot2 charts in R — cowplot minimal themes, white backgrounds, direct labeling, informative titles, and ggsave conventions. Use whenever writing or editing ggplot2 code (plots, charts, figures in R scripts, Quarto docs, or slides).
---

# my-chart-style: polished ggplot2 conventions

Follow these conventions whenever writing ggplot2 code. The goal is a clean,
report-ready chart every time, without restating the style.

## Standard setup

```r
library(tidyverse)
library(cowplot)

font <- "sans"  # generic default; swap for any installed font you like
```

- Always `library(tidyverse)` + `library(cowplot)`. Add as needed: `ggrepel`
  (direct labels), `ggtext` (markdown in titles), `scales` (label formatting).
- Use the native pipe `|>`.
- Define plot settings (font, colors, long title/caption strings) as variables
  at the top of the script.

## Fonts

Define the font once at the top and pass it everywhere — to the theme
(`font_family = font`) and to every text geom (`family = font` in
`geom_text()` / `geom_text_repel()` / `geom_label()`). `"sans"` is a safe default
that always resolves; swap in any installed font (e.g. a condensed font like
`"Roboto Condensed"`) if you have it.

## Themes: cowplot minimal themes, matched to plot type

Never use `theme_gray()` or a bare `theme_minimal()`. Pick the cowplot theme by
gridline direction:

| Plot type | Theme |
|---|---|
| Vertical bars / columns | `theme_minimal_hgrid(font_family = font)` |
| Horizontal bars, dot / error-bar plots (y = categories) | `theme_minimal_vgrid(font_family = font)` |
| Scatter plots, line charts, faceted grids | `theme_minimal_grid(font_family = font)` |

Set font size in the theme call when needed:
`theme_minimal_grid(font_family = font, font_size = 16)`.

### Standard theme() additions

Always force solid white backgrounds (so saved PNGs aren't transparent):

```r
theme_minimal_hgrid(font_family = font) +
theme(
  plot.title.position = "plot",
  plot.caption.position = "plot",
  panel.background = element_rect(fill = "white", color = NA),
  plot.background = element_rect(fill = "white", color = NA)
)
```

When faceting, also add `strip.background = element_rect(fill = "grey80", color = NA)`,
`panel.grid.minor = element_blank()`, and `panel_border()` (cowplot) after `theme()`.

## Legends: prefer direct labeling

Default to `legend.position = "none"` and label series directly:

- **Line charts**: label at the line ends with `geom_text_repel()` on the
  last-period data, making room via x-axis expansion
  (`scale_x_continuous(expand = expansion(mult = c(0.02, 0.15)))`).
- **Stacked bars**: `geom_text()` next to the final stacked bar at segment midpoints.

When a legend is genuinely needed, place it inside the panel
(`legend.position = c(0.05, 0.9)`) or at `"bottom"`.

## Colors

- Define a named `plotColors` vector at the top of the script and apply with
  `scale_color_manual()` / `scale_fill_manual()`.
- A reliable palette: green `#8FC977FF`, blue `#80C5DCFF`, yellow `#E8BF4DFF`,
  orange `#E37D39FF`, red `#980000FF`, gray `grey70`.
- Use grays (`grey60`–`grey80`) to de-emphasize context categories and a
  saturated color for the focal series.

## Scales and axes

- Explicit breaks: `breaks = seq(2014, 2025)`, `breaks = seq(0, 100, 20)`.
- Bars sit on the axis: `scale_y_continuous(expand = expansion(mult = c(0, 0.05)))`.
- Formatted labels via scales: `scales::dollar`, `scales::percent`, `scales::comma`.
- Zoom with `coord_cartesian(xlim = ..., ylim = ...)` rather than scale limits
  (avoids dropping data); add `clip = "off"` when labels extend past the panel.
- Drop redundant axis titles: `x = NULL` when the axis is self-evident (e.g., years).

## Labels

Every polished chart gets full `labs()`: `x`, `y`, `title`, and where relevant
`subtitle` (states the takeaway in a sentence) and `caption` (data source).

## Factor ordering

Set factor levels explicitly before plotting to control stack / legend / facet
order, e.g. `fct_relevel()` / `fct_reorder()` in a `mutate()`.

## Saving

Save with `ggsave()` to a `figs/` folder, with explicit dimensions and a path
built via `file.path()` or `here::here()`:

```r
ggsave(
  file.path("figs", "annual-sales.png"),
  width = 9,
  height = 6.5,
  dpi = 300
)
```

Common sizes: single chart ~7×5 to 9×6.5; wide faceted rows ~11–12 × 3.5–5.5.

## Full example

```r
library(tidyverse)
library(cowplot)

font <- "sans"
plotColors <- c(focus = "#980000FF", other = "grey60")

plot <- df |>
  ggplot() +
  geom_col(aes(x = year, y = sales, fill = type), width = 0.8) +
  scale_fill_manual(values = as.vector(plotColors)) +
  scale_x_continuous(breaks = seq(2011, 2025, 1)) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05))) +
  labs(
    x = NULL,
    y = "Annual Vehicle Sales (Millions)",
    title = "In the US, PEV sales continue to grow",
    subtitle = "PEV share of new vehicle sales has risen steadily",
    caption = "Data source: AFDC"
  ) +
  theme_minimal_hgrid(font_family = font) +
  theme(
    plot.title.position = "plot",
    plot.caption.position = "plot",
    plot.caption = element_text(hjust = 0, face = "italic"),
    legend.position = "none",
    panel.background = element_rect(fill = "white", color = NA),
    plot.background = element_rect(fill = "white", color = NA)
  )

ggsave(file.path("figs", "annual-sales.png"), plot, width = 9, height = 6.5, dpi = 300)
```
