USE WideWorldImporters
GO


-- SELECT 
--     CONCAT(
--         -- DB_NAME()
--         -- ,'.'
--         s.name
--         ,'.'
--         ,o.name
--     )
-- FROM sys.objects o 
-- JOIN sys.schemas s ON o.schema_id = s.schema_id
-- WHERE 
--     o.[type] = 'U'
-- ORDER BY 
--     s.name
--     ,o.name
/*

SELECT 
    CONCAT(
        -- QUOTENAME(DB_NAME())
        -- ,'.'
        QUOTENAME(s.name)
        ,'.'
        ,QUOTENAME(o.name)
    )
FROM sys.objects o 
JOIN sys.schemas s ON o.schema_id = s.schema_id
WHERE 
    o.[type] = 'U'
ORDER BY 
    s.name
    ,o.name

*/
/*

[WideWorldImporters].[Application].[Cities]
[WideWorldImporters].[Application].[Cities_Archive]
[WideWorldImporters].[Application].[Countries]
[WideWorldImporters].[Application].[Countries_Archive]
[WideWorldImporters].[Application].[DeliveryMethods]
[WideWorldImporters].[Application].[DeliveryMethods_Archive]
[WideWorldImporters].[Application].[PaymentMethods]
[WideWorldImporters].[Application].[PaymentMethods_Archive]
[WideWorldImporters].[Application].[People]
[WideWorldImporters].[Application].[People_Archive]
[WideWorldImporters].[Application].[StateProvinces]
[WideWorldImporters].[Application].[StateProvinces_Archive]
[WideWorldImporters].[Application].[SystemParameters]
[WideWorldImporters].[Application].[TransactionTypes]
[WideWorldImporters].[Application].[TransactionTypes_Archive]
[WideWorldImporters].[Purchasing].[PurchaseOrderLines]
[WideWorldImporters].[Purchasing].[PurchaseOrders]
[WideWorldImporters].[Purchasing].[SupplierCategories]
[WideWorldImporters].[Purchasing].[SupplierCategories_Archive]
[WideWorldImporters].[Purchasing].[Suppliers]
[WideWorldImporters].[Purchasing].[Suppliers_Archive]
[WideWorldImporters].[Purchasing].[SupplierTransactions]
[WideWorldImporters].[Sales].[BuyingGroups]
[WideWorldImporters].[Sales].[BuyingGroups_Archive]
[WideWorldImporters].[Sales].[CustomerCategories]
[WideWorldImporters].[Sales].[CustomerCategories_Archive]
[WideWorldImporters].[Sales].[Customers]
[WideWorldImporters].[Sales].[Customers_Archive]
[WideWorldImporters].[Sales].[CustomerTransactions]
[WideWorldImporters].[Sales].[InvoiceLines]
[WideWorldImporters].[Sales].[Invoices]
[WideWorldImporters].[Sales].[OrderLines]
[WideWorldImporters].[Sales].[Orders]
[WideWorldImporters].[Sales].[SpecialDeals]
[WideWorldImporters].[Warehouse].[ColdRoomTemperatures]
[WideWorldImporters].[Warehouse].[ColdRoomTemperatures_Archive]
[WideWorldImporters].[Warehouse].[Colors]
[WideWorldImporters].[Warehouse].[Colors_Archive]
[WideWorldImporters].[Warehouse].[PackageTypes]
[WideWorldImporters].[Warehouse].[PackageTypes_Archive]
[WideWorldImporters].[Warehouse].[StockGroups]
[WideWorldImporters].[Warehouse].[StockGroups_Archive]
[WideWorldImporters].[Warehouse].[StockItemHoldings]
[WideWorldImporters].[Warehouse].[StockItems]
[WideWorldImporters].[Warehouse].[StockItems_Archive]
[WideWorldImporters].[Warehouse].[StockItemStockGroups]
[WideWorldImporters].[Warehouse].[StockItemTransactions]
[WideWorldImporters].[Warehouse].[VehicleTemperatures]

*/

