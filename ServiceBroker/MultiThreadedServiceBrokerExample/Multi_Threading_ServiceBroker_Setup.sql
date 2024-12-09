/*
===================================================
	Service Broker Sample 1: Parallel Querying
===================================================
Copyright:	Eitan Blumin (C) 2012
Email:		eitan@madeira.co.il
Source:		www.madeira.co.il
Disclaimer:
	The author is not responsible for any damage this
	script or any of its variations may cause.
	Do not execute it or any variations of it on production
	environments without first verifying its validity
	on controlled testing and/or QA environments.
	You may use this script at your own risk and may change it
	to your liking, as long as you leave this disclaimer header
	fully intact and unchanged.
*/

-- Creation of the test database
IF DB_ID('SB_PQ_Test') IS NULL
	CREATE DATABASE [SB_PQ_Test]
GO
USE
	[SB_PQ_Test]
GO
-- Creation of the table to hold SB logs
IF OBJECT_ID('SB_PQ_ServiceBrokerLogs') IS NULL
BEGIN
	CREATE TABLE SB_PQ_ServiceBrokerLogs
	(
		LogID			BIGINT		IDENTITY(1,1)	NOT NULL,
		LogDate			DATETIME					NOT NULL DEFAULT (GETDATE()),
		SPID			INT							NOT NULL DEFAULT (@@SPID),
		ProgramName		NVARCHAR(255)				NOT NULL DEFAULT (APP_NAME()),
		HostName		NVARCHAR(255)				NOT NULL DEFAULT (HOST_NAME()),
		ErrorSeverity	INT							NOT NULL DEFAULT (0),
		ErrorMessage	NVARCHAR(MAX)				NULL,
		ErrorLine		INT							NULL,
		ErrorProc		SYSNAME						NOT NULL DEFAULT (COALESCE(ERROR_PROCEDURE(),OBJECT_NAME(@@PROCID),'<unknown>')),
		QueueMessage	XML							NULL,
		PRIMARY KEY NONCLUSTERED (LogID)
	);
	CREATE CLUSTERED INDEX IX_SB_PQ_ServiceBrokerLogs ON SB_PQ_ServiceBrokerLogs (LogDate ASC) WITH FILLFACTOR=100;
	PRINT 'Table SB_PQ_ServiceBrokerLogs Created';
END
ELSE
	TRUNCATE TABLE SB_PQ_ServiceBrokerLogs
GO
IF OBJECT_ID('SB_PQ_ExecuteDynamicQuery') IS NOT NULL DROP PROCEDURE SB_PQ_ExecuteDynamicQuery;
RAISERROR(N'Creating SB_PQ_ExecuteDynamicQuery...',0,0) WITH NOWAIT;
GO
-- This procedure executes a single dynamic SQL command
CREATE PROCEDURE SB_PQ_ExecuteDynamicQuery
	@SQLCommand			NVARCHAR(MAX),
	@OutputXMLVarName	VARCHAR(128) = 'SB_PQ_Result',
	@Result				XML OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @SQLParams		NVARCHAR(MAX);
	SET @SQLParams = '@' + @OutputXMLVarName + ' XML OUTPUT';
	
	EXEC sp_executesql @SQLCommand, @SQLParams, @Result OUTPUT
	
	RETURN;
