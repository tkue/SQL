
CREATE FUNCTION [Stat].[GetPearsonsCorrelation]
(
    @Input dbo.PlotType READONLY

)
RETURNS NUMERIC(18,8)
AS
BEGIN

    RETURN (
		SELECT (Avg(x * y) - (Avg(x) * Avg(y))) / (StDevP(x) * StDevP(y))
		FROM @Input
	)
END
GO