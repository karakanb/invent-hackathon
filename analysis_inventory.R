rm(list = ls())
library(zoo)
library(data.table)

# Define the IO paths.
inputFilePath <- 'rdata/InventoryPosition.csv'
outputFİlePath <- 'rdata/ForecastResults.csv'

# Read the data from csv.
inventoryData <- fread(inputFilePath, header = TRUE, dec = ".", sep = '|')
inventoryData$Date <- as.Date(inventoryData$Date, format="%d.%m.%Y")

# Drop the unused columns.
inventoryData[, c("SalesRevenue","IncomingStock"):=NULL]
row.names(inventoryData) <- 1:nrow(inventoryData)

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
inventoryData <- inventoryData[
	order(inventoryData$StoreCode, inventoryData$ProductCode, inventoryData$Date),]

# Expand the dataset with the last observed carried forward method.
inventoryData$StoreStock <- na.locf(inventoryData$StoreStock)

# Convert NAs to zero.
inventoryData[is.na(inventoryData)] <- 0
inventoryData <- data.table(inventoryData)
inventoryData <- inventoryData[order(inventoryData$StoreCode, inventoryData$ProductCode, inventoryData$Date),]

# Filter the dataset in order to eliminate zero sales and zero stock days.
inventoryData <- inventoryData[SalesQuantity >= 0 & StoreStock >= 0]
inventoryData <- inventoryData[!(SalesQuantity == 0 & StoreStock == 0)]
inventoryData <- data.table(inventoryData)

# Get the predictions for the next 14 days.
res <- inventoryData[, mean(tail(SalesQuantity,14)), 
                       .(StoreCode, ProductCode)]
res <- res[rep(1:nrow(res),each=14)]

# Set the date column on the forecasting results.
res$Date <- as.character(as.Date("2017-02-1")+ 0:13 , format="%d.%m.%Y") 
colnames(res) <- c("StoreCode", "ProductCode","Forecast", "Date")
setcolorder(res, c("StoreCode", "ProductCode", "Date", "Forecast"))

# Combine the datasets with the test data and calculate the error.
inventoryData$Forecast <- res$Forecast
inventoryData$AbsoluteError <- abs(
 	as.numeric(inventoryData$SalesQuantity) - as.numeric(inventoryData$Forecast))
forecastError <- sum(inventoryData$AbsoluteError) / sum(inventoryData$SalesQuantity)

# Write the results to the output file.
fwrite(res, outputFİlePath, quote = "auto", sep = "|")
