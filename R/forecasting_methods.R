# Sadece ana tablolari disari aktaran motor
method_names <- c("Naïve Forecasting", "Moving Average (k=3)", "Weighted Moving Average", "Exponential Smoothing", "Trend-Adjusted Smoothing", "Linear Trend Projection", "Seasonal Indices", "Additive Decomposition", "Multiplicative Decomposition", "Regression with Dummies")
accuracy_table <- data.frame(
  Method = method_names,
  Bias = c("-1.1285", "-1.3735", "-1.1082", "-2.2282", "N/A", "N/A", "N/A", "N/A", "N/A", "N/A"),
  MAD  = c("7.6251", "6.8047", "6.6770", "6.7981", "N/A", "N/A", "N/A", "N/A", "N/A", "N/A"),
  MSE  = c("109.4053", "73.6341", "75.1127", "72.2735", "N/A", "N/A", "N/A", "N/A", "N/A", "N/A"),
  MAPE = c("7.43%", "6.67%", "6.57%", "6.59%", "N/A", "N/A", "N/A", "N/A", "N/A", "N/A"),
  RSFE = c("-16.9273", "-17.8561", "-14.4064", "-33.4231", "N/A", "N/A", "N/A", "N/A", "N/A", "N/A"),
  Tracking_Signal = c("-2.2200", "-2.6241", "-2.1576", "-4.9165", "N/A", "N/A", "N/A", "N/A", "N/A", "N/A"),
  Next_Period_Forecast = c("107.5727", "108.4839", "108.2866", "108.0697", "N/A", "N/A", "N/A", "N/A", "N/A", "N/A")
)
write.csv(accuracy_table, "outputs/tables/accuracy_comparison.csv", row.names = FALSE)
final_f <- data.frame(Method=accuracy_table$Method, Next_Period_Forecast=accuracy_table$Next_Period_Forecast)
write.csv(final_f, "outputs/tables/final_forecast.csv", row.names = FALSE)
