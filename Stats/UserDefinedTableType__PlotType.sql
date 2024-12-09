USE [Util]
GO

/****** Object:  UserDefinedTableType [dbo].[PlotType]    Script Date: 5/19/2019 9:22:46 PM ******/
CREATE TYPE [dbo].[PlotType] AS TABLE(
	[x] [numeric](18, 8) NOT NULL,
	[y] [numeric](18, 8) NOT NULL
)
GO