DROP PROCEDURE IF EXISTS #createTableCopy
GO

CREATE PROCEDURE #createTableCopy
(
    @table_name sysname
    ,@suffix nvarchar(20)
    ,@allSql nvarchar(max) OUTPUT 
)
AS
SET NOCOUNT ON

DECLARE 
    @__isExecute bit = 0

SET @allSql = N''

-- SELECT @table_name = @table_name + @suffix
-- SELECT @table_name
DECLARE
      @object_name SYSNAME
    , @object_id INT

SELECT
      @object_name = '[' + s.name + '].[' + o.name + ']'
    , @object_id = o.[object_id]
FROM sys.objects o WITH (NOWAIT)
JOIN sys.schemas s WITH (NOWAIT) ON o.[schema_id] = s.[schema_id]
WHERE s.name + '.' + o.name = @table_name
    AND o.[type] = 'U'
    AND o.is_ms_shipped = 0

DECLARE @SQL NVARCHAR(MAX) = ''

DECLARE @newTableName nvarchar(256)
SET @newTableName = CONCAT(SUBSTRING(@object_name, 1, -1 + LEN(@object_name)), @suffix, ']')


SET @SQL = 'DROP TABLE IF EXISTS ' + @newTableName + '; ' 
PRINT @SQL
SET @allSql += @SQL + CHAR(10)


IF @__isExecute = 1
    EXEC sys.sp_executesql @SQL

