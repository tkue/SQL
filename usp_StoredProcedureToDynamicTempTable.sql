USE Util
GO



/*
CREATE TABLE [dbo].[##t]
GO


CREATE PROCEDURE Util.GenScript_AddObjectColumnsToTempTable (
	@objectDatabase nvarchar(128)
	,@objectSchema nvarchar(128)
	,@objectName nvarchar(128)
	,@localTempTableName nvarchar(128)
	,@sql nvarchar(max) OUTPUT
)
AS

SET NOCOUNT ON

DECLARE 
	@localSql nvarchar(max)

DECLARE 
	@name nvarchar(128)
	,@systemTypeName nvarchar(128)

DECLARE
	@objectId int


-- Get object_id
SET @localSql = 
	'
	SELECT @objectIdOUT = (SELECT o.object_id
						FROM ' + QUOTENAME(@objectDatabase) + '.sys.objects o
						JOIN ' + QUOTENAME(@objectDatabase) + '.sys.schemas s ON o.schema_id = s.schema_id
						WHERE
							o.name = ''' + @objectName + '''
							AND s.name = ''' + @objectSchema + '''
						)'

EXEC sp_executesql @localSql
					,N'@objectIdOUT int OUTPUT'
					,@objectIdOUT = @objectId OUTPUT


-- Get column resultset 
SET @localSql = CONCAT(
				'USE ' + @objectDatabase + CHAR(10)
				,'SELECT name, system_type_name
				FROM ', @objectDatabase + '.'
				,'sys.dm_exec_describe_first_result_set_for_object(' + CAST(@objectId AS varchar) + ', 0) ORDER BY column_ordinal'
			)


DROP TABLE IF EXISTS #Columns 
CREATE TABLE #Columns (
	name nvarchar(128)
	,system_type_name nvarchar(128)
)

INSERT #Columns
EXEC (@localSql)


SET @sql = ''

-- Build alter statements
DECLARE cur CURSOR LOCAL FAST_FORWARD
FOR
	SELECT 
		name
		,system_type_name
	FROM #Columns

OPEN cur

FETCH NEXT 
FROM cur
INTO 
	@name
	,@systemTypeName

WHILE @@FETCH_STATUS = 0
BEGIN


	SET @sql += 'ALTER TABLE ' + @localTempTableName + ' ADD ' + QUOTENAME(@name) + ' ' + @systemTypeName + ';' + CHAR(10)


	FETCH NEXT 
	FROM cur
	INTO 
		@name
		,@systemTypeName
END
CLOSE cur
DEALLOCATE cur


DROP TABLE #Columns
GO

--DROP TABLE IF EXISTS #t 

--CREATE TABLE #t (_Id int IDENTITY(1, 1))


--EXEC sp_executesql @sql

--SELECT *
--FROM #t 


--SELECT *
--FROM sys.dm_exec_describe_first_result_set_for_object(OBJECT_ID(@objectName), 0)
