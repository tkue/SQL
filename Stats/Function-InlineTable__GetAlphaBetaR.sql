USE [Util]
GO

/****** Object:  UserDefinedFunction [Stat].[GetAlphaBetaR]    Script Date: 5/19/2019 9:17:35 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




-- https://www.red-gate.com/simple-talk/blogs/statistics-sql-simple-linear-regressions/
CREATE FUNCTION [Stat].[GetAlphaBetaR] (
	@Input dbo.PlotType READONLY
)
RETURNS TABLE AS RETURN
(
	SELECT 
		alpha, 
		beta, 
		rho,
		Minx AS xLineMin, 
		alpha + (beta * Minx) AS yLineMin, 
		Maxx AS xLineMax,  
		alpha + (beta * Maxx) AS yLineMax
	  FROM
		  (
		  SELECT 
			Maxx, Minx, Maxy, Miny,
			((Sy * Sxx) - (Sx * Sxy))
			/ ((N * (Sxx)) - (Sx * Sx)) AS alpha,
			((N * Sxy) - (Sx * Sy))
			/ ((N * Sxx) - (Sx * Sx)) AS beta,
			((N * Sxy) - (Sx * Sy))
			/ SQRT((((N * Sxx) - (Sx * Sx))
					* ((N * Syy - (Sy * Sy)))
				   )
				  ) AS rho
			FROM
			  (
			  SELECT 
				SUM([@Input].x) AS Sx, SUM([@Input].y) AS Sy,
				SUM([@Input].x * [@Input].x) AS Sxx,
				SUM([@Input].x * [@Input].y) AS Sxy,
				SUM([@Input].y * [@Input].y) AS Syy, 
				COUNT(*) AS N,
				MAX([@Input].x) AS Maxx, MIN([@Input].x) AS Minx,
				MAX([@Input].y) AS Maxy, MIN([@Input].y) AS Miny
				FROM @Input
			  ) sums
		  ) AlphaBetaRho
)
GO


