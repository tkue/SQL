USE master
GO


DECLARE 
	@path nvarchar(4000) = 'C:\Users\tomku\bin\sql\sample_db\'
	,@dbpath nvarchar(4000) = 'C:\DATA\'

EXEC (
	'RESTORE FILELISTONLY FROM DISK = ''' + @path + 'AdventureWorksDW2016CTP3.bak'''
)


-- C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\
--SELECT * FROM master.sys.sysfiles

EXEC (
	'RESTORE DATABASE AdventureWorksDW2014
	FROM DISK = ''' + @path + 'AdventureWorksDW2016CTP3.bak''
	WITH STATS = 10,
		 MOVE ''AdventureWorksDW2014_Data'' TO ''' + @dbpath + 'AdventureWorksDW2016CTP3_Data.mdf''
		,MOVE ''AdventureWorksDW2014_Log'' TO ''' + @dbpath + 'AdventureWorksDW2016CTP3_Log.ldf'''
)


EXEC (
	'RESTORE FILELISTONLY FROM DISK = ''' + @path + 'AdventureWorks2016CTP3.bak'''
)

EXEC (
	'RESTORE DATABASE AdventureWorks2016CTP3
	FROM DISK = ''' + @path + 'AdventureWorks2016CTP3.bak''
	WITH STATS = 10
		,MOVE ''AdventureWorks2016CTP3_Data'' TO ''' + @dbpath + 'AdventureWorks2016CTP3_Data.mdf''
		,MOVE ''AdventureWorks2016CTP3_Log'' TO ''' + @dbpath + 'AdventureWorks2016CTP3_Log.ldf''
		,MOVE ''AdventureWorks2016CTP3_mod'' TO ''' + @dbpath + 'AdventureWorks2016CTP3_mod'''
)

GO
