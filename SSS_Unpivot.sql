-- Source 
-- http://www.sqlservercentral.com/articles/Stairway+Series/125504/


USE tempdb;
GO
IF object_id('PhoneNumbers') IS NOT NULL DROP TABLE PhoneNumbers;
GO
CREATE TABLE PhoneNumbers (
	PersonID int, 
	HomePhone varchar(12),
	CellPhone varchar(12), 
	Workphone varchar(12), 
	FaxNumber varchar(12));

INSERT INTO PhoneNumbers VALUES 
	(1,Null,'444-555-2931',Null,Null),
	(2,'444-555-1950','444-555-2931',Null, Null),
	(3,'444-555-1950', Null,'444-555-1324','444-555-2310'),
	(4,'444-555-1950','444-555-2931','444-555-1324',
        '444-555-1987');

-----------------------------------------------------------------------

SELECT * FROM PhoneNumbers

SELECT 
	PersonID
	,PhoneType
	,PhoneNumber
FROM (
	SELECT 
		PersonID
		,HomePhone
		,CellPhone
		,Workphone
		,FaxNumber
	FROM PhoneNumbers
) AS src
UNPIVOT (
	PhoneNumber FOR PhoneType IN 
	(HomePhone, CellPhone, WorkPhone, FaxNumber)
) AS unpvt

---------------------------------------------------------------------
-- Using Two UNPIVOT Operations
---------------------------------------------------------------------

IF object_id('CustPref') IS NOT NULL DROP TABLE CustPref;
GO
CREATE TABLE CustPref(CustID int identity, CustName varchar(20), 
             Pref1Type varchar(20),  Pref1Data varchar(100),
             Pref2Type varchar(20),  Pref2Data varchar(100),
			Pref3Type varchar(20),  Pref3Data varchar(100),
			 Pref4Type varchar(20),  Pref4Data varchar(100),
			 );
GO
INSERT INTO CustPref (CustName, Pref1Type, Pref1Data,
                                Pref2Type, Pref2Data, 
                                Pref3Type, Pref3Data,
                                Pref4Type, Pref4Data)
VALUES 
	('David Smith','Pool', 'Yes',
	              'Children', 'Yes',
				  'Bed', 'King',
				  'Pets', 'No'),
	('Randy Johnson','Vehicle', 'Convertible',
	              'PriceRange', '$$$',
				  null, null,
				  null, null),
	('Dr. John Fluke','Email', 'DrJ@Pain.com',
	              'Office Phone', '555-444-9845',
				  'Emergency Phone', '555-444-9846',
				  null,null);
GO

SELECT * FROM CustPref;

SELECT 
	CustId
	,CustName
	,PrefType
	,PrefValue
FROM (
	SELECT 
		CustID
		,CustName
		,Pref1Type
		,Pref1Data
		,Pref2Type
		,Pref2Data
		,Pref3Type
		,Pref3Data
		,Pref4Type
		,Pref4Data
	FROM CustPref
) pref
UNPIVOT (
	PrefValue FOR PrefValues IN
		(Pref1Data, Pref2Data, Pref3Data, Pref4Data)
) AS up1
UNPIVOT (
	PrefType FOR PrefTypes IN
		(Pref1Type, Pref2Type, Pref3Type, Pref4Type)
) AS up2
WHERE
	SUBSTRING(PrefValues,5,1) = SUBSTRING(PrefTypes,5,1)

-- Dynamically Build Query
DECLARE @ColNames varchar(1000);
SET @ColNames = '';
-- Get PrefValue Columns
SELECT @ColNames=stuff((
    SELECT DISTINCT ',' + QUOTENAME(COLUMN_NAME)
    FROM INFORMATION_SCHEMA.COLUMNS p2
    WHERE TABLE_NAME = 'CustPref'
	  AND COLUMN_NAME like 'Pref_Type'
    FOR XML PATH(''), TYPE).value('.', 'varchar(max)')
            ,1,1,'')
-- Get PrefType Columns
DECLARE @ColValues varchar(1000);
SET @ColValues = '';
SELECT @ColValues=stuff((
    SELECT DISTINCT ',' + QUOTENAME(COLUMN_NAME)
    FROM INFORMATION_SCHEMA.COLUMNS p2
    WHERE TABLE_NAME = 'CustPref'
	  AND COLUMN_NAME like 'Pref_Data'
    FOR XML PATH(''), TYPE).value('.', 'varchar(max)')
            ,1,1,'')
-- Generate UNPIVOT Statement
DECLARE @CMD nvarchar(2000);
SET @CMD = 'SELECT CustId, CustName, PrefType, PrefValue FROM ' + 
           '(SELECT CustID, CustName, ' + @ColNames + ',' + @ColValues + 
		   ' FROM CustPref) AS Perf UNPIVOT (PrefValue FOR PrefValues IN (' +  
		   @ColValues + ')) AS UP1 UNPIVOT (PrefType FOR PrefTypes IN (' + 
		   @ColNames + ')) AS UP2 WHERE ' + 
		   'substring(PrefValues,5,1) = substring(PrefTypes,5,1);'
-- Print UNPIVOT Command
PRINT @CMD
-- Execute UNPIVOT Command
execute sp_executesql @CMD