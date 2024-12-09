USE NYCTaxi_Sample
GO

/*
	Splits data into specified part 

	Drops tables and inserts data into them
		nyctaxi_sample_training
		nyctaxi_sample_testing
*/
EXEC [dbo].[PyTrainTestSplit] 60
GO

-- Create model - SciKit
DECLARE @model VARBINARY(MAX);
EXEC PyTrainScikit @model OUTPUT;
INSERT INTO nyc_taxi_models (name, model) VALUES('SciKit_model', @model);
GO

-- Create model - RevoScalePy
DECLARE @model VARBINARY(MAX);
EXEC TrainTipPredictionModelRxPy @model OUTPUT;
INSERT INTO nyc_taxi_models (name, model) VALUES('revoscalepy_model', @model);

