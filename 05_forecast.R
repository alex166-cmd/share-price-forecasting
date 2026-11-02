# 05_forecast.R ------------------------------------------------------------
# Refit the selected models on ALL data and produce a short-horizon forecast of the price.
# Horizon is counted in REPORT DAYS (about 4 weeks for h = 20).
# The interval combines the ARIMA mean path with GARCH variance forecasts and assumes
# normal errors, so it is only an approximation (returns are heavy tailed).

source(here::here("R", "00_setup.R"))

daily <- read_csv(here("data", "processed", "illovo_clean.csv"), show_col_types = FALSE)
sel <- readRDS(here("outputs", "models", "selected.rds"))
h <- 20

r <- daily$ret[!is.na(daily$ret)]
r_pct <- 100 * r
p_last <- tail(daily$close, 1)
d_last <- max(daily$date)

arima_fit <- Arima(r, order = sel$arima_order, include.mean = TRUE)
mu_path <- as.numeric(forecast(arima_fit, h = h)$mean)

garch_fit <- ugarchfit(mk_garch_spec(sel$garch_model, sel$garch_dist), data = r_pct, solver = "hybrid")
sig_path <- as.numeric(sigma(ugarchforecast(garch_fit, n.ahead = h))) / 100

cum_mu <- cumsum(mu_path)
cum_sd <- sqrt(cumsum(sig_path^2))

future_dates <- seq(d_last + 1, by = "day", length.out = h * 2)
future_dates <- future_dates[wday(future_dates, week_start = 1) <= 5][1:h]

fc <- tibble(
  step = 1:h, date = future_dates,
  expected_price = p_last * exp(cum_mu),
  lower_80 = p_last * exp(cum_mu - qnorm(0.90) * cum_sd),
  upper_80 = p_last * exp(cum_mu + qnorm(0.90) * cum_sd),
  lower_95 = p_last * exp(cum_mu - qnorm(0.975) * cum_sd),
  upper_95 = p_last * exp(cum_mu + qnorm(0.975) * cum_sd),
  daily_volatility_pct = 100 * sig_path
)
save_tab(fc, "05_forecast_20_steps.csv")
print(fc, n = Inf)

hist_df <- tail(daily, 120)
fig <- ggplot() +
  geom_line(data = hist_df, aes(date, close), colour = "#1b6ca8", linewidth = 0.8) +
  geom_ribbon(data = fc, aes(date, ymin = lower_95, ymax = upper_95), fill = "#c0392b", alpha = 0.15) +
  geom_ribbon(data = fc, aes(date, ymin = lower_80, ymax = upper_80), fill = "#c0392b", alpha = 0.25) +
  geom_line(data = fc, aes(date, expected_price), colour = "#c0392b", linewidth = 0.9) +
  scale_y_continuous(labels = comma) +
  labs(title = "ILLOVO price: 20-report-day forecast",
       subtitle = paste0("Mean: ", sel$arima_name, " | Volatility: ", sel$garch_label,
                         " | Bands: 80% and 95% (normal approximation)"),
       x = NULL, y = "MWK",
       caption = paste(src_caption, "| Illustrative only, not investment advice")) +
  theme_illovo()
save_fig(fig, "05_price_forecast.png")
message("05_forecast.R finished.")
