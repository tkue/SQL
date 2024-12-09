DECLARE
    @column_list nvarchar(max)
    ,@table_name nvarchar(128) = 'Invoices'
    ,@schema_name nvarchar(128) = 'Sales'
    ,@pk nvarchar(128)

SELECT @column_list = COALESCE(@column_list + ', ', '')
        + /* Put your casting here from XML, text, etc columns */ QUOTENAME(COLUMN_NAME)
FROM    INFORMATION_SCHEMA.COLUMNS
WHERE   TABLE_NAME = @table_name
    AND TABLE_SCHEMA = @schema_name

SELECT @pk = Col.Column_Name from
    INFORMATION_SCHEMA.TABLE_CONSTRAINTS Tab,
    INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE Col
WHERE
    Col.Constraint_Name = Tab.Constraint_Name
    AND Col.Table_Name = Tab.Table_Name
    AND Constraint_Type = 'PRIMARY KEY'
    AND Col.Table_Name = @table_name


DECLARE @template AS varchar(MAX)
SET @template = 'SELECT [k]={@pk},[v]=CAST(CHECKSUM_AGG(CHECKSUM({@column_list})) AS nvarchar(100)) FROM {@schema_name}.{@table_name} GROUP BY {@pk}'

DECLARE @sql AS nvarchar(MAX)
SET @sql = REPLACE(REPLACE(REPLACE(REPLACE(@template,
    '{@column_list}', @column_list),
    '{@schema_name}', @schema_name),
    '{@table_name}', @table_name),
    '{@pk}', CAST(@pk AS nvarchar(20)))


DROP TABLE IF EXISTS #ResultSet
CREATE TABLE #ResultSet (
    [is_hidden] bit
    ,[column_ordinal] int
    ,[name] nvarchar(128) NULL
    ,[is_nullable] bit
    ,[system_type_id] int
    ,[system_type_name] nvarchar(256) NULL
    ,[max_length] smallint
    ,[precision] tinyint
    ,[scale] tinyint
    ,[collation_name] nvarchar(128) NULL
    ,[user_type_id] int NULL
    ,[user_type_database] nvarchar(128) NULL
    ,[user_type_schema] nvarchar(128) NULL
    ,[user_type_name] nvarchar(128) NULL
    ,[assembly_qualified_type_name] nvarchar(4000)
    ,[xml_collection_id] int NULL
    ,[xml_collection_database] nvarchar(128) NULL
    ,[xml_collection_schema] nvarchar(128) NULL
    ,[xml_collection_name] nvarchar(128) NULL
    ,[is_xml_document] bit
    ,[is_case_sensitive] bit
    ,[is_fixed_length_clr_type] bit
    ,[source_server] nvarchar(100) NULL
    ,[source_database] nvarchar(128)
    ,[source_schema] nvarchar(128)
    ,[source_table] nvarchar(128)
    ,[source_column] nvarchar(128)
    ,[is_identity_column] bit NULL
    ,[is_part_of_unique_key] bit NULL
    ,[is_updateable] bit NULL
    ,[is_computed_column] bit NULL
    ,[is_sparse_column_set] bit NULL
    ,[ordinal_in_order_by_list] smallint NULL
    ,[order_by_list_length] smallint NULL
    ,[order_by_is_descending] smallint NULL
    ,[tds_type_id] int
    ,[tds_length] int
    ,[tds_collation_id] int NULL
    ,[tds_collation_sort_id] tinyint NULL
)
INSERT #ResultSet
EXEC sp_describe_first_result_set @sql, NULL, 0

SELECT r.name, r.system_type_name
INTO #Columns
FROM #ResultSet r

DECLARE
    @localTempTableName nvarchar(128) = 'Invoices'
	,@tsql nvarchar(max)
    ,@name nvarchar(128)
	,@systemTypeName nvarchar(128)

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

SELECT @sql
GO


SELECT
    -- SUM(p.rows)
    *
FROM
    sys.tables t
INNER JOIN
    sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN
    sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id

-- CREATE TABLE dbo.KV (
--     K bigint NOT NULL
--     ,V nvarchar(100) NOT NULL
--     ,Obj nvarchar(100) NOT NULL
--     ,CONSTRAINT PK_KV PRIMARY KEY NONCLUSTERED HASH (K)
--         WITH (BUCKET_COUNT = 45000000)
--     ,CONSTRAINT UC_KV_K_OBJ UNIQUE (K, Obj)
-- )
-- WITH (
--     MEMORY_OPTIMIZED = ON
--     ,DURABILITY = SCHEMA_AND_DATA
-- );
