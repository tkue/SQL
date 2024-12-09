USE master
GO


CREATE OR ALTER PROCEDURE dbo.uspKillDatabaseConnections(
	@dbName nvarchar(50) 
)
AS
SET NOCOUNT ON;

DECLARE 
	@msg nvarchar(max)

IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE Name = @dbName)
BEGIN
	SET @msg = CONCAT(N'No database exists for database: ', @dbName)
	RAISERROR(@msg, 16, 1)
END

DECLARE @KillSpid INT
	,@CMD NVARCHAR(50);

SET @CMD = '';

DECLARE cur_kill CURSOR
FOR
SELECT s.session_id
FROM sys.dm_exec_sessions s
JOIN sys.databases d ON d.database_id = s.database_id
WHERE d.name = @dbName

OPEN cur_kill

FETCH NEXT
FROM cur_kill
INTO @KillSpid;

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @CMD = 'BEGIN TRY KILL ' + CAST(@KillSpid AS VARCHAR(3)) + ' END TRY BEGIN CATCH END CATCH'

	EXECUTE sp_executesql @CMD

	PRINT CAST ( @KillSpid  as Varchar(3)) +  ' SPID KILLED '
	FETCH NEXT
	FROM cur_kill
	INTO @KillSpid
END
CLOSE cur_kill
DEALLOCATE cur_kill

SET @CMD = N'DROP DATABASE ' + QUOTENAME(@dbName)
EXEC sp_executesql @CMD
GO