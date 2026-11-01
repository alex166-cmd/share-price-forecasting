# ILLOVO Sugar Malawi (MSE) – Share Price Time Series Analysis in R

An end-to-end analysis of daily share price data for **Illovo Sugar Malawi Plc (MSE: ILLOVO)** on the Malawi Stock Exchange, from January 2024 to October 2026. The project covers data extraction from raw PDF reports, cleaning and validation, exploratory analysis, statistical testing, ARIMA and GARCH modelling with out-of-sample evaluation, and a short-horizon forecast.

> **Purpose:** portfolio project. Nothing here is investment advice.

## Questions

1. How has the ILLOVO share price behaved since 2024, and how liquid is the stock?
2. Are daily returns predictable (ARIMA), or is the price close to a random walk?
3. Does volatility cluster, and can a GARCH-type model forecast it better than a constant-variance benchmark?

## Data

| | |
|---|---|
| Source | Malawi Stock Exchange – *Daily Stock News* PDF reports (mse.co.mw/market/reports) |
| Coverage | 2 Jan 2024 – 29 Oct 2026 |
| Reports used | 466 daily reports (weekly reports excluded) |
| Raw file | `data/raw/illovo_daily_2024_2026.csv` (one row per report) |

The ILLOVO row was extracted from page 1 of each PDF with `extraction/extract_illovo.py`. The date comes from the "As On Date" field inside each report, not from the file name.

### Data issues found and how they are handled

| Issue | What I found | Treatment |
|---|---|---|
| **Missing reports** | 466 of 738 weekdays (about 63%) have a report in the source files | Returns are computed between consecutive *reports*; those spanning a gap are flagged (`after_gap`). A **weekly series** (last close of each week; all 148 weeks are covered) is analysed as a regular-frequency robustness check |
| **Thin trading** | About 52% of returns are exactly zero; volume is positive on about 78% of reports | Tested explicitly (`03_tests.R`), and discussed in the limitations below |
| **Price moves without trades** | The MSE closing price sometimes changes by cents with zero volume | Flagged as `no_trade_move`; kept |
| **Extreme moves** | A few jumps of up to about 14% in one report | Flagged as `large_move` (beyond 3 SD), **not removed** – they are real price changes |
| **Scale** | Price rose from about MWK 1,260 to about MWK 3,502 | All modelling uses log returns |

## Methods

| Stage | Script | What it does |
|---|---|---|
| Extraction | `extraction/extract_illovo.py` | Parses the ILLOVO line from each PDF into a CSV |
| Cleaning | `R/01_clean.R` | Validation checks, log returns, gap and trading flags, weekly aggregation, data-quality table |
| Descriptives | `R/02_descriptives.R` | Summary statistics (overall, by year, traded vs not traded), price/volume plots, return distribution and QQ plot, ACF/PACF, rolling volatility, data-coverage chart |
| Tests | `R/03_tests.R` | ADF, Phillips–Perron, KPSS; Jarque–Bera; Ljung–Box on returns and squared returns; ARCH-LM; thin-trading dependence test; Bai–Perron structural breaks; CUSUM |
| Models | `R/04_models.R` | ARIMA candidates + `auto.arima`; sGARCH, GJR-GARCH and EGARCH with normal, Student-t and skew-t errors; out-of-sample evaluation |
| Forecast | `R/05_forecast.R` | Refits the selected models on all data; 20-report-day price forecast with 80% and 95% bands |

**Evaluation design.** The last 20% of observations are held out. Model parameters are estimated on the first 80% only. Test-period predictions are one-step-ahead, each using only past data. Mean forecasts are compared with a zero-return (random walk) benchmark and a training-mean benchmark using RMSE, MAE, directional hit rate and the Diebold–Mariano test. Variance forecasts are compared with a constant-variance benchmark using the QLIKE loss. GARCH models are selected by BIC on the training sample.

## Results

