

USE master 
GO

EXEC master.dbo.uspKillDatabaseConnections 'AsyncTest'; 
GO 

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'AsyncTest')
    -- EXEC master.dbo.uspKillDatabaseConnections 'AsyncTest'; 
    DROP DATABASE AsyncTest;
GO 

CREATE DATABASE AsyncTest
GO

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = N'AsyncTest' AND is_broker_enabled = 0)
    ALTER DATABASE AsyncTest SET ENABLE_BROKER WITH ROLLBACK IMMEDIATE 
GO

USE AsyncTest
GO


DROP TABLE IF EXISTS dbo.ServiceBrokerLogs
GO

CREATE TABLE dbo.ServiceBrokerLogs (
    ServiceBrokerLogsId bigint PRIMARY KEY NONCLUSTERED IDENTITY(1, 1)
    ,ServiceBrokerRowGuid uniqueidentifier NOT NULL DEFAULT(NEWID()) ROWGUIDCOL
    ,ServiceBrokerRowCreatedOnUtc datetime NOT NULL DEFAULT(GETUTCDATE())
    ,BatchId uniqueidentifier NOT NULL DEFAULT(NEWID())
    ,Comment nvarchar(max) NULL
    ,Request xml NULL 
)
GO

CREATE CLUSTERED INDEX cx_ServiceBrokerLogs ON dbo.ServiceBrokerLogs (BatchId)
GO 


-- Create the message types
CREATE MESSAGE TYPE [AsyncRequest] VALIDATION = WELL_FORMED_XML;
CREATE MESSAGE TYPE [AsyncResult]  VALIDATION = WELL_FORMED_XML;

CREATE CONTRACT [AsyncContract] 
(
  [AsyncRequest] SENT BY INITIATOR, 
  [AsyncResult]  SENT BY TARGET
);

-- Create the processing queue and service - specify the contract to allow sending to the service
CREATE QUEUE ProcessingQueue;
CREATE SERVICE [ProcessingService] ON QUEUE ProcessingQueue ([AsyncContract]);
 
-- Create the request queue and service 
CREATE QUEUE RequestQueue;
CREATE SERVICE [RequestService] ON QUEUE RequestQueue;

GO

-- Create the wrapper procedure for sending messages
CREATE OR ALTER PROCEDURE dbo.SendBrokerMessage 
	@FromService SYSNAME,
	@ToService   SYSNAME,
	@Contract    SYSNAME,
	@MessageType SYSNAME,
	@MessageBody XML
AS
BEGIN
  SET NOCOUNT ON;
 
  DECLARE @conversation_handle UNIQUEIDENTIFIER;
 
  BEGIN TRANSACTION;
 
  BEGIN DIALOG CONVERSATION @conversation_handle
    FROM SERVICE @FromService
    TO SERVICE @ToService
    ON CONTRACT @Contract
    WITH ENCRYPTION = OFF;
 
  SEND ON CONVERSATION @conversation_handle
    MESSAGE TYPE @MessageType(@MessageBody);
 
  COMMIT TRANSACTION;
END
GO

-- Create processing procedure for processing queue
CREATE OR ALTER PROCEDURE dbo.ProcessingQueueActivation
AS
BEGIN
  SET NOCOUNT ON;
 
  DECLARE @conversation_handle UNIQUEIDENTIFIER;
  DECLARE @message_body XML;
  DECLARE @message_type_name sysname;
 
  WHILE (1=1)
  BEGIN
    BEGIN TRANSACTION;
 
    WAITFOR
    (
      RECEIVE TOP (1)
        @conversation_handle = conversation_handle,
        @message_body = CAST(message_body AS XML),
        @message_type_name = message_type_name
      FROM ProcessingQueue
    ), TIMEOUT 5000;
 
    IF (@@ROWCOUNT = 0)
    BEGIN
      ROLLBACK TRANSACTION;
      BREAK;
    END
 
    IF @message_type_name = N'AsyncRequest'
    BEGIN
      -- Handle complex long processing here
      -- For demonstration we'll pull the account number and send a reply back only
 
      DECLARE @AccountNumber INT = @message_body.value('(AsyncRequest/AccountNumber)[1]', 'INT');
 
      -- Build reply message and send back
      DECLARE @reply_message_body XML = N'
        ' + CAST(@AccountNumber AS NVARCHAR(11)) + '
      ';
 
      SEND ON CONVERSATION @conversation_handle
        MESSAGE TYPE [AsyncResult] (@reply_message_body);
    END
 
    -- If end dialog message, end the dialog
    ELSE IF @message_type_name = N'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog'
    BEGIN
      END CONVERSATION @conversation_handle;
    END
 
    -- If error message, log and end conversation
    ELSE IF @message_type_name = N'http://schemas.microsoft.com/SQL/ServiceBroker/Error'
    BEGIN
      -- Log the error code and perform any required handling here
      -- End the conversation for the error
      END CONVERSATION @conversation_handle;
    END
 
    COMMIT TRANSACTION;
  END
