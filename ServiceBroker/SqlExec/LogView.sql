USE WideWorldImporters
GO

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
GO

CREATE OR ALTER VIEW Logging.vGetLogs
AS
WITH c_DetailsJson AS (
    SELECT DetailsJsonFromXml = l.DetailsXml.value('(/request/details/text())[1]', 'nvarchar(max)')
        ,*
    FROM Logging.LogEntry l WITH (NOLOCK)
),
c_LogSeries AS (
    SELECT DISTINCT
        l.LogEntrySeriesId
    FROM Logging.LogEntry l WITH (NOLOCK)
)

SELECT
    RequestBatchId = CONVERT(uniqueidentifier, JSON_VALUE(c.DetailsJsonFromXml, '$.details[0].batchId'))
    ,*
FROM c_DetailsJson c
GO


-- ;WITH c_DetailsJson AS (
--     SELECT DetailsJsonFromXml = l.DetailsXml.value('(/request/details/text())[1]', 'nvarchar(max)')
--         ,*
--     FROM Logging.LogEntry l
-- ),
-- c_LogSeries AS (
--     SELECT DISTINCT
--         l.LogEntrySeriesId
--     FROM Logging.LogEntry l
-- ),
-- c_WithParsedJson AS (
--     SELECT
--         RequestBatchId = CONVERT(uniqueidentifier, JSON_VALUE(c.DetailsJsonFromXml, '$.details[0].batchId'))
--         ,*
--     FROM c_DetailsJson c
-- )

CREATE OR ALTER VIEW Logging.vGetLogEntrySeries
AS
WITH c_WithParsedJson AS (
    SELECT *
    FROM Logging.vGetLogs
)
,c_UniqueSeriesIds AS (
    SELECT DISTINCT LogEntrySeriesId
    FROM c_WithParsedJson
)
,c_LogSeries_Stage AS (
    SELECT
        c.LogEntrySeriesId
        ,LogSeriesTotalTimeMS = DATEDIFF(MILLISECOND, series.LogSeriesStart, series.LogSeriesEnd)
        ,series.*
    FROM c_UniqueSeriesIds c
    OUTER APPLY (
        SELECT
            MAX(c1.LogEntryRowCreatedOnUtc) AS LogSeriesEnd
            ,MIN(c1.LogEntryRowCreatedOnUtc) AS LogSeriesStart
            ,COUNT(*) AS LogSeriesRowCount

        FROM c_WithParsedJson c1
        WHERE
            c1.LogEntrySeriesId = c.LogEntrySeriesId
        GROUP BY
            c1.LogEntrySeriesId
    ) series
)
,c_LogSeriesTimes AS (
    SELECT
        c.*
        ,LogEntrySeriesTotalTimeS = CAST(c.LogSeriesTotalTimeMS AS decimal) / 1000
        ,LogEntrySeriesTotalTimeM = (CAST(c.LogSeriesTotalTimeMS AS decimal) / 1000) / 60
        ,LogEntrySeriesTotalTimeH = ((CAST(c.LogSeriesTotalTimeMS AS decimal) / 1000) / 60) / 60
    FROM c_LogSeries_Stage c
)

SELECT *
FROM c_LogSeriesTimes
GO

CREATE OR ALTER VIEW Logging.vGetBatches
AS
WITH c_WithParsedJson AS (
    SELECT *
    FROM Logging.vGetLogs
)
,c_UniqueRequestBatchIds AS (
    SELECT DISTINCT RequestBatchId
    FROM c_WithParsedJson
)
,c_BatchTimes_Stage AS (
    SELECT
        requestBatch.RequestBatchId
        ,requestBatch.RequestBatchStart
        ,requestBatch.RequestBatchEnd
        ,RequestBatchTotalTimeMS = DATEDIFF(MILLISECOND, requestBatch.RequestBatchStart, requestBatch.RequestBatchEnd)
        ,requestBatch.RequestBatchRowCount
        ,requestBatch.RequestBatchTotalQueries
        -- ,RequestBatchTotalTimeS =  DATEDIFF(SECOND, requestBatch.RequestBatchStart, requestBatch.RequestBatchEnd)
        -- ,RequestBatchTotalTimeM  = DATEDIFF(MINUTE, requestBatch.RequestBatchStart, requestBatch.RequestBatchEnd)
        -- ,RequestBatchTotalTimeH = DATEDIFF(HOUR, requestBatch.RequestBatchStart, requestBatch.RequestBatchEnd)
    FROM c_UniqueRequestBatchIds rBat
    OUTER APPLY (
        SELECT
            c1.RequestBatchId
            ,MAX(c1.LogEntryRowCreatedOnUtc) AS RequestBatchEnd
            ,MIN(c1.LogEntryRowCreatedOnUtc) AS RequestBatchStart
            ,COUNT(*) AS RequestBatchRowCount
            ,COUNT(DISTINCT c1.LogEntrySeriesId) AS RequestBatchTotalQueries
        FROM c_WithParsedJson c1
        GROUP BY
            c1.RequestBatchId
    ) requestBatch
    WHERE
        rBat.RequestBatchId = requestBatch.RequestBatchId
)
,c_BatchTimes AS (
    SELECT
        c.*
        ,RequestBatchTotalTimeS =  CAST(c.RequestBatchTotalTimeMS AS decimal) / 1000
        ,RequestBatchTotalTimeM  = (CAST(c.RequestBatchTotalTimeMS AS decimal) / 1000) / 60
        ,RequestBatchTotalTimeH = ((CAST(c.RequestBatchTotalTimeMS AS decimal) / 1000) / 60) / 60
    FROM c_BatchTimes_Stage c
)

SELECT *
FROM c_BatchTimes
GO


SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT *
FROM Logging.vGetBatches bat
ORDER BY
    bat.RequestBatchStart DESC

SELECT
    ls.*
    ,l.*
FROM Logging.vGetLogEntrySeries ls
JOIN Logging.vGetLogs l ON l.LogEntrySeriesId = ls.LogEntrySeriesId
ORDER BY
    ls.LogSeriesTotalTimeMS DESC



-- SELECT
--     bat.RequestBatchId
--     ,bat.RequestBatchTotalTimeS
--     ,bat.RequestBatchTotalTimeM
--     ,bat.RequestBatchTotalTimeH
--     ,bat.RequestBatchStart
--     ,bat.RequestBatchEnd
--     ,ls.LogSeriesRowCount
--     ,ls.LogSeriesTotalTimeMS
--     ,ls.LogEntrySeriesTotalTimeS
--     ,ls.LogEntrySeriesTotalTimeM
--     ,ls.LogEntrySeriesTotalTimeH
--     ,ls.LogSeriesStart
--     ,ls.LogSeriesEnd
-- FROM Logging.vGetLogs c
-- JOIN Logging.vGetLogEntrySeries ls ON ls.LogEntrySeriesId = c.LogEntrySeriesId
-- JOIN Logging.vGetBatches bat ON bat.RequestBatchId = c.RequestBatchId
-- ORDER BY
--     bat.RequestBatchStart DESC

SELECT *
FROM Logging.vGetBatches
