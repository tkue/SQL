

SET NOCOUNT ON;

USE master
GO

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'ServiceBrokerTest')
BEGIN
    ALTER DATABASE ServiceBrokerTest
        SET ENABLE_BROKER
            WITH ROLLBACK IMMEDIATE;
END
GO


IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'ServiceBrokerTest')
BEGIN
    EXEC master..uspKillDatabaseConnections 'ServiceBrokerTest';

    BEGIN TRY
        EXEC('DROP DATABASE ServiceBrokerTest')
    END TRY
    BEGIN CATCH
    END CATCH
END
GO
 

CREATE DATABASE ServiceBrokerTest
GO

ALTER DATABASE ServiceBrokerTest
    SET ENABLE_BROKER
        WITH ROLLBACK IMMEDIATE;

ALTER DATABASE ServiceBrokerTest
    SET NEW_BROKER;
GO

ALTER DATABASE ServiceBrokerTest
    SET TRUSTWORTHY ON;



USE ServiceBrokerTest
GO



IF SCHEMA_ID('SqlExec') IS NULL
    EXEC('CREATE SCHEMA SqlExec AUTHORIZATION dbo')
GO

IF SCHEMA_ID('Logging') IS NULL
    EXEC('CREATE SCHEMA Logging AUTHORIZATION dbo')
GO

IF SCHEMA_ID('Util') IS NULL
    EXEC('CREATE SCHEMA Util AUTHORIZATION dbo')
GO





DROP TABLE IF EXISTS Logging.Batch
GO

CREATE TABLE Logging.Batch (
    BatchId bigint PRIMARY KEY IDENTITY(1, 1)
    ,BatchRowCreatedOnUtc datetime NOT NULL DEFAULT(GETUTCDATE())
    ,BatchRowGuid uniqueidentifier NOT NULL DEFAULT(NEWSEQUENTIALID()) ROWGUIDCOL
    ,BatchName varchar(128) NOT NULL
    ,BatchDescription varchar(1500)
)
GO

DROP TABLE IF EXISTS Logging.LogStatus
GO

CREATE TABLE Logging.LogStatus (
    LogStatusId int PRIMARY KEY IDENTITY(1, 1)
    ,LogStatusRowCreatedOnUtc datetime NOT NULL DEFAULT(GETUTCDATE())
    ,LogStatusRowGuid uniqueidentifier NOT NULL DEFAULT(NEWSEQUENTIALID()) ROWGUIDCOL
    ,LogStatusName varchar(128) NOT NULL UNIQUE
    ,IsFinished bit NOT NULL
    ,IsSuccess bit NOT NULL
)
GO

INSERT INTO Logging.LogStatus (
    LogStatusName
    ,IsFinished
    ,IsSuccess
)
VALUES
    ('not_started', 0, 0)
    ,('in_progress', 0, 0)
    ,('failed', 1, 0)
    ,('success', 1, 1)
    ,('timeout', 1, 0)
GO

CREATE NONCLUSTERED INDEX ix_LogStatus_LogStatusId_IsFinished
    ON Logging.LogStatus (LogStatusId, IsFinished)
GO


DROP TABLE IF EXISTS Logging.LogEntry
GO


CREATE TABLE Logging.LogEntry (
    LogEntryId bigint PRIMARY KEY IDENTITY(1, 1)
    ,LogEntryRowCreatedOnUtc datetime DEFAULT(GETUTCDATE())
    ,LogEntryRowGuid uniqueidentifier DEFAULT(NEWSEQUENTIALID()) ROWGUIDCOL
    ,LogEntrySeriesId uniqueidentifier DEFAULT(NEWID())
    ,ErrorNumber int NULL DEFAULT(ERROR_NUMBER())
	,ErrorSeverity int NULL DEFAULT(ERROR_SEVERITY())
	,ErrorState int NULL DEFAULT(ERROR_STATE())
	,ErrorProcedure nvarchar(256) NULL DEFAULT(ERROR_PROCEDURE())
	,ErrorLine int NULL DEFAULT(ERROR_LINE())
	,ErrorMessage nvarchar(max) NULL DEFAULT(ERROR_MESSAGE())
    ,CallingObject nvarchar(256) DEFAULT(ISNULL(ERROR_PROCEDURE(),OBJECT_NAME(@@PROCID)))
    ,Spid int DEFAULT(@@SPID)
    ,AppName nvarchar(256) DEFAULT(APP_NAME())
    ,HostName nvarchar(256) DEFAULT(HOST_NAME())
    ,Username sysname DEFAULT(CURRENT_USER)
    ,[RowCount] int DEFAULT(@@ROWCOUNT)
    ,DetailsXml xml
    ,DetailsJson nvarchar(max)
    ,LogStatusId int FOREIGN KEY REFERENCES Logging.LogStatus (LogStatusId)
)
GO


