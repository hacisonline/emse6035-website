# chart-plain.R ---------------------------------------------------------------
# Share of flights delayed 15+ minutes at departure, by airline.
# EMSE 6035, week 2 practice. This is the PLAIN chart: no skill applied, so it
# can be compared against the same chart built with /my-chart-style.
#
# Run from the repo root (open the emse6035-website folder in Positron).
# Every path is built with file.path(), per the course convention.

library(tidyverse)

# Paths -----------------------------------------------------------------------

data_dir <- file.path("practice", "week-02", "data")
figs_dir <- file.path("practice", "week-02", "figs")

flights_path  <- file.path(data_dir, "flights.csv")
airlines_path <- file.path(data_dir, "airlines.csv")
out_path      <- file.path(figs_dir, "delay-share-plain.png")

if (!dir.exists(figs_dir)) dir.create(figs_dir, recursive = TRUE)

# Read ------------------------------------------------------------------------

flights  <- read_csv(flights_path,  show_col_types = FALSE)
airlines <- read_csv(airlines_path, show_col_types = FALSE)

# Join the airline names onto the flights. left_join keeps every flight, so a
# carrier code with no matching name would show up as NA rather than vanish.
flights_named <- flights |>
  left_join(airlines, by = "carrier")

stopifnot(!any(is.na(flights_named$name)))

# Count what we are about to throw away ---------------------------------------
# dep_delay is NA when the flight never departed (cancelled). Those flights
# cannot be "delayed 15+ minutes", but they also should not silently disappear:
# a carrier whose only flights were cancelled would drop off the chart with no
# trace. So count them first, then report them in the caption.

n_total     <- nrow(flights_named)
n_cancelled <- sum(is.na(flights_named$dep_delay))

departed <- flights_named |>
  filter(!is.na(dep_delay))

# Carriers present in the data but with no departure on record at all.
dropped <- flights_named |>
  group_by(name) |>
  summarise(departures = sum(!is.na(dep_delay)), .groups = "drop") |>
  filter(departures == 0) |>
  pull(name)

# Summarise -------------------------------------------------------------------

delay_share <- departed |>
  group_by(name) |>
  summarise(
    n_flights = n(),
    n_delayed = sum(dep_delay >= 15),
    share     = n_delayed / n_flights,
    .groups   = "drop"
  ) |>
  arrange(share)

# Keep the sorted order when ggplot draws the bars.
delay_share <- delay_share |>
  mutate(name = factor(name, levels = name))

print(delay_share, n = nrow(delay_share))

# Caption ---------------------------------------------------------------------
# Say out loud what the chart rests on: the sample, what was excluded, and any
# airline that fell out entirely.

caption_text <- paste0(
  "Sample of ", format(n_total, big.mark = ","), " flights (2013). ",
  n_cancelled, " with no recorded departure (cancelled) are excluded.",
  if (length(dropped) > 0) {
    paste0(
      "\nNot shown: ", paste(dropped, collapse = ", "),
      " (no departures in this sample, so no share can be computed)."
    )
  } else {
    ""
  },
  "\nn beside each bar is the number of departures it is computed from. ",
  "The smallest bars rest on very few flights."
)

# Plot ------------------------------------------------------------------------

bar_fill  <- "#2a78d6"
ink       <- "#0b0b0b"
ink_muted <- "#52514e"
surface   <- "#fcfcfb"

p <- ggplot(delay_share, aes(x = share, y = name)) +
  geom_col(fill = bar_fill, width = 0.7) +
  geom_text(
    aes(label = paste0(round(share * 100), "%   n = ", n_flights)),
    hjust = -0.08,
    size  = 3.1,
    colour = ink_muted
  ) +
  scale_x_continuous(
    labels = scales::percent_format(accuracy = 1),
    expand = expansion(mult = c(0, 0.22))
  ) +
  labs(
    title    = "Share of flights delayed 15 or more minutes at departure",
    subtitle = "By airline, 2013 sample. Bars ordered worst at the top.",
    x        = NULL,
    y        = NULL,
    caption  = caption_text
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.background   = element_rect(fill = surface, colour = NA),
    panel.background  = element_rect(fill = surface, colour = NA),
    panel.grid.major.y = element_blank(),
    panel.grid.minor   = element_blank(),
    panel.grid.major.x = element_line(colour = "#e4e3e0", linewidth = 0.3),
    axis.text          = element_text(colour = ink_muted),
    plot.title         = element_text(colour = ink, face = "bold", size = 13),
    plot.subtitle      = element_text(colour = ink_muted, size = 10),
    plot.caption       = element_text(colour = ink_muted, size = 8, hjust = 0),
    plot.caption.position = "plot",
    plot.title.position   = "plot",
    plot.margin        = margin(14, 18, 12, 14)
  )

ggsave(out_path, plot = p, width = 8.5, height = 5.6, dpi = 300, bg = surface)

message("wrote ", out_path)
