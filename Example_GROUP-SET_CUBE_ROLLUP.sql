USE AdventureWorks2012
GO

SELECT  t.[Group] AS region, t.name AS territory,  sum(TotalDue) AS revenue, 
  datepart(yyyy, OrderDate) AS [year], datepart(mm, OrderDate) AS [month]
FROM    Sales.SalesOrderHeader s
  INNER JOIN Sales.SalesTerritory T ON s.TerritoryID = T.TerritoryID
GROUP BY t.[Group], t.name, datepart(yyyy, OrderDate), datepart(mm, OrderDate)
  WITH ROLLUP