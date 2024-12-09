USE ServiceBrokerTests
GO

DROP TABLE IF EXISTS dbo.Testing
CREATE TABLE dbo.Testing (
    Val int NOT NULL
)
GO


DECLARE
    @maxQueries int = 10000
    ,@i int = 0
    ,@sql nvarchar(max)
    ,@conversationGroupId uniqueidentifier = NEWID()

WHILE @i < @maxQueries
BEGIN
    SET @i += 1


    DECLARE
        @request xml
    SET @sql = N'INSERT INTO dbo.Testing (Val) VALUES (' + CAST(@i AS nvarchar(20)) + ')'
    SET @request = dbo.GetAsyncRequestXml(@sql, NEWID())

    -- EXEC dbo.ExecuteSql @request


    EXECUTE dbo.SendServiceBrokerConversation
                                                @fromService = 'SqlExecRequestQueue'
                                                ,@toService   = 'SqlExecProcessingService'
                                                ,@onContact    = 'SqlExecVoidContract'
                                                ,@messageType = 'SqlExecVoidRequest'
                                                ,@messageBody = @request
                                                -- ,@conversationGroupId = @conversationGroupId
END



-- Check for message on processing queue
-- SELECT CAST(message_body AS XML) FROM SqlExecProcessingQueue;


-- Process the message from the processing queue
EXECUTE dbo.ProcessSqlExecProcessingQueue;
GO

-- Check for reply message on request queue
-- SELECT CAST(message_body AS XML) FROM SqlExecRequestQueue;
GO

-- Process the message from the request queue
EXECUTE dbo.ProcessSqlExecRequestQueue;
GO

SELECT COUNT(*) FROM dbo.Testing WITH (NOLOCK)

-- SELECT
--     OBJECT_NAME(t.queue_id)
--     ,t.*
-- FROM sys.dm_broker_activated_tasks t

;WITH c AS (
    SELECT TOP 1
        StartTime = (SELECT MIN(LogEntryRowCreatedOnUtc) FROM Logging.LogEntry)
        ,EndTime = (SELECT max(LogEntryRowCreatedOnUtc) FROM Logging.LogEntry)
    FROM Logging.LogEntry
)
,c2 AS (
    SELECT
        TotalTime = DATEDIFF(second, c.StartTime, c.EndTime)
        ,c.StartTime
        ,c.EndTime
    FROM c
)

/*
    rows: 10000
    threads: 5
    isParallel: false
    time: 51

    rows: 10000
    threads: 5
    isParallel: true
    time: 202

    rows: 10000
    threads: -1
    isParallel: false
    time: 393



    rows: 10000
    threads: 20
    isParallel: false
    time: 802

    rows: 10000
    threads: 20
    isParallel: true
    time: 937


    rows: 10000
    threads: 10
    isParallel: false
    time: 1393

    rows: 10000
    threads: 10
    isParallel: true
    time: 1235

*/
SELECT *
FROM c2 c