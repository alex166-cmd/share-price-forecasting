# 02_descriptives.R ---------------------------------------------------------
# Descriptive statistics and exploratory figures.
# Output: outputs/tables/02_*.csv and outputs/figures/02_*.png

source(here::here("R", "00_setup.R"))

daily  <- read_csv(here("data", "processed", "illovo_clean.csv"), show_col_types = FALSE)
weekly <- read_csv(here("data", "processed", "illovo_weekly_clean.csv"), show_col_types = FALSE)
ret_d  <- daily %>% filter(!is.na(ret))
ret_w  <- weekly %>% filter(!is.na(ret))

# ---- Tables ------------------------------------------------------------------------
tab_overall <- bind_rows(
  desc_stats(ret_d$ret_pct, "Daily-report log returns (%)"),
  desc_stats(ret_d$ret_pct[ret_d$ret_pct != 0], "Daily-report log returns, non-zero only (%)"),
  desc_stats(ret_w$ret_pct, "Weekly log returns (%)"),
  desc_stats(daily$close, "Closing price (MWK)"),
  desc_stats(daily$volume, "Volume per report (shares)")
)
save_tab(tab_overall, "02_summary_statistics.csv")
print(tab_overall)

tab_year <- daily %>%
  group_by(year) %>%
  summarise(reports = n(), first_close = dplyr::first(close), last_close = dplyr::last(close),
            price_change_pct = 100 * (last_close / first_close - 1),
            share_days_traded = mean(traded), avg_volume = mean(volume), .groups = "drop") %>%
  left_join(
    ret_d %>% group_by(year) %>%
      summarise(mean_ret_pct = mean(ret_pct), sd_ret_pct = sd(ret_pct),
                share_zero_returns = mean(zero_ret), .groups = "drop"),
    by = "year")
save_tab(tab_year, "02_by_year.csv")
print(tab_year)

tab_trade <- ret_d %>%
  group_by(traded) %>%
  summarise(n = n(), share_zero_returns = mean(zero_ret), sd_ret_pct = sd(ret_pct),
            mean_abs_ret_pct = mean(abs(ret_pct)), .groups = "drop")
save_tab(tab_trade, "02_traded_vs_not_traded.csv")

tab_top <- ret_d %>%
  arrange(desc(abs_ret)) %>% slice_head(n = 10) %>%
  dplyr::select(date, close, volume, ret_pct, after_gap, wk_gap)
save_tab(tab_top, "02_largest_moves.csv")
print(tab_top)

tab_cor <- tibble(
  pair = c("Volume vs absolute return (Spearman)", "Volume vs absolute return, traded days only (Spearman)"),
  rho = c(cor(ret_d$volume, ret_d$abs_ret, method = "spearman"),
          cor(ret_d$volume[ret_d$traded], ret_d$abs_ret[ret_d$traded], method = "spearman"))
)
save_tab(tab_cor, "02_volume_vs_volatility.csv")

# ---- Figures --------------------------------------------------------------------------
# 1. Price and volume
p_price <- ggplot(daily, aes(date, close)) +
  geom_line(colour = "#1b6ca8", linewidth = 0.7) +
  scale_y_continuous(labels = comma) +
  labs(title = "ILLOVO closing price (MWK)", x = NULL, y = "MWK")
p_logp <- ggplot(daily, aes(date, close)) +
  geom_line(colour = "#1b6ca8", linewidth = 0.7) +
  scale_y_log10(labels = comma) +
  labs(title = "Closing price, log scale", x = NULL, y = "MWK (log scale)")
p_vol <- ggplot(daily, aes(date, volume)) +
  geom_col(width = 1, fill = "grey40") +
  scale_y_continuous(labels = comma) +
  labs(title = "Shares traded per report", x = NULL, y = "Shares", caption = src_caption)
fig1 <- (p_price / p_logp / p_vol) & theme_illovo()
save_fig(fig1, "02_price_volume.png", h = 9)

# 2. Returns over time, with large moves highlighted
fig2 <- ggplot(ret_d, aes(date, ret_pct)) +
  geom_col(width = 1, fill = "grey55") +
  geom_point(data = filter(ret_d, large_move), colour = "#c0392b", size = 2) +
  labs(title = "Log returns between consecutive reports (%)",
       subtitle = "Red points: moves beyond 3 standard deviations",
       x = NULL, y = "Return (%)", caption = src_caption) +
  theme_illovo()
save_fig(fig2, "02_returns.png")

# 3. Distribution: histogram vs normal, and QQ plot
mu <- mean(ret_d$ret_pct); s <- sd(ret_d$ret_pct)
p_hist <- ggplot(ret_d, aes(ret_pct)) +
  geom_histogram(aes(y = after_stat(density)), binwidth = 0.5, fill = "grey60", colour = "white") +
  stat_function(fun = dnorm, args = list(mean = mu, sd = s), colour = "#c0392b", linewidth = 1) +
  labs(title = "Return distribution vs normal", x = "Return (%)", y = "Density")
p_qq <- ggplot(ret_d, aes(sample = ret_pct)) +
  stat_qq(alpha = 0.6) + stat_qq_line(colour = "#c0392b") +
  labs(title = "Normal QQ plot", x = "Theoretical quantiles", y = "Sample quantiles")
save_fig((p_hist | p_qq) & theme_illovo(), "02_return_distribution.png", w = 11, h = 4.5)

# 4. Autocorrelation of returns, squared returns and absolute returns
r <- ret_d$ret
fig4 <- (ggAcf(r, lag.max = 30) + ggtitle("ACF: returns") | ggPacf(r, lag.max = 30) + ggtitle("PACF: returns")) /
        (ggAcf(r^2, lag.max = 30) + ggtitle("ACF: squared returns") | ggAcf(abs(r), lag.max = 30) + ggtitle("ACF: absolute returns"))
save_fig(fig4 & theme_illovo(), "02_acf_pacf.png", w = 11, h = 7)

# 5. Rolling volatility (20 reports)
daily <- daily %>%
  mutate(roll_sd_20 = zoo::rollapply(ret_pct, width = 20, FUN = sd, fill = NA, align = "right"))
fig5 <- ggplot(daily, aes(date, roll_sd_20)) +
  geom_line(colour = "#1b6ca8", linewidth = 0.8, na.rm = TRUE) +
  labs(title = "Rolling volatility", subtitle = "Standard deviation of the last 20 returns (%)",
       x = NULL, y = "Std. dev. (%)", caption = src_caption) +
  theme_illovo()
save_fig(fig5, "02_rolling_volatility.png")

# 6. Data availability by month (how complete is the source data?)
weekdays_all <- tibble(date = seq(min(daily$date), max(daily$date), by = "day")) %>%
  filter(wday(date, week_start = 1) <= 5)
cov <- weekdays_all %>%
  count(month = floor_date(date, "month"), name = "weekdays") %>%
  left_join(daily %>% count(month = floor_date(date, "month"), name = "reports"), by = "month") %>%
  mutate(reports = coalesce(reports, 0L), coverage_pct = 100 * reports / weekdays)
save_tab(cov, "02_monthly_coverage.csv")
fig6 <- ggplot(cov, aes(month, coverage_pct)) +
  geom_col(fill = "#1b6ca8") +
  scale_y_continuous(limits = c(0, 100)) +
  labs(title = "Share of weekdays with a daily report, by month",
       x = NULL, y = "Coverage (%)", caption = src_caption) +
  theme_illovo()
save_fig(fig6, "02_data_coverage.png")

message("02_descriptives.R finished.")
