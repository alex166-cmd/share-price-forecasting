# 01_clean.R ---------------------------------------------------------------
# Validate the raw extract, build return series and save clean datasets.
# Input : data/raw/illovo_daily_2024_2026.csv
# Output: data/processed/illovo_clean.csv        (one row per daily report)
#         data/processed/illovo_weekly_clean.csv (last report of each week)
#         outputs/tables/01_data_quality.csv

source(here::here("R", "00_setup.R"))

raw <- read_csv(here("data", "raw", "illovo_daily_2024_2026.csv"), show_col_types = FALSE)
stopifnot(inherits(raw$date, "Date"))

# ---- 1. Validation checks ---------------------------------------------------
checks <- tibble(
  check = c("Missing dates", "Duplicate dates", "Missing close prices",
            "Non-positive close prices", "Negative volumes", "Dates falling on weekends"),
  count = c(sum(is.na(raw$date)), sum(duplicated(raw$date)), sum(is.na(raw$close)),
            sum(raw$close <= 0, na.rm = TRUE), sum(raw$volume < 0, na.rm = TRUE),
            sum(wday(raw$date, week_start = 1) > 5, na.rm = TRUE))
)
print(checks)
stopifnot("Validation failed - see checks above" = all(checks$count == 0))

# ---- 2. Daily-report dataset --------------------------------------------------
# Returns are log differences between consecutive REPORTS. Because about 40% of
# trading days have no report in the source files, some returns span more than one day;
# these are flagged with after_gap = TRUE.
daily <- raw %>%
  arrange(date) %>%
  mutate(
    year = year(date),
    month = floor_date(date, "month"),
    cal_gap = as.integer(date - dplyr::lag(date)),
    wk_gap = weekday_gap(dplyr::lag(date), date),   # 1 = consecutive weekdays
    after_gap = wk_gap > 1,
    log_close = log(close),
    ret = log_close - dplyr::lag(log_close),
    ret_pct = 100 * ret,
    abs_ret = abs(ret),
    traded = volume > 0,
    zero_ret = ret == 0,
    # closing price changed although no shares traded (MSE closing-price quirk)
    no_trade_move = !traded & !is.na(ret) & ret != 0
  )

sd_ret <- sd(daily$ret, na.rm = TRUE)
mu_ret <- mean(daily$ret, na.rm = TRUE)
daily <- daily %>% mutate(large_move = abs(ret - mu_ret) > 3 * sd_ret)
# Large moves are flagged, NOT removed: they are genuine price changes and removing
# them would understate risk.

# ---- 3. Weekly dataset (regular frequency) ---------------------------------------
weekly <- daily %>%
  mutate(week = floor_date(date, "week", week_start = 1)) %>%
  group_by(week) %>%
  summarise(date = max(date), close = dplyr::last(close), volume = sum(volume),
            n_reports = n(), .groups = "drop") %>%
  arrange(week) %>%
  mutate(
    log_close = log(close),
    ret = log_close - dplyr::lag(log_close),
    ret_pct = 100 * ret,
    week_gap = as.integer(as.numeric(week - dplyr::lag(week)) / 7),
    zero_ret = ret == 0
  )

# ---- 4. Data quality summary -----------------------------------------------------
all_weekdays <- seq(min(daily$date), max(daily$date), by = "day")
all_weekdays <- all_weekdays[wday(all_weekdays, week_start = 1) <= 5]
weeks_in_span <- length(seq(min(weekly$week), max(weekly$week), by = "week"))

quality <- tibble(
  metric = c("First report", "Last report", "Daily reports used",
             "Weekdays in the date range", "Weekdays without a report",
             "Report coverage (%)", "Returns computed", "Returns spanning a gap",
             "Zero returns (%)", "Reports with volume > 0 (%)",
             "Price changed with zero volume (count)",
             "Returns beyond 3 SD (count)", "Weeks with at least one report",
             "Weeks in the date range"),
  value = c(as.character(min(daily$date)), as.character(max(daily$date)),
            nrow(daily), length(all_weekdays), length(all_weekdays) - nrow(daily),
            round(100 * nrow(daily) / length(all_weekdays), 1), sum(!is.na(daily$ret)),
            sum(daily$after_gap, na.rm = TRUE),
            round(100 * mean(daily$zero_ret, na.rm = TRUE), 1),
            round(100 * mean(daily$traded), 1), sum(daily$no_trade_move, na.rm = TRUE),
            sum(daily$large_move, na.rm = TRUE), nrow(weekly), weeks_in_span) %>% as.character()
)
print(quality, n = Inf)

# ---- 5. Save -----------------------------------------------------------------------
write_csv(daily, here("data", "processed", "illovo_clean.csv"))
write_csv(weekly, here("data", "processed", "illovo_weekly_clean.csv"))
save_tab(quality, "01_data_quality.csv")
message("01_clean.R finished: ", nrow(daily), " daily rows, ", nrow(weekly), " weekly rows.")
