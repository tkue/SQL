USE Northwind
GO

DECLARE
	@objectFullName sysname
	,@objectId int
	,@schemaName nvarchar(128)
	,@objectName nvarchar(128)
	,@sql nvarchar(max)

--DROP PROCEDURE IF EXISTS #uspExecSql
--GO

--CREATE PROCEDURE #uspExecSql(
--	@sql nvarchar(max)
--	,@comment nvarchar(max)
--	,@loggingId int OUTPUT
--)
--AS
--SET NOCOUNT ON

--DECLARE 
--	@start datetime
--	,@end datetime

--SET @start = GETUTCDATE()

--BEGIN TRY
--	EXEC sp_executesql @sql
--	INSERT INTO #Logging ( Sql

--END TRY

DROP TABLE IF EXISTS #Logging
CREATE TABLE #Logging (
	LoggingId int PRIMARY KEY IDENTITY(1, 1)
	,ErrorSeverity int
	,ErrorState int
	,ErrorProcedure nvarchar(256)
	,ErrorLine int
	,ErrorMessage nvarchar(max)
	,SqlStatement nvarchar(max)
	,Comment nvarchar(max)
	,ObjectId int
	,ExecutionStartUTC datetime
	,ExecutionEndUTC datetime
)



DROP TABLE IF EXISTS #Objects
SELECT 
	ObjectFullName = CAST(QUOTENAME(SCHEMA_NAME(obj.schema_id)) + '.' + QUOTENAME(obj.name) AS sysname)
	,ObjectId = obj.object_id
	,SchemaName = QUOTENAME(SCHEMA_NAME(obj.schema_id))
	,ObjectName = obj.name
INTO #Objects
FROM sys.objects obj
WHERE
	obj.type_desc IN (
			'SQL_SCALAR_FUNCTION'
			,'SQL_STORED_PROCEDURE'
			,'SQL_TABLE_VALUED_FUNCTION'
		)
ORDER BY
	SCHEMA_NAME(obj.schema_id)
	,obj.name


DROP TABLE IF EXISTS #Sql 
CREATE TABLE #Sql (
	Id int PRIMARY KEY IDENTITY(1, 1)
	,SqlStmt nvarchar(max)
)





DECLARE cur CURSOR 
FOR
SELECT 
	ObjectFullName
	,ObjectId
	,SchemaName
	,ObjectName
FROM #Objects obj

OPEN cur

FETCH NEXT 
FROM cur
INTO
	@objectFullName
	,@objectId
	,@schemaName
	,@objectName

WHILE @@FETCH_STATUS = 0
BEGIN
	
	BEGIN TRY
		SET @sql = 'EXEC sp_refreshsqlmodule ''' + @objectFullName + ''''
	END TRY
	BEGIN CATCH
		INSERT INTO #Logging (
			ErrorSeverity
			,ErrorState
			,ErrorProcedure
			,ErrorLine
			,ErrorMessage
			,SqlStatement
			,Comment
		)
		SELECT 
			ERROR_SEVERITY()
			,ERROR_STATE()
			,ERROR_PROCEDURE()
			,ERROR_LINE()
			,ERROR_MESSAGE()
			,@sql
			,'sp_refreshsqlmodule'
	END CATCH

	NEXT_ROW:
	FETCH NEXT 
	FROM cur
	INTO
		@objectFullName
		,@objectId
		,@schemaName
		,@objectName
END 
CLOSE cur
DEALLOCATE cur


DECLARE @oId int 
SET @oId = OBJECT_ID('Reporting.GetOrderDetails')

SELECT @oId

SELECT *
FROM sys.dm_exec_describe_first_result_set_for_object(@oId, 0)
SELECT 
FROM sys.objects obj
JOIN sys.dm_exec_describe_first_result_set_for_object(obj.object_id) r ON 
WHERE
	obj.type_desc IN (
			'SQL_SCALAR_FUNCTION'
			,'SQL_STORED_PROCEDURE'
			,'SQL_TABLE_VALUED_FUNCTION'
		)
