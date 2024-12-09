USE master
GO

DROP TABLE IF EXISTS #FileListOnlyResults
CREATE TABLE #FileListOnlyResults (
    LogicalName	nvarchar(128)
    ,PhysicalName	nvarchar(260)
    ,[Type]	char(1)
    ,FileGroupName	nvarchar(128) NULL
    ,Size	numeric(20,0)
    ,MaxSize	numeric(20,0)
    ,FileID	bigint
    ,CreateLSN	numeric(25,0)
    ,DropLSN	numeric(25,0) NULL
    ,UniqueID	uniqueidentifier
    ,ReadOnlyLSN	numeric(25,0) NULL
    ,ReadWriteLSN	numeric(25,0) NULL
    ,BackupSizeInBytes	bigint
    ,SourceBlockSize	int
    ,FileGroupID	int
    ,LogGroupGUID	uniqueidentifier NULL
    ,DifferentialBaseLSN	numeric(25,0) NULL
    ,DifferentialBaseGUID	uniqueidentifier NULL
    ,IsReadOnly	bit
    ,IsPresent	bit
    ,TDEThumbprint	varbinary(32) NULL
    ,SnapshotURL	nvarchar(360) NULL
)



DECLARE 
    @basePath nvarchar(1000)
    ,@restoreBasePath nvarchar(2000)
    ,@path nvarchar(max)
    ,@sql nvarchar(max)

SELECT 
    @basePath = '/var/opt/mssql2019/'
    ,@restoreBasePath = @basePath

SET @path = @basePath + '/Address.bak'

SET @sql = N'RESTORE FILELISTONLY FROM DISK = ''' +  @path + ''''

INSERT #FileListOnlyResults
EXEC sp_executesql @sql


SELECT 
    PhysicalNameBaseName = CASE WHEN CHARINDEX('\', LTRIM(RTRIM(r.PhysicalName))) <> 0 THEN RIGHT(r.PhysicalName, CHARINDEX('\', REVERSE(r.PhysicalName)) - 1) END
    ,
FROM #FileListOnlyResults r

-- SET @path = @basePath + '/AddressEtl.bak'
-- RESTORE FILELISTONLY FROM DISK = @path 

-- SET @path = @basePath + '/AdventureWorks.bak'
-- RESTORE FILELISTONLY FROM DISK = @path 

-- SET @path = @basePath + '/AdventureWorksDW.bak'
-- RESTORE FILELISTONLY FROM DISK = @path 

-- SET @path = @basePath + '/Clr.bak'
-- RESTORE FILELISTONLY FROM DISK = @path 

-- SET @path = @basePath + '/NorthwindAlpha.bak'
-- RESTORE FILELISTONLY FROM DISK = @path 

-- SET @path = @basePath + '/Northwind.bak'
-- RESTORE FILELISTONLY FROM DISK = @path 

-- SET @path = @basePath + '/NorthwindBeta.bak'
-- RESTORE FILELISTONLY FROM DISK = @path 

-- SET @path = @basePath + '/NYCTaxiSample.bak'
-- RESTORE FILELISTONLY FROM DISK = @path 

-- SET @path = @basePath + '/pubs.bak'
-- RESTORE FILELISTONLY FROM DISK = @path 

-- SET @path = @basePath + '/SampleData.bak'
-- RESTORE FILELISTONLY FROM DISK = @path 

-- SET @path = @basePath + '/Testing.bak'
-- RESTORE FILELISTONLY FROM DISK = @path 

-- SET @path = @basePath + '/Util.bak'
-- RESTORE FILELISTONLY FROM DISK = @path 

-- SET @path = @basePath + '/WideWorldImporters.bak'
-- RESTORE FILELISTONLY FROM DISK = @path 

-- SET @path = @basePath + '/WideWorldImportersDW.bak'
-- RESTORE FILELISTONLY FROM DISK = @path 