DROP TABLE IF EXISTS SqlExec.SqlExecQueue
GO

CREATE TABLE SqlExec.SqlExecQueue (
    SqlExecQueueId bigint PRIMARY KEY NONCLUSTERED IDENTITY(1, 1)
    ,SqlExecQueueRowCreatedOnUtc datetime NOT NULL DEFAULT(GETUTCDATE())
    ,SqlExecQueueRowGuid uniqueidentifier NOT NULL DEFAULT(NEWSEQUENTIALID())
    ,SqlStmt nvarchar(max) NOT NULL
    ,SqlStmtSha1Hash varbinary(8000)
    ,ExecutionOrder tinyint NOT NULL DEFAULT(0)
    ,BatchId bigint NOT NULL FOREIGN KEY REFERENCES Logging.Batch (BatchId)
    ,LogStatusId int NOT NULL FOREIGN KEY REFERENCES Logging.LogStatus (LogStatusId)
)
-- WITH
--         (MEMORY_OPTIMIZED = ON,
--         DURABILITY        = SCHEMA_ONLY);
GO



DROP FUNCTION IF EXISTS Logging.GetInitLogStatusId
GO

CREATE FUNCTION Logging.GetInitLogStatusId(
    @args nvarchar(max) = NULL
)
RETURNS int
AS
BEGIN
    RETURN (
        SELECT TOP 1 LogStatusId
        FROM Logging.LogStatus
        WHERE
            IsFinished = 0
        ORDER BY
            LogStatusId ASC
    )
END
GO


DROP FUNCTION IF EXISTS Logging.GetSuccessLogStatusId
GO

CREATE FUNCTION Logging.GetSuccessLogStatusId(
    @args nvarchar(max) = NULL
)
RETURNS int
AS
BEGIN
    RETURN (
        SELECT LogStatusId
        FROM Logging.LogStatus
        WHERE
            LogStatusName = 'failed'
    )
END
GO


DROP FUNCTION IF EXISTS Logging.GetFailedLogStatusId
GO

CREATE FUNCTION Logging.GetFailedLogStatusId(
    @args nvarchar(max) = NULL
)
RETURNS int
AS
BEGIN
    RETURN (
        SELECT LogStatusId
        FROM Logging.LogStatus
        WHERE
            LogStatusName = 'success'
    )
END
GO


DROP FUNCTION IF EXISTS Util.GetArgsFromJson
GO

CREATE FUNCTION Util.GetArgsFromJson(
    @args nvarchar(max)
)
RETURNS TABLE AS RETURN
(
    SELECT
        [Sql] = CAST(JSON_VALUE(@args, '$.sql') AS nvarchar(max))
        ,[LogEntryStatusId] = CAST(JSON_VALUE(@args, '$.logStatusId') AS int)
)
GO



DROP FUNCTION IF EXISTS Util.AddArgToJsonArgs
GO

CREATE FUNCTION Util.AddArgToJsonArgs(
    @args nvarchar(max)
    ,@key nvarchar(max)
    ,@value nvarchar(max)
)
RETURNS nvarchar(max)
AS
BEGIN
    RETURN (
        SELECT TOP 1
            Args = JSON_MODIFY(v.Args, '$.' + REPLACE(@key, '$.', ''), @value)
        FROM (
            SELECT Args = ISNULL(NULLIF(TRIM(@args), ''), '{}')
        ) v
    )
    -- RETURN (
    --     SELECT JSON_MODIFY(@args, '$.' + REPLACE(@key, '$.', ''), @value)
    -- )
