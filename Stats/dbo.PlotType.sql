USE Util
GO

CREATE TYPE dbo.PlotType AS TABLE (
	x NUMERIC(18,6) NOT NULL
    ,y NUMERIC(18,6) NOT NULL
)