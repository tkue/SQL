USE Util
GO


CREATE OR ALTER FUNCTION Stat.GetGrowFromDatePlot (
	@datePlot dbo.DatePlot READONLY 
)
RETURNS TABLE AS RETURN (
	WITH c AS (
		SELECT 
			[Date]
			,Val
			,Prev = CAST(LAG(c.Val, 1) OVER (ORDER BY c.[Date]) AS float)
		FROM @datePlot c
	)

	SELECT 
		c.[Date]
		,c.Val
		,Growth = (c.Val - c.Prev) / NULLIF(c.Prev, 0)
		,PreviousValue = c.Prev
	FROM c
)