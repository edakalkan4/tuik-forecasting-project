if(!require(httr)) install.packages("httr")
if(!require(dplyr)) install.packages("dplyr")
if(!require(tuikr)) install.packages("tuikr")
if(!require(readxl)) install.packages("readxl")

library(httr)
library(dplyr)
library(tuikr)
library(readxl)

cat("1. Adım: tuikr üzerinden güncel tablo listesi alınıyor...\n")

# Tablo listesini çekip içinden "Services" (Hizmet) geçen ilk tabloyu buluyoruz
hizmet_tablolari <- statistical_tables("9") %>% 
  filter(grepl("Services", table_name, ignore.case = TRUE))

# TÜİK portalının o saniyede ürettiği TAZE indirme linkini dinamik olarak yakalıyoruz
dinamik_url <- hizmet_tablolari$table_url[1]

if (is.na(dinamik_url) || dinamik_url == "") {
  stop("TÜİK dinamik URL'si yakalanamadı. Lütfen internet bağlantınızı kontrol edin.")
}

cat("2. Adım: Taze indirme linki başarıyla yakalandı.\n")

# Proje klasöründe yasaklı veri dosyası birikmemesi için .xls uzantılı geçici dosya açıyoruz
temp_xls <- tempfile(fileext = ".xls")

cat("3. Adım: Tarayıcı taklidiyle TÜİK sunucusundan ham Excel bülteni indiriliyor...\n")

# 403 ve 404 hatalarına takılmamak için tarayıcı başlıklarıyla (User-Agent) istek atıyoruz
response <- GET(
  url = dinamik_url,
  add_headers(
    `Accept` = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
    `Accept-Language` = "tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7"
  ),
  user_agent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"),
  write_disk(temp_xls, overwrite = TRUE)
)

# 200 = Başarılı Bağlantı Kontrolü
if (status_code(response) == 200) {
  cat("4. Adım: İndirme başarılı. readxl::read_xls ile veri hafızaya alınıyor...\n")
  
  # İnen ikili (binary) eski tip Excel dosyasını doğrudan tablo olarak söküyoruz
  raw_spi_data <- readxl::read_xls(temp_xls)
  
  cat("\n--- HAM VERİ SETİ BAŞARIYLA R HAFIZASINA AKTARILDI ---\n")
  print(head(raw_spi_data, 5))
  
} else {
  cat("Durum Kodu:", status_code(response), "\n")
  stop("TÜİK veri indirme işlemi başarısız oldu. Sunucu erişimi kısıtlanmış olabilir.")
}