END
GO


-- DECLARE @args nvarchar(max)
-- SET @args = Util.AddArgToJsonArgs(@args, 'sql', 'select * from some table')
-- SET @args = Util.AddArgToJsonArgs(@args, 'sql', 'select * from some othertable')
-- SELECT @args


DROP FUNCTION IF EXISTS Util.GetArgsFromXml
GO

CREATE FUNCTION Util.GetArgsFromXml(
    @args xml
)
RETURNS TABLE AS RETURN
(
    SELECT
        [SqlExecQueueId] =      x.value('(/SqlExecQueueId/text())[1]', 'int')
        ,[Sql] =                x.value('(/Sql/text())[1]', 'nvarchar(max)')
        ,[LogEntryStatusId] =   x.value('(/LogEntryStatusId/text())[1]', 'int')
    FROM @args.nodes('/') AS T(x)
)
GO



DROP FUNCTION IF EXISTS Util.AddArgsToXmlArgs
GO


CREATE FUNCTION Util.AddArgsToXmlArgs(
    @args xml
    ,@key nvarchar(max)
    ,@value nvarchar(max)
)
RETURNS xml
AS
BEGIN
    DECLARE
        @tempString varchar(50) = '<?temp --?>'
        ,@isReplaceTempString bit = 0
        ,@s nvarchar(max)


    IF @args IS NULL
    BEGIN
        SET @args = CAST(@tempString AS xml)
        SET @isReplaceTempString = 1
    END

    -- convert xml to string
    SET @s = CAST(@args AS nvarchar(max))


    -- When the value doesn't exist
    IF PATINDEX('%' + @key + '%', CAST(@args AS nvarchar(max))) = 0
    BEGIN
        -- SET @args = CAST(CAST(@args AS nvarchar(max)) + CAST(Util.ConvertKeyValuePairToXml(@key, @value) AS nvarchar(max)) AS xml)
        SET @s += CAST(Util.ConvertKeyValuePairToXml(@key, @value) AS nvarchar(max))
    END
    ELSE
    -- When you need to replace the value
    BEGIN

        DECLARE
            @substring nvarchar(max)
            ,@startPat nvarchar(500) = '%<' + @key + '>%'       -- beginning tag
            ,@endPat nvarchar(500) = '%</' + @key + '>%'        -- ending tag

        -- Get string to replace
        SET @substring = SUBSTRING(@s, PATINDEX(@startPat, @s), PATINDEX(@endPat, @s) + LEN(@endPat))

        -- Replace the string
        SET @s = REPLACE(@s, @substring, CONVERT(nvarchar(max), Util.ConvertKeyValuePairToXml(@key, @value)))

    END

    -- replace the temp string if @args was passed as null
    IF @isReplaceTempString = 1
        SET @s = REPLACE(@s, @tempString, '')


    RETURN CONVERT(xml, @s)
END
GO


DROP FUNCTION IF EXISTS Util.ConvertKeyValuePairToXml
GO

CREATE FUNCTION Util.ConvertKeyValuePairToXml
(
    @key varchar(250)
    ,@value varchar(max)
)
RETURNS xml
AS
BEGIN
    RETURN (
        SELECT '<' + @key + '>' + CASE
                                        WHEN TRY_CAST(@value AS int) IS NOT NULL
                                            THEN ''
                                        ELSE '"'
                                    END + @value + CASE
                                                        WHEN TRY_CAST(@value AS int) IS NOT NULL
                                                            THEN ''
                                                        ELSE '"'
                                                    END + '</' + @key + '>'
    )
END
GO




CREATE OR ALTER PROCEDURE SqlExec.ExecuteSql (
    @sql nvarchar(max)
    ,@args nvarchar(max) OUTPUT
)
AS
SET NOCOUNT ON;

INSERT INTO Logging.LogEntry (DetailsJson)
VALUES ('SqlExec.ExecuteSql:init')


SELECT
    @sql = NULLIF(TRIM(@sql), '')
    ,@args = NULLIF(TRIM(@args), '')

