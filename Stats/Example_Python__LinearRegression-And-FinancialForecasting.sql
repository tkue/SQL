USE Northwind
GO

DECLARE 
	@sql nvarchar(max)

SET @sql = 'WITH c_Orders AS (
	SELECT
		OrderDate = CAST(ord.OrderDate AS date)
		,Amount = SUM(( od.UnitPrice * od.Quantity ) - od.Discount)
	FROM Northwind.dbo.[Order Details] od
	JOIN Northwind.dbo.Orders ord ON od.OrderID = ord.OrderID
	--JOIN Util.Stat.TallyDay tally ON CAST(ord.OrderDate AS date) = tally.Date
	GROUP BY
		ord.OrderDate
)
,c_Dates AS (
	SELECT *
	FROM Util.Stat.TallyDay
	OUTER APPLY ( SELECT MAX(OrderDate) AS MaxOrderDate FROM c_Orders ) maxDate
	OUTER APPLY ( SELECT MIN(OrderDate) AS MinOrderDate FROM c_Orders ) minDate
	WHERE
		Date >= minDate.MinOrderDate
		AND [Date] <= DATEADD(year, 5, maxDate.MaxOrderDate)
)
,c_StageDates AS (
	SELECT
		d.N
		,d.[Date]
		,o.Amount
		,CAST(CASE WHEN d.Date <= d.MaxOrderDate THEN 0 ELSE 1 END AS bit) AS IsForecast
	FROM c_Dates d
	LEFT JOIN c_Orders o ON d.Date = o.OrderDate
)

SELECT
	[Date] AS OrderDate
	,Amount AS OrderAmount
FROM c_StageDates'




DROP TABLE IF EXISTS #Predictions

CREATE TABLE #Predictions (
	OrderDate date
	,Amount float
)
INSERT #Predictions
EXEC sp_execute_external_script
      @language = N'Python'
    , @script = N'
from revoscalepy import rx_lin_mod, rx_predict
 
linearmodel = rx_lin_mod(formula = "OrderAmount ~ OrderDate", data = InputDataSet); # Formula specifies OrderAmount is dependent variable and OrderDate in independent variable
predict = rx_predict(linearmodel, data = InputDataSet[["OrderDate"]]) # Predict the data for the input Celcius values
predict.insert(loc=0, column="OrderDate", value=InputDataSet[["OrderDate"]]) # Add the original Celcius field to the predicted OrderAmount field
 
OutputDataSet = predict # Assigned the dataset to output data frame
' ,
@input_data_1 = @sql


SELECT *
FROM #Predictions
ORDER BY
	OrderDate