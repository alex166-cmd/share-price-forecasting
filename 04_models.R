# 04_models.R --------------------------------------------------------------
# Models for the MEAN (ARIMA family) and VARIANCE (GARCH family) of ILLOVO log returns.
# Out-of-sample design: the first 80% of observations are used for estimation and the
# final 20% are held back. Test-period predictions are ONE-STEP-AHEAD: parameters are
# estimated on the training sample only, and each test prediction uses only data
# available up to the previous observation.
# Output: outputs/tables/04_*.csv, outputs/figures/04_*.png, outputs/models/selected.rds

source(here::here("R", "00_setup.R"))

daily  <- read_csv(here("data", "processed", "illovo_clean.csv"), show_col_types = FALSE)
weekly <- read_csv(here("data", "processed", "illovo_weekly_clean.csv"), show_col_types = FALSE)
test_frac <- 0.20

# =====================================================================================
# PART A: Mean models (ARIMA) for log returns, daily-report and weekly frequency
# =====================================================================================
eval_mean_models <- function(dat, label, test_frac = 0.20) {
  dat <- dat %>% mutate(close_prev = dplyr::lag(close))
  d <- dat %>% filter(!is.na(ret))
  r <- d$ret
  n <- length(r)
  n_test <- ceiling(test_frac * n)
  n_train <- n - n_test
  idx_test <- (n_train + 1):n
  r_train <- r[1:n_train]

  # Candidate models, compared on the TRAINING sample by AICc / BIC
  cands <- list("ARIMA(0,0,0) mean only" = c(0, 0, 0), "AR(1)" = c(1, 0, 0),
                "MA(1)" = c(0, 0, 1), "AR(2)" = c(2, 0, 0), "MA(2)" = c(0, 0, 2),
                "ARMA(1,1)" = c(1, 0, 1))
  fits <- imap(cands, function(ord, nm) {
    tryCatch(Arima(r_train, order = ord, include.mean = TRUE), error = function(e) NULL)
  }) %>% compact()
  ic <- imap_dfr(fits, function(f, nm) tibble(model = nm, aicc = f$aicc, bic = f$bic, loglik = f$loglik))

  auto <- auto.arima(r_train, d = 0, D = 0, max.p = 5, max.q = 5, seasonal = FALSE,
                     stepwise = FALSE, approximation = FALSE, ic = "aicc", allowmean = TRUE)
  ord <- arimaorder(auto)
  auto_name <- paste0("auto.arima ARIMA(", ord[1], ",", ord[2], ",", ord[3], ")")

  # One-step-ahead predictions: apply fixed training-sample parameters to the full series
  one_step <- function(fit) as.numeric(fitted(Arima(ts(r), model = fit)))[idx_test]

  preds <- c(
    list("Benchmark: zero return (random walk)" = rep(0, n_test),
         "Benchmark: training-mean return (random walk + drift)" = rep(mean(r_train), n_test)),
    map(fits, one_step),
    setNames(list(one_step(auto)), auto_name)
  )

  actual <- r[idx_test]
  close_t <- d$close[idx_test]; close_prev_t <- d$close_prev[idx_test]
  metrics <- imap_dfr(preds, function(p, nm) {
    price_hat <- close_prev_t * exp(p)
    forecast_metrics(actual, p) %>%
      mutate(model = nm,
             price_mae_mwk = mean(abs(close_t - price_hat)),
             price_mape_pct = 100 * mean(abs(close_t - price_hat) / close_t))
  }) %>% mutate(sample = label) %>% relocate(sample, model)

  # Diebold-Mariano test: is the auto.arima model better than the zero-return benchmark?
  cmp <- paste(auto_name, "vs zero-return benchmark")
  dm <- tryCatch({
    t <- dm.test(actual - preds[[auto_name]], actual - preds[[1]], h = 1, power = 2)
    tibble(sample = label, comparison = cmp, dm_statistic = unname(t$statistic), p_value = t$p.value)
  }, error = function(e) {
    tibble(sample = label, comparison = cmp, dm_statistic = NA_real_, p_value = NA_real_)
  })

  # Residual diagnostics of the selected model (training sample)
  res <- as.numeric(residuals(auto))
  fitdf <- sum(ord[c(1, 3)])
  diag <- bind_rows(
    lb_test(res, 10, label, "ARIMA residuals", fitdf = fitdf),
    lb_test(res^2, 10, label, "squared ARIMA residuals"),
    arch_lm(res, 5, label)
  )

  list(ic = mutate(ic, sample = label), metrics = metrics, dm = dm, diag = diag,
       order = as.numeric(ord), name = auto_name, n_train = n_train, n_test = n_test)
}

