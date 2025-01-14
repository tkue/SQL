USE Northwind
GO

DECLARE 
    @schemaTableName nvarchar(256) = 'dbo.Customers'
    ,@columnName nvarchar(128)
    ,@firstColumn nvarchar(128)
	,@primaryKey nvarchar(128)
    ,@sql nvarchar(max)


SELECT TOP 1 @firstColumn = name
FROM sys.columns c
WHERE 
    c.object_id = OBJECT_ID(@schemaTableName)
ORDER BY
    c.column_id

SELECT @primaryKey = COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE 
	OBJECTPROPERTY(OBJECT_ID(CONSTRAINT_SCHEMA + '.' + QUOTENAME(CONSTRAINT_NAME)), 'IsPrimaryKey') = 1
AND OBJECT_ID(CONCAT(CONSTRAINT_SCHEMA, '.', TABLE_NAME)) = OBJECT_ID(@schemaTableName)


SET @sql = 'SELECT HASHBYTES(''SHA1'', CONCAT('


DECLARE cur CURSOR FAST_FORWARD
FOR
SELECT name
FROM sys.columns c
WHERE 
    c.object_id = OBJECT_ID(@schemaTableName)

OPEN cur
FETCH NEXT 
FROM cur 
INTO 
    @columnName

WHILE @@FETCH_STATUS = 0
BEGIN 
    IF @columnName <> @firstColumn
        SET @sql += ', '

     SET @sql += 'CAST(' + @columnName + ' AS nvarchar(max))'



    FETCH NEXT 
    FROM cur 
    INTO 
        @columnName
END 
CLOSE cur
DEALLOCATE cur

SET @sql += '))'
SET @sql += ', [' + @primaryKey + '] = ' + @primaryKey
SET @sql += ' FROM ' + @schemaTableName