IF ISNULL(@sql, '') = ''
BEGIN
    RAISERROR(N'@sql cannot be null', 16, 1)
    RETURN 1
END


DECLARE
    @logEntrySeriesId uniqueidentifier = NEWID()
    ,@logEntryStatusId int

-- SET @args = JSON_MODIFY(@args, '$.sql', @sql)
SET @args = Util.AddArgToJsonArgs(@args, 'sql', @sql)
SET @args = Util.AddArgToJsonArgs(@args, 'logEntrySeriesId', CAST(@logEntrySeriesId AS nchar(36)))

BEGIN TRY
    -- start
    INSERT INTO Logging.LogEntry(LogStatusId, DetailsJson, LogEntrySeriesId)
    VALUES
        (Logging.GetInitLogStatusId(@args), @args, @logEntrySeriesId)

    -- exec
    EXEC sp_executesql @sql

    -- end
    SET @logEntryStatusId = Logging.GetSuccessLogStatusId(@args)
    SET @args = Util.AddArgToJsonArgs(@args, 'logStatusId', CAST(@logEntryStatusId AS nvarchar(5)))

    INSERT INTO Logging.LogEntry(LogStatusId, DetailsJson, LogEntrySeriesId)
    VALUES
        (@logEntryStatusId, @args, @logEntrySeriesId)

END TRY
BEGIN CATCH
    -- fail
    INSERT INTO Logging.LogEntry(LogStatusId, DetailsJson, LogEntrySeriesId)
    VALUES
        (Logging.GetFailedLogStatusId(@args), @args, @logEntrySeriesId)
END CATCH
GO



CREATE OR ALTER PROCEDURE dbo.Process_SqlExec_InitQueue
AS
SET NOCOUNT ON;
SET ARITHABORT ON;

INSERT INTO Logging.LogEntry (DetailsJson)
VALUES ('dbo.Process_SqlExec_InitQueue: init')


DECLARE
    @message xml
    ,@messageType sysname
    ,@dialogId uniqueidentifier
    ,@logEntrySeriesId uniqueidentifier

WHILE (1=1)
BEGIN
    BEGIN TRANSACTION
    BEGIN TRY
        SELECT
            @message = NULL
            ,@messageType = NULL
            ,@dialogId = NULL


        -- turn queue on if it isn't already
        IF EXISTS (
            SELECT 1
            FROM sys.service_queues q
            WHERE
                q.name = 'SqlExec_InitQueue'
                AND q.is_receive_enabled = 0
        )
        BEGIN
            ALTER QUEUE dbo.SqlExec_InitQueue
                WITH STATUS = ON;
        END

        WAITFOR
        (
            RECEIVE TOP(1)
                @message = CONVERT(xml, message_body)
                ,@messageType = message_type_name
                ,@dialogId = [conversation_handle]
            FROM dbo.SqlExec_InitQueue
        )

        -- timeout
        IF @@ROWCOUNT = 0
        BEGIN
            INSERT INTO Logging.LogEntry (LogStatusId, DetailsXml)
            VALUES
                (Logging.GetFailedLogStatusId(NULL), @message)

            IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;

            BREAK;
        END


        -- end dialog/error
        IF @messageType IN (
            N'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog'
            ,N'http://schemas.microsoft.com/SQL/ServiceBroker/Error'
        )
        BEGIN
            END CONVERSATION @dialogId;

            -- TODO: Handle service broker error messages
            IF @@TRANCOUNT > 0
                COMMIT TRANSACTION

            INSERT INTO Logging.LogEntry (LogStatusId, DetailsXml)
            VALUES
                (Logging.GetFailedLogStatusId(NULL), @message)

            BREAK;
        END


    IF @messageType = N'//SqlExec/Message'
    BEGIN
        DECLARE
            @logEntryStatusId int
            ,@sqlExecQueueId int

        SELECT
            @logEntryStatusId = m.LogEntryStatusId
            ,@sqlExecQueueId = m.SqlExecQueueId
        FROM Util.GetArgsFromXml(@message) m

        INSERT INTO Logging.LogEntry (DetailsXml)
        VALUES (@message)


        UPDATE SqlExec.SqlExecQueue
        SET LogStatusId = @logEntryStatusId
        WHERE
            SqlExecQueueId = @sqlExecQueueId
    END


    IF @@TRANCOUNT > 0
        COMMIT TRANSACTION

    ;END CONVERSATION @dialogId

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION


        INSERT INTO Logging.LogEntry(LogStatusId, DetailsXml)
        VALUES (Logging.GetFailedLogStatusId(NULL), @message)

        ;END CONVERSATION @dialogId
    END CATCH