res_d <- eval_mean_models(daily,  "Daily reports", test_frac)
res_w <- eval_mean_models(weekly, "Weekly",        test_frac)

save_tab(bind_rows(res_d$ic, res_w$ic), "04_arima_model_selection.csv")
mean_metrics <- bind_rows(res_d$metrics, res_w$metrics)
save_tab(mean_metrics, "04_arima_forecast_accuracy.csv")
save_tab(bind_rows(res_d$dm, res_w$dm), "04_diebold_mariano.csv")
save_tab(bind_rows(res_d$diag, res_w$diag), "04_arima_residual_diagnostics.csv")
print(mean_metrics %>% mutate(across(where(is.numeric), ~ round(.x, 5))), n = Inf)

fig_rmse <- ggplot(mean_metrics, aes(reorder(model, -rmse), 100 * rmse)) +
  geom_col(fill = "#1b6ca8") + coord_flip() +
  facet_wrap(~ sample, ncol = 1, scales = "free_y") +
  labs(title = "Out-of-sample forecast error of log returns (RMSE, % points)",
       subtitle = "One-step-ahead predictions on the last 20% of observations",
       x = NULL, y = "RMSE (%)") +
  theme_illovo()
save_fig(fig_rmse, "04_arima_rmse.png", h = 7)

# =====================================================================================
# PART B: GARCH-family volatility models (daily-report returns, in percent)
# =====================================================================================
dates_r <- daily$date[!is.na(daily$ret)]
r_pct <- 100 * daily$ret[!is.na(daily$ret)]     # percent scale helps the optimiser
n <- length(r_pct)
n_test <- ceiling(test_frac * n); n_train <- n - n_test
idx_test <- (n_train + 1):n
r_train <- r_pct[1:n_train]

spec_tbl <- tribble(
  ~label,                 ~model,      ~dist,
  "sGARCH(1,1) normal",   "sGARCH",    "norm",
  "sGARCH(1,1) Student-t","sGARCH",    "std",
  "sGARCH(1,1) skew-t",   "sGARCH",    "sstd",
  "gjrGARCH(1,1) Student-t", "gjrGARCH", "std",
  "eGARCH(1,1) Student-t",  "eGARCH",    "std"
)

fit_one <- function(model, dist) {
  tryCatch(ugarchfit(mk_garch_spec(model, dist), data = r_train, solver = "hybrid"),
           error = function(e) NULL)
}
fits <- pmap(spec_tbl, function(label, model, dist) fit_one(model, dist))
names(fits) <- spec_tbl$label

gar_tab <- imap_dfr(fits, function(f, nm) {
  if (is.null(f)) return(tibble(model = nm, converged = FALSE))
  ic <- infocriteria(f)
  tibble(model = nm, converged = convergence(f) == 0, loglik = likelihood(f),
         aic = ic[1] * n_train, bic = ic[2] * n_train, persistence = persistence(f))
})
save_tab(gar_tab, "04_garch_model_selection.csv")
print(gar_tab)

