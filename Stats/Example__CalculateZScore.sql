USE Northwind
GO

-- http://www.silota.com/docs/recipes/sql-z-score.html

;WITH c_Sales AS (
	SELECT 
		OrderDate = CONVERT(date, o.OrderDate)
		,NumberOfOrders = COUNT(DISTINCT od.OrderID)
		,SUM(ISNULL(od.Quantity, 0)) AS Quantity
	FROM dbo.Orders o
	JOIN dbo.[Order Details] od ON o.OrderID = od.OrderID
	GROUP BY
		CONVERT(date, o.OrderDate)
)
,c_Stats AS (
	SELECT 
		AVG(c.NumberOfOrders) AS OrderMean
		,STDEV(c.NumberOfOrders) AS OrderSd
		,AVG(c.Quantity) AS QuantityMean
		,STDEV(c.Quantity) AS QuantitySd
	FROM c_Sales c
)
,c_SalesStats AS (
	SELECT 
		s.*
		,ABS(s.NumberOfOrders - stat.OrderMean) / stat.OrderSd AS ZScore_NumberOfOrders
		,ABS(s.Quantity - stat.QuantityMean) / stat.QuantitySd AS ZScore_Quantity
	FROM c_Sales s
	OUTER APPLY (
		SELECT *
		FROM c_Stats
	) stat 
)

SELECT *
	,IsOutlier_NumberOfOrders = CASE 
									WHEN c.ZScore_NumberOfOrders < -1.96 
										OR c.ZScore_NumberOfOrders > 1.96 THEN 1 
									ELSE 0 
								END
	,IsOutlier_Quantity = CASE 
									WHEN c.ZScore_Quantity < -1.96 
										OR c.ZScore_Quantity > 1.96 THEN 1 
									ELSE 0 
								END
FROM c_SalesStats c
ORDER BY
	c.OrderDate