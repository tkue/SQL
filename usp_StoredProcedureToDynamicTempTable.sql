USE Util
GO



/*
CREATE TABLE [dbo].[##t](	  [is_hidden] BIT	, [column_ordinal] INT	, [name] NVARCHAR(128)	, [is_nullable] BIT	, [system_type_id] INT	, [system_type_name] NVARCHAR(128)	, [max_length] SMALLINT	, [precision] TINYINT	, [scale] TINYINT	, [collation_name] NVARCHAR(128)	, [user_type_id] INT	, [user_type_database] NVARCHAR(128)	, [user_type_schema] NVARCHAR(128)	, [user_type_name] NVARCHAR(128)	, [assembly_qualified_type_name] NVARCHAR(4000)	, [xml_collection_id] INT	, [xml_collection_database] NVARCHAR(128)	, [xml_collection_schema] NVARCHAR(128)	, [xml_collection_name] NVARCHAR(128)	, [is_xml_document] BIT	, [is_case_sensitive] BIT	, [is_fixed_length_clr_type] BIT	, [source_server] NVARCHAR(128)	, [source_database] NVARCHAR(128)	, [source_schema] NVARCHAR(128)	, [source_table] NVARCHAR(128)	, [source_column] NVARCHAR(128)	, [is_identity_column] BIT	, [is_part_of_unique_key] BIT	, [is_updateable] BIT	, [is_computed_column] BIT	, [is_sparse_column_set] BIT	, [ordinal_in_order_by_list] SMALLINT	, [order_by_is_descending] BIT	, [order_by_list_length] SMALLINT	, [error_number] INT	, [error_severity] INT	, [error_state] INT	, [error_message] NVARCHAR(2048)	, [error_type] INT	, [error_type_desc] NVARCHAR(30))*/
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

