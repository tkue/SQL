USE Util
GO

IF NOT EXISTS ( SELECT 1 FROM sys.schemas WHERE name = 'Logging' )
BEGIN
	EXEC ('CREATE SCHEMA Logging AUTHORIZATION dbo')
END
GO


DROP TABLE IF EXISTS Logging.Logging 
GO

DROP TABLE IF EXISTS Logging.Batch
GO

CREATE TABLE Logging.Batch (
	BatchId int PRIMARY KEY IDENTITY(1, 1)
	,RowLastUpdatedUTC datetime DEFAULT(GETUTCDATE()) NOT NULL 
	,RowGuid uniqueidentifier ROWGUIDCOL DEFAULT(NEWSEQUENTIALID()) NOT NULL
	,BatchName varchar(250)
	,BatchDescription varchar(max)
	,BatchStatus varchar(50)
	,BatchStartUTC datetime
	,BatchEndUTC datetime
)
GO



CREATE TABLE Logging.Logging (
	LoggingId bigint PRIMARY KEY IDENTITY(1, 1)
	,RowLastUpdatedUTC datetime DEFAULT(GETUTCDATE()) NOT NULL
	,RowGuid uniqueidentifier ROWGUIDCOL DEFAULT(NEWSEQUENTIALID()) NOT NULL
	,BatchId int NULL
	,LocationSource nvarchar(500)
	,LocationDestination nvarchar(500)
	,SqlStatement xml
	,Comment varchar(max)
	,EventType varchar(128)
	,ExecutionStatus varchar(128)
	,ExecutionStartUTC datetime
	,ExecutionEndUTC datetime
	,ErrorNumber int
	,ErrorSeverity int
	,ErrorState int
	,ErrorProcedure nvarchar(256)
	,ErrorLine int
	,ErrorMessage nvarchar(max)
	,IsError bit NOT NULL DEFAULT(0)
	,SqlRowCount int
	,CallingObjectId int
	,CallingObjectName nvarchar(500)
	,UserName sysname DEFAULT(CURRENT_USER) NOT NULL
	,DatabaseName nvarchar(256) DEFAULT(DB_NAME())
	,ServerName nvarchar(500) DEFAULT(@@SERVERNAME)
	,AdditionalLoggingInformation xml 
	,CONSTRAINT FK_Logging_Batch FOREIGN KEY (BatchId) REFERENCES Logging.Batch (BatchId)
)
GO

DROP PROCEDURE IF EXISTS Logging.uspLogErrorOrComment
GO

CREATE PROCEDURE Logging.uspLogErrorOrComment (
	@loggingId int = 0 OUTPUT
	,@locationSource nvarchar(500)
	,@locationDestination nvarchar(500)
	,@sqlStatement nvarchar(max)
	,@comment varchar(max)
	,@eventType varchar(128)
	,@executionStatus varchar(128)
	,@executionStart datetime
	,@executionEnd datetime
	,@isError bit
	,@rowCount int
	,@callingObjectId int
	,@callingObjectName nvarchar(500)
	,@additionalLoggingInformation xml
)
AS
SET NOCOUNT ON
	SELECT 
		@locationSource = NULLIF(TRIM(@locationSource), '')
		,@locationDestination = NULLIF(TRIM(@locationDestination), '')
		,@sqlStatement = NULLIF(TRIM(@sqlStatement), '')
		,@comment = NULLIF(TRIM(@comment), '')
		,@eventType = NULLIF(TRIM(@eventType), '')
		,@executionStatus = NULLIF(TRIM(@executionStatus), '')
		,@executionEnd = ISNULL(@executionEnd, GETUTCDATE())
	
	IF @isError IS NULL
	BEGIN
		SET @isError = CASE 
							WHEN ERROR_NUMBER() IS NOT NULL THEN 1
							ELSE 0
						END
	END

	SELECT 
		@locationSource
		,@locationDestination
		,@sqlStatement
		,@comment
		,@eventType
		,@executionStatus
		,@executionStart
		,@executionEnd
		,@isError
		,@rowCount
		,@callingObjectId
		,@callingObjectName
		,@additionalLoggingInformation
GO

