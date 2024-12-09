CREATE FUNCTION Stat.GetGrowth(
	@plot dbo.PlotType READONLY
)
RETURNS TABLE AS RETURN (
	WITH c AS (
		SELECT 
			x
			,y
			,Prev = CAST(LAG(c.Y, 1) OVER (ORDER BY c.X) AS float)
		FROM @plot c
	)

	SELECT 
		c.X
		,c.Y
		,Growth = (c.y - c.Prev) / NULLIF(c.Prev, 0)
		,tally.Date
	FROM c
	JOIN Stat.TallyDay tally ON c.X = tally.N
)
GO