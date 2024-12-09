USE master
GO

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'WideWorldImporters_ETL')
BEGIN
    EXEC master..uspKillDatabaseConnections 'WideWorldImporters_ETL'
    DROP DATABASE WideWorldImporters_ETL
END
GO

CREATE DATABASE WideWorldImporters_ETL
GO


USE WideWorldImporters_ETL
GO

IF SCHEMA_ID('Sales') IS NULL
    EXEC('CREATE SCHEMA Sales AUTHORIZATION dbo')
GO


SELECT TOP 1 *
INTO Sales.InvoiceLines
FROM WideWorldImporters.Sales.InvoiceLines

SELECT TOP 1 *
INTO Sales.Invoices
FROM WideWorldImporters.Sales.Invoices

SELECT TOP 1 *
INTO Sales.Orders
FROM WideWorldImporters.Sales.Orders

SELECT TOP 1 *
INTO Sales.OrderLines
FROM WideWorldImporters.Sales.OrderLines


TRUNCATE TABLE Sales.InvoiceLines
TRUNCATE TABLE Sales.Invoices
TRUNCATE TABLE Sales.Orders
TRUNCATE TABLE Sales.OrderLines
