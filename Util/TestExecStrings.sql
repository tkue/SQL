USE Util
GO

DECLARE 
	@ret int
	,@nsql nvarchar(max)
	,@sql varchar(max)
	,@loggingId int
	,@rowCount int

SET @sql = 'SELECT TOP 10 * FROM WideWorldImporters.Sales.OrderLines'

SET @nsql = 'SELECT TOP 10 * FROM WideWorldImporters.Sales.OrderLines'

EXEC sp_executesql @nsql

SELECT @rowCount = @@ROWCOUNT

--EXEC dbo.ExecuteSql @sql
--					,NULL
--					,0
--					,0
--					,@loggingId OUTPUT


--SELECT *
--FROM Logging.Logging
--WHERE
--	LoggingId = @loggingId


EXEC dbo.ExecuteSql NULL
					,@nsql
					,0
					,0
					,@loggingId OUTPUT



SELECT *
FROM Logging.Logging
WHERE
	LoggingId = @loggingId
