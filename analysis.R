rm(list = ls())
library(smooth)
library(ggplot2)
library(gtools)
library(dplyr)
library(data.table)
library(zoo)

Mode <- function(x) {
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}

inputFilePath <- 'rdata/InventoryPosition.csv'
outputFİlePath <- 'rdata/ForecastResults.csv'

# Read the data from csv.
inventoryData <- fread(inputFilePath, header = TRUE, dec = ".", sep = '|')
inventoryData$Date <- as.Date(inventoryData$Date)

#inventoryData <- inventoryData[StoreStock != 0 | SalesQuantity != 0]
#
inventoryData[, c("StoreStock","IncomingStock"):=NULL]
row.names(inventoryData) <- 1:nrow(inventoryData)

# Filter the data to a smaller subset in order to test the results.
inventoryData <- inventoryData[StoreCode == 'Store1']

# Construct a date vector.
startDate <- as.Date("2015-01-1")
endDate <- as.Date("2017-01-31")
dates <- seq(from = startDate, to = endDate, by=1)

# Get the product groups.
productGroups <- inventoryData[,c("StoreCode", "ProductCode"),]
productGroups <- unique(productGroups)

# Create a cross join of the dates and the product groups.
merged <- merge(dates, productGroups)
colnames(merged) <- c("Date", "StoreCode", "ProductCode")
inventoryData <- merge(inventoryData, merged, 
                       by.x=c("Date", "StoreCode", "ProductCode"), 
                       by.y=c("Date", "StoreCode", "ProductCode"), 
                       all=T)

# Sort the data.
inventoryData <- inventoryData[order(inventoryData$StoreCode, inventoryData$ProductCode, inventoryData$Date),]
inventoryData$StoreStock <- na.locf(inventoryData$StoreStock)

# Convert NAs to zero.
inventoryData[is.na(inventoryData)] <- 0
inventoryData <- data.table(inventoryData)
inventoryData <- inventoryData[order(inventoryData$StoreCode, inventoryData$ProductCode, inventoryData$Date),]

# Get the predictions for the next 14 days.
res <- inventoryData[,sma(SalesQuantity, h=14)$forecast, 
                     .(StoreCode, ProductCode)]

# Set the date column on the forecasting results.
res$Date <- as.character(as.Date("2017-02-01"), format="%d.%m.%Y")
colnames(res) <- c("StoreCode", "ProductCode","Forecast", "Date")
setcolorder(res, c("StoreCode", "ProductCode", "Date", "Forecast"))

# Check the mods 
mods <- inventoryData[SalesQuantity != 0 & Date > 
                        as.Date("01.01.2017", format="%d.%m.%Y"), 
                      mean(SalesQuantity), 
                      .(StoreCode, ProductCode)]

# Write the results to the output file.
fwrite(res, outputFİlePath, quote = "auto", sep = "|")
