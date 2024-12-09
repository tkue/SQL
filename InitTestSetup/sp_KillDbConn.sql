USE master
GO

---------------------------------------------------------------------------------------------------
-- KILL DB CONNECTIONS
---------------------------------------------------------------------------------------------------
IF EXISTS (
	SELECT * FROM master.sys.objects WHERE name = 'sp_KillDbConn' AND type = 'P'
)
BEGIN
	DROP PROCEDURE sp_KillDbConn;
END
GO

CREATE PROCEDURE sp_KillDbConn (
	@dbName nvarchar(128)
)
AS
BEGIN

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
		PRINT CAST(@KillSpid AS varchar)

		SET @CMD = 'BEGIN TRY KILL ' + CAST(@KillSpid AS VARCHAR(3)) + ' END TRY BEGIN CATCH END CATCH'

		EXECUTE sp_executesql @CMD

		PRINT CAST ( @KillSpid  as Varchar(3)) +  ' SPID KILLED '
		FETCH NEXT
		FROM cur_kill
		INTO @KillSpid
	END
	CLOSE cur_kill
	DEALLOCATE cur_kill
END
GO