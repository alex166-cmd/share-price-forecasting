# run_all.R ----------------------------------------------------------------
# Runs the whole pipeline in order. From the project root:  source("run_all.R")
# Prerequisite: data/raw/illovo_daily_2024_2026.csv (see extraction/ to rebuild it).

if (!requireNamespace("here", quietly = TRUE)) install.packages("here")

scripts <- c("01_clean.R", "02_descriptives.R", "03_tests.R", "04_models.R", "05_forecast.R")
for (s in scripts) {
  message("\n=== Running ", s, " ===")
  source(here::here("R", s), local = new.env())
}

writeLines(capture.output(sessionInfo()), here::here("outputs", "session_info.txt"))
message("\nDone. See outputs/tables and outputs/figures.")