;WITH index_column AS
(
    SELECT
          ic.[object_id]
        , ic.index_id
        , ic.is_descending_key
        , ic.is_included_column
        , c.name
    FROM sys.index_columns ic WITH (NOWAIT)
    JOIN sys.columns c WITH (NOWAIT) ON ic.[object_id] = c.[object_id] AND ic.column_id = c.column_id
    WHERE ic.[object_id] = @object_id
),
fk_columns AS
(
     SELECT
          k.constraint_object_id
        , cname = c.name
        , rcname = rc.name
    FROM sys.foreign_key_columns k WITH (NOWAIT)
    JOIN sys.columns rc WITH (NOWAIT) ON rc.[object_id] = k.referenced_object_id AND rc.column_id = k.referenced_column_id
    JOIN sys.columns c WITH (NOWAIT) ON c.[object_id] = k.parent_object_id AND c.column_id = k.parent_column_id
    WHERE k.parent_object_id = @object_id
)
-- SELECT @SQL = 'CREATE TABLE ' + CONCAT(REPLACE(REPLACE(CAST(@object_name AS nvarchar(256)) COLLATE SQL_Latin1_General_CP1_CI_AS, '[' COLLATE SQL_Latin1_General_CP1_CI_AS, ''), ']' COLLATE SQL_Latin1_General_CP1_CI_AS, ''), @suffix) + CHAR(13) + '(' + CHAR(13) + STUFF((
    SELECT @SQL = 'CREATE TABLE ' + @newTableName + CHAR(13) + '(' + CHAR(13) + STUFF((
    SELECT CHAR(9) + ', [' + c.name + '] ' +
        CASE WHEN c.is_computed = 1
            THEN 'AS ' + cc.[definition]
            ELSE UPPER(tp.name) +
                CASE WHEN tp.name IN ('varchar', 'char', 'varbinary', 'binary', 'text')
                       THEN '(' + CASE WHEN c.max_length = -1 THEN 'MAX' ELSE CAST(c.max_length AS VARCHAR(5)) END + ')'
                     WHEN tp.name IN ('nvarchar', 'nchar', 'ntext')
                       THEN '(' + CASE WHEN c.max_length = -1 THEN 'MAX' ELSE CAST(c.max_length / 2 AS VARCHAR(5)) END + ')'
                     WHEN tp.name IN ('datetime2', 'time2', 'datetimeoffset')
                       THEN '(' + CAST(c.scale AS VARCHAR(5)) + ')'
                     WHEN tp.name = 'decimal'
                       THEN '(' + CAST(c.[precision] AS VARCHAR(5)) + ',' + CAST(c.scale AS VARCHAR(5)) + ')'
                    ELSE ''
                END +
                CASE WHEN c.collation_name IS NOT NULL THEN ' COLLATE ' + c.collation_name ELSE '' END +
                CASE WHEN c.is_nullable = 1 THEN ' NULL' ELSE ' NOT NULL' END +
                CASE WHEN dc.[definition] IS NOT NULL THEN ' DEFAULT' + dc.[definition] ELSE '' END +
                CASE WHEN ic.is_identity = 1 THEN ' IDENTITY(' + CAST(ISNULL(ic.seed_value, '0') AS CHAR(1)) + ',' + CAST(ISNULL(ic.increment_value, '1') AS CHAR(1)) + ')' ELSE '' END
        END + CHAR(13)
    FROM sys.columns c WITH (NOWAIT)
    JOIN sys.types tp WITH (NOWAIT) ON c.user_type_id = tp.user_type_id
    LEFT JOIN sys.computed_columns cc WITH (NOWAIT) ON c.[object_id] = cc.[object_id] AND c.column_id = cc.column_id
    LEFT JOIN sys.default_constraints dc WITH (NOWAIT) ON c.default_object_id != 0 AND c.[object_id] = dc.parent_object_id AND c.column_id = dc.parent_column_id
    LEFT JOIN sys.identity_columns ic WITH (NOWAIT) ON c.is_identity = 1 AND c.[object_id] = ic.[object_id] AND c.column_id = ic.column_id
    WHERE c.[object_id] = @object_id
    ORDER BY c.column_id
    FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, CHAR(9) + ' ')
    + '); '
    
    -- + ISNULL((SELECT CHAR(9) + ', CONSTRAINT [' + k.name + '] PRIMARY KEY (' +
    --                 (SELECT STUFF((
    --                      SELECT ', [' + c.name + '] ' + CASE WHEN ic.is_descending_key = 1 THEN 'DESC' ELSE 'ASC' END
    --                      FROM sys.index_columns ic WITH (NOWAIT)
    --                      JOIN sys.columns c WITH (NOWAIT) ON c.[object_id] = ic.[object_id] AND c.column_id = ic.column_id
    --                      WHERE ic.is_included_column = 0
    --                          AND ic.[object_id] = k.parent_object_id
    --                          AND ic.index_id = k.unique_index_id
    --                      FOR XML PATH(N''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, ''))
    --         + ')' + CHAR(13)
    --         FROM sys.key_constraints k WITH (NOWAIT)
    --         WHERE k.parent_object_id = @object_id
    --             AND k.[type] = 'PK'), '') + ')'  + CHAR(13)
    -- + ISNULL((SELECT (
    --     SELECT CHAR(13) +
    --          'ALTER TABLE ' + @object_name + ' WITH'
    --         + CASE WHEN fk.is_not_trusted = 1
    --             THEN ' NOCHECK'
    --             ELSE ' CHECK'
    --           END +
    --           ' ADD CONSTRAINT [' + fk.name  + '] FOREIGN KEY('
    --           + STUFF((
    --             SELECT ', [' + k.cname + ']'
    --             FROM fk_columns k
    --             WHERE k.constraint_object_id = fk.[object_id]
    --             FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '')
    --            + ')' +
    --           ' REFERENCES [' + SCHEMA_NAME(ro.[schema_id]) + '].[' + ro.name + '] ('
    --           + STUFF((
    --             SELECT ', [' + k.rcname + ']'
    --             FROM fk_columns k
    --             WHERE k.constraint_object_id = fk.[object_id]
    --             FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '')
    --            + ')'
    --         + CASE
    --             WHEN fk.delete_referential_action = 1 THEN ' ON DELETE CASCADE'
    --             WHEN fk.delete_referential_action = 2 THEN ' ON DELETE SET NULL'
    --             WHEN fk.delete_referential_action = 3 THEN ' ON DELETE SET DEFAULT'
    --             ELSE ''
    --           END
    --         + CASE
    --             WHEN fk.update_referential_action = 1 THEN ' ON UPDATE CASCADE'
    --             WHEN fk.update_referential_action = 2 THEN ' ON UPDATE SET NULL'
    --             WHEN fk.update_referential_action = 3 THEN ' ON UPDATE SET DEFAULT'
    --             ELSE ''
    --           END
    --         + CHAR(13) + 'ALTER TABLE ' + @object_name + ' CHECK CONSTRAINT [' + fk.name  + ']' + CHAR(13)
    --     FROM sys.foreign_keys fk WITH (NOWAIT)
    --     JOIN sys.objects ro WITH (NOWAIT) ON ro.[object_id] = fk.referenced_object_id
    --     WHERE fk.parent_object_id = @object_id
    --     FOR XML PATH(N''), TYPE).value('.', 'NVARCHAR(MAX)')), '')
    -- + ISNULL(((SELECT
    --      CHAR(13) + 'CREATE' + CASE WHEN i.is_unique = 1 THEN ' UNIQUE' ELSE '' END
    --             + ' NONCLUSTERED INDEX [' + i.name + '] ON ' + @object_name + ' (' +
    --             STUFF((
    --             SELECT ', [' + c.name + ']' + CASE WHEN c.is_descending_key = 1 THEN ' DESC' ELSE ' ASC' END
    --             FROM index_column c
    --             WHERE c.is_included_column = 0
    --                 AND c.index_id = i.index_id
    --             FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '') + ')'
    --             + ISNULL(CHAR(13) + 'INCLUDE (' +
    --                 STUFF((
    --                 SELECT ', [' + c.name + ']'
    --                 FROM index_column c
    --                 WHERE c.is_included_column = 1
    --                     AND c.index_id = i.index_id
    --                 FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '') + ')', '')  + CHAR(13)
    --     FROM sys.indexes i WITH (NOWAIT)
    --     WHERE i.[object_id] = @object_id
    --         AND i.is_primary_key = 0
    --         AND i.[type] = 2
    --     FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)')
    -- ), '')

PRINT @SQL
SET @allSql += @SQL + CHAR(10)

IF @__isExecute = 1
    EXEC sys.sp_executesql @SQL


SET @SQL = 'INSERT INTO ' + @newTableName + ' SELECT * FROM ' + @table_name
PRINT @SQL
SET @allSql += @SQL + CHAR(10)

IF @__isExecute = 1
    EXEC sys.sp_executesql @SQL 



GO 


DECLARE @sql nvarchar(max)
EXEC #createTableCopy 'Application.Cities', '_etl', @sql OUTPUT 
EXEC sp_executesql @sql 
GO
DECLARE @sql nvarchar(max)
EXEC #createTableCopy 'Application.Cities_Archive', '_etl', @sql OUTPUT 
EXEC sp_executesql @sql 
GO
DECLARE @sql nvarchar(max)
EXEC #createTableCopy 'Application.Countries', '_etl', @sql OUTPUT 
EXEC sp_executesql @sql 
GO
DECLARE @sql nvarchar(max)
EXEC #createTableCopy 'Application.Countries_Archive', '_etl', @sql OUTPUT 
EXEC sp_executesql @sql 
GO
DECLARE @sql nvarchar(max)
EXEC #createTableCopy 'Application.DeliveryMethods', '_etl', @sql OUTPUT 
EXEC sp_executesql @sql 
GO
DECLARE @sql nvarchar(max)
EXEC #createTableCopy 'Application.DeliveryMethods_Archive', '_etl', @sql OUTPUT 
EXEC sp_executesql @sql 
GO
DECLARE @sql nvarchar(max)
EXEC #createTableCopy 'Application.PaymentMethods', '_etl', @sql OUTPUT 
EXEC sp_executesql @sql 
GO
DECLARE @sql nvarchar(max)
EXEC #createTableCopy 'Application.PaymentMethods_Archive', '_etl', @sql OUTPUT 
EXEC sp_executesql @sql 
GO
DECLARE @sql nvarchar(max)
EXEC #createTableCopy 'Application.People', '_etl', @sql OUTPUT 
EXEC sp_executesql @sql 
GO
DECLARE @sql nvarchar(max)
EXEC #createTableCopy 'Application.People_Archive', '_etl', @sql OUTPUT 
EXEC sp_executesql @sql 
GO
DECLARE @sql nvarchar(max)
EXEC #createTableCopy 'Application.StateProvinces', '_etl', @sql OUTPUT 
EXEC sp_executesql @sql 
GO
DECLARE @sql nvarchar(max)
EXEC #createTableCopy 'Application.StateProvinces_Archive', '_etl', @sql OUTPUT 
EXEC sp_executesql @sql 
GO
DECLARE @sql nvarchar(max)
EXEC #createTableCopy 'Application.SystemParameters', '_etl', @sql OUTPUT 
EXEC sp_executesql @sql 
GO
DECLARE @sql nvarchar(max)
EXEC #createTableCopy 'Application.TransactionTypes', '_etl', @sql OUTPUT 
EXEC sp_executesql @sql 
GO
DECLARE @sql nvarchar(max)
EXEC #createTableCopy 'Application.TransactionTypes_Archive', '_etl', @sql OUTPUT 
EXEC sp_executesql @sql 
GO
DECLARE @sql nvarchar(max)
EXEC #createTableCopy 'Purchasing.PurchaseOrderLines', '_etl', @sql OUTPUT 
EXEC sp_executesql @sql 
GO
DECLARE @sql nvarchar(max)
EXEC #createTableCopy 'Purchasing.PurchaseOrders', '_etl', @sql OUTPUT 
EXEC sp_executesql @sql 
GO
DECLARE @sql nvarchar(max)
EXEC #createTableCopy 'Purchasing.SupplierCategories', '_etl', @sql OUTPUT 
EXEC sp_executesql @sql 
GO
DECLARE @sql nvarchar(max)
EXEC #createTableCopy 'Purchasing.SupplierCategories_Archive', '_etl', @sql OUTPUT 
EXEC sp_executesql @sql 
GO
DECLARE @sql nvarchar(max)
EXEC #createTableCopy 'Purchasing.Suppliers', '_etl', @sql OUTPUT 
EXEC sp_executesql @sql 
GO
DECLARE @sql nvarchar(max)
EXEC #createTableCopy 'Purchasing.Suppliers_Archive', '_etl', @sql OUTPUT 
EXEC sp_executesql @sql 
GO
DECLARE @sql nvarchar(max)
EXEC #createTableCopy 'Purchasing.SupplierTransactions', '_etl', @sql OUTPUT 
EXEC sp_executesql @sql 
GO
DECLARE @sql nvarchar(max)
EXEC #createTableCopy 'Sales.BuyingGroups', '_etl', @sql OUTPUT 
EXEC sp_executesql @sql 
GO
DECLARE @sql nvarchar(max)
EXEC #createTableCopy 'Sales.BuyingGroups_Archive', '_etl', @sql OUTPUT 
EXEC sp_executesql @sql 
GO
DECLARE @sql nvarchar(max)
EXEC #createTableCopy 'Sales.CustomerCategories', '_etl', @sql OUTPUT 
EXEC sp_executesql @sql 
GO
DECLARE @sql nvarchar(max)
EXEC #createTableCopy 'Sales.CustomerCategories_Archive', '_etl', @sql OUTPUT 
EXEC sp_executesql @sql 
GO
DECLARE @sql nvarchar(max)
EXEC #createTableCopy 'Sales.Customers', '_etl', @sql OUTPUT 
EXEC sp_executesql @sql 
GO
DECLARE @sql nvarchar(max)
EXEC #createTableCopy 'Sales.Customers_Archive', '_etl', @sql OUTPUT 
EXEC sp_executesql @sql 
GO
DECLARE @sql nvarchar(max)
EXEC #createTableCopy 'Sales.CustomerTransactions', '_etl', @sql OUTPUT 
EXEC sp_executesql @sql 
GO
DECLARE @sql nvarchar(max)
EXEC #createTableCopy 'Sales.InvoiceLines', '_etl', @sql OUTPUT 
EXEC sp_executesql @sql 
GO
DECLARE @sql nvarchar(max)
EXEC #createTableCopy 'Sales.Invoices', '_etl', @sql OUTPUT 
EXEC sp_executesql @sql 
GO
DECLARE @sql nvarchar(max)
EXEC #createTableCopy 'Sales.OrderLines', '_etl', @sql OUTPUT 
EXEC sp_executesql @sql 
GO
DECLARE @sql nvarchar(max)
EXEC #createTableCopy 'Sales.Orders', '_etl', @sql OUTPUT 
EXEC sp_executesql @sql 
GO
DECLARE @sql nvarchar(max)
EXEC #createTableCopy 'Sales.SpecialDeals', '_etl', @sql OUTPUT 
EXEC sp_executesql @sql 
GO
DECLARE @sql nvarchar(max)
EXEC #createTableCopy 'Warehouse.ColdRoomTemperatures', '_etl', @sql OUTPUT 
EXEC sp_executesql @sql 
GO
DECLARE @sql nvarchar(max)
EXEC #createTableCopy 'Warehouse.ColdRoomTemperatures_Archive', '_etl', @sql OUTPUT 
EXEC sp_executesql @sql 
GO
DECLARE @sql nvarchar(max)
EXEC #createTableCopy 'Warehouse.Colors', '_etl', @sql OUTPUT 
EXEC sp_executesql @sql 
GO
DECLARE @sql nvarchar(max)
EXEC #createTableCopy 'Warehouse.Colors_Archive', '_etl', @sql OUTPUT 
EXEC sp_executesql @sql 
GO
DECLARE @sql nvarchar(max)
EXEC #createTableCopy 'Warehouse.PackageTypes', '_etl', @sql OUTPUT 
EXEC sp_executesql @sql 
GO
DECLARE @sql nvarchar(max)
EXEC #createTableCopy 'Warehouse.PackageTypes_Archive', '_etl', @sql OUTPUT 
EXEC sp_executesql @sql 
GO
DECLARE @sql nvarchar(max)
EXEC #createTableCopy 'Warehouse.StockGroups', '_etl', @sql OUTPUT 
EXEC sp_executesql @sql 
GO
DECLARE @sql nvarchar(max)
EXEC #createTableCopy 'Warehouse.StockGroups_Archive', '_etl', @sql OUTPUT 
EXEC sp_executesql @sql 
GO
DECLARE @sql nvarchar(max)
EXEC #createTableCopy 'Warehouse.StockItemHoldings', '_etl', @sql OUTPUT 
EXEC sp_executesql @sql 
GO
DECLARE @sql nvarchar(max)
EXEC #createTableCopy 'Warehouse.StockItems', '_etl', @sql OUTPUT 
EXEC sp_executesql @sql 
GO
DECLARE @sql nvarchar(max)
EXEC #createTableCopy 'Warehouse.StockItems_Archive', '_etl', @sql OUTPUT 
EXEC sp_executesql @sql 
GO
DECLARE @sql nvarchar(max)
EXEC #createTableCopy 'Warehouse.StockItemStockGroups', '_etl', @sql OUTPUT 
EXEC sp_executesql @sql 
GO
DECLARE @sql nvarchar(max)
EXEC #createTableCopy 'Warehouse.StockItemTransactions', '_etl', @sql OUTPUT 
EXEC sp_executesql @sql 
GO
DECLARE @sql nvarchar(max)
EXEC #createTableCopy 'Warehouse.VehicleTemperatures', '_etl', @sql OUTPUT 
EXEC sp_executesql @sql 
GO