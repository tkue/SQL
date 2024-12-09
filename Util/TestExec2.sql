USE Util
GO

DECLARE 
	@sql varchar(max)
	,@loggingId int


SET @sql = '
DELETE FROM [Test_1].[dbo].[Employees]

INSERT INTO [Test_1].[dbo].[Employees] (
      [LastName]
      ,[FirstName]
      ,[Title]
      ,[TitleOfCourtesy]
      ,[BirthDate]
      ,[HireDate]
      ,[Address]
      ,[City]
      ,[Region]
      ,[PostalCode]
      ,[Country]
      ,[HomePhone]
      ,[Extension]
      ,[Photo]
      ,[Notes]
      ,[ReportsTo]
      ,[PhotoPath]
	)
	SELECT 
	 [LastName]
      ,[FirstName]
      ,[Title]
      ,[TitleOfCourtesy]
      ,[BirthDate]
      ,[HireDate]
      ,[Address]
      ,[City]
      ,[Region]
      ,[PostalCode]
      ,[Country]
      ,[HomePhone]
      ,[Extension]
      ,[Photo]
      ,[Notes]
      ,[ReportsTo]
      ,[PhotoPath]
  FROM Northwind.[dbo].[Employees]
'

EXEC Util.dbo.ExecuteSql @sql, NULL, 0, 0, @loggingId

SET @sql = '
TRUNCATE TABLE [Test_1].[dbo].[Customers]

INSERT INTO [Test_1].[dbo].[Customers] (
	CustomerID
	,[CompanyName]
      ,[ContactName]
      ,[ContactTitle]
      ,[Address]
      ,[City]
      ,[Region]
      ,[PostalCode]
      ,[Country]
      ,[Phone]
      ,[Fax]
)
SELECT 
CustomerId
,[CompanyName]
      ,[ContactName]
      ,[ContactTitle]
      ,[Address]
      ,[City]
      ,[Region]
      ,[PostalCode]
      ,[Country]
      ,[Phone]
      ,[Fax]
  FROM Northwind.[dbo].[Customers]
 '
 EXEC Util.dbo.ExecuteSql @sql, NULL, 0, 0, @loggingId