END
GO
IF OBJECT_ID('SB_PQ_HandleQueue') IS NOT NULL DROP PROCEDURE SB_PQ_HandleQueue
RAISERROR(N'Creating SB_PQ_HandleQueue...',0,0) WITH NOWAIT;
GO
-- This procedure is activated to handle each item in the Request queue
CREATE PROCEDURE SB_PQ_HandleQueue
AS
	SET NOCOUNT ON;
	SET ARITHABORT ON
	DECLARE @msg XML
	DECLARE @MsgType SYSNAME
	DECLARE @DlgId UNIQUEIDENTIFIER
	DECLARE @Info nvarchar(max)
	DECLARE @ErrorsCount int
	SET @ErrorsCount = 0

	-- Set whether to log verbose status messages before and after each operation
	DECLARE @Verbose BIT = 1

	-- Allow 10 retries in case of errors
	WHILE @ErrorsCount < 10
	BEGIN
		
		BEGIN TRANSACTION
		BEGIN TRY
			-- Make sure queue is active
			IF EXISTS (SELECT NULL FROM sys.service_queues 
					   WHERE NAME = 'SB_PQ_Request_Queue'
					   AND is_receive_enabled = 0)
				ALTER QUEUE SB_PQ_Request_Queue WITH STATUS = ON;

			-- handle one message at a time
			WAITFOR
			(
				RECEIVE TOP(1)
					@msg		= convert(xml,message_body),
					@MsgType	= message_type_name,
					@DlgId		= conversation_handle
				FROM dbo.SB_PQ_Request_Queue
			);
			
			-- exit when waiting has been timed out
			IF @@ROWCOUNT = 0
			BEGIN
				IF @@TRANCOUNT > 0
					ROLLBACK TRANSACTION;
				BREAK;
			END
			
			-- If message type is end dialog or error, end the conversation
			IF (@MsgType = N'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog' OR
				@MsgType = N'http://schemas.microsoft.com/SQL/ServiceBroker/Error')
			BEGIN
				END CONVERSATION @DlgId;

				IF @@TRANCOUNT > 0
					COMMIT TRANSACTION;

				IF @Verbose = 1
					INSERT INTO SB_PQ_ServiceBrokerLogs(ErrorSeverity,ErrorMessage,ErrorProc,QueueMessage)
					VALUES(0,'Ended Conversation ' + CONVERT(nvarchar(max),@DlgId),OBJECT_NAME(@@PROCID),@msg);
			END
			ELSE
			BEGIN

			-- Retreive data from xml message
			DECLARE @SQL NVARCHAR(MAX), @OutputVar VARCHAR(128)
			DECLARE @Result XML;
			
			SELECT
				@SQL			= x.value('(/Request/SQL)[1]','VARCHAR(MAX)'),
				@OutputVar		= x.value('(/Request/OutputVar)[1]','VARCHAR(128)')
			FROM @msg.nodes('/Request') AS T(x);
			
			-- Log operation start
			IF @Verbose = 1
				INSERT INTO SB_PQ_ServiceBrokerLogs(ErrorSeverity,ErrorMessage,ErrorProc,QueueMessage)
				VALUES(0,'Starting Process',OBJECT_NAME(@@PROCID),@msg);
			
			-- Encapsulate execution in TRY..CATCH
			-- to handle problems in the specific request
			BEGIN TRY
			
				-- Execute Request
				EXEC SB_PQ_ExecuteDynamicQuery @SQL, @OutputVar, @Result OUTPUT;
			
			END TRY
			BEGIN CATCH
			
				-- log operation fail
				INSERT INTO SB_PQ_ServiceBrokerLogs(ErrorSeverity,ErrorMessage,ErrorLine,ErrorProc,QueueMessage)
				VALUES(ERROR_SEVERITY(),ERROR_MESSAGE(),ERROR_LINE(),ERROR_PROCEDURE(),@msg);
				
				-- return empty response
				SET @Result = NULL;
			
			END CATCH
			;
			
			-- Send response to initiator
			SEND ON CONVERSATION @DlgId
				MESSAGE TYPE [//SB_PQ/Message]
				( @Result );
			
			-- commit
			IF @@TRANCOUNT > 0
				COMMIT TRANSACTION;
			
			-- Log operation end
			IF @Verbose = 1
			INSERT INTO SB_PQ_ServiceBrokerLogs(ErrorSeverity,ErrorMessage,ErrorProc,QueueMessage)
			VALUES(0,'Finished Process',OBJECT_NAME(@@PROCID),@msg);
			
			END

			-- reset xml message
			SET @msg = NULL;
		END TRY
		BEGIN CATCH
		
			-- rollback transaction
			-- this will also rollback the extraction of the message from the queue
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION;
			
			-- log operation fail
			INSERT INTO SB_PQ_ServiceBrokerLogs(ErrorSeverity,ErrorMessage,ErrorLine,ErrorProc,QueueMessage)
			VALUES(ERROR_SEVERITY(),ERROR_MESSAGE(),ERROR_LINE(),ERROR_PROCEDURE(),@msg);
			
			-- increase error counter
			SET @ErrorsCount = @ErrorsCount + 1;
			
			-- wait 5 seconds before retrying
			WAITFOR DELAY '00:00:05'
		END CATCH
	
	END
GO

DECLARE @SQL nvarchar(max)

-- Enable service broker
IF EXISTS (SELECT * FROM sys.databases WHERE database_id = DB_ID() AND is_broker_enabled = 0)
BEGIN
	SET @SQL = 'ALTER DATABASE [' + DB_NAME() + '] SET NEW_BROKER WITH ROLLBACK IMMEDIATE';
	EXEC(@SQL);
	PRINT 'Enabled Service Broker for DB ' + DB_NAME();
END

GO
-- Drop existing objects

IF EXISTS (SELECT NULL FROM sys.services WHERE NAME = '//SB_PQ/ProcessReceivingService')
	DROP SERVICE [//SB_PQ/ProcessReceivingService];

IF EXISTS (SELECT NULL FROM sys.services WHERE NAME = '//SB_PQ/ProcessStartingService')
	DROP SERVICE [//SB_PQ/ProcessStartingService];
	
IF EXISTS (SELECT NULL FROM sys.service_queues WHERE NAME = 'SB_PQ_Request_Queue')
	DROP QUEUE dbo.SB_PQ_Request_Queue;

IF EXISTS (SELECT NULL FROM sys.service_queues WHERE NAME = 'SB_PQ_Response_Queue')
	DROP QUEUE dbo.SB_PQ_Response_Queue;
	
IF EXISTS (SELECT NULL FROM sys.service_contracts WHERE NAME = '//SB_PQ/Contract')
	DROP CONTRACT [//SB_PQ/Contract];

IF EXISTS (SELECT NULL FROM sys.service_message_types WHERE name='//SB_PQ/Message')
	DROP MESSAGE TYPE [//SB_PQ/Message];
GO
-- Create service broker objects

RAISERROR(N'Creating Message Type...',0,0) WITH NOWAIT;
CREATE MESSAGE TYPE [//SB_PQ/Message]
	VALIDATION = WELL_FORMED_XML;

RAISERROR(N'Creating Contract...',0,0) WITH NOWAIT;
CREATE CONTRACT [//SB_PQ/Contract] 
	([//SB_PQ/Message] SENT BY ANY);

RAISERROR(N'Creating Request Queue...',0,0) WITH NOWAIT;
CREATE QUEUE dbo.SB_PQ_Request_Queue
	WITH STATUS=ON,
	ACTIVATION (
		PROCEDURE_NAME = SB_PQ_HandleQueue,		-- sproc to run when queue receives message
		MAX_QUEUE_READERS = 10,					-- max concurrent instances
		EXECUTE AS SELF
		);
		
RAISERROR(N'Creating Response Queue...',0,0) WITH NOWAIT;
CREATE QUEUE dbo.SB_PQ_Response_Queue
	WITH STATUS=ON;					-- This queue is without activation because we need to handle it manually

RAISERROR(N'Creating Recieving Service...',0,0) WITH NOWAIT;
CREATE SERVICE [//SB_PQ/ProcessReceivingService]
	AUTHORIZATION dbo
ON QUEUE dbo.SB_PQ_Request_Queue ([//SB_PQ/Contract]);

RAISERROR(N'Creating Sending Service...',0,0) WITH NOWAIT;
CREATE SERVICE [//SB_PQ/ProcessStartingService]
	AUTHORIZATION dbo
ON QUEUE dbo.SB_PQ_Response_Queue ([//SB_PQ/Contract]);
GO
IF OBJECT_ID('SB_PQ_Start_Query') IS NOT NULL DROP PROCEDURE SB_PQ_Start_Query;
RAISERROR(N'Creating SB_PQ_Start_Query...',0,0) WITH NOWAIT;
GO
-- This procedure sends items to the queue
CREATE PROCEDURE SB_PQ_Start_Query
	@SQLCommand				NVARCHAR(MAX),
	@OutputXMLVarName		VARCHAR(128)		= 'SB_PQ_Result',
	@Conversation_Group_ID	UNIQUEIDENTIFIER	= NULL
AS
	SET NOCOUNT ON;

	DECLARE @msg XML
	
	-- build the XML message
	SET @msg = N'
	<Request>
		  <SQL>' + @SQLCommand + N'</SQL>
		  <OutputVar>' + @OutputXMLVarName + N'</OutputVar>
	</Request>'
	
	DECLARE @DlgId UNIQUEIDENTIFIER
	
	BEGIN TRY
	
	-- if conversation group was not specified
	IF @Conversation_Group_ID IS NULL
	BEGIN
		BEGIN DIALOG @DlgId
			FROM SERVICE [//SB_PQ/ProcessStartingService]
			TO SERVICE '//SB_PQ/ProcessReceivingService',
			'CURRENT DATABASE'
			ON CONTRACT [//SB_PQ/Contract]
		WITH ENCRYPTION = OFF;
	END
	-- else, send on specified conversation group
	ELSE
	BEGIN
		BEGIN DIALOG @DlgId
			FROM SERVICE [//SB_PQ/ProcessStartingService]
			TO SERVICE '//SB_PQ/ProcessReceivingService',
			'CURRENT DATABASE'
			ON CONTRACT [//SB_PQ/Contract]
		WITH
			RELATED_CONVERSATION_GROUP = @Conversation_Group_ID,
			ENCRYPTION = OFF;
	END
	;
	
	-- send the message
	SEND ON CONVERSATION @DlgId
	MESSAGE TYPE [//SB_PQ/Message] (@msg);
	
	PRINT N'Started SB_PQ process on dialogId ' + ISNULL(convert(varchar(100),@DlgId),'(null)');
	
	END TRY
	BEGIN CATCH
		DECLARE @Err nvarchar(max)
		SET @Err = ERROR_MESSAGE()
		RAISERROR('Error starting SB_PQ process: %s', 16, 1, @Err);
	END CATCH
GO
IF OBJECT_ID('SB_PQ_Get_Response_One') IS NOT NULL DROP PROCEDURE SB_PQ_Get_Response_One;
RAISERROR(N'Creating SB_PQ_Get_Response_One...',0,0) WITH NOWAIT;
GO
-- This procedure receives one result item from the queue
CREATE PROCEDURE SB_PQ_Get_Response_One
	@Conversation_Group_ID	UNIQUEIDENTIFIER = NULL,
	@Result					XML OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @DlgId UNIQUEIDENTIFIER;
	DECLARE @MsgType SYSNAME;
	DECLARE @Verbose BIT = 1;

	-- if conversation group was specified
	IF @Conversation_Group_ID IS NOT NULL
	BEGIN
		WAITFOR
		(
			RECEIVE TOP (1)
				@Result = convert(xml,message_body),
				@MsgType = message_type_name,
				@DlgId = conversation_handle
			FROM SB_PQ_Response_Queue
			WHERE
				conversation_group_id = @Conversation_Group_ID
		)
	END
	-- else, retrieve from any converation group
	ELSE
	BEGIN
		WAITFOR
		(
			RECEIVE TOP (1)
				@Result = convert(xml,message_body),
				@MsgType = message_type_name,
				@DlgId = conversation_handle
			FROM SB_PQ_Response_Queue
		)
	END
	
	-- If message type is end dialog or error, end the conversation
	IF (@MsgType = N'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog' OR
		@MsgType = N'http://schemas.microsoft.com/SQL/ServiceBroker/Error')
	BEGIN
		END CONVERSATION @DlgId;

		IF @Verbose = 1
			INSERT INTO SB_PQ_ServiceBrokerLogs(ErrorSeverity,ErrorMessage,ErrorProc,QueueMessage)
			VALUES(0,'Ended Conversation ' + CONVERT(nvarchar(max),@DlgId),OBJECT_NAME(@@PROCID),@Result);
	END
	-- Close the dialog if it's unused
	ELSE IF NOT EXISTS (SELECT * FROM SB_PQ_Response_Queue WHERE conversation_handle = @DlgId)
	BEGIN
		END CONVERSATION @DlgId;
		
		IF @Verbose = 1
			INSERT INTO SB_PQ_ServiceBrokerLogs(ErrorSeverity,ErrorMessage,ErrorProc,QueueMessage)
			VALUES(0,'Ending Conversation ' + CONVERT(nvarchar(max),@DlgId),OBJECT_NAME(@@PROCID),@Result);
	END

	RETURN;
END
GO

PRINT 'Done';
GO
