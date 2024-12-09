USE Util
GO

DECLARE 
	@sql nvarchar(max)

DECLARE 
	@objectDatabase nvarchar(128) = 'Northwind'
	,@objectSchema nvarchar(128) = 'dbo'
	,@objectName nvarchar(128) = 'Sales by Year'
	,@localTempTableName nvarchar(128) = '#t'


EXEC Util.GenScript_AddObjectColumnsToTempTable @objectDatabase
													,@objectSchema
													,@objectName
													,@localTempTableName
													,@sql OUTPUT


DROP TABLE IF EXISTS #t 
CREATE TABLE #t (
	_id int
)

EXEC sp_executesql @sql 

ALTER TABLE #t DROP COLUMN _id


SET @sql = CONCAT(
				'INSERT ', @localTempTableName, CHAR(10)
				,'EXEC ', QUOTENAME(@objectDatabase) + '.', QUOTENAME(@objectSchema) + '.', QUOTENAME(@objectName)
				,' @Beginning_Date=''1800-01-01'', @Ending_Date=''2020-01-01'''
			)

PRINT (@sql)
EXEC (@sql)

--INSERT #t
--EXEC [Northwind].[dbo].[Sales by Year] '1800-01-01', '2020-01-01'

SELECT *
FROM #t 