END
GO



CREATE OR ALTER PROCEDURE dbo.Process_SqlExec_ProcessingQueue
-- WITH EXECUTE AS OWNER
AS
SET NOCOUNT ON;
SET ARITHABORT ON;

RAISERROR(N'dbo.Process_SqlExec_ProcessingQueue',0,0) WITH NOWAIT;
PRINT('dbo.Process_SqlExec_ProcessingQueue')

INSERT INTO Logging.LogEntry (DetailsJson)
VALUES ('dbo.Process_SqlExec_ProcessingQueue:init')

DECLARE
    @message xml
    ,@messageType sysname
    ,@dialogId uniqueidentifier
    ,@logEntrySeriesId uniqueidentifier

DECLARE @error int, @errorMessage nvarchar(4000)

WHILE (1=1)
BEGIN
    -- BEGIN TRANSACTION
    BEGIN TRY
        SELECT
            @message = NULL
            ,@messageType = NULL
            ,@dialogId = NULL


        -- turn queue on if it isn't already
        IF EXISTS (
            SELECT 1
            FROM sys.service_queues q
            WHERE
                q.name = 'SqlExec_ProcessingQueue'
                AND q.is_receive_enabled = 0
        )
        BEGIN
            ALTER QUEUE dbo.SqlExec_ProcessingQueue
                WITH STATUS = ON;
        END

        WAITFOR
        (
            RECEIVE TOP(1)
                @message = CONVERT(xml, message_body)
                ,@messageType = message_type_name
                ,@dialogId = [conversation_handle]
            FROM dbo.SqlExec_ProcessingQueue
        )

        -- timeout
        IF @@ROWCOUNT = 0
        BEGIN
            -- IF @@TRANCOUNT > 0
            --     ROLLBACK TRANSACTION;

            INSERT INTO Logging.LogEntry (LogStatusId, DetailsXml)
            VALUES
                (Logging.GetFailedLogStatusId(NULL), @message)

            ;END CONVERSATION @dialogId
                WITH    ERROR = @error
                        DESCRIPTION = @errorMessage

            BREAK;
        END


        -- end dialog/error
        IF @messageType IN (
            N'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog'
            ,N'http://schemas.microsoft.com/SQL/ServiceBroker/Error'
        )
        BEGIN
            -- END CONVERSATION @dialogId;

            -- TODO: Handle service broker error messages
            -- IF @@TRANCOUNT > 0
            --     COMMIT TRANSACTION

            INSERT INTO Logging.LogEntry (LogStatusId, DetailsXml)
            VALUES
                (Logging.GetFailedLogStatusId(NULL), @message)

            SELECT @error = ERROR_NUMBER(), @errorMessage = ERROR_MESSAGE()

            ;END CONVERSATION @dialogId
                WITH    ERROR = @error
                        DESCRIPTION = @errorMessage


            BREAK;
        END;


        IF @messageType = N'//SqlExec/Message'
        BEGIN
            DECLARE
                @sql nvarchar(max)
                ,@args nvarchar(max)

            DECLARE @msg nvarchar(max)
            RAISERROR(@msg,0,0) WITH NOWAIT;

            SELECT
                @sql = [Sql]
            FROM Util.GetArgsFromXml(@message)

            EXEC SqlExec.ExecuteSql @sql, @args OUTPUT

            DECLARE
                @logEntryStatusId int

            SET @logEntryStatusId = (
                SELECT LogEntryStatusId
                FROM Util.GetArgsFromJson(@args)
            )

            SET @message = Util.AddArgsToXmlArgs(@message, 'LogEntryStatusId', @logEntryStatusId)
        END;

        -- IF @@TRANCOUNT > 0
        --     COMMIT TRANSACTION;

        -- END CONVERSATION @dialogId;
        SEND ON CONVERSATION @dialogId
        MESSAGE TYPE @messageType(@message);

    END TRY
    BEGIN CATCH
        INSERT INTO Logging.LogEntry (LogStatusId, DetailsXml)
        VALUES (Logging.GetFailedLogStatusId(NULL), @message)


        SELECT @error = ERROR_NUMBER(), @errorMessage = ERROR_MESSAGE()

        ;END CONVERSATION @dialogId
                WITH    ERROR = @error
                        DESCRIPTION = @errorMessage
    END CATCH
