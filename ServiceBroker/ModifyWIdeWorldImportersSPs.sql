
USE WideWorldImporters
GO

EXEC DataLoadSimulation.Configuration_ApplyDataLoadSimulationProcedures;
GO

ALTER PROCEDURE DataLoadSimulation.DailyProcessToCreateHistory
@StartDate date,
@EndDate date,
@AverageNumberOfCustomerOrdersPerDay int,
@SaturdayPercentageOfNormalWorkDay int,
@SundayPercentageOfNormalWorkDay int,
@UpdateCustomFields bit,
@IsSilentMode bit,
@AreDatesPrinted bit
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CurrentDateTime datetime2(7) = @StartDate;
    DECLARE @EndOfTime datetime2(7) =  '99991231 23:59:59.9999999';
    DECLARE @StartingWhen datetime;
    DECLARE @NumberOfCustomerOrders int;
    DECLARE @IsWeekday bit;
    DECLARE @IsSaturday bit;
    DECLARE @IsSunday bit;
    DECLARE @IsMonday bit;
    DECLARE @Weekday int;
    DECLARE @IsStaffOnly bit;

    SET DATEFIRST 7;  -- Week begins on Sunday

    EXEC DataLoadSimulation.DeactivateTemporalTablesBeforeDataLoad;

    WHILE @CurrentDateTime <= @EndDate
    BEGIN
        IF @AreDatesPrinted <> 0 OR @IsSilentMode = 0
        BEGIN
            PRINT  SUBSTRING(DATENAME(weekday, @CurrentDateTime), 1,3) + N' ' + CONVERT(nvarchar(20), @CurrentDateTime, 107);
            SELECT SUBSTRING(DATENAME(weekday, @CurrentDateTime), 1,3) + N' ' + CONVERT(nvarchar(20), @CurrentDateTime, 107);
            PRINT N' ';
        END;

      -- Calculate the days of the week - different processing happens on each day
        SET @Weekday = DATEPART(weekday, @CurrentDateTime);
        SET @IsSaturday = 0;
        SET @IsSunday = 0;
        SET @IsMonday = 0;
        SET @IsWeekday = 1;

        IF @Weekday = 7
        BEGIN
            SET @IsSaturday = 1;
            SET @IsWeekday = 0;
        END;
        IF @Weekday = 1
        BEGIN
            SET @IsSunday = 1;
            SET @IsWeekday = 0;
        END;
        IF @Weekday = 2 SET @IsMonday = 1;

    -- Purchase orders
        IF @IsWeekday <> 0
        BEGIN
            -- Start receiving purchase orders at 7AM on weekdays
            SET @StartingWhen = DATEADD(hour, 7, @CurrentDateTime);
            EXEC DataLoadSimulation.ReceivePurchaseOrders @CurrentDateTime, @StartingWhen, @EndOfTime, @IsSilentMode;
        END;

    -- Password changes
        SET @StartingWhen = DATEADD(hour, 8, @CurrentDateTime);
        EXEC DataLoadSimulation.ChangePasswords @CurrentDateTime, @StartingWhen, @EndOfTime, @IsSilentMode;

    -- Activate new website users
        SET @StartingWhen = DATEADD(minute, 10, DATEADD(hour, 8, @CurrentDateTime));
        EXEC DataLoadSimulation.ActivateWebsiteLogons @CurrentDateTime, @StartingWhen, @EndOfTime, @IsSilentMode;

    -- Payments to suppliers
        IF DATEPART(weekday, @CurrentDateTime) = 2
        BEGIN
            SET @StartingWhen = DATEADD(hour, 9, @CurrentDateTime); -- Suppliers are paid on Monday mornings
            EXEC DataLoadSimulation.PaySuppliers @CurrentDateTime, @StartingWhen, @EndOfTime, @IsSilentMode;
        END;

    -- Customer orders received
        SET @StartingWhen = DATEADD(hour, 10, @CurrentDateTime);
        SET @NumberOfCustomerOrders = @AverageNumberOfCustomerOrdersPerDay / 2
                                    + CEILING(RAND() * @AverageNumberOfCustomerOrdersPerDay);
        SET @NumberOfCustomerOrders = CASE DATEPART(weekday, @CurrentDateTime)
                                           WHEN 7
                                           THEN FLOOR(@NumberOfCustomerOrders * @SaturdayPercentageOfNormalWorkDay / 100)
                                           WHEN 1
                                           THEN FLOOR(@NumberOfCustomerOrders * @SundayPercentageOfNormalWorkDay / 100)
                                           ELSE @NumberOfCustomerOrders
                                      END;
		SET @NumberOfCustomerOrders = FLOOR(@NumberOfCustomerOrders * CASE WHEN YEAR(@StartingWhen) = 2013 THEN 1.0
		                                                                   WHEN YEAR(@StartingWhen) = 2014 THEN 1.12
																		   WHEN YEAR(@StartingWhen) = 2015 THEN 1.21
																		   WHEN YEAR(@StartingWhen) = 2016 THEN 1.23
																		   ELSE 1.26
																	  END);
       EXEC DataLoadSimulation.CreateCustomerOrders @CurrentDateTime, @StartingWhen, @EndOfTime, @NumberOfCustomerOrders, @IsSilentMode;

    -- Pick any customer orders that can be picked
        SET @StartingWhen = DATEADD(hour, 11, @CurrentDateTime);
        EXEC DataLoadSimulation.PickStockForCustomerOrders @CurrentDateTime, @StartingWhen, @EndOfTime, @IsSilentMode;

    -- Process any payments from customers
        IF @Weekday <> 0
        BEGIN
            SET @StartingWhen = DATEADD(minute, 30, DATEADD(hour, 11, @CurrentDateTime));
            EXEC DataLoadSimulation.ProcessCustomerPayments @CurrentDateTime, @StartingWhen, @EndOfTime, @IsSilentMode;
        END;

    -- Invoice orders that have been fully picked
        SET @StartingWhen = DATEADD(hour, 12, @CurrentDateTime);
        EXEC DataLoadSimulation.InvoicePickedOrders @CurrentDateTime, @StartingWhen, @EndOfTime, @IsSilentMode;

    -- Place supplier orders
        IF @Weekday <> 0
        BEGIN
            SET @StartingWhen = DATEADD(hour, 13, @CurrentDateTime);
            EXEC DataLoadSimulation.PlaceSupplierOrders @CurrentDateTime, @StartingWhen, @EndOfTime, @IsSilentMode;
        END;

    -- End of quarter stock take
        IF (MONTH(@CurrentDateTime) = 1 AND DAY(@CurrentDateTime) = 31)
            OR (MONTH(@CurrentDateTime) = 4 AND DAY(@CurrentDateTime) = 30)
            OR (MONTH(@CurrentDateTime) = 7 AND DAY(@CurrentDateTime) = 31)
            OR (MONTH(@CurrentDateTime) = 10 AND DAY(@CurrentDateTime) = 31)
        BEGIN
            SET @StartingWhen = DATEADD(hour, 14, @CurrentDateTime);
            EXEC DataLoadSimulation.PerformStocktake @CurrentDateTime, @StartingWhen, @EndOfTime, @IsSilentMode;
        END;

    -- Record invoice deliveries
        SET @StartingWhen = DATEADD(hour, 7, @CurrentDateTime);
        EXEC DataLoadSimulation.RecordInvoiceDeliveries @CurrentDateTime, @StartingWhen, @EndOfTime, @IsSilentMode;

    -- Add customers
        IF @Weekday <> 0
        BEGIN
            SET @StartingWhen = DATEADD(hour, 15, @CurrentDateTime);
            EXEC DataLoadSimulation.AddCustomers @CurrentDateTime, @StartingWhen, @EndOfTime, @IsSilentMode;
        END;

     -- Add stock items
        SET @StartingWhen = DATEADD(hour, 16, @CurrentDateTime);
        EXEC DataLoadSimulation.AddStockItems @CurrentDateTime, @StartingWhen, @EndOfTime, @IsSilentMode;

    -- Add special deals
        SET @StartingWhen = DATEADD(hour, 16, @CurrentDateTime);
        EXEC DataLoadSimulation.AddSpecialDeals @CurrentDateTime, @StartingWhen, @EndOfTime, @IsSilentMode;

     -- Temporal changes
        SET @StartingWhen = DATEADD(hour, 16, @CurrentDateTime);
        EXEC DataLoadSimulation.MakeTemporalChanges @CurrentDateTime, @StartingWhen, @EndOfTime, @IsSilentMode;

    -- Record delivery van temperatures
        IF @CurrentDateTime >= '20160101'
        BEGIN
            SET @StartingWhen = DATEADD(hour, 7, @CurrentDateTime);
            EXEC DataLoadSimulation.RecordDeliveryVanTemperatures 300, 2, @CurrentDateTime, @StartingWhen, @IsSilentMode;
        END;

    -- Record cold room temperatures
        IF @CurrentDateTime >= '20151220'
        BEGIN
            EXEC DataLoadSimulation.RecordColdRoomTemperatures 30, 4, @CurrentDateTime, @EndOfTime, @IsSilentMode;
        END;

        IF @IsSilentMode = 0
        BEGIN
            PRINT N' ';
        END;

        SET @CurrentDateTime = DATEADD(day, 1, @CurrentDateTime);
    END; -- of processing each day

    IF @UpdateCustomFields <> 0
    BEGIN
        EXEC DataLoadSimulation.UpdateCustomFields @EndDate;
    END;

    EXEC DataLoadSimulation.ReactivateTemporalTablesAfterDataLoad;

    EXEC Sequences.ReseedAllSequences;

    -- Ensure RLS is applied
    EXEC [Application].Configuration_ApplyRowLevelSecurity
END;
GO


CREATE OR ALTER PROCEDURE dbo.LoadData
AS
SET NOCOUNT ON;

EXECUTE DataLoadSimulation.PopulateDataToCurrentDate
        @AverageNumberOfCustomerOrdersPerDay = 100,
        @SaturdayPercentageOfNormalWorkDay = 50,
        @SundayPercentageOfNormalWorkDay = 0,
        @IsSilentMode = 1,
        @AreDatesPrinted = 1;
GO
