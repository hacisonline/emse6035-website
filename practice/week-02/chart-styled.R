# chart-styled.R --------------------------------------------------------------
# Share of flights delayed 15+ minutes at departure, by airline.
# EMSE 6035, week 2 practice. This is the STYLED chart, written under
# /my-chart-style, to be compared against chart-plain.R.
#
# Run from the repo root (open the emse6035-website folder in Positron).
# Every path is built with file.path(), per the course convention.

library(tidyverse)
library(cowplot)

# Plot settings ---------------------------------------------------------------

font <- "sans"

plotColors <- c(
  reliable = "#980000FF",  # airlines with enough flights to trust
  thin     = "grey70"      # airlines whose bar rests on a handful of flights
)

min_flights <- 300  # below this, a share is too noisy to rank on

plot_title <- "ExpressJet is the airline actually worth avoiding"
plot_subtitle <- paste0(
  "Share of flights delayed 15 or more minutes at departure. Grey bars rest on ",
  "fewer than ", min_flights, " departures\nand are too noisy to rank: the three ",
  "airlines above ExpressJet are small-sample artifacts."
)

# Paths -----------------------------------------------------------------------

data_dir <- file.path("practice", "week-02", "data")
figs_dir <- file.path("practice", "week-02", "figs")

flights_path  <- file.path(data_dir, "flights.csv")
airlines_path <- file.path(data_dir, "airlines.csv")
out_path      <- file.path(figs_dir, "delay-share-styled.png")

if (!dir.exists(figs_dir)) dir.create(figs_dir, recursive = TRUE)

# Read and join ---------------------------------------------------------------

flights <- read_csv(flights_path, show_col_types = FALSE)
airlines <- read_csv(airlines_path, show_col_types = FALSE)

flights_named <- flights |>
  left_join(airlines, by = "carrier")

stopifnot(!any(is.na(flights_named$name)))

# Account for what gets excluded ----------------------------------------------
# dep_delay is NA when the flight never departed (cancelled). Count those before
# dropping them, and catch any airline that loses every flight that way.

n_total <- nrow(flights_named)
n_cancelled <- sum(is.na(flights_named$dep_delay))

dropped <- flights_named |>
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
  mutate(
    sample = if_else(n_flights >= min_flights, "reliable", "thin"),
    name = fct_reorder(name, share)
  )

caption_text <- paste0(
  "Data source: nycflights13 sample of ", format(n_total, big.mark = ","),
  " flights (2013), week 2 class practice files. ",
  n_cancelled, " flights with no recorded departure (cancelled) are excluded. ",
  if (length(dropped) > 0) {
    paste0(
      "Not shown: ", paste(dropped, collapse = ", "),
      ", which has no departures in this sample, so no share can be computed. "
    )
  } else {
    ""
  },
  "n is the number of departures behind each bar."
)

# Plot ------------------------------------------------------------------------

plot <- delay_share |>
  ggplot() +
  geom_col(
    aes(x = share, y = name, fill = sample),
    width = 0.75
  ) +
  geom_text(
    aes(
      x = share,
      y = name,
      label = paste0(scales::percent(share, accuracy = 1), "   n = ", n_flights),
      color = sample
    ),
    hjust = -0.1,
    size = 3.2,
    family = font,
    show.legend = FALSE
  ) +
  scale_fill_manual(values = plotColors) +
  scale_color_manual(values = c(reliable = "grey25", thin = "grey55")) +
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
