USE Northwind
GO


;WITH c_Orders AS (
	SELECT 
		CONVERT(date, ord.OrderDate) AS OrderDate
		,Quantity = SUM(ISNULL(od.Quantity, 0))
		,Amount = SUM(( od.UnitPrice * od.Quantity ) - od.Discount)
		,NumberOfOrders = COUNT(*)
	FROM Northwind.dbo.[Order Details] od
	JOIN Northwind.dbo.Orders ord ON od.OrderID = ord.OrderID
	GROUP BY
		CONVERT(date, ord.OrderDate)
)
,c_Prev AS (
	SELECT
		*
		,NumberOfOrders_Prev = CAST(LAG(c.NumberOfOrders, 1) OVER (ORDER BY c.OrderDate) AS float)
		,Amount_Prev = CAST(LAG(c.Amount, 1) OVER (ORDER BY c.OrderDate) AS float)
		,Quantity_Prev = CAST(LAG(c.Quantity, 1) OVER (ORDER BY c.OrderDate) AS float)
	FROM c_Orders c
)

SELECT
	c.*
	,NumberOfOrders_Growth = (c.NumberOfOrders - c.NumberOfOrders_Prev) / NULLIF(c.NumberOfOrders_Prev, 0)
	,Amount_Growth = (c.Amount - c.Amount_Prev) / NULLIF(c.Amount_Prev, 0)
	,Quantity_Growth = (c.Quantity - c.Quantity_Prev) / NULLIF(c.Quantity, 0)
FROM c_Prev c

