/*
	BULK INSERT
*/


PRINT 'Loading [Person].[Address]';

BULK INSERT [Person].[Address] FROM '$(SqlSamplesSourceDataPath)Address.csv'
WITH (
    CHECK_CONSTRAINTS,
    CODEPAGE='ACP',
    DATAFILETYPE = 'widechar',
    FIELDTERMINATOR= '\t',
    ROWTERMINATOR = '\n',
    KEEPIDENTITY,
    TABLOCK
);


PRINT 'Loading [Person].[AddressType]';

BULK INSERT [Person].[AddressType] FROM '$(SqlSamplesSourceDataPath)AddressType.csv'
WITH (
    CHECK_CONSTRAINTS,
    CODEPAGE='ACP',
    DATAFILETYPE = 'char',
    FIELDTERMINATOR= '\t',
    ROWTERMINATOR = '\n',
    KEEPIDENTITY,
    TABLOCK
);


PRINT 'Loading [Person].[BusinessEntity]';

BULK INSERT [Person].[BusinessEntity] FROM '$(SqlSamplesSourceDataPath)BusinessEntity.csv'
WITH (
    CHECK_CONSTRAINTS,
    CODEPAGE='ACP',
    DATAFILETYPE='widechar',
    FIELDTERMINATOR='+|',
    ROWTERMINATOR='&|\n',
    KEEPIDENTITY,
    TABLOCK
);

