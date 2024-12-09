/*
https://docs.microsoft.com/en-us/sql/t-sql/queries/select-over-clause-transact-sql
*/

USE AdventureWorks2012
GO

-- Percent of product per order
SELECT
	SalesOrderID
	,ProductID
	,OrderQty
	,Total = SUM(OrderQty) OVER (PARTITION BY SalesOrderID)
	,PercentByProductID = CAST(1. * OrderQty / SUM(OrderQty) OVER (PARTITION BY SalesOrderID) * 100 AS DECIMAL(5, 2))
FROM Sales.SalesOrderDetail
WHERE SalesOrderID IN (43659, 43664)



-- Moving average
SELECT BusinessEntityID, TerritoryID   
   ,DATEPART(yy,ModifiedDate) AS SalesYear  
   ,CONVERT(varchar(20),SalesYTD,1) AS  SalesYTD  
   ,CONVERT(varchar(20),AVG(SalesYTD) OVER (PARTITION BY TerritoryID   
                                            ORDER BY DATEPART(yy,ModifiedDate)   
                                           ),1) AS MovingAvg  
   ,CONVERT(varchar(20),SUM(SalesYTD) OVER (PARTITION BY TerritoryID   
                                            ORDER BY DATEPART(yy,ModifiedDate)   
                                            ),1) AS CumulativeTotal  
FROM Sales.SalesPerson  
WHERE TerritoryID IS NULL OR TerritoryID < 5  
ORDER BY TerritoryID,SalesYear;  