END
GO



CREATE OR ALTER PROCEDURE dbo.SendServiceBrokerConversation(
    @fromService sysname
    ,@toService sysname
    ,@onContract sysname
    ,@messageType sysname
    ,@messageBody xml = NULL
    ,@conversationGroupId uniqueidentifier = NULL
)
AS
SET NOCOUNT ON;
RAISERROR(N'dbo.SendServiceBrokerConversation',0,0) WITH NOWAIT;


DECLARE
    @conversationHandleId uniqueidentifier


IF @conversationGroupId IS NULL
BEGIN

    BEGIN DIALOG CONVERSATION @conversationHandleId
        FROM SERVICE @fromService
        TO SERVICE @toService
        ON CONTRACT @onContract
            WITH
                ENCRYPTION = OFF
END
ELSE
BEGIN
    -- Has a conversation group
    BEGIN DIALOG CONVERSATION @conversationHandleId
        FROM SERVICE @fromService
        TO SERVICE @toService
        ON CONTRACT @onContract
            WITH
                ENCRYPTION = OFF
                ,RELATED_CONVERSATION_GROUP = @conversationGroupId
END
    RAISERROR(N'Sending message...',0,0) WITH NOWAIT;

    SEND ON CONVERSATION @conversationHandleId
    MESSAGE TYPE @messageType(@messageBody);
GO