> Fill this section in after running the pipeline. Suggested structure:
>
> - **Stationarity:** do the ADF/PP/KPSS results agree that log price is I(1) and returns are stationary? (`outputs/tables/03_unit_root_tests.csv`)
> - **Return behaviour:** mean, volatility, skewness and kurtosis; how far from normal? (`02_summary_statistics.csv`, `02_return_distribution.png`)
> - **Predictability:** does the selected ARIMA beat the zero-return benchmark out of sample? Report the Diebold–Mariano p-value. (`04_arima_forecast_accuracy.csv`, `04_diebold_mariano.csv`)
> - **Volatility:** is there ARCH structure (`03_dependence_tests.csv`)? Which GARCH model was selected, and does it beat constant variance on QLIKE? (`04_garch_forecast_accuracy.csv`)
> - **Breaks:** when did the price level or volatility regime change? (`03_structural_breaks.csv`)

Key figures are saved in `outputs/figures/`.

## Limitations

- **Incomplete daily series.** About 37% of weekdays have no report in the source files, so "daily" returns sometimes span several days. The weekly analysis is the cleaner view of dynamics; the daily-report analysis keeps more observations.
- **Thin trading and stale prices.** When more than half of returns are zero, residuals from ARMA/GARCH models are rarely clean white noise, and standard errors should be read with caution.
- **Short sample.** About 465 returns. GARCH estimates (especially skew-t and asymmetric models) can be unstable, and a test sample of about 93 observations has low power.
- **Heavy tails.** A handful of large jumps dominate the kurtosis; normal-based forecast intervals understate tail risk.
- **No dividend adjustment.** Prices are unadjusted closing prices.
- **Small information set.** The models use ILLOVO's own history only. No macro, exchange-rate, sugar-price or earnings-announcement variables are included.

## Possible extensions

- Add ex-dividend and results-announcement dates as event dummies.
- Add macro regressors (inflation, MWK/USD, policy rate) in an ARIMAX or VAR framework.
- Model the price as a jump process, or model trade incidence (zero vs non-zero returns) separately.
- Backtest value-at-risk (Kupiec/Christoffersen tests).
- Compare with other MSE counters using the same pipeline.

## Reproducing the analysis

**Requirements:** R ≥ 4.1. Packages are installed automatically by `R/00_setup.R`: `here`, `tidyverse`, `tseries`, `forecast`, `rugarch`, `strucchange`, `zoo`, `patchwork`, `scales`.

```r
# from the project root (the folder containing this README)
source("run_all.R")
```

All tables are written to `outputs/tables/`, figures to `outputs/figures/`, and session details to `outputs/session_info.txt`.

**Rebuilding the raw CSV from the PDFs (optional).** Requires Python 3.8+ and `pdftotext` (poppler-utils):

```bash
python extraction/extract_illovo.py --pdf-dir path/to/pdfs --out data/raw/illovo_daily_2024_2026.csv
```

## Repository structure

```
illovo-mse-timeseries/
├── README.md
├── run_all.R                  # runs the full pipeline
├── extraction/
│   └── extract_illovo.py      # PDF -> CSV
├── data/
│   ├── raw/                   # illovo_daily_2024_2026.csv
│   └── processed/             # created by 01_clean.R
├── R/
│   ├── 00_setup.R             # packages and folders
│   ├── functions.R            # helper functions
│   ├── 01_clean.R
│   ├── 02_descriptives.R
│   ├── 03_tests.R
│   ├── 04_models.R
│   └── 05_forecast.R
└── outputs/
    ├── figures/
    ├── tables/
    └── models/
```

## Data dictionary (raw file)

| Column | Meaning |
|---|---|
| `date` | Report date ("As On Date") |
| `high`, `low` | Daily range in MWK; blank when no trade |
| `buy`, `sell` | Best bid / ask (0 = none) |
| `prev_close`, `close` | Previous and today's closing price (MWK) |
| `volume` | Shares traded |
| `dividend_mk`, `dividend_yield_pct`, `earnings_yield_pct`, `pe_ratio`, `pb_ratio` | Valuation fields as reported by the MSE |
| `market_cap_mkmn`, `after_tax_profit_mkmn`, `shares_in_issue` | Market capitalisation and profit (MWK millions); shares outstanding |
| `source_file` | PDF the row came from |

Variables created by `01_clean.R` include `ret` (log return), `ret_pct`, `wk_gap` (weekdays since the previous report), `after_gap`, `traded`, `zero_ret`, `no_trade_move` and `large_move`.

## Author

Alex J. Maseko – alexmaseko166@gmail.com

## Licence
MIT

MIT – see `LICENSE`. Source data are published by the Malawi Stock Exchange.
