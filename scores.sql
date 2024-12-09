USE tempdb
GO

DECLARE @t TABLE (
	Id int PRIMARY KEY IDENTITY(1, 1)
	,Score int
)

INSERT INTO @t ( Score )
VALUES
	(10)
	,(20)
	,(30)
	,(40)
	,(50)

;WITH c AS (
	SELECT
		t.Id
		,t.Score
		,maxScore.MaxScore
		,minScore.MinScore
		,sumScore.SumScore
		,avgScore.AvgScore
		,stdDevScore.StdDev
	FROM @t t
	OUTER APPLY ( SELECT MAX(Score) AS MaxScore FROM @t ) maxScore
	OUTER APPLY ( SELECT MIN(Score) AS MinScore FROM @t WHERE ISNULL(Score, 0) <> 0 ) AS minScore
	OUTER APPLY ( SELECT SUM(ISNULL(Score, 0)) AS SumScore FROM @t ) AS sumScore
	OUTER APPLY ( SELECT AVG(ISNULL(Score, 0)) AS AvgScore FROM @t t WHERE t.Score <> 0) AS avgScore
	OUTER APPLY ( SELECT STDEV(ISNULL(Score, 0)) AS StdDev FROM @t WHERE ISNULL(Score, 0) <> 0) AS stdDevScore
)
,c2 AS (

	SELECT
		Calc1 = (( (c.MaxScore - c.MinScore) - c.MinScore ) / (c.MaxScore - c.MinScore)) * (100 - 1) + 1
		,Calc2 = ( (c.Score - 1) / (c.MaxScore - 1) ) * 9 + 1
		,ZScore = (c.Score - c.AvgScore) / c.StdDev
		,Calc3 = 1 + (c.Score - c.MinScore) * (100 - 1) / (c.MaxScore - c.MinScore)
		,c.*
	FROM c c
)

SELECT
	( (c.ZScore - 1) / (c.MaxScore - 1) ) * 99 + 1
	,c.*
FROM c2 c