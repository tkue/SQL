/*
 === Extract XML structure automatically ===

 http://weblogs.sqlteam.com/peterl/archive/2009/03/05/Extract-XML-structure-automatically.aspx

Today I am going to write about how to extract the XML structure from a file. The basic idea is to bulk read the file from disk, place the content in an XML variable and traverse elements in the variable and ultimately output a resultset showing the structure of xml file.

I often use this to determine what kind of XML the file is by comparing the returned resultset with a lookup-table.
See comment in code to understand what happens 
*/

CREATE PROCEDURE dbo.uspGetFileStructureXML
(
    @FileName NVARCHAR(256)
)
AS

-- Prevent unwanted resultsets back to client
SET NOCOUNT ON

-- Initialize command string, return code and file content
DECLARE @cmd NVARCHAR(MAX),
        @rc INT,
        @Data XML

-- Make sure accents are preserved if encoding is missing by adding encoding information UTF-8
SET     @cmd = 'SELECT  @Content = CASE
                                       WHEN BulkColumn LIKE ''%xml version="1.0" encoding="UTF%'' THEN BulkColumn
                                       ELSE ''<?xml version="1.0" encoding="UTF-8"?>'' + BulkColumn
                                   END
                FROM    OPENROWSET(BULK ' + QUOTENAME(@FileName, '''') + ', SINGLE_CLOB) AS f'

-- Read the file
EXEC    @rc = sp_executesql @cmd, N'@Content XML OUTPUT', @Content = @Data OUTPUT

-- What? An error?
IF @@ERROR <> 0 OR @rc <> 0
        BEGIN
                SET     @cmd = CHAR(10) + ERROR_MESSAGE()
                RAISERROR('The file %s was not read.%s', 18, 1, @FileName, @cmd)
                RETURN  -100
        END

-- Create a staging table holding element names
CREATE TABLE #Nodes
             (
                 NodeLevel INT NOT NULL,
                 RootName NVARCHAR(MAX) NOT NULL,
                 ElementName NVARCHAR(MAX) NOT NULL
             )

-- Initialize some control variables
DECLARE     @NodeLevel INT

-- Begin at root level
SET     @NodeLevel = 1

-- Iterate all levels until no more levels found
WHILE @@ROWCOUNT > 0
    BEGIN
            -- Build a dynamic SQL string for each level
            SELECT   @cmd = 'SELECT  DISTINCT
                                     ' + STR(@NodeLevel) + ', 
                                     t.n.value(''local-name(..)[1]'', ''VARCHAR(MAX)'') AS RootName,
                                     t.n.value(''local-name(.)[1]'', ''VARCHAR(MAX)'') AS ElementName
                             FROM    @n.nodes(''' + REPLICATE('/*', @NodeLevel) + ''') AS t(n)',
                     @NodeLevel = @NodeLevel + 1

            -- Store the result in the staging table
            INSERT  #Nodes
                    (
                        NodeLevel,
                        RootName,
                        ElementName
                    )
            EXEC    sp_executesql @cmd, N'@n XML', @n = @Data
    END

-- Reveal the XML file structure
SELECT    NodeLevel,
          RootName,
          ElementName
FROM      #Nodes
ORDER BY  NodeLevel,
          RootName

-- Clean up
DROP TABLE  #Nodes
GO

If you already have the XML data in a variable, the stored procedure can be simplified as this following code


CREATE PROCEDURE dbo.uspGetVariableStructureXML
(
    @Data XML
)
AS

-- Prevent unwanted resultsets back to client
SET NOCOUNT ON

-- Initialize command string, return code and file content
DECLARE @cmd NVARCHAR(MAX),
        @rc INT 

-- Create a staging table holding element names
CREATE TABLE #Nodes
             (
                 NodeLevel INT NOT NULL,
                 RootName NVARCHAR(MAX) NOT NULL,
                 ElementName NVARCHAR(MAX) NOT NULL 
             )

-- Initialize some control variables
DECLARE     @NodeLevel INT

-- Begin at root level
SET     @NodeLevel = 1

-- Iterate all levels until no more levels found
WHILE @@ROWCOUNT > 0
    BEGIN
            -- Build a dynamic SQL string for each level
            SELECT   @cmd = 'SELECT  DISTINCT
                                     ' + STR(@NodeLevel) + ', 
                                     t.n.value(''local-name(..)[1]'', ''VARCHAR(MAX)'') AS RootName,
                                     t.n.value(''local-name(.)[1]'', ''VARCHAR(MAX)'') AS ElementName
                             FROM    @n.nodes(''' + REPLICATE('/*', @NodeLevel) + ''') AS t(n)',
                     @NodeLevel = @NodeLevel + 1

            -- Store the result in the staging table
            INSERT  #Nodes
                    (
                        NodeLevel,
                        RootName,
                        ElementName
                    )
            EXEC    sp_executesql @cmd, N'@n XML', @n = @Data
    END

-- Reveal the XML file structure
SELECT    NodeLevel,
          RootName,
          ElementName
FROM      #Nodes
ORDER BY  NodeLevel,
          RootName

-- Clean up
DROP TABLE  #Nodes
GO