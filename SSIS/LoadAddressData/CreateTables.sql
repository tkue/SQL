USE AddressEtl
GO


DECLARE 
	@sql nvarchar(max)

DECLARE cur CURSOR FAST_FORWARD
FOR
SELECT 
	   SqlStmt = 'ALTER TABLE ' + QUOTENAME(CONVERT(SYSNAME,SCHEMA_NAME(O1.SCHEMA_ID))) + '.' + QUOTENAME(CONVERT(SYSNAME,O2.NAME)) + ' DROP CONSTRAINT ' + QUOTENAME(CONVERT(SYSNAME,OBJECT_NAME(F.OBJECT_ID)))
FROM   SYS.ALL_OBJECTS O1, 
       SYS.ALL_OBJECTS O2, 
       SYS.ALL_COLUMNS C1, 
       SYS.ALL_COLUMNS C2, 
       SYS.FOREIGN_KEYS F 
       INNER JOIN SYS.FOREIGN_KEY_COLUMNS K 
         ON (K.CONSTRAINT_OBJECT_ID = F.OBJECT_ID) 
       INNER JOIN SYS.INDEXES I 
         ON (F.REFERENCED_OBJECT_ID = I.OBJECT_ID 
             AND F.KEY_INDEX_ID = I.INDEX_ID) 
WHERE  O1.OBJECT_ID = F.REFERENCED_OBJECT_ID 
       AND O2.OBJECT_ID = F.PARENT_OBJECT_ID 
       AND C1.OBJECT_ID = F.REFERENCED_OBJECT_ID 
       AND C2.OBJECT_ID = F.PARENT_OBJECT_ID 
       AND C1.COLUMN_ID = K.REFERENCED_COLUMN_ID
       AND C2.COLUMN_ID = K.PARENT_COLUMN_ID

OPEN cur

FETCH NEXT
FROM cur
INTO 
	@sql

WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC (@sql)

	FETCH NEXT
	FROM cur
	INTO 
		@sql
END 
CLOSE cur
DEALLOCATE cur
GO


IF NOT EXISTS ( SELECT 1 FROM sys.schemas WHERE name = 'Crm' )
	EXEC ('CREATE SCHEMA Crm AUTHORIZATION dbo')
GO

IF NOT EXISTS ( SELECT 1 FROM sys.schemas WHERE name = 'Staging' )
	EXEC ('CREATE SCHEMA Staging AUTHORIZATION dbo')
GO


DROP TABLE IF EXISTS Staging.Cities
GO

CREATE TABLE Staging.Cities
(
	  [geoname_id] VARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
	, [locale_code] VARCHAR(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
	, [continent_code] VARCHAR(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
	, [continent_name] VARCHAR(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
	, [country_iso_code] VARCHAR(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
	, [country_name] VARCHAR(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
	, [subdivision_1_iso_code] VARCHAR(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
	, [subdivision_1_name] VARCHAR(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
	, [subdivision_2_iso_code] VARCHAR(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
	, [subdivision_2_name] VARCHAR(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
	, [city_name] VARCHAR(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
	, [metro_code] VARCHAR(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
	, [time_zone] VARCHAR(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
	, [is_in_european_union] VARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
)
GO

INSERT INTO Staging.Cities
SELECT *
FROM Address.dbo.[GeoLite2-City-Locations-en]



-- TimeZone
DROP TABLE IF EXISTS Crm.TimeZone
GO

CREATE TABLE Crm.TimeZone (
	TimeZoneId int PRIMARY KEY IDENTITY(1, 1)
	,TimeZoneName nvarchar(100) NOT NULL UNIQUE
)
GO

-- Locale

DROP TABLE IF EXISTS Crm.Locale
GO

CREATE TABLE Crm.Locale (
	LocaleId int PRIMARY KEY IDENTITY(1, 1)
	,LocaleCode varchar(5) UNIQUE NOT NULL 
)
GO


-- Subdivision Level

DROP TABLE IF EXISTS Crm.SubDivisionLevel
GO


CREATE TABLE Crm.SubDivisionLevel (
	SubDivisionLevelId int PRIMARY KEY IDENTITY(1, 1)
	,SubDivisionLevel tinyint NOT NULL 
)
GO

DROP TABLE IF EXISTS Crm.SubDivision
GO

CREATE TABLE Crm.SubDivision (
	SubDivisionId int PRIMARY KEY IDENTITY(1, 1)
	,IsoCode varchar(20) NOT NULL UNIQUE
	,SubDivisionName nvarchar(70) NOT NULL UNIQUE
	,SubDivisionLevelId int NOT NULL 
		FOREIGN KEY REFERENCES Crm.SubDivisionLevel (SubDivisionLevelId) 
)
GO


-- Continent
DROP TABLE IF EXISTS Crm.Continent
GO

CREATE TABLE Crm.Continent (
	ContinentId int PRIMARY KEY IDENTITY(1, 1)
	,ContinentCode varchar(2) NOT NULL 
	,ContinentName varchar(15)
)
GO


-- Country 
DROP TABLE IF EXISTS Crm.Country
GO

CREATE TABLE Crm.Country (
	CountryId int PRIMARY KEY IDENTITY(1, 1)
	,CountryIsoCode char(2)
	,CountryName nvarchar(50)
	,ContinentId int NOT NULL
		FOREIGN KEY REFERENCES Crm.Continent (ContinentId)
	,IsInEuropeanUnion bit 
)



DROP TABLE IF EXISTS Crm.MetroCode
GO

CREATE TABLE Crm.MetroCode (
	MetroCodeId int PRIMARY KEY IDENTITY(1, 1)
	,MetroCodeName varchar(15) NOT NULL UNIQUE
)
GO

DROP TABLE IF EXISTS Crm.City
GO

CREATE TABLE Crm.City (
	CityId int PRIMARY KEY IDENTITY(1, 1)
	,CityName nvarchar(70) NOT NULL 
	--,MetroCodeId int NULL
	--	FOREIGN KEY REFERENCES Crm.MetroCode (MetroCodeId)
	,TimeZoneId int NOT NULL
		FOREIGN KEY REFERENCES Crm.TimeZone (TimeZoneId)
	,CountryId int NOT NULL 
		FOREIGN KEY REFERENCES Crm.Country (CountryId)
	,CONSTRAINT uc_CityCountry UNIQUE (CityName, CountryId)
)
GO

DROP TABLE IF EXISTS Crm.CityMetroCode
GO

CREATE TABLE Crm.CityMetroCode (
	CityMetroCodeId int PRIMARY KEY IDENTITY(1, 1)
	,CityId int NOT NULL 
		FOREIGN KEY REFERENCES Crm.City (CityId)
	,MetroCodeId int NOT NULL 
		FOREIGN KEY REFERENCEs Crm.MetroCode (MetroCodeId)
	,CONSTRAINT uc_CityIdMetroCodeId UNIQUE (CityId, MetroCodeId)
)
GO