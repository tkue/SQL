USE Northwind
GO

SELECT * FROM dbo.Employees


-- Duplicate Employees
--INSERT INTO dbo.Employees (
--	LastName
--	,FirstName
--	,Title
--	,TitleOfCourtesy
--	,BirthDate
--	,HireDate
--	,Address
--	,City
--	,Region
--	,PostalCode
--	,Country
--	,HomePhone
--	,Extension
--	,Photo
--	,Notes
--	,ReportsTo
--	,PhotoPath
--)
--SELECT 
--	e.LastName
--	,e.FirstName
--	,e.Title
--	,e.TitleOfCourtesy
--	,e.BirthDate
--	,HireDate = DATEADD(day, 100, e.HireDate)
--	,e.Address
--	,e.City
--	,e.Region
--	,e.PostalCode
--	,e.Country
--	,e.HomePhone
--	,Extension = NULL
--	,e.Photo
--	,e.Notes
--	,e.ReportsTo
--	,e.PhotoPath
--FROM dbo.Employees e
--WHERE
--	e.EmployeeID < 4
GO


--;WITH cte AS (
--	SELECT
--		RowNum = ROW_NUMBER() OVER (PARTITION BY e.FirstName, e.LastName, e.Title ORDER BY e.HireDate DESC)
--		,*
--	FROM dbo.Employees e
--)--INSERT INTO dbo.Employees (
--	LastName
--	,FirstName
--	,Title
--	,TitleOfCourtesy
--	,BirthDate
--	,HireDate
--	,Address
--	,City
--	,Region
--	,PostalCode
--	,Country
--	,HomePhone
--	,Extension
--	,Photo
--	,Notes
--	,ReportsTo
--	,PhotoPath
--)
--SELECT TOP 1
--	e.LastName
--	,e.FirstName
--	,e.Title
--	,e.TitleOfCourtesy
--	,e.BirthDate
--	,HireDate = DATEADD(day, 100, e.HireDate)
--	,e.Address
--	,e.City
--	,e.Region
--	,e.PostalCode
--	,e.Country
--	,e.HomePhone
--	,Extension = NULL
--	,e.Photo
--	,e.Notes
--	,e.ReportsTo
--	,e.PhotoPath
--FROM cte e
--WHERE
--	e.RowNum > 1
--ORDER BY
--	e.FirstName