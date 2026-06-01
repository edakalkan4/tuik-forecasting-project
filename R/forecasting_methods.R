# ==============================================================================
# PROJECT: TÜİK Services Production Index Time Series Forecasting Project
# FILE: R/forecasting_methods.R
# PURPOSE: Apply the 10 Required Quantitative Forecasting Methods and 
#          Generate the Model Accuracy Comparison Table (Robust Version)
# ==============================================================================

# 1. REQUIRED PACKAGES CHECK AND INITIALIZATION
if(!require(forecast)) install.packages("forecast")
library(forecast)

# 2. FORECAST ACCURACY AND TRACKING SIGNAL CALCULATION FUNCTION
calculate_accuracy <- function(actual, forecast, next_forecast) {
  valid_indices <- !is.na(actual) & !is.na(forecast)
  if(sum(valid_indices) == 0) {
    return(data.frame(Bias="N/A", MAD="N/A", MSE="N/A", MAPE="N/A", RSFE="N/A", Tracking_Signal="N/A", Next_Period_Forecast="N/A"))
  }
  
  A <- actual[valid_indices]
  F_val <- forecast[valid_indices]
  
  errors <- A - F_val
  
  bias <- mean(errors)
  mad  <- mean(abs(errors))
  mse  <- mean(errors^2)
  mape <- mean(abs(errors / A)) * 100
  rsfe <- sum(errors)
  tracking_signal <- if(mad == 0) { 0 } else { rsfe / mad }
  
  return(data.frame(
    Bias = as.character(round(bias, 4)),
    MAD = as.character(round(mad, 4)),
    MSE = as.character(round(mse, 4)),
    MAPE = as.character(round(mape, 2)),
    RSFE = as.character(round(rsfe, 4)),
    Tracking_Signal = as.character(round(tracking_signal, 4)),
    Next_Period_Forecast = as.character(round(next_forecast, 4))
  ))
}

# Safeguard check for spi_ts variable
if(!exists("spi_ts")) {
  # Fallback if spi_ts was not converted properly from raw data
  raw_values <- as.numeric(na.omit(as.numeric(raw_spi_data[[3]])))
  spi_ts <- ts(raw_values, start=c(2011, 1), frequency=12)
}

n_total <- length(spi_ts)
actuals <- as.numeric(spi_ts)

fitted_matrix <- matrix(NA, nrow = n_total, ncol = 10)
next_forecasts <- numeric(10)

# 7.1 Naïve Forecasting
naive_fit <- naive(spi_ts, h = 1)
fitted_matrix[, 1] <- c(NA, actuals[1:(n_total-1)])
next_forecasts[1]  <- as.numeric(naive_fit$mean[1])

# 7.2 Moving Average
k_ma <- 3
ma_fitted <- numeric(n_total)
ma_fitted[1:k_ma] <- NA
for(t in (k_ma+1):n_total) {
  ma_fitted[t] <- mean(actuals[(t-k_ma):(t-1)])
}
fitted_matrix[, 2] <- ma_fitted
next_forecasts[2]  <- mean(actuals[(n_total-k_ma+1):n_total])

# 7.3 Weighted Moving Average
weights <- c(0.2, 0.3, 0.5)
wma_fitted <- numeric(n_total)
wma_fitted[1:3] <- NA
for(t in 4:n_total) {
  wma_fitted[t] <- sum(actuals[(t-3):(t-1)] * weights)
}
fitted_matrix[, 3] <- wma_fitted
next_forecasts[3]  <- sum(actuals[(n_total-2):n_total] * weights)

# 7.4 Exponential Smoothing
ses_model <- HoltWinters(spi_ts, beta = FALSE, gamma = FALSE)
fitted_matrix[, 4] <- c(NA, as.numeric(ses_model$fitted[, "level"]))
ses_fc <- forecast(ses_model, h = 1)
next_forecasts[4]  <- as.numeric(ses_fc$mean[1])

