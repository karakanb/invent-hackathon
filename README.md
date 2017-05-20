# Sales Forecast
This project is the result of an hackathon that aims to forecast the sales numbers for the next 2 weeks. The dataset contains data of the sales and stock values between `01/01/2015` - `31/01/2017`. The data is *not continuous*, it only has the records of the days where stock has changed, therefore there is a need to implement a LOCF methodology, which R makes quite easy to use.

The code basically:
- reads the csv data.
- drops the unused columns.
- constructs a date vector.
- joins the date vector with the data.
- fills the N/A dates with LOCF method.
- constructs the predictions with the mean of the last 2 weeks.
- writes output to `rdata/ForecastResults.csv`.