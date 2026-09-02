# chart-modified.R ------------------------------------------------------------
# Share of flights delayed 15+ minutes at departure, by airline.
# EMSE 6035, week 2 practice, step 4: the same chart again, built under the
# MODIFIED my-chart-style skill. Compare with chart-plain.R (no skill) and
# chart-styled.R (skill as the professor shipped it).
#
# What the modified skill changes, and what it therefore forced here:
#   - House palette: focal deep teal #1B6B7A, context grey75, red reserved for a
#     mark the chart is actively warning about. So the styled version's dark red
#     bars become teal, and red now appears only on the airline being warned about.
#   - "Honest aggregates": n beside every mark, a declared min_n with thin marks
#     greyed and never ranked, exclusions itemised in the caption with counts, no
#     category allowed to vanish silently, and the title may only claim what the
#     visible marks support.
# In chart-styled.R those last points were my own judgement calls. Here the skill
# requires them, which is the whole point of putting a lesson in a skill.
#
# Run from the repo root (open the emse6035-website folder in Positron).
# Every path is built with file.path(), per the course convention.

library(tidyverse)
library(cowplot)

# Plot settings ---------------------------------------------------------------

font <- "sans"

plotColors <- c(
  focal   = "#1B6B7A",  # house teal: airlines with enough flights to rank
  context = "grey75",   # thin samples: shown, never ranked
  warn    = "#980000"   # reserved: the mark the chart is warning about
)

min_n <- 300  # stated in the subtitle, as the skill requires

# Paths -----------------------------------------------------------------------

data_dir <- file.path("practice", "week-02", "data")
figs_dir <- file.path("practice", "week-02", "figs")

flights_path  <- file.path(data_dir, "flights.csv")
airlines_path <- file.path(data_dir, "airlines.csv")
out_path      <- file.path(figs_dir, "delay-share-modified.png")

if (!dir.exists(figs_dir)) dir.create(figs_dir, recursive = TRUE)

# Read and join ---------------------------------------------------------------

flights <- read_csv(flights_path, show_col_types = FALSE)
airlines <- read_csv(airlines_path, show_col_types = FALSE)

flights_named <- flights |>
  left_join(airlines, by = "carrier")

stopifnot(!any(is.na(flights_named$name)))

# Exclusions, counted before they are made ------------------------------------

n_total <- nrow(flights_named)
n_cancelled <- sum(is.na(flights_named$dep_delay))

# "Never let a category vanish": catch any airline that loses every row.
vanished <- flights_named |>
  group_by(name) |>
  summarise(departures = sum(!is.na(dep_delay)), .groups = "drop") |>
  filter(departures == 0) |>
  pull(name)

# Summarise -------------------------------------------------------------------

delay_share <- flights_named |>
  filter(!is.na(dep_delay)) |>
  group_by(name) |>
  summarise(
    n_flights = n(),
    share = mean(dep_delay >= 15),
    .groups = "drop"
  ) |>
  mutate(name = fct_reorder(name, share))

# The worst airline among those the chart is allowed to rank.
rankable <- delay_share |> filter(n_flights >= min_n)
worst <- rankable |> slice_max(share, n = 1)

delay_share <- delay_share |>
  mutate(
    band = case_when(
      name == worst$name       ~ "warn",
      n_flights >= min_n       ~ "focal",
      TRUE                     ~ "context"
    )
  )

# Title may only claim what the visible marks support.
plot_title <- paste0(
  worst$name, " is the airline worth avoiding, at ",
  scales::percent(worst$share, accuracy = 1), " of departures delayed"
)

plot_subtitle <- paste0(
  "Flights delayed 15 or more minutes at departure. Grey bars rest on fewer than ",
  min_n, " departures:\nthey are shown but not ranked, and the three sitting above ",
  worst$name, " are small-sample noise."
)

caption_text <- paste0(
  "Data source: nycflights13 sample of ", format(n_total, big.mark = ","),
  " flights (2013), EMSE 6035 week 2 practice files. ",
  "Excluded: ", n_cancelled, " flights with no recorded departure (cancelled), ",
  "which cannot be delayed. ",
  if (length(vanished) > 0) {
    paste0(
      "Not shown: ", paste(vanished, collapse = ", "),
      " lost every flight to that exclusion (",
      nrow(flights_named[flights_named$name %in% vanished, ]),
      " flight(s) in sample, all cancelled), so no share exists. "
    )
  } else {
    ""
  },
  "n beside each bar is the number of departures behind it."
)

# Plot ------------------------------------------------------------------------

plot <- delay_share |>
  ggplot() +
  geom_col(aes(x = share, y = name, fill = band), width = 0.75) +
  geom_text(
    aes(
      x = share,
      y = name,
      label = paste0(scales::percent(share, accuracy = 1), "   n = ", n_flights),
      color = band
    ),
    hjust = -0.1,
    size = 3.2,
    family = font,
    show.legend = FALSE
  ) +
  scale_fill_manual(values = plotColors) +
  scale_color_manual(
    values = c(focal = "grey25", context = "grey60", warn = "grey25")
  ) +
  scale_x_continuous(
    labels = scales::percent,
    breaks = seq(0, 0.30, 0.05),
    expand = expansion(mult = c(0, 0.18))
  ) +
  labs(
    x = "Share of departures delayed 15+ minutes",
    y = NULL,
    title = plot_title,
    subtitle = plot_subtitle,
    caption = str_wrap(caption_text, width = 120)
  ) +
  theme_minimal_vgrid(font_family = font, font_size = 12) +
  theme(
    plot.title.position = "plot",
    plot.caption.position = "plot",
    plot.caption = element_text(hjust = 0, face = "italic", size = 8, color = "grey40"),
    plot.subtitle = element_text(size = 10, color = "grey30"),
    legend.position = "none",
    panel.background = element_rect(fill = "white", color = NA),
    plot.background = element_rect(fill = "white", color = NA)
  )

ggsave(out_path, plot, width = 9, height = 6.5, dpi = 300)

message("wrote ", out_path)
