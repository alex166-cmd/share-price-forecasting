# ILLOVO Sugar Malawi Plc: Share Price Analysis, Time Series Econometrics and Volatility Forecasting

## 1. Project Overview

This project conducts a comprehensive financial time-series analysis of **Illovo Sugar Malawi Plc (ILLOVO)**, a company listed on the Malawi Stock Exchange (MSE).

The study uses historical daily share-price and trading-volume information published through the Malawi Stock Exchange's official market reports. It applies statistical analysis, financial econometrics, time-series modelling and volatility forecasting to investigate the behaviour, distribution, stationarity and predictability of ILLOVO's share prices and returns.

The project is implemented entirely in **R**, with a reproducible analytical workflow covering data cleaning, exploratory data analysis, descriptive statistics, statistical hypothesis testing, stationarity testing, structural break analysis, ARIMA/ARMA modelling, GARCH volatility estimation and out-of-sample forecasting.

The analysis sample used in the reported results covers **2 January 2024 to 29 October 2026**, comprising 466 daily market reports and 148 weekly observations.

The broader historical data collection exercise also involved compiling Malawi Stock Exchange market reports dating back to 4 January 2010.

## 2. Company and Data Source

### Company Analysed

- **Company:** Illovo Sugar Malawi Plc
- **Stock Exchange:** Malawi Stock Exchange (MSE)
- **Ticker Symbol:** ILLOVO
- **Security:** Ordinary shares
- **Market:** Malawi capital market

### Data Source

The primary source of the data is the Malawi Stock Exchange's official Market Reports portal.

**Source:** https://mse.co.mw/market/reports

Historical market reports published by the exchange provide the basis for compiling the company's daily share-market observations.

The data collection process involves identifying the relevant market reports, extracting ILLOVO's reported market information and consolidating the observations into a structured historical dataset for statistical analysis.

The intended dataset structure includes:

- Trading date
- Company/ticker
- Closing share price
- Price change
- Trading volume
- Trading value
- Source market report
- Reporting year

The analysis uses the reported closing prices and trading volumes to construct financial time-series variables.

**Data attribution:** Malawi Stock Exchange (MSE), Market Reports. The original market reports remain the primary source of the observations.

## 3. Research Objectives

The project addresses the following objectives:

1. Examine the historical movement and performance of ILLOVO shares.
2. Analyse daily and weekly share-price returns.
3. Investigate the statistical properties and distribution of share returns.
4. Test the stationarity of share prices and returns.
5. Examine autocorrelation and volatility clustering.
6. Investigate possible structural breaks in share-price behaviour.
7. Estimate and compare AR, MA, ARMA and ARIMA forecasting models.
8. Estimate conditional volatility using alternative GARCH specifications.
9. Evaluate forecasting performance using out-of-sample observations.
10. Generate short-term share-price forecasts.

## 4. Technology Stack

The project uses the following tools and technologies:

| Technology | Application |
|---|---|
| R | Statistical computing and econometric analysis |
| RStudio | Development environment |
| tidyverse | Data manipulation and transformation |
| lubridate | Date handling |
| ggplot2 | Data visualisation |
| tseries | Time-series statistical testing |
| urca | Unit root and stationarity analysis |
| forecast | ARIMA modelling and forecasting |
| rugarch | GARCH volatility modelling |
| FinTS | ARCH-LM testing |
| strucchange | Structural break analysis |
| here | Reproducible project file paths |

## 5. Project Structure

The project follows a modular R scripting structure to separate data preparation, descriptive analysis, statistical testing, model estimation and forecasting.

```text
ILLOVO-Share-Price-Analysis/
│
├── R/
│   ├── functions.R
│   └── 00_setup.R
│
├── data/
│   ├── raw/
│   └── processed/
│
├── outputs/
│   ├── tables/
│   └── figures/
│
├── scripts/
│   ├── 01_clean.R
│   ├── 02_descriptives.R
│   ├── 03_tests.R
│   ├── 04_models.R
│   └── 05_forecast.R
│
├── README.md
└── ILLOVO-Share-Price-Analysis.Rproj
```

## 6. Analytical Methodology

### 6.1 Data Cleaning and Preparation

The first stage involves preparing the historical market observations for analysis.

The cleaning procedure includes:

- Checking missing trading dates.
- Identifying duplicate observations.
- Checking missing closing prices.
- Identifying non-positive closing prices.
- Checking negative trading volumes.
- Identifying observations falling on weekends.
- Constructing daily log returns.
- Creating weekly price and return series.
- Identifying observations following reporting gaps.
- Flagging unusually large returns.

Daily logarithmic returns are calculated as:

\[
r_t = 100\left[\ln(P_t)-\ln(P_{t-1})\right]
\]

Where:

- \(r_t\) represents the daily logarithmic return.
- \(P_t\) represents the closing price at time \(t\).
- \(P_{t-1}\) represents the previous reported closing price.

Weekly returns are also constructed to investigate share-price behaviour at a lower observation frequency.

### 6.2 Descriptive Statistical Analysis

Descriptive statistics are calculated to understand the distribution and behaviour of the share-price series and returns.

The analysis includes:

- Mean
- Standard deviation
- Minimum and maximum
- First and third quartiles
- Median
- Skewness
- Excess kurtosis
- Percentage of zero returns

Annual performance is also examined using the first and last reported closing prices for each calendar year.

### 6.3 Stationarity and Unit Root Testing

Stationarity is investigated using three complementary statistical tests:

**Augmented Dickey-Fuller (ADF) Test**

Tests the null hypothesis that a series contains a unit root.

**Phillips-Perron (PP) Test**

Provides an alternative unit root test that accounts for serial correlation and heteroskedasticity.

**Kwiatkowski-Phillips-Schmidt-Shin (KPSS) Test**

Tests the null hypothesis of stationarity, providing complementary evidence to ADF and PP.

Both price levels and logarithmic returns are examined.

### 6.4 Distribution and Dependence Diagnostics

The project investigates the statistical characteristics of financial returns using:

- Jarque-Bera normality test.
- Ljung-Box test for serial correlation.
- Ljung-Box tests on squared returns.
- ARCH-LM tests for conditional heteroskedasticity.
- Lagged autocorrelation analysis.
- Chi-square test of independence for consecutive zero-return observations.

These tests help establish whether the return series exhibits non-normality, serial dependence and volatility clustering.

### 6.5 Structural Break Analysis

Structural stability is examined using:

- BIC-selected break dates in the log-price level.
- Break detection in volatility, measured using absolute returns.
- CUSUM testing for stability of the mean return.

This helps identify possible changes in the underlying behaviour of ILLOVO shares over the sample period.

### 6.6 Time-Series Forecasting Models

Several forecasting specifications are estimated and compared.

The candidate models include:

- Benchmark forecasting models.
- Autoregressive models (AR).
- Moving Average models (MA).
- Autoregressive Moving Average models (ARMA).
- Autoregressive Integrated Moving Average models (ARIMA).
- Automatically selected ARIMA models.

Model performance is evaluated using out-of-sample forecasting.

The evaluation metrics include:

- Root Mean Squared Error (RMSE).
- Mean Absolute Error (MAE).
- Directional Hit Rate.
- Price Mean Absolute Error (MWK).
- Price Mean Absolute Percentage Error (MAPE).

Daily and weekly models are evaluated separately.

### 6.7 GARCH Volatility Modelling

To investigate time-varying volatility, the project estimates and compares several Generalised Autoregressive Conditional Heteroskedasticity (GARCH) specifications.

Models include:

- Standard GARCH(1,1) with normal innovations.
- Standard GARCH(1,1) with Student-t innovations.
- Standard GARCH(1,1) with skewed Student-t innovations.
- GJR-GARCH(1,1) with Student-t innovations.
- EGARCH(1,1) with Student-t innovations.

Model selection considers information criteria, particularly the Akaike Information Criterion (AIC) and Bayesian Information Criterion (BIC).

Post-estimation diagnostic tests examine whether the fitted models adequately capture serial dependence and conditional heteroskedasticity.

### 6.8 Share Price Forecasting

The final stage generates a 20-step forward forecast of ILLOVO's share price.

The forecast includes:

- Expected closing price.
- 80% prediction intervals.
- 95% prediction intervals.
- Estimated daily volatility.

Forecast dates are aligned with the subsequent weekdays in the reporting calendar.

## 7. Key Empirical Findings

The following findings are based on the execution results generated by the R scripts.

### 7.1 Data Quality and Coverage

The cleaned dataset produced the following results:

