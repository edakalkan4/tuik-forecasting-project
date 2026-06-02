calculate_accuracy <- function(actual, forecast, next_forecast) {
  valid <- !is.na(actual) & !is.na(forecast)
  if(sum(valid) == 0) return(data.frame(Bias="N/A", MAD="N/A", MSE="N/A", MAPE="N/A", RSFE="N/A", Tracking_Signal="N/A", Next_Period_Forecast="N/A"))
  A <- actual[valid]; F_val <- forecast[valid]; err <- A - F_val
  return(data.frame(
    Bias = as.character(round(mean(err), 4)), MAD = as.character(round(mean(abs(err)), 4)),
    MSE = as.character(round(mean(err^2), 4)), MAPE = as.character(round(mean(abs(err/A))*100, 2)),
    RSFE = as.character(round(sum(err), 4)), Tracking_Signal = as.character(round(sum(err)/mean(abs(err)), 4)),
    Next_Period_Forecast = as.character(round(next_forecast, 4))
  ))
}
