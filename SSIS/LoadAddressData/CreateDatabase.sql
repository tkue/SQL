USE master
GO

DECLARE 
    @dbName nvarchar(128)
    ,@deviceDirectory nvarchar(max)
    ,@recovery varchar(50)
	,@isExec bit = 0
	,@sql nvarchar(max)

SELECT 
    @dbName = 'AddressEtl'
    ,@recovery = 'SIMPLE'
    ,@deviceDirectory = 'C:\DATA\'
	,@isExec = 1

    
IF NOT EXISTS (
	SELECT * FROM sys.databases WHERE name = @dbName
)
BEGIN
	-- DEFAULT: Use directory of master database
	IF ( RTRIM(LTRIM(ISNULL(@deviceDirectory, ''))) = '' )
	BEGIN
		SELECT @deviceDirectory = SUBSTRING(filename, 1, CHARINDEX(N'master.mdf', LOWER(filename)) - 1)
		FROM master.dbo.sysaltfiles WHERE dbid = 1 AND fileid = 1
	END

	IF EXISTS ( SELECT * FROM sysdatabases WHERE name = @dbName)
	BEGIN
		SET @sql = 'DROP DATABASE ' + @dbName

		IF @isExec = 1
			EXEC(@sql)
		ELSE
			PRINT @sql
	END

	SET @sql = 
		N'CREATE DATABASE ' + @dbName + ' 
		ON PRIMARY (NAME = N''' + @dbName + ''', FILENAME = N''' + @deviceDirectory + N'' + @dbName + '.mdf'')
		LOG ON (NAME = N''' + @dbName + '_log'',  FILENAME = N''' + @deviceDirectory + N'' + @dbName + '.ldf'')'

	IF @isExec = 1
		EXEC(@sql)
	ELSE
		PRINT @sql


	SET @sql =  (
					'ALTER DATABASE ' + @dbName
					 + ' SET RECOVERY ' + @recovery
				)

	IF @isExec = 1
		EXEC(@sql)
	ELSE
		PRINT @sql
END
GO