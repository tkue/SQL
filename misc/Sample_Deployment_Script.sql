DECLARE @RetVal INT


-- Run in validation mode and capture success/failure
EXEC @RetVal = usp_Merge_Location 'South', 'Corporate', 1, 'Validate'

-- If success, run in deployment mode
IF @RetVal = 1
BEGIN
	EXEC @RetVal = usp_Merge_Billing_Unit 'South', 'Corporate', 1, 'Deploy'
END
GO

DECLARE @RetVal INT

-- Run in validation mode and capture success/failure
EXEC @RetVal = usp_Merge_Location 'North', 'Corporate', 1, 'Validate'

-- If success, run in deployment mode
IF @RetVal = 1
BEGIN
	EXEC @RetVal = usp_Merge_Billing_Unit 'North', 'Corporate', 1, 'Deploy'
END
GO


IF EXISTS(SELECT 1 FROM sys.Procedures WHERE name = 'usp_Merge_Billing_Unit')
BEGIN
	DROP PROCEDURE usp_Merge_Billing_Unit
END