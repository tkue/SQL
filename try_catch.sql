BEGIN TRY
	BEGIN TRANSACTION



	COMMIT TRANSACTION;
	PRINT CHAR(10) + '*** DONE ***';
END TRY
BEGIN CATCH

    IF (@@TRANCOUNT > 0)
    	ROLLBACK TRANSACTION;

    PRINT CHAR(10) + '*** UPDATE FAILED ***';

    SELECT
         ERROR_NUMBER() AS ErrorNumber
        ,ERROR_SEVERITY() AS ErrorSeverity
        ,ERROR_STATE() AS ErrorState
        ,ERROR_PROCEDURE() AS ErrorProcedure
        ,ERROR_LINE() AS ErrorLine
        ,ERROR_MESSAGE() AS ErrorMessage;
END CATCH




BEGIN TRY
    BEGIN TRANSACTION



    COMMIT TRANSACTION;
    PRINT CHAR(10) + '*** DONE ***';
END TRY
BEGIN CATCH

    IF (@@TRANCOUNT > 0)
        ROLLBACK TRANSACTION;

    PRINT CHAR(10) + '*** UPDATE FAILED ***';

    PRINT CHAR(10);
    PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS nvarchar);
    PRINT 'Error Severity: ' + CAST(ERROR_SEVERITY() AS nvarchar);
    PRINT 'Error State: ' + CAST (ERROR_STATE() AS nvarchar);
    PRINT 'Error Procedure: ' + CAST(ERROR_PROCEDURE AS varchar);
    PRINT 'Error Line: ' + CAST(ERROR_LINE() AS nvarchar);
    PRINT 'Error Message: ' + CAST(ERROR_MESSAGE() AS nvarchar);
END CATCH



PRINT CHAR(10);
PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS varchar);
PRINT 'Error Severity: ' + CAST(ERROR_SEVERITY() AS varchar);
PRINT 'Error State: ' + CAST (ERROR_STATE() AS varchar);
PRINT 'Error Procedure: ' + CAST(ERROR_PROCEDURE AS varchar);
PRINT 'Error Line: ' + CAST(ERROR_LINE() AS varchar);
PRINT 'Error Message: ' + CAST(ERROR_MESSAGE() AS varchar);
