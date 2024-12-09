
CREATE OR ALTER PROCEDURE Util.GetTestSqlQueryForObject (
    @objectId INT
)
AS
SET NOCOUNT ON

DECLARE
    @msg nvarchar(max)
    ,@sql nvarchar(max)
    ,@objectName nvarchar(256)
    ,@objectSchemaName nvarchar(128)
    ,@objectFullName nvarchar(512)
    ,@objectType nvarchar(256)
    ,@parameterId int
    ,@paramName nvarchar(256)
    ,@paramType nvarchar(128)
    ,@paramMaxLength INT
    ,@paramPrecision int
    ,@paramScale int
    ,@paramIsOutput bit



IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = @objectId)
BEGIN
    SET @msg = N'Object cannot be found for object_id: ' + CAST(@objectId AS varchar(50))
    RAISERROR(@msg, 16, 1)
END


SET @objectType = (SELECT type_desc FROM sys.objects WHERE object_id = @objectId)

SELECT
    @objectName = o.name
    ,@objectSchemaName = SCHEMA_NAME(o.schema_id)
    ,@objectType = o.type_desc
FROM sys.objects o
WHERE
    o.object_id = @objectId

SET @objectFullName = QUOTENAME(@objectSchemaName) + '.' + QUOTENAME(@objectName)

SET @sql = CASE
                WHEN @objectType = 'SQL_STORED_PROCEDURE'
                    THEN 'EXEC ' + @objectFullName + ' '
                WHEN @objectType = 'SQL_TABLE_VALUED_FUNCTION'
                    THEN 'SELECT COUNT(*) FROM ' + @objectFullName + '('
                WHEN @objectType = 'SQL_SCALAR_FUNCTION'
                    THEN 'SELECT ' + @objectFullName + '('
            END



DECLARE cur CURSOR
FOR
SELECT
    parameter_id = ROW_NUMBER() OVER (ORDER BY p.parameter_id)
    ,p.name AS ParameterName
    ,t.name AS SystemType
    ,p.max_length
    ,p.[precision]
    ,p.scale
    ,p.is_output
FROM sys.parameters p
JOIN sys.objects o ON p.object_id = o.object_id
JOIN sys.types t ON p.system_type_id = t.system_type_id
WHERE
    o.object_id = @objectId
    AND ISNULL(p.name, '') <> ''
ORDER BY
    p.parameter_id

OPEN cur

FETCH NEXT
FROM cur
INTO
    @parameterId
    ,@paramName
    ,@paramType
    ,@paramMaxLength
    ,@paramPrecision
    ,@paramScale
    ,@paramIsOutput

WHILE @@FETCH_STATUS = 0
BEGIN
    IF @parameterId > 1
        SET @sql += ','

    SET @sql += CASE
                    WHEN @paramType IN ('int', 'bigint', 'float', 'decimal', 'numeric', 'smallint', 'tinyint')
                        THEN '''0'''
                    WHEN @paramType IN ('bit')
                        THEN '''1'''
                    WHEN @paramType IN ('char', 'nchar')
                        THEN '''A'''
                    WHEN @paramType IN ('data', 'datetime', 'datetime2')
                        THEN CAST(CAST(GETDATE() AS date) AS varchar(100))
                    WHEN @paramType = 'uniqueidentifier'
                        THEN CAST(NEWID() AS char(36))
                END

    FETCH NEXT
    FROM cur
    INTO
        @parameterId
        ,@paramName
        ,@paramType
        ,@paramMaxLength
        ,@paramPrecision
        ,@paramScale
        ,@paramIsOutput

END
CLOSE cur
DEALLOCATE cur

IF @objectType IN ('SQL_SCALAR_FUNCTION', 'SQL_TABLE_VALUED_FUNCTION')
    SET @sql += ')'

SELECT @sql AS SqlStmt
GO