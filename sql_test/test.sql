USE Northwind
GO

-- ==========================================================
-- 1
-- ==========================================================
/*
	Several employees left the company and then came back.
	As a result, some rows have the same employee, but with a different HireDate. These are considered to be duplicates.

	A duplicate is defined as having the same FirstName, LastName, and Title. 

	The ultimate goal is to remove all duplicate rows based on the criteria above. 
	You want to keep the record with the most recent HireDate. 

	Write a query that selects all rows that you would remove. 

	EXAMPLE

		Review this query:
			
			SELECT * 
			FROM dbo.Employees e
			WHERE
				e.EmployeeID IN (1, 10)
			ORDER BY
				e.EmployeeID
		

		Nancy Davolio is listed twice.
		The row with the EmployeeID of 10 is the one you want to keep because the HireDate is the greatest (1992-08-09 00:00:00.000 > 1992-05-01 00:00:00.000)
		This row, with EmployeeID of 10, is one of the rows that should be displayed in the query
*/

;WITH cte AS (
	SELECT
		RowNum = ROW_NUMBER() OVER (PARTITION BY e.FirstName, e.LastName, e.Title ORDER BY e.HireDate DESC)
		,*
	FROM dbo.Employees e
)

SELECT *
FROM cte 
WHERE
	cte.RowNum > 1

-- ==========================================================
GO


-- ==========================================================
-- 2
-- ==========================================================
/*
	Create a stored procedure that has the following requirements:

	NAME
		The stored procedure will reside in the Reporting schema and be called GetEmployeeTotalSales.
		The Reporting schema does not currently exist.
			
			EXAMPLE
				Reporting.GetEmployeeTotalSales

	PARAMETERS

		The stored procedure will take 3 parameters:
			FirstName
			LastName
			Region

		All the parameters will be optional
		The parameter FirstName will search dbo.Employees for a partial match (using LIKE) on dbo.Employees.LastName
			EXAMPLE
				SELECT * FROM dbo.Employees WHERE LastName LIKE '%' + @lastName + '%'
		The parameter LastName will search dbo.Employees for a partial match (using LIKE) on dbo.Employees.LastName
		The parameter Region will be based on dbo.Employees.Region using an EXACT match that is NOT case-sensitive

	

	COLUMNS

		The stored procedure will return the following columns.
		Some columns require concatenating strings 

		EmployeeName: TitleOfCourtesy FirstName LastName (Title)
		PhoneNumber: HomePhone xExtension
			The extension will be concatenated to HomePhone only if it exists
		TotalAmountSold
			This is the total amount sold by the employee in dbo.[Order Details]
			The total amount for an order is defined as:
				( UnitPrice - Discount ) * Quantity
			Round to 2 decimal places 
			Return only 2 decimal places
		EmployeeRegion
			This is the region tied to the employee (dbo.Employees.Region)
		

	OTHER REQUIREMENTS
		
		You should be able to run this query continuously.
		This means that you should check to see if the stored procedure and/or schema exists and either drop or alter it


	EXAMPLE OUTPUT

		EmployeeName                                                                              PhoneNumber                    TotalAmountSold       EmployeeRegion
		----------------------------------------------------------------------------------------- ------------------------------ --------------------- ---------------
		Ms.Nancy Davolio (Sales Representative)                                                   (206) 555-9857 x5467           201667.70             WA
		Dr.Andrew Fuller (Vice President, Sales)                                                  (206) 555-9482 x3457           177378.66             WA
		Ms.Janet Leverling (Sales Representative)                                                 (206) 555-3412 x3355           212636.35             WA
		Mrs.Margaret Peacock (Sales Representative)                                               (206) 555-8122 x5176           249480.80             WA
		Mr.Steven Buchanan (Sales Manager)                                                        (71) 555-4848 x3453            75344.70              NULL
		Mr.Michael Suyama (Sales Representative)                                                  (71) 555-7773 x428             78000.15              NULL
		Mr.Robert King (Sales Representative)                                                     (71) 555-5598 x465             140884.49             NULL
		Ms.Laura Callahan (Inside Sales Coordinator)                                              (206) 555-1189 x2344           133003.63             WA
		Ms.Anne Dodsworth (Sales Representative)                                                  (71) 555-4444 x452             82740.15              NULL
		Ms.Nancy Davolio (Sales Representative)                                                   (206) 555-9857                 0.00                  WA
		Dr.Andrew Fuller (Vice President, Sales)                                                  (206) 555-9482                 0.00                  WA
		Ms.Janet Leverling (Sales Representative)                                                 (206) 555-3412                 0.00                  WA
		Dr.Andrew Fuller (Vice President, Sales)                                                  (206) 555-9482                 0.00                  WA

		
*/
IF NOT EXISTS (
	SELECT 1 FROM sys.schemas WHERE Name = 'Reporting'
)
BEGIN
	EXEC ('CREATE SCHEMA Reporting')
