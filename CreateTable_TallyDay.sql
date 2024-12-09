USE Util
GO


CREATE TABLE Stat.TallyDay (
	N bigint PRIMARY KEY NOT NULL
	,[Date] date NOT NULL
	,[Day] int NOT NULL
	,[Month] int NOT NULL
	,[Year] int NOT NULL
)
GO

TRUNCATE TABLE Stat.TallyDay
GO


;WITH Tally (N) AS
(
    SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL))
    FROM (VALUES(0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) a(n)
    CROSS JOIN (VALUES(0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) b(n)
    CROSS JOIN (VALUES(0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) c(n)
	CROSS JOIN (VALUES(0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) d(n)
	CROSS JOIN (VALUES(0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) e(n)
	CROSS JOIN (VALUES(0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) f(n)
)
,TallyDate (N, [Date]) AS (
	SELECT 
		n,
		DATEADD(day, n-1, '1800-01-01')
	FROM Tally 
)

INSERT INTO Stat.TallyDay
SELECT 
	N
	,[Date]
	,DATEPART(day, [Date]) AS [Day]
	,DATEPART(month, [Date]) AS [Month]
	,DATEPART(year, [Date]) AS [Year]
FROM TallyDate