IF EXISTS (SELECT 1 FROM sys.services s WHERE name = '//SqlExec/InitService')
    DROP SERVICE [//SqlExec/InitService]
GO

IF EXISTS (SELECT 1 FROM sys.services s WHERE name = '//SqlExec/ProcessingService')
    DROP SERVICE [//SqlExec/ProcessingService]
GO

IF EXISTS (SELECT 1 FROM sys.service_queues WHERE name = 'SqlExec_InitQueue')
    DROP QUEUE [dbo].[SqlExec_InitQueue]
GO

IF EXISTS (SELECT 1 FROM sys.service_queues WHERE name = 'SqlExec_ProcessingQueue')
    DROP QUEUE [dbo].[SqlExec_ProcessingQueue]
GO

IF EXISTS (SELECT 1 FROM sys.service_contracts WHERE name = '//SqlExec/Contract')
    DROP CONTRACT [//SqlExec/Contract]
GO

IF EXISTS (SELECT 1 FROM sys.service_message_types WHERE name = '//SqlExec/Message')
    DROP MESSAGE TYPE [//SqlExec/Message]
GO



CREATE MESSAGE TYPE [//SqlExec/Message]
    VALIDATION = WELL_FORMED_XML
GO

CREATE CONTRACT [//SqlExec/Contract] ([//SqlExec/Message] SENT BY ANY)
GO

CREATE QUEUE dbo.SqlExec_ProcessingQueue
    WITH STATUS=ON
    ,ACTIVATION (
        MAX_QUEUE_READERS = 8
        ,EXECUTE AS SELF
        ,PROCEDURE_NAME = dbo.Process_SqlExec_ProcessingQueue
    )
GO

CREATE QUEUE dbo.SqlExec_InitQueue
    WITH STATUS = ON
    ,ACTIVATION (
        MAX_QUEUE_READERS = 8
        ,EXECUTE AS SELF
        ,PROCEDURE_NAME = dbo.Process_SqlExec_InitQueue
    )
GO

-- CREATE QUEUE dbo.SqlExec_InitQueue
--     WITH STATUS = ON
-- GO

CREATE SERVICE [//SqlExec/ProcessingService] AUTHORIZATION dbo
    ON QUEUE dbo.SqlExec_ProcessingQueue ([//SqlExec/Contract])
GO

CREATE SERVICE [//SqlExec/InitService] AUTHORIZATION dbo
    ON QUEUE [dbo].[SqlExec_InitQueue] ([//SqlExec/Contract])
GO




DELETE SqlExec.SqlExecQueue
GO

DELETE Logging.Batch
GO


DECLARE
    @batchId int
    ,@sql nvarchar(max)
    ,@logStatusId_init int
    ,@sqlExecQueueId int
    ,@convoId uniqueidentifier
    ,@conversationHandleId uniqueidentifier
    ,@payload xml

SET @logStatusId_init = (SELECT TOP 1 LogStatusId FROM Logging.LogStatus ORDER BY LogStatusId ASC)




-- create batch
INSERT INTO Logging.Batch (BatchName)
VALUES('WideWorldImporters_ETL inserts')

SET @batchId = @@IDENTITY



SET @sql = N'TRUNCATE TABLE WideWorldImporters_ETL.Sales.InvoiceLines'
INSERT INTO SqlExec.SqlExecQueue (BatchId, SqlStmt, SqlStmtSha1Hash, ExecutionOrder, LogStatusId)
VALUES
    (@batchId, @sql, HASHBYTES('SHA1', @sql), 1, @logStatusId_init)


SET @sql = N'TRUNCATE TABLE WideWorldImporters_ETL.Sales.Invoices'
INSERT INTO SqlExec.SqlExecQueue (BatchId, SqlStmt, SqlStmtSha1Hash, ExecutionOrder, LogStatusId)
VALUES
    (@batchId, @sql, HASHBYTES('SHA1', @sql), 1, @logStatusId_init)


SET @sql = N'TRUNCATE TABLE WideWorldImporters_ETL.Sales.Orders'
INSERT INTO SqlExec.SqlExecQueue (BatchId, SqlStmt, SqlStmtSha1Hash, ExecutionOrder, LogStatusId)
VALUES
    (@batchId, @sql, HASHBYTES('SHA1', @sql), 1, @logStatusId_init)


SET @sql = N'TRUNCATE TABLE WideWorldImporters_ETL.Sales.OrderLines'
INSERT INTO SqlExec.SqlExecQueue (BatchId, SqlStmt, SqlStmtSha1Hash, ExecutionOrder, LogStatusId)
VALUES
    (@batchId, @sql, HASHBYTES('SHA1', @sql), 1, @logStatusId_init)




SET @sql = N'INSERT INTO WideWorldImporters.Sales.InvoiceLines SELECT * FROM WideWorldImporters.Sales.InvoiceLines'
INSERT INTO SqlExec.SqlExecQueue (BatchId, SqlStmt, SqlStmtSha1Hash, ExecutionOrder, LogStatusId)
VALUES
    (@batchId, @sql, HASHBYTES('SHA1', @sql), 2, @logStatusId_init)

SET @sql = N'INSERT INTO WideWorldImporters.Sales.Invoices SELECT * FROM WideWorldImporters.Sales.Invoices'
INSERT INTO SqlExec.SqlExecQueue (BatchId, SqlStmt, SqlStmtSha1Hash, ExecutionOrder, LogStatusId)
VALUES
    (@batchId, @sql, HASHBYTES('SHA1', @sql), 2, @logStatusId_init)

SET @sql = N'INSERT INTO WideWorldImporters.Sales.Orders SELECT * FROM WideWorldImporters.Sales.Orders'
INSERT INTO SqlExec.SqlExecQueue (BatchId, SqlStmt, SqlStmtSha1Hash, ExecutionOrder, LogStatusId)
VALUES
    (@batchId, @sql, HASHBYTES('SHA1', @sql), 2, @logStatusId_init)

SET @sql = N'INSERT INTO WideWorldImporters.Sales.OrderLines SELECT * FROM WideWorldImporters.Sales.OrderLines'
INSERT INTO SqlExec.SqlExecQueue (BatchId, SqlStmt, SqlStmtSha1Hash, ExecutionOrder, LogStatusId)
VALUES
    (@batchId, @sql, HASHBYTES('SHA1', @sql), 2, @logStatusId_init)



-- SELECT TOP 1 q.SqlExecQueueId
-- FROM SqlExec.SqlExecQueue q
-- LEFT JOIN Logging.LogStatus s ON q.LogStatusId = s.LogStatusId
--                                     AND s.IsFinished = 1

-- ORDER BY
--     q.SqlExecQueueId ASC




-- SqlExec.GetNextFromQueue (@batchId)
-- SET @sql = (
--             SELECT TOP 1 SqlStmt
--             FROM SqlExec.SqlExecQueue q
--             WHERE
--                 NOT EXISTS (
--                     SELECT 1
--                     FROM Logging.LogStatus s
--                     WHERE
--                         s.LogStatusId = q.LogStatusId
--                         AND s.IsFinished = 0
--                 )
--             ORDER BY
--                 SqlExecQueueId ASC
--         )
SET @sqlExecQueueId = (
                        SELECT TOP 1 q.SqlExecQueueId
                        FROM SqlExec.SqlExecQueue q
                        WHERE
                            NOT EXISTS (
                                SELECT 1
                                FROM Logging.LogStatus s
                                WHERE
                                    s.LogStatusId = q.LogStatusId
                                    AND s.IsFinished = 1
                            )
                        ORDER BY
                            SqlExecQueueId ASC
                    )

SET @sql = (SELECT SqlStmt FROM SqlExec.SqlExecQueue WHERE SqlExecQueueId = @sqlExecQueueId)
SET @convoId = NEWID()
-- SET @payload = CONCAT('<sql>', REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@sql, '&', '&amp;'), '<', ''), '>', '&gt;'), '"', '&quot;'), '''', '&apos;'), '</sql>')
-- SET @payload = CONCAT('<payload><SqlExecQueueId>', CAST(@sqlExecQueueId AS nvarchar(5)), '</SqlExecQueueId></payload>')
SET @payload = CONCAT('<SqlExecQueueId>', CAST(@sqlExecQueueId AS nvarchar(5)), '</SqlExecQueueId><Sql>', @sql, '</Sql>')

-- SELECT * FROM Util.GetArgsFromXml(@payload)

-- SqlExec.GetSqlExecQueueIdFromPayload
-- SELECT @payload.value('(/payload/SqlExecQueueId/text())[1]', 'int')



RAISERROR(N'Sending message...',0,0) WITH NOWAIT;
BEGIN DIALOG CONVERSATION @conversationHandleId
    FROM SERVICE [//SqlExec/InitService]
    TO SERVICE '//SqlExec/ProcessingService'  --'//SqlExec/ProcessingService' --, 'CURRENT_DATABASE'
    ON CONTRACT [//SqlExec/Contract]
        WITH
            ENCRYPTION = OFF
            ,RELATED_CONVERSATION_GROUP = @convoId;


;SEND ON CONVERSATION @conversationHandleId
MESSAGE TYPE [//SqlExec/Message](@payload);

RAISERROR(N'Done.',0,0) WITH NOWAIT;
-- WAITFOR DELAY '00:00:10.00';


-- ALTER QUEUE SqlExec.SqlExec_ProcessingQueue
--     WITH STATUS = ON;

-- ALTER QUEUE SqlExec.SqlExec_InitQueue
--     WITH STATUS = ON;

return




set TRANSACTION ISOLATION LEVEL read UNCOMMITTED


SELECT * FROM dbo.SqlExec_ProcessingQueue WITH (NOLOCK)
SELECT * FROM dbo.SqlExec_InitQueue WITH (NOLOCK)

SELECT CONVERT(xml, message_body), * FROM sys.transmission_queue



SELECT * FROM Logging.LogEntry WITH (NOLOCK)


SELECT * FROM sys.service_queues

EXEC dbo.Process_SqlExec_InitQueue