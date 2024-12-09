USE Northwind
GO
SET NOCOUNT ON
DECLARE 
	@sql nvarchar(max)
	,@line nvarchar(max)
	,@objectName nvarchar(128)
	,@objectText nvarchar(max)
	,@id int

DROP TABLE IF EXISTS #Text 
CREATE TABLE #Text ( ObjText nvarchar(max) )

DECLARE @s AS dbo.StringTable

DROP TABLE IF EXISTS #ObjDefinitions 
CREATE TABLE #ObjDefinitions (
	Id int PRIMARY KEY IDENTITY(1, 1)
	,ObjectName nvarchar(250)
	,ObjectText nvarchar(max)
)

DECLARE cur CURSOR FAST_FORWARD
FOR
SELECT TOP 5
	QUOTENAME(SCHEMA_NAME(o.schema_id)) + '.' + QUOTENAME(o.name)
FROM sys.objects o
WHERE
	o.type IN ('FN', 'IF', 'P', 'V')
ORDER BY
	o.object_id


OPEN cur

FETCH NEXT
FROM cur
INTO 
	@objectName

WHILE @@FETCH_STATUS = 0
BEGIN 
	DELETE FROM @s 

	INSERT INTO @s (Val)
	EXEC sp_helptext @objectName


	EXEC Util.GetSqlStringFromTable @s, @sql OUTPUT, ' '

	INSERT INTO #ObjDefinitions ( ObjectName, ObjectText )
	VALUES
		(@objectName, @sql)

	PRINT @sql

	FETCH NEXT
	FROM cur
	INTO 
		@objectName
END 
CLOSE cur
DEALLOCATE cur


SELECT *
FROM #ObjDefinitions