CREATE OR ALTER PROCEDURE Logging.uspLogError (
	@loggingId int = 0 OUTPUT
)
AS
SET NOCOUNT ON

IF @@ERROR IS NULL
	RETURN

IF XACT_STATE() = -1
BEGIN
	PRINT 'Unable to log error. XACT_STATE() is -1'
END

IF NOT EXISTS ( SELECT 1 FROM Logging.Logging WHERE LoggingId = @loggingId )
BEGIN
	INSERT INTO Logging.Logging (
		ErrorNumber
		,ErrorSeverity
		,ErrorState
		,ErrorProcedure
		,ErrorLine
		,ErrorMessage
		,IsError
	)
	SELECT 
		ERROR_NUMBER()
		,ERROR_SEVERITY()
		,ERROR_STATE()
		,ERROR_PROCEDURE()
		,ERROR_LINE()
		,ERROR_MESSAGE()
		,1

	SET @loggingId = @@IDENTITY
END

IF EXISTS ( SELECT 1 FROM Logging.Logging WHERE LoggingId = @loggingId )
BEGIN
	UPDATE Logging.Logging
	SET 
		ErrorNumber = ERROR_NUMBER()
		,ErrorSeverity = ERROR_SEVERITY()
		,ErrorState = ERROR_STATE()
		,ErrorProcedure = ERROR_PROCEDURE()
		,ErrorLine = ERROR_LINE()
		,ErrorMessage = ERROR_MESSAGE()
		,IsError = 1
	WHERE
		LoggingId = @loggingId
END 
GO









--DROP TABLE IF EXISTS Logging.LoggingLocation
--GO

--CREATE TABLE Logging.LoggingLocation (
--	LoggingLocationId int PRIMARY KEY IDENTITY 
--	,RowLastUpdatedUTC datetime DEFAULT(GETUTCDATE()) NOT NULL 
--	,RowGuid uniqueidentifier ROWGUIDCOL DEFAULT(NEWSEQUENTIALID()) NOT NULL
--	,Alias varchar(128) UNIQUE
--	,ServerName nvarchar(256)
--	,DatabaseName nvarchar(256)
--	,SchemaName nvarchar(256)
--	,TableName nvarchar(256)
--	,net_transport sql_variant
--	,protocol_type sql_variant
--	,auth_scheme sql_variant
--	,local_net_address sql_variant
--	,local_tcp_port sql_variant
--	,client_net_address sql_variant
--)

--DROP TABLE IF EXISTS Logging.Logging 
--GO

--CREATE TABLE Logging.Logging (
--	LoggingId bigint PRIMARY KEY IDENTITY(1, 1)
--	,RowLastUpdatedUTC datetime DEFAULT(GETUTCDATE()) NOT NULL
--	,BatchId int NULL
--	,SourceLoggingLocationId int
--	,DestinationLoggingLocationId int
--	,SqlStatement nvarchar(max)
--	,SqlStatementAsVarchar varchar(max)
--	,Comment varchar(max)
--	,EventType varchar(256)
--	,ExecutionStartUTC datetime
--	,ExecutionEndUTC datetime
--	,ErrorNumber int
--	,ErrorSeverity int
--	,ErrorState int
--	,ErrorProcedure nvarchar(256)
--	,ErrorLine int
--	,ErrorMessage nvarchar(max)
--	,IsError bit NOT NULL DEFAULT(0)
--	,SqlRowCount int
--	,UserName sysname DEFAULT(CURRENT_USER) NOT NULL
--	,DatabaseName nvarchar(256) DEFAULT(DB_NAME())
--	,ServerName nvarchar(500) DEFAULT(@@SERVERNAME)
--	,AdditionalLoggingInformation xml 
--	,CONSTRAINT FK_Logging_Batch FOREIGN KEY (BatchId) REFERENCES Logging.Batch (BatchId)
--	,CONSTRAINT FK_Logging_Source_LoggingLocation FOREIGN KEY (SourceLoggingLocationId) REFERENCES Logging.LoggingLocation (LoggingLocationId)
--	,CONSTRAINT FK_Logging_Destination_LoggingLocation FOREIGN KEY (DestinationLoggingLocationId) REFERENCES Logging.LoggingLocation (LoggingLocationId)
--)
--GO