END
GO

IF NOT EXISTS (
	SELECT 1 FROM sys.procedures WHERE object_id = OBJECT_ID('Reporting.GetEmployeeTotalSales') AND type IN ('P', 'PC')
)
BEGIN
	EXEC ('CREATE PROCEDURE Reporting.GetEmployeeTotalSales AS SELECT 1')
END
GO

ALTER PROCEDURE Reporting.GetEmployeeTotalSales (
	@lastName nvarchar(50) = NULL
	,@firstName nvarchar(50) = NULL
	,@region nvarchar(50) = NULL
)
AS
BEGIN
	SET NOCOUNT ON

	SELECT
		@lastName = NULLIF(LTRIM(RTRIM(ISNULL(@lastName, ''))), '')
		,@firstName = NULLIF(LTRIM(RTRIM(ISNULL(@firstName, ''))), '')
		,@region = NULLIF(LTRIM(RTRIM(ISNULL(@region, ''))), '')

	SELECT 
		EmployeeName = CONCAT(e.TitleOfCourtesy, e.FirstName, ' ', e.LastName, ' (' + e.Title + ')')
		,PhoneNumber = CONCAT(e.HomePhone, ' x' + e.Extension)
		,TotalAmountSold = ISNULL(CAST(ROUND(ord.TotalOrderAmount, 2) AS money), 0)
		,EmployeeRegion = e.Region
	FROM dbo.Employees e
	OUTER APPLY (
		SELECT 
			TotalOrderAmount = SUM(
									( ISNULL(od.UnitPrice, 0) - ISNULL(od.Discount, 0) ) * ISNULL(od.Quantity, 0)
								)
		FROM dbo.Orders o
		JOIN dbo.[Order Details] od ON o.OrderID = od.OrderID
		WHERE
			o.EmployeeID = e.EmployeeID
		GROUP BY
			o.EmployeeID
	) ord
	WHERE
		(
			@lastName IS NULL
			OR e.LastName LIKE '%' + @lastName + '%'
		)
		AND (
			@firstName IS NULL
			OR e.FirstName LIKE '%' + @firstName + '%'
		)
		AND (
			@region IS NULL
			OR e.Region = @region
		)
END
GO

	
-- ==========================================================
GO


-- ==========================================================
-- 3
-- ==========================================================
/*
	
*/

DECLARE @Years TABLE (
	OrderYear int PRIMARY KEY
)

INSERT INTO @Years (
	OrderYear
)
VALUES
	(1995)
	,(1996)
	,(1997)
	,(1998)
	,(1999)
	,(2000)

;WITH cte_OrdersByYear AS (
	SELECT
		prod.ProductName
		,OrderYear = YEAR(o.OrderDate)
		,OrderTotal = CAST(ROUND(SUM(( ISNULL(od.UnitPrice, 0) - ISNULL(od.Discount, 0) ) * ISNULL(od.Quantity, 0)), 2) AS money)
	FROM dbo.Orders o
	JOIN dbo.[Order Details] od ON o.OrderID = od.OrderID
	JOIN dbo.Products prod ON od.ProductID = prod.ProductID
	GROUP BY
		prod.ProductName 
		,YEAR(o.OrderDate)
)

SELECT
	ord.ProductName
	,OrderTotal = ord.OrderTotal
	,yr.OrderYear
FROM @Years yr
LEFT JOIN cte_OrdersByYear ord ON yr.OrderYear = yr.OrderYear



--SELECT
--	prod.ProductName
--	,OrderTotal = CAST(ROUND(SUM(( ISNULL(od.UnitPrice, 0) - ISNULL(od.Discount, 0) ) * ISNULL(od.Quantity, 0)), 2) AS money)
--	--,[Year] = YEAR(o.OrderDate)
--	,yr.OrderYear
--FROM @Years yr
--LEFT JOIN (
--	SELECT *
--	FROM dbo.Orders o
--	JOIN dbo.[Order Details] od ON o.OrderID = od.OrderID
--	JOIN dbo.Products prod ON od.ProductID = prod.ProductID
--GROUP BY
--	prod.ProductName
--	,yr.OrderYear
--	--,YEAR(o.OrderDate)
--ORDER BY
--	prod.ProductName
--	,yr.OrderYear
--	--,YEAR(o.OrderDate)

-- ==========================================================
GO


-- ==========================================================
-- 
-- ==========================================================
/*

*/


-- ==========================================================
GO


-- ==========================================================
-- 
-- ==========================================================
/*

*/


-- ==========================================================
GO


-- ==========================================================
-- 
-- ==========================================================
/*

*/


-- ==========================================================
GO


-- ==========================================================
-- 
-- ==========================================================
/*

*/


-- ==========================================================
GO


-- ==========================================================
-- 
-- ==========================================================
/*

*/


-- ==========================================================
GO


-- ==========================================================
-- 
-- ==========================================================
/*

*/


-- ==========================================================
GO
