USE AddressEtl
GO

:r "C:\Users\tomku\Dropbox\bin\sql\SSIS\LoadAddressData\CreateAndInsertCityStagingData.sql"

SELECT *
FROM Staging.Cities

EXEC sp_rename 'dbo.[GeoLite2-City-Locations-en]', 'Staging.Cities'

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

SELECT *
FROM Staging.Cities