END
GO

-- CREATE OR ALTER PROCEDURE for processing replies to the request queue
CREATE OR ALTER PROCEDURE dbo.RequestQueueActivation
AS
BEGIN
  SET NOCOUNT ON;
 
  DECLARE @conversation_handle UNIQUEIDENTIFIER;
  DECLARE @message_body XML;
  DECLARE @message_type_name sysname;
 
  WHILE (1=1)
  BEGIN
    BEGIN TRANSACTION;
 
    WAITFOR
    (
      RECEIVE TOP (1)
        @conversation_handle = conversation_handle,
        @message_body = CAST(message_body AS XML),
        @message_type_name = message_type_name
      FROM RequestQueue
    ), TIMEOUT 5000;
 
    IF (@@ROWCOUNT = 0)
    BEGIN
      ROLLBACK TRANSACTION;
      BREAK;
    END
 
    IF @message_type_name = N'AsyncResult'
    BEGIN
      -- If necessary handle the reply message here
      DECLARE @AccountNumber INT = @message_body.value('(AsyncResult/AccountNumber)[1]', 'INT');
 
      -- Since this is all the work being done, end the conversation to send the EndDialog message
      END CONVERSATION @conversation_handle;
    END
 
    -- If end dialog message, end the dialog
    ELSE IF @message_type_name = N'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog'
    BEGIN
       END CONVERSATION @conversation_handle;
    END
 
    -- If error message, log and end conversation
    ELSE IF @message_type_name = N'http://schemas.microsoft.com/SQL/ServiceBroker/Error'
    BEGIN
       END CONVERSATION @conversation_handle;
    END
 
    COMMIT TRANSACTION;
  END
END
GO


CREATE OR ALTER FUNCTION dbo.GetAsyncRequestXml (
    @sql nvarchar(max)
    ,@batchId uniqueidentifier = NULL
)
RETURNS xml
BEGIN
    RETURN (
        CONVERT(xml, CONCAT('<request>
            <details>
                {
                    "details": [
                            {
                                "batchId": "', CAST(@batchId AS nvarchar(36)), '"
                            },
                            {
                                "query": [
                                    {
                                        "sql": "', @sql, '"
                                    }
                                ]
                            }
                        ]
                }
            </details>
            <data></data>
        </request>'
        ))
    )
END
GO


-- CREATE OR ALTER PROCEDURE dbo.ExecuteSqlAsync(
DECLARE
    @request xml
-- )
-- AS 
SET NOCOUNT ON 


SET @request = '<request>
    <details>
        {
            "details": [
                    {
                        "batchId": ""
                    },
                    {
                        "query": [
                            {
                                "sql": ""
                            }
                        ]
                    }
                ]
        }
</details>
    <data></data>
</request>'

SET @request = dbo.GetAsyncRequestXml('SELECT * FROM WideWorldImporters.Sales.Customers', (NEWID()))


DECLARE 
    @detailsJson nvarchar(max)
    ,@batchId uniqueidentifier 
    ,@sql nvarchar(max)

SELECT 
    @detailsJson = @request.value('(/request/details/text())[1]', 'nvarchar(max)')


SELECT 
    @batchId = JSON_VALUE(@detailsJson, '$.details[0].batchId')
    ,@sql = JSON_VALUE(@detailsJson, '$.details[1].query[0].sql')

SELECT 
    @batchId
    ,@sql





