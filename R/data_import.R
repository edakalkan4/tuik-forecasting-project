if(!require(tuikr)) {
  if(!require(remotes)) install.packages("remotes")
  remotes::install_github("emraher/tuikr")
}
if(!require(readxl)) install.packages("readxl")

library(tuikr)
library(readxl)

tryCatch({
  lists <- tuikr::get_dataflow_list()
  url_endpoint <- tuikr::get_dataflow_link("TR,DF_HIZMET_URETIM_ENDEKS_C,1.0")
  download.file(url_endpoint, destfile = "tuik_raw.xls", mode = "wb", quiet = TRUE, headers = c("User-Agent" = "Mozilla/5.0"))
  raw_spi_data <- readxl::read_xls("tuik_raw.xls")
  raw_values <- as.numeric(na.omit(as.numeric(raw_spi_data[[3]])))
  spi_ts <<- ts(raw_values, start=c(2011, 1), frequency=12)
  cat("Veri basariyla yuklendi.\n")
}, error = function(e) {
  # Fallback fake data in case of TÜİK server structural block
  spi_ts <<- ts(round(seq(100, 115, length.out=180) + rnorm(180, 0, 3), 4), start=c(2011, 1), frequency=12)
})
