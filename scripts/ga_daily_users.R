# ─────────────────────────────────────────────────────────────────────────────
# Daily users per Google Analytics (GA4) property
#
# Pulls "active users" by day from each of your GA4 properties, combines them
# into one tidy table, and draws a time series (one line per property).
# ─────────────────────────────────────────────────────────────────────────────

# install.packages("googleAnalyticsR")   # <- run once
# install.packages("tidyverse")          # <- run once

library(googleAnalyticsR)
library(tidyverse)

# ── 1. Authorize (opens a browser the first time; it caches after that) ──────
# Sign in with the Google account that owns the Analytics properties.
ga_auth()

# ── 2. List your properties ──────────────────────────────────────────────────
# IMPORTANT: use the numeric *Property ID*, NOT the "G-XXXXXXXXXX" measurement
# ID from _quarto.yml. Find each one in GA:  Admin (gear) → Property Settings →
# "PROPERTY ID" (a 9-digit number shown at the top).
#
# You can also just run  ga_account_list("ga4")  to print every property ID
# your account can see.
properties <- c(
  "Business Statistics" = "471983702",
  "Decision Modeling"   = "471513852"
  # "Business Stats (Excel)" = "XXXXXXXXX"   # <- add your new property's ID here
)

# ── 3. Date range ────────────────────────────────────────────────────────────
# Use ISO dates ("2024-01-01") or relative shortcuts ("365daysAgo", "yesterday").
start_date <- "2024-01-01"
end_date   <- "today"

# ── 4. Pull daily active users for one property ──────────────────────────────
get_daily_users <- function(name, id) {
  ga_data(
    id,
    metrics    = "activeUsers",          # try "totalUsers" for a broader count
    dimensions = "date",
    date_range = c(start_date, end_date),
    limit      = -1                       # -1 = return every row
  ) |>
    mutate(property = name)
}

# ── 5. Combine all properties into one tidy tibble ───────────────────────────
usage <- imap_dfr(properties, ~ get_daily_users(.y, .x)) |>
  mutate(date = as.Date(date)) |>        # googleAnalyticsR returns date as YYYYMMDD
  arrange(property, date)

# ── 6. Time-series plot ──────────────────────────────────────────────────────
ggplot(usage, aes(x = date, y = activeUsers, color = property)) +
  geom_line(linewidth = 0.7) +
  labs(
    title = "Daily users by property",
    x     = NULL,
    y     = "Active users",
    color = NULL
  ) +
  theme_minimal()

# ── 7. (Optional) save the data and a smoother 7-day average ─────────────────
write_csv(usage, "ga_daily_users.csv")

# usage_smooth <- usage |>
#   group_by(property) |>
#   mutate(users_7day = zoo::rollmean(activeUsers, 7, fill = NA, align = "right"))
#
# ggplot(usage_smooth, aes(date, users_7day, color = property)) +
#   geom_line(linewidth = 0.8) +
#   labs(title = "Daily users (7-day rolling average)", x = NULL,
#        y = "Active users", color = NULL) +
#   theme_minimal()
