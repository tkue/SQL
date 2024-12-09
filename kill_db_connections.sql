/*** KILL ALL CONNECTIONS TO  DATABASE ***/

USE master
GO

DECLARE @dbName nvarchar(50) = 'DATABASE_NAME'

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