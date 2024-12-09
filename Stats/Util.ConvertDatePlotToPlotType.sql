USE Util
GO


CREATE FUNCTION Util.ConvertDatePlotToPlotType (
	@datePlot dbo.DatePlot READONLY
)
RETURNS TABLE AS RETURN (
	SELECT 
		t.N
		,d.Val
	FROM @datePlot d
	JOIN Stat.TallyDay t ON d.Date = t.Date
)