-- =============================================
-- Create database
-- =============================================
USE master
GO

IF NOT EXISTS (
	SELECT * FROM sys.databases WHERE name = 'Util'
)
BEGIN
	DECLARE 
		 @dbName nvarchar(128)
		,@deviceDirectory nvarchar(max)
		,@recovery varchar(50)
	SELECT 
		 @dbName = 'Util'
		,@recovery = 'SIMPLE'
		,@deviceDirectory = NULL

	-- DEFAULT: Use directory of master database
	IF ( RTRIM(LTRIM(ISNULL(@deviceDirectory, ''))) = '' )
	BEGIN
		SELECT @deviceDirectory = SUBSTRING(filename, 1, CHARINDEX(N'master.mdf', LOWER(filename)) - 1)
		FROM master.dbo.sysaltfiles WHERE dbid = 1 AND fileid = 1
	END

	IF EXISTS ( SELECT * FROM sysdatabases WHERE name = @dbName)
	BEGIN
		EXEC('DROP DATABASE ' + @dbName)
	END

	EXECUTE (N'CREATE DATABASE ' + @dbName + ' 
	  ON PRIMARY (NAME = N''' + @dbName + ''', FILENAME = N''' + @deviceDirectory + N'' + @dbName + '.mdf'')
	  LOG ON (NAME = N''' + @dbName + '_log'',  FILENAME = N''' + @deviceDirectory + N'' + @dbName + '.ldf'')')


	EXEC (
		'ALTER DATABASE ' + @dbName + '
		 SET RECOVERY ' + @recovery
	)
END
GO

USE Util
GO

-- =============================================
-- Kill DB Connections
-- =============================================
IF NOT EXISTS (
	SELECT * FROM sys.procedures WHERE type = 'P' AND name = 'usp_KillDbConn'
)
BEGIN
	EXEC ('CREATE PROCEDURE usp_KillDbConn AS SELECT 1')
END
GO

ALTER PROCEDURE usp_KillDbConn (
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

-- =============================================
-- Backup All Databases
-- =============================================
IF NOT EXISTS (
	SELECT * FROM sys.procedures WHERE type = 'P' AND name = 'usp_BackupAllDatabases'
)
BEGIN
	EXEC ('CREATE PROCEDURE usp_BackupAllDatabases AS SELECT 1')
END
GO

ALTER PROCEDURE usp_BackupAllDatabases (
	@backupPath nvarchar(4000)
)
AS
BEGIN
	DECLARE	
		 @Year varchar(20) = CAST(DATEPART(Year, GETDATE()) AS VARCHAR(4))
		,@Month varchar(20) = RIGHT('0' + CAST(DATEPART(Month, GETDATE()) AS VARCHAR(2)), 2)
		,@Day varchar(20) = CAST(DATEPART(Day, GETDATE()) AS VARCHAR(4))
		,@MS varchar(20) = CAST(DATEPART(MS, GETDATE()) AS VARCHAR(4))
	
		,@dbName nvarchar(128)
		,@sql nvarchar(4000)
		,@fileName nvarchar(max)

	IF RIGHT(@backupPath, 1) <> '\'
		SET @backupPath	+= '\'

	DECLARE cur CURSOR LOCAL STATIC FORWARD_ONLY
	FOR
	SELECT name
	FROM master.sys.databases
	WHERE name NOT IN (
		'master',
		'tempdb',
		'model',
		'msdb'
	)

	OPEN cur

	FETCH NEXT
	FROM cur
	INTO @dbName

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @fileName = @backupPath + @year + '-' + @month + '-' + @day + '-' + @ms + '_' + @dbName + '.bak'

		SET @sql = 
			'BACKUP DATABASE ' + @dbName + ' ' +
			'TO DISK = ''' + @fileName + ''' ' +
			'WITH COPY_ONLY, INIT, COMPRESSION, STATS = 10'
	
		PRINT ''
		PRINT 'Database: ' + @dbName
		PRINT 'Path: ' + @fileName
		PRINT 'SQL: ' + @sql
		PRINT ''

		EXEC sp_executesql @sql

		FETCH NEXT
		FROM cur
		INTO @dbName
	END
END
GO

-- =============================================
-- Backup Database
-- =============================================
IF NOT EXISTS (
	SELECT * FROM sys.procedures WHERE type = 'P' AND name = 'usp_BackupDatabase'
)
BEGIN
	EXEC ('CREATE PROCEDURE usp_BackupDatabase AS SELECT 1')
END
GO

ALTER PROCEDURE usp_BackupDatabase (
	 @dbName nvarchar(128)
	,@backupPath nvarchar(max)
)
AS
BEGIN
	DECLARE
		 @Year varchar(20) = CAST(DATEPART(Year, GETDATE()) AS VARCHAR(4))
		,@Month varchar(20) = RIGHT('0' + CAST(DATEPART(Month, GETDATE()) AS VARCHAR(2)), 2)
		,@Day varchar(20) = CAST(DATEPART(Day, GETDATE()) AS VARCHAR(4))
		,@MS varchar(20) = CAST(DATEPART(MS, GETDATE()) AS VARCHAR(4))

		,@sql nvarchar(4000)
		,@fileName nvarchar(max)


		IF RIGHT(RTRIM(LTRIM(@backupPath)), 1) <> '\'
			SET @backupPath	+= '\'

		SET @fileName = @backupPath + @year + '-' + @month + '-' + @day + '-' + @ms + '_' + @dbName + '.bak'

		SET @sql = 
			'BACKUP DATABASE ' + @dbName + ' ' +
			'TO DISK = ''' + @fileName + ''' ' +
			'WITH COPY_ONLY, INIT, COMPRESSION, STATS = 10'
	
		PRINT ''
		PRINT 'Database: ' + @dbName
		PRINT 'Path: ' + @fileName
		PRINT 'SQL: ' + @sql
		PRINT ''

		EXEC sp_executesql @sql
END

-- =============================================
-- 
-- =============================================
