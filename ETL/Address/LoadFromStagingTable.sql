USE Address
GO

SELECT *
FROM Crm.City

SELECT *
FROM Staging.Cities 


-- TimeZone
DROP TABLE IF EXISTS Crm.TimeZone
GO

CREATE TABLE Crm.TimeZone (
	TimeZoneId int PRIMARY KEY IDENTITY(1, 1)
	,TimeZoneName nvarchar(100) NOT NULL UNIQUE
)
GO

INSERT INTO Crm.TimeZone (
	TimeZoneName
)
SELECT DISTINCT 
	l.time_zone
FROM Staging.Cities l

-- Locale
IF EXISTS ( SELECT 1 FROM Crm.Locale )
	TRUNCATE TABLE Crm.Locale
GO

INSERT INTO Crm.Locale (
	LocaleCode
)
SELECT DISTINCT
	l.locale_code
FROM Staging.Cities l



-- Subdivision Level

DROP TABLE IF EXISTS Crm.SubDivisionLevel
GO


CREATE TABLE Crm.SubDivisionLevel (
	SubDivisionLevelId int PRIMARY KEY IDENTITY(1, 1)
	,SubDivisionLevel tinyint NOT NULL 
)
GO

INSERT INTO Crm.SubDivisionLevel ( SubDivisionLevel )
VALUES
	(1)
	,(2)
GO


-- Subdivision

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

-- Level 1
INSERT INTO Crm.SubDivision ( 
	IsoCode
	,SubDivisionName
	,SubDivisionLevelId
)
SELECT DISTINCT 
	l.subdivision_1_iso_code
	,l.subdivision_1_name
	,sdLevel.SubDivisionLevelId
FROM Staging.Cities l
OUTER APPLY (
	SELECT SubDivisionLevelId
	FROM Crm.SubDivisionLevel
	WHERE
		SubDivisionLevel = 1
) sdLevel


-- Level 2
INSERT INTO Crm.SubDivision ( 
	IsoCode
	,SubDivisionName
	,SubDivisionLevelId
)
SELECT DISTINCT 
	l.subdivision_2_iso_code
	,l.subdivision_2_name
	,sdLevel.SubDivisionLevelId
FROM Staging.Cities l
OUTER APPLY (
	SELECT SubDivisionLevelId
	FROM Crm.SubDivisionLevel
	WHERE
		SubDivisionLevel = 2
) sdLevel



-- Continent
DROP TABLE IF EXISTS Crm.Continent
GO

CREATE TABLE Crm.Continent (
	ContinentId int PRIMARY KEY IDENTITY(1, 1)
	,ContinentCode varchar(2) NOT NULL 
	,ContinentName varchar(15)
)
INSERT INTO Crm.Continent (
	ContinentCode
	,ContinentName
)
SELECT DISTINCT 
	l.continent_code
	,l.continent_name
FROM Staging.Cities l

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

INSERT INTO Crm.Country (
	CountryIsoCode
	,CountryName
	,ContinentId
	,IsInEuropeanUnion
)
SELECT DISTINCT 
		l.country_iso_code
		,l.country_name
		,con.ContinentId
		,CAST(l.is_in_european_union AS bit)
FROM Staging.Cities l
LEFT JOIN Crm.Continent con ON l.continent_code = con.ContinentCode	
								AND l.continent_name = con.ContinentName


DROP TABLE IF EXISTS Crm.MetroCode
GO

CREATE TABLE Crm.MetroCode (
	MetroCodeId int PRIMARY KEY IDENTITY(1, 1)
	,MetroCodeName varchar(15) NOT NULL UNIQUE
)
GO

INSERT INTO Crm.MetroCode ( 
	MetroCodeName
)
SELECT DISTINCT metro_code
FROM Staging.Cities
WHERE
	NULLIF(TRIM(metro_code), '') IS NOT NULL 
GO


-- City 



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

INSERT INTO Crm.City (
	CityName
	,TimeZoneId
	,CountryId
)
SELECT DISTINCT 
	l.city_name
	,tz.TimeZoneId
	,c.CountryId
FROM Staging.Cities l
LEFT JOIN Crm.TimeZone tz ON l.time_zone = tz.TimeZoneName
LEFT JOIN Crm.Country c ON l.country_iso_code = c.CountryId
							AND l.country_name = c.CountryName

-- TODO: Check for null countries 
-- TODO: One metro code per city? 1<>1

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



;WITH c_City AS (
	SELECT
		c.CityId
		,c.CityName
		,country.CountryIsoCode
		,country.CountryName
		,con.ContinentCode
		,con.ContinentName
	FROM Crm.City c
	JOIN Crm.Country country ON c.CountryId = country.CountryId
	JOIN Crm.Continent con ON country.ContinentId = con.ContinentId

)

INSERT INTO Crm.CityMetroCode (
	CityId
	,MetroCodeId
)
SELECT DISTINCT
	c.CityId
	,mc.MetroCodeId
FROM Staging.Cities l
LEFT JOIN c_City c ON c.CityName = l.city_name
						AND c.ContinentCode = l.continent_code
						AND c.ContinentName = l.continent_name
						AND c.CountryIsoCode = l.country_iso_code
						AND c.CountryName = l.country_name
LEFT JOIN Crm.MetroCode mc ON l.metro_code = mc.MetroCodeName
GO

SELECT DISTINCT 
	l.city_name
	,l.locale_code
	,COUNT(*) 
FROM Staging.Cities l
GROUP BY
	l.locale_code
	,l.city_name
ORDER BY
	COUNT(*) DESC









-- 46 name
--2 code 

;WITH c AS (
	SELECT TOP 10
		--MAX(LEN(l.city))
		l.city_name
		,l.metro_code
		,l.country_iso_code
		,COUNT(*) AS RowCnt
	FROM Staging.Cities l
	WHERE
		NULLIF(TRIM(l.metro_code), '') IS NOT NULL 
	GROUP BY
		l.city_name
		,l.metro_code
		,l.country_iso_code
	HAVING 
		COUNT(*) > 1
	ORDER BY
		COUNT(*) DESC
)

SELECT *
FROM c 
JOIN Staging.Cities l ON c.metro_code = l.metro_code
											AND c.city_name = l.city_name
ORDER BY
	c.city_name
	,c.metro_code

SELECT
	l.city_name
	,l.country_iso_code
	,l.metro_code
	,COUNT(*) AS RowCnt
FROM Staging.Cities l
GROUP BY
	l.city_name
	,l.country_iso_code
	,l.metro_code
HAVING 
	COUNT(*) > 1
ORDER BY
	RowCnt DESC

SELECT *
FROM Staging.Cities l
WHERE
	l.city_name = '"Sao Paulo"'
	AND l.country_iso_code = 'BR'



SELECT MAX(LEN(metro_code))
FROM Staging.Cities l
	