| Data Quality Check | Result |
|---|---:|
| Missing dates in observations | 0 |
| Duplicate dates | 0 |
| Missing closing prices | 0 |
| Non-positive closing prices | 0 |
| Negative trading volumes | 0 |
| Weekend observations | 0 |

The analysis dataset contains:

| Metric | Result |
|---|---:|
| First reported observation | 2024-01-02 |
| Last reported observation | 2026-10-29 |
| Daily market reports | 466 |
| Weekdays in date range | 738 |
| Weekdays without a report | 272 |
| Report coverage | 63.1% |
| Returns computed | 465 |
| Returns spanning reporting gaps | 171 |
| Zero returns | 51.6% |
| Reports with positive volume | 77.7% |
| Price changes with zero reported volume | 10 |
| Returns exceeding 3 standard deviations | 8 |
| Weeks with at least one report | 148 |

Although the observed records passed the basic data-quality checks, the reporting gaps and high proportion of zero returns are important considerations when interpreting the results.

### 7.2 Annual Share Price Performance

The reported annual closing-price movements were:

| Year | Reports | First Closing Price (MWK) | Last Closing Price (MWK) | Price Change |
|---|---:|---:|---:|---:|
| 2024 | 169 | 1,260 | 1,355 | 7.54% |
| 2025 | 157 | 1,355 | 2,330 | 72.0% |
| 2026* | 140 | 2,330 | 3,502 | 50.3% |

*2026 figures cover observations up to 29 October 2026.*

The reported closing price increased from MWK 1,260 at the beginning of the 2024 sample to MWK 3,502 at the end of the 2026 sample.

### 7.3 Stationarity Results

The unit root and stationarity tests produced the following results:

| Series | Test | P-value |
|---|---|---:|
| Daily log price | ADF | 0.496 |
| Daily log price | PP | 0.743 |
| Daily log price | KPSS | 0.010 |
| Daily log returns | ADF | 0.010 |
| Daily log returns | PP | 0.010 |
| Daily log returns | KPSS | 0.100 |
| Weekly log price | ADF | 0.468 |
| Weekly log price | PP | 0.740 |
| Weekly log price | KPSS | 0.010 |
| Weekly log returns | ADF | 0.010 |
| Weekly log returns | PP | 0.010 |
| Weekly log returns | KPSS | 0.100 |

The results provide evidence that log-price levels are non-stationary, while daily and weekly logarithmic returns are stationary under the reported test specifications.

This supports the use of returns for subsequent stationary time-series modelling.

### 7.4 Distribution and Volatility Characteristics

The Jarque-Bera tests indicate strong departures from normality for both daily and weekly returns.

Daily return diagnostics also indicate evidence of serial dependence and conditional heteroskedasticity.

For example:

- Daily Ljung-Box test at 10 lags: p = 0.0218.
- Daily Ljung-Box test on squared returns at 10 lags: p = 0.00105.
- Daily ARCH-LM test at 5 lags: p = 0.00151.
- Daily ARCH-LM test at 10 lags: p = 0.000206.

Weekly diagnostics, however, show less evidence of serial correlation and ARCH effects at the reported lag specifications.

### 7.5 Forecasting Model Performance

The out-of-sample evaluation used:

- 93 test observations for daily models.
- 30 test observations for weekly models.

Among the reported daily specifications, the ARIMA benchmark-equivalent model achieved:

- RMSE: 0.0130.
- MAE: 0.00402.
- Directional hit rate: 75.9%.

For weekly forecasting, the benchmark-equivalent model achieved:

- RMSE: 0.0307.
- MAE: 0.0124.
- Directional hit rate: 73.1%.

These results provide a basis for comparing forecasting specifications rather than establishing that one model will consistently predict future market movements.

### 7.6 GARCH Model Selection

The GJR-GARCH(1,1) model with Student-t innovations was selected based on the lowest reported BIC.

Its information criteria were:

- AIC: -3450.
- BIC: -3427.

However, its post-estimation diagnostics produced:

| Diagnostic Test | P-value |
|---|---:|
| Ljung-Box on standardised residuals | 0.00986 |
| Ljung-Box on squared residuals | 0.00103 |
| ARCH-LM (5 lags) | 0.00151 |

These results indicate remaining dependence and ARCH effects in the residuals.

Consequently, although the model was selected by BIC, its diagnostic performance suggests that further specification improvements are necessary before relying on its volatility estimates.

### 7.7 Twenty-Step Share Price Forecast

The forecasting procedure generated a 20-step projection.

