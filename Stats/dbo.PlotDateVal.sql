USE Util
GO

CREATE TYPE dbo.DatePlot AS TABLE (
	[Date] date UNIQUE NOT NULL
	,Val numeric(18,6) NOT NULL
)
GO