gar_coef <- imap_dfr(fits, function(f, nm) {
  if (is.null(f)) return(NULL)
  m <- as.data.frame(f@fit$robust.matcoef)
  colnames(m) <- c("estimate", "robust_se", "t_value", "p_value")
  m %>% rownames_to_column("parameter") %>% mutate(model = nm, .before = 1)
})
save_tab(gar_coef, "04_garch_coefficients.csv")

cand <- gar_tab %>% filter(converged %in% TRUE, is.finite(bic)) %>% arrange(bic)
if (nrow(cand) == 0) stop("No GARCH model converged - inspect 04_garch_model_selection.csv")
best_lab <- cand$model[1]
best_row <- spec_tbl[spec_tbl$label == best_lab, ]
message("Selected GARCH model (lowest BIC): ", best_lab)

# Diagnostics on standardised residuals of the selected model
z <- as.numeric(residuals(fits[[best_lab]], standardize = TRUE))
gar_diag <- bind_rows(
  lb_test(z, 10, best_lab, "standardised residuals"),
  lb_test(z^2, 10, best_lab, "squared standardised residuals"),
  arch_lm(z, 5, best_lab)
)
save_tab(gar_diag, "04_garch_residual_diagnostics.csv")
print(gar_diag)

# Out-of-sample variance forecasts: fix parameters at training-sample estimates and filter
# the full series; sigma[t] depends only on data up to t-1 (one-step-ahead).
eval_garch <- function(label) {
  f <- fits[[label]]
  if (is.null(f) || convergence(f) != 0) return(NULL)
  row <- spec_tbl[spec_tbl$label == label, ]
  sp <- mk_garch_spec(row$model, row$dist)
  setfixed(sp) <- as.list(coef(f))
  sig <- as.numeric(sigma(ugarchfilter(sp, data = r_pct)))[idx_test]
  e2 <- (r_pct[idx_test] - unname(coef(f)["mu"]))^2
  tibble(model = label, qlike = qlike(e2, sig^2), mse_variance = mean((e2 - sig^2)^2))
}
e2_bench <- (r_pct[idx_test] - mean(r_train))^2
gar_eval <- bind_rows(
  tibble(model = "Benchmark: constant variance (training sample)",
         qlike = qlike(e2_bench, rep(var(r_train), n_test)),
         mse_variance = mean((e2_bench - var(r_train))^2)),
  map_dfr(spec_tbl$label, eval_garch)
)
save_tab(gar_eval, "04_garch_forecast_accuracy.csv")
print(gar_eval)

# Figure: conditional volatility of the selected model vs absolute returns
sp_best <- mk_garch_spec(best_row$model, best_row$dist)
setfixed(sp_best) <- as.list(coef(fits[[best_lab]]))
vol_df <- tibble(date = dates_r,
                 sigma = as.numeric(sigma(ugarchfilter(sp_best, data = r_pct))),
                 abs_ret = abs(r_pct))
fig_vol <- ggplot(vol_df, aes(date)) +
  geom_point(aes(y = abs_ret), colour = "grey60", size = 1, alpha = 0.7) +
  geom_line(aes(y = sigma), colour = "#c0392b", linewidth = 0.9) +
  geom_vline(xintercept = as.numeric(dates_r[n_train + 1]), linetype = "dashed") +
  annotate("text", x = dates_r[n_train + 1], y = max(vol_df$abs_ret) * 0.95,
           label = " test period", hjust = 0, size = 3.5) +
  labs(title = paste0("Conditional volatility: ", best_lab),
       subtitle = "Red line: one-step-ahead sigma (%). Grey points: absolute returns (%). Parameters fixed at training-sample estimates.",
       x = NULL, y = "%", caption = src_caption) +
  theme_illovo()
save_fig(fig_vol, "04_garch_volatility.png")

# Save selections for the forecasting script
saveRDS(list(arima_order = res_d$order, arima_name = res_d$name,
             garch_label = best_lab, garch_model = best_row$model, garch_dist = best_row$dist),
        here("outputs", "models", "selected.rds"))
message("04_models.R finished.")
