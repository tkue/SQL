 /*************************************************************
*                                                            *
*   Copyright (C) Microsoft Corporation. All rights reserved.*
*                                                            *
*************************************************************/

 --****************** [ DWAdventureWorksLT2012Lab1 ETL Code ] *********************--
-- This file will flush and fill the sales data mart in the DWAdventureWorksLT2012Lab1 database
--***********************************************************************************************--
Use DWAdventureWorksLT2012Lab01;
go

 
--********************************************************************--
-- Drop Foreign Key Constraints
--********************************************************************--

ALTER TABLE dbo.FactSales DROP CONSTRAINT
	fkFactSalesToDimProducts;

ALTER TABLE dbo.FactSales DROP CONSTRAINT 
	fkFactSalesToDimCustomers;

ALTER TABLE dbo.FactSales DROP CONSTRAINT
	fkFactSalesOrderDateToDimDates;

ALTER TABLE dbo.FactSales DROP CONSTRAINT
	fkFactSalesShipDateDimDates;			

--********************************************************************--
-- Clear Table Data
--********************************************************************--

TRUNCATE TABLE dbo.FactSales;
TRUNCATE TABLE dbo.DimCustomers;
TRUNCATE TABLE dbo.DimProducts; 
  

--********************************************************************--
-- Fill Dimension Tables
--********************************************************************--

-- DimCustomers
-- <Add ETL Code Here>

INSERT INTO dbo.DimCustomers (
	CustomerID
	,ContactFullName
	,CompanyName
)
SELECT 
	CustomerID
	,FullName = CAST((FirstName + ' ' + LastName) AS nvarchar(200))
	,CompanyName
FROM AdventureWorksLT2012.SalesLT.Customer
go

-- DimProducts
-- <Add ETL Code Here>
INSERT INTO dbo.DimProducts (
	ProductID
	,ProductName
	--,ProductNumber
	,ProductColor
	--,ProductStandardCost
	,ProductListPrice
	,ProductSize
	,ProductWeight
	,ProductCategoryID
	,ProductCategoryName
)
SELECT
	p.ProductID
	,p.Name
	--,ProductNumber = CAST(ProductNumber AS nvarchar(50))
	,Color = CAST(ISNULL(p.Color, '') AS nvarchar(50))
	--,StandardCost
	,p.ListPrice
	,Size = ISNULL(p.Size, 0)
	,p.Weight
	,p.ProductCategoryID
	,ProductCategoryName = ISNULL(c.Name, 'N/A')
FROM AdventureWorksLT2012.SalesLT.Product p
JOIN AdventureWorksLT2012.SalesLT.ProductCategory c ON p.ProductCategoryID = c.ProductCategoryID
go

--********************************************************************--
-- Fill Fact Tables
--********************************************************************--

-- Fill Fact Sales 
--  <Add ETL Code Here>
INSERT INTO dbo.FactSales (
	SalesOrderID
	,SalesOrderDetailID
	,CustomerKey
	,ProductKey
	,OrderDateKey
	,ShipDateKey
	,OrderQty
	,UnitPrice
	,UnitPriceDiscount
)
SELECT
	 sod.SalesOrderID
	,sod.SalesOrderDetailID
	,dc.CustomerKey
	,dp.ProductKey
	,dd0.CalendarDateKey
	,dd1.CalendarDateKey
	,sod.OrderQty
	,sod.UnitPrice
	,sod.UnitPriceDiscount
FROM AdventureWorksLT2012.SalesLT.SalesOrderDetail sod
JOIN DWAdventureWorksLT2012Lab01.dbo.DimProducts dp ON dp.ProductID = sod.ProductID
JOIN AdventureWorksLT2012.SalesLT.SalesOrderHeader soh ON soh.SalesOrderID = sod.SalesOrderID
JOIN dbo.DimCustomers dc ON dc.CustomerID = soh.CustomerID
JOIN dbo.DimDates dd0 ON CAST(dd0.CalendarDate AS Date) = CAST(soh.OrderDate AS Date)
JOIN dbo.DimDates dd1 ON CAST(dd1.CalendarDate AS date) = CAST(soh.ShipDate AS date)
GO

--********************************************************************--
-- Replace Foreign Key Constraints
--********************************************************************--
ALTER TABLE dbo.FactSales ADD CONSTRAINT
	fkFactSalesToDimProducts FOREIGN KEY (ProductKey) 
	REFERENCES dbo.DimProducts	(ProductKey);

ALTER TABLE dbo.FactSales ADD CONSTRAINT 
	fkFactSalesToDimCustomers FOREIGN KEY (CustomerKey) 
	REFERENCES dbo.DimCustomers (CustomerKey);
 
ALTER TABLE dbo.FactSales ADD CONSTRAINT
	fkFactSalesOrderDateToDimDates FOREIGN KEY (OrderDateKey) 
	REFERENCES dbo.DimDates(CalendarDateKey);

ALTER TABLE dbo.FactSales ADD CONSTRAINT
	fkFactSalesShipDateDimDates FOREIGN KEY (ShipDateKey)
	REFERENCES dbo.DimDates (CalendarDateKey);
 
 
--********************************************************************--
-- Verify that the tables are filled
--********************************************************************--
-- Dimension Tables
--SELECT * FROM [DWAdventureWorksLT2012Lab01].[dbo].[DimCustomers]; 
--SELECT * FROM [DWAdventureWorksLT2012Lab01].[dbo].[DimProducts]; 
--SELECT * FROM [DWAdventureWorksLT2012Lab01].[dbo].[DimDates]; 

---- Fact Tables 
--SELECT * FROM [DWAdventureWorksLT2012Lab01].[dbo].[FactSales]; 
