# 03_tests.R ---------------------------------------------------------------
# Statistical tests that decide how the data should be modelled:
#   stationarity, normality, autocorrelation, ARCH effects, thin trading, structural breaks.
# Output: outputs/tables/03_*.csv

source(here::here("R", "00_setup.R"))

daily  <- read_csv(here("data", "processed", "illovo_clean.csv"), show_col_types = FALSE)
weekly <- read_csv(here("data", "processed", "illovo_weekly_clean.csv"), show_col_types = FALSE)

r_d <- daily$ret[!is.na(daily$ret)]
r_w <- weekly$ret[!is.na(weekly$ret)]

# ---- 1. Stationarity -----------------------------------------------------------------
# Prices are expected to be non-stationary (I(1)); log returns stationary.
unit_roots <- bind_rows(
  unit_root_tests(daily$log_close, "Log price (daily reports)", kpss_null = "Trend"),
  unit_root_tests(r_d,             "Log returns (daily reports)"),
  unit_root_tests(weekly$log_close, "Log price (weekly)", kpss_null = "Trend"),
  unit_root_tests(r_w,             "Log returns (weekly)")
)
save_tab(unit_roots, "03_unit_root_tests.csv")
print(unit_roots, n = Inf)

diffs_needed <- tibble(
  series = c("Log price (daily reports)", "Log price (weekly)"),
  differences_suggested_by_kpss = c(ndiffs(daily$log_close, test = "kpss"),
                                    ndiffs(weekly$log_close, test = "kpss"))
)
save_tab(diffs_needed, "03_differencing.csv")

# ---- 2. Normality, autocorrelation and ARCH effects ---------------------------------
dependence <- bind_rows(
  jb_test(r_d, "Returns (daily reports)"),
  jb_test(r_w, "Returns (weekly)"),
  lb_test(r_d, 10, "Returns (daily reports)", "returns"),
  lb_test(r_d, 20, "Returns (daily reports)", "returns"),
  lb_test(r_d^2, 10, "Returns (daily reports)", "squared returns"),
  lb_test(r_d^2, 20, "Returns (daily reports)", "squared returns"),
  arch_lm(r_d, 5, "Returns (daily reports)"),
  arch_lm(r_d, 10, "Returns (daily reports)"),
  lb_test(r_w, 10, "Returns (weekly)", "returns"),
  lb_test(r_w^2, 10, "Returns (weekly)", "squared returns"),
  arch_lm(r_w, 5, "Returns (weekly)")
)
save_tab(dependence, "03_dependence_tests.csv")
print(dependence, n = Inf)

# ---- 3. Thin trading ----------------------------------------------------------------------
# If inactive days cluster, returns are "sticky" and standard ARMA/GARCH residuals will
# not look clean. Test whether a zero return today depends on a zero return yesterday.
z <- daily$zero_ret[!is.na(daily$ret)]
prev <- z[-length(z)]; today <- z[-1]
chi <- suppressWarnings(chisq.test(table(prev, today)))
thin <- tibble(
  metric = c("Share of zero returns", "P(zero | previous return was zero)",
             "P(zero | previous return was non-zero)", "Chi-square test of independence (p-value)",
             "Lag-1 autocorrelation of returns", "Lag-1 autocorrelation of non-zero returns"),
  value = c(mean(z), mean(today[prev]), mean(today[!prev]), chi$p.value,
            acf(r_d, plot = FALSE, lag.max = 1)$acf[2],
            acf(r_d[r_d != 0], plot = FALSE, lag.max = 1)$acf[2])
)
save_tab(thin, "03_thin_trading.csv")
print(thin)

# ---- 4. Structural breaks ---------------------------------------------------------------------
# (a) breaks in the level of log price, (b) breaks in volatility (mean of |return|),
# (c) CUSUM test for stability of the mean return. Minimum segment = 15% of the sample.
dates_r <- daily$date[!is.na(daily$ret)]
df_r <- tibble(date = dates_r, ret = r_d, abs_ret = abs(r_d))
df_p <- tibble(date = daily$date, log_close = daily$log_close)

break_dates <- function(bp_obj, dates) {
  idx <- breakpoints(bp_obj)$breakpoints
  if (all(is.na(idx))) return(character(0))
  as.character(dates[idx])
}

bp_level <- breakpoints(log_close ~ 1, data = df_p, h = 0.15)
bp_vol   <- breakpoints(abs_ret ~ 1, data = df_r, h = 0.15)
cusum_p  <- sctest(efp(ret ~ 1, data = df_r, type = "OLS-CUSUM"))$p.value

breaks <- tibble(
  analysis = c("Break dates in log-price level (BIC-selected)",
               "Break dates in volatility, mean |return| (BIC-selected)",
               "CUSUM test for stable mean return (p-value)"),
  result = c(paste(break_dates(bp_level, df_p$date), collapse = "; "),
             paste(break_dates(bp_vol, df_r$date), collapse = "; "),
             format(round(cusum_p, 4)))
)
breaks$result[breaks$result == ""] <- "none detected"
save_tab(breaks, "03_structural_breaks.csv")
print(breaks)

message("03_tests.R finished.")
