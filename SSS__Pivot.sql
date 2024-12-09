-- Source
-- http://www.sqlservercentral.com/articles/Stairway+Series/125187/

USE AdventureWorks2012;
GO

-- To Pivot
SELECT [TerritoryID]
     , Year([OrderDate]) AS OrderYear
	 , COUNT(*)  NumOfOrders
FROM [Sales].[SalesOrderHeader]
WHERE Year([OrderDate]) in (2005,2006)
GROUP BY Year([OrderDate]),[TerritoryID]
ORDER BY Year([OrderDate]),[TerritoryID]

-- Pivot Number of Orders Per Year by Territory ID
SELECT OrderYear as Num_Of_Orders_Per_Year_By_TerritoryID, 
 [1], [2], [3], [4], [5], [6], [7], [8], [9], [10]
FROM
(SELECT [TerritoryID]
     , Year([OrderDate]) AS OrderYear
	 ,1 Num
FROM [Sales].[SalesOrderHeader]
WHERE Year([OrderDate]) in (2005,2006)) AS SourceTable
PIVOT
(
SUM(Num)  
FOR [TerritoryID] IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10])
) AS PivotTable;


-- Multiple Columns Not Used in Pivot
-- -- Sales Per Quarter by TerritoryID
SELECT OrderYear, TerritoryID, 
       [1], [2], [3], [4] 
	    
FROM
(SELECT Year([OrderDate]) AS OrderYear
        ,TerritoryID 
        , ((Month([OrderDate])-1)/3) + 1 as OrderQtr
	   ,1 Num
FROM [Sales].[SalesOrderHeader]
WHERE Year([OrderDate]) in (2005,2006)) AS SourceTable
PIVOT
(
COUNT(Num)  
FOR [OrderQtr] IN ([1], [2], [3], [4])
) AS PivotTable
ORDER BY OrderYear, TerritoryID;


-- Dynamically Determining PIVOT columns 
/*
What happens if you don't always know the column values you want to pivot on? 
Does this mean you can't write your PIVOT query in advance? 

Not knowing the pivot column values doesn't keep you from pivoting your data. 
You can use dynamic SQL code to generate your PIVOT query when the data values for the FOR clause of the PIVOT operator are not known. 
The code in Listing 4 generates dynamic SQL to determine the number of SalesOrderHeader records there are by TerritoryID and OrderYear.
*/
DECLARE @Columns nvarchar(1000)='';
-- Identify columns to pivot
SELECT @Columns=stuff((
    SELECT DISTINCT ',' + QUOTENAME(CAST(Year([OrderDate]) AS CHAR(4))) as OrderYear
    FROM [AdventureWorks2012].[Sales].[SalesOrderHeader] p2
    ORDER BY OrderYear
    FOR XML PATH(''), TYPE).value('.', 'varchar(max)')
            ,1,1,'')
--FROM (SELECT DISTINCT CAST(Year([OrderDate]) AS CHAR(4)) AS OrderYear 
--      FROM [Sales].[SalesOrderHeader]) AS Years
DECLARE @CMD nvarchar(1000);
-- Generate Dynamic SQL
SET @CMD = 'SELECT TerritoryID, ' + @Columns +
           ' FROM (SELECT TerritoryID, Year(OrderDate) AS OrderYear ' +
		   'FROM [Sales].[SalesOrderHeader])AS SourceTable ' +
           ' PIVOT(COUNT(OrderYear) For [OrderYear] IN (' + @Columns + ')) as PivotTable';
-- Print and execute generated command
PRINT @CMD
EXEC sp_executesql @CMD;

SELECT TerritoryID, [2005],[2006],[2007],[2008] 
FROM (
   SELECT TerritoryID, Year(OrderDate) AS OrderYear 
   FROM [Sales].[SalesOrderHeader])AS SourceTable  
   PIVOT(COUNT(OrderYear) For [OrderYear] IN ([2005],[2006],[2007],[2008])) as PivotTable