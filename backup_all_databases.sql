DECLARE	@backupPath nvarchar(4000) = 'C:\DATA\BACKUP'

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

--EXEC sys.sp_MSforeachdb
--						'IF DB_ID(''?'') > 4 ' +
--						'BACKUP DATABASE [?] TO DISK = ''' + @backupPath + @year + '-' + @month + '-' + @day + '-' + @ms + '_' + '[?].bak ' + 
--						'WITH COPY_ONLY, INIT, COMPRESSION'

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