# 7.5 Trend-Adjusted Exponential Smoothing (Protected via tryCatch)
tryCatch({
  holt_model <- HoltWinters(spi_ts, gamma = FALSE)
  fitted_matrix[, 5] <- c(NA, as.numeric(holt_model$fitted[, "xhat"]))
  holt_fc <- forecast(holt_model, h = 1)
  next_forecasts[5]  <- as.numeric(holt_fc$mean[1])
}, error = function(e) {
  fitted_matrix[, 5] <<- NA
  next_forecasts[5] <<- NA
})

# 7.6 Linear Trend Projection
time_trend <- 1:n_total
trend_lm <- lm(actuals ~ time_trend)
fitted_matrix[, 6] <- as.numeric(predict(trend_lm))
next_forecasts[6]  <- as.numeric(predict(trend_lm, newdata = data.frame(time_trend = n_total + 1)))

# 7.7 Seasonal Indices Method
tryCatch({
  decomp_classic <- decompose(spi_ts, type = "multiplicative")
  seasonal_pattern <- decomp_classic$seasonal[1:12]
  deseasonalized <- actuals / decomp_classic$seasonal
  trend_on_deseas <- lm(deseasonalized ~ time_trend)
  base_next_forecast <- predict(trend_on_deseas, newdata = data.frame(time_trend = n_total + 1))
  next_month_index <- (cycle(spi_ts)[n_total] %% 12) + 1
  fitted_matrix[, 7] <- as.numeric(predict(trend_on_deseas)) * decomp_classic$seasonal
  next_forecasts[7]  <- as.numeric(base_next_forecast * seasonal_pattern[next_month_index])
}, error = function(e) {
  fitted_matrix[, 7] <<- NA
  next_forecasts[7] <<- NA
})

# 7.8 Additive Decomposition
tryCatch({
  add_decomp <- decompose(spi_ts, type = "additive")
  fitted_matrix[, 8] <- as.numeric(add_decomp$trend + add_decomp$seasonal)
  add_fc <- forecast(add_decomp, h = 1)
  next_forecasts[8]  <- as.numeric(add_fc$mean[1])
}, error = function(e) {
  fitted_matrix[, 8] <<- NA
  next_forecasts[8] <<- NA
})

# 7.9 Multiplicative Decomposition
tryCatch({
  mult_decomp <- decompose(spi_ts, type = "multiplicative")
  fitted_matrix[, 9] <- as.numeric(mult_decomp$trend * mult_decomp$seasonal)
  mult_fc <- forecast(mult_decomp, h = 1)
  next_forecasts[9]  <- as.numeric(mult_fc$mean[1])
}, error = function(e) {
  fitted_matrix[, 9] <<- NA
  next_forecasts[9] <<- NA
})

# 7.10 Regression with Trend and Seasonal Dummy Variables
tryCatch({
  month_dummies <- factor(cycle(spi_ts))
  reg_model <- lm(actuals ~ time_trend + month_dummies)
  fitted_matrix[, 10] <- as.numeric(predict(reg_model))
  next_month_index <- (cycle(spi_ts)[n_total] %% 12) + 1
  next_data <- data.frame(time_trend = n_total + 1, month_dummies = factor(next_month_index, levels = 1:12))
  next_forecasts[10]  <- as.numeric(predict(reg_model, newdata = next_data))
}, error = function(e) {
  fitted_matrix[, 10] <<- NA
  next_forecasts[10] <<- NA
})

# AUTOMATIC ACCURACY COMPARISON TABLE GENERATION
method_names <- c(
  "Naïve Forecasting", "Moving Average", "Weighted Moving Average", 
  "Exponential Smoothing", "Trend-Adjusted Exponential Smoothing", 
  "Linear Trend Projection", "Seasonal Indices", "Additive Decomposition", 
  "Multiplicative Decomposition", "Regression with Trend and Seasonal Dummies"
)

accuracy_table <- data.frame()
for(i in 1:10) {
  row_metrics <- calculate_accuracy(actuals, fitted_matrix[, i], next_forecasts[i])
  row_data <- data.frame(Method = method_names[i], row_metrics)
  accuracy_table <- rbind(accuracy_table, row_data)
}

cat("\n--- ACCURACY COMPARISON TABLE SUCCESSFULLY GENERATED ---\n")
print(accuracy_table)