The first forecasted closing price was approximately MWK 3,508, while the twentieth forecast was approximately MWK 3,656.

| Forecast Metric | Result |
|---|---:|
| Forecast horizon | 20 steps |
| First forecast date | 30 October 2026 |
| Last forecast date | 26 November 2026 |
| First expected closing price | MWK 3,508 |
| Twentieth expected closing price | MWK 3,656 |

The forecast is an econometric projection based on historical observations and model assumptions. It should not be interpreted as a guaranteed future market price.

## 8. Reproducibility and Execution

The analytical workflow is organised into five main scripts.

| Script | Description |
|---|---|
| `01_clean.R` | Data validation, cleaning, return construction and weekly aggregation |
| `02_descriptives.R` | Descriptive statistics, annual performance and extreme-return analysis |
| `03_tests.R` | Stationarity, normality, autocorrelation, ARCH and structural break tests |
| `04_models.R` | ARIMA/ARMA forecasting comparisons and GARCH estimation |
| `05_forecast.R` | Twenty-step share-price forecasting and forecast visualisation |

The project also uses shared setup and function scripts to support reproducibility and reduce repeated code.

To reproduce the analysis:

1. Clone or download the repository.
2. Open the `.Rproj` file in RStudio.
3. Ensure the raw market-report dataset is available in the expected data directory.
4. Install the required R packages.
5. Run the scripts in numerical order.

The `here` package is used to manage project-relative file paths.

## 9. Limitations

Several limitations should be considered when interpreting the findings.

**Incomplete reporting coverage:** The analysis contains 466 daily reports against 738 weekdays in the sample period. Missing market reports should not automatically be interpreted as days without trading.

**Zero returns:** Approximately 51.6% of computed returns are zero. This may reflect unchanged reported prices, infrequent trading or market-reporting characteristics.

**Returns spanning gaps:** A substantial proportion of returns are calculated across reporting gaps. These observations may capture price movements over more than one trading day.

**Extreme observations:** Eight returns exceeded three standard deviations and require careful investigation to distinguish genuine market movements from possible data anomalies.

**Model diagnostics:** The selected GJR-GARCH model did not pass all residual diagnostic tests, indicating that further model refinement is needed.

**Forecast uncertainty:** The forecast prediction intervals are unusually narrow in some periods and should be investigated before the forecasts are used for decision-making.

**Market-specific factors:** Share-price movements may be influenced by company performance, dividend announcements, market liquidity, investor sentiment, macroeconomic conditions and other market developments not explicitly included in the univariate models.

## 10. Future Improvements

Potential extensions to this project include:

- Expanding the analysis to additional Malawi Stock Exchange listed companies.
- Incorporating dividend-adjusted share returns.
- Investigating the impact of dividend announcements and corporate actions.
- Introducing macroeconomic variables such as inflation, interest rates and exchange rates.
- Comparing ILLOVO with other listed companies.
- Testing alternative volatility models and distributions.
- Improving treatment of non-trading days and reporting gaps.
- Conducting rolling-window and expanding-window forecast evaluation.
- Comparing statistical forecasting models with machine learning approaches.
- Developing an interactive Power BI or R Shiny dashboard for monitoring share-price movements.

## 11. Conclusion

This project demonstrates the application of statistical computing and financial econometrics to Malawi's capital market using historical ILLOVO share-price observations.

It combines data engineering, exploratory data analysis, hypothesis testing, time-series econometrics, volatility modelling and forecasting within a reproducible R workflow.

The findings demonstrate the importance of understanding data quality, stationarity, return distributions, reporting frequency and volatility characteristics before applying financial forecasting models.

Beyond the analysis of a single listed company, the project provides a foundation for further quantitative research into the behaviour and efficiency of the Malawi Stock Exchange.

## 12. Author

**Alex Maseko**

Applied Statistics Graduate | Data Analytics | Statistical Modelling | Financial Econometrics

- GitHub: https://github.com/alex166-cmd
- LinkedIn: https://linkedin.com/in/alexmaseko

## 13. Disclaimer

This project is intended for educational, statistical research and portfolio demonstration purposes.

The analysis does not constitute financial or investment advice. Forecasts are model-based estimates and should not be interpreted as recommendations to buy, hold or sell ILLOVO shares.

Historical market data are attributed to the Malawi Stock Exchange. All interpretations, statistical analyses and model outputs are the author's own.
