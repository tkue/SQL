USE Northwind
GO

CREATE OR ALTER FUNCTION Reporting.fnGetTopRevenueEmployeeForCustomer (
	@customerId int = NULL
)
RETURNS TABLE AS RETURN (

	WITH c AS (
		SELECT 
			emp.EmployeeID
			,ord.CustomerID
			,SUM(ISNULL(total.TotalOrderRevenue, 0)) AS TotalEmployeeRevenue
			,COUNT(*) AS NumberOfOrders
		FROM dbo.[Orders] ord
		JOIN dbo.Employees emp ON ord.EmployeeID = emp.EmployeeID
		CROSS APPLY (
			SELECT SUM(( od.UnitPrice - od.Discount ) * od.Quantity) AS TotalOrderRevenue
				,od.OrderID
			FROM dbo.[Order Details] od
			WHERE
				ord.OrderID = od.OrderID
			GROUP BY
				od.OrderID
		) total
		WHERE
			ord.CustomerID = ISNULL(@customerId, ord.CustomerID)
		GROUP BY
			ord.CustomerID
			,emp.EmployeeID
	)

	SELECT
		cust.CustomerID
		,emp.EmployeeID
		,CONVERT(money, emp.TotalEmployeeRevenue) AS TotalEmployeeRevenue
		,emp.NumberOfOrders
	FROM dbo.Customers cust
	OUTER APPLY (
		SELECT TOP 1 
			c.EmployeeID
			,c.TotalEmployeeRevenue
			,c.NumberOfOrders
		FROM c 
		WHERE
			c.CustomerID = cust.CustomerID
		ORDER BY
			c.TotalEmployeeRevenue DESC
	) emp
)
GO