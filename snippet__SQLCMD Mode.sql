/*
	SQLCMD Mode
*/

-->> NOTE: THIS SCRIPT MUST BE RUN IN SQLCMD MODE INSIDE SQL SERVER MANAGEMENT STUDIO. <<--
:on error exit


:setvar SqlSamplesDatabasePath   "C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\"

IF '$(SqlSamplesSourceDataPath)' IS NULL OR '$(SqlSamplesSourceDataPath)' = ''
BEGIN
	RAISERROR(N'The variable SqlSamplesSourceDataPath must be defined.', 16, 127) WITH NOWAIT
	RETURN
END;

