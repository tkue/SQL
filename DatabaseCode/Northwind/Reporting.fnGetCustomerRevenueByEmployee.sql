USE Northwind
GO

CREATE OR ALTER FUNCTION Reporting.fnGetCustomerRevenueByEmployee(
	@orderStartDate date = NULL
	,@orderEndDate date = NULL
)
RETURNS TABLE AS RETURN (
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
		ord.OrderDate >= ISNULL(@orderStartDate, ord.OrderDate)
		AND ord.OrderDate <= ISNULL(@orderEndDate, ord.OrderDate)
	GROUP BY
		ord.CustomerID
		,emp.EmployeeID
)
GO