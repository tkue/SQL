CREATE PROCEDURE dbo.ParseXMLtoTable

     @strXML AS XML
    ,@rootnode NVARCHAR(255)

AS
BEGIN

    SET NOCOUNT ON

    DECLARE
        @strText AS NVARCHAR(MAX)
       ,@idoc INT
       ,@id INT
       ,@parentid INT

    IF OBJECT_ID('tempdb..#ChildList') IS NOT NULL
    DROP TABLE #ChildList

    CREATE TABLE #ChildList (
        [RowNum] INT IDENTITY(1,1) NOT NULL,
        [parentid] INT NULL,
        [id] INT NULL,
        PRIMARY KEY (RowNum))
        

    IF OBJECT_ID('tempdb..#NodeList') IS NOT NULL
    DROP TABLE #NodeList

    CREATE TABLE #NodeList (
        [RowNum] INT NOT NULL,
        [id] INT NULL,
        [parentid] INT NULL,
        [nodetype] INT NULL,
        [localname] NVARCHAR(MAX) NULL,
        [text] NVARCHAR(MAX) NULL,
        PRIMARY KEY (RowNum))

    SET @id = 1
    SET @parentid = NULL


    /* Get rid of tabs and extra spaces */

    SET @strText = CAST(@strXML AS NVARCHAR(MAX))

    SET @strText = 
    REPLACE(
        REPLACE(
            REPLACE(
                REPLACE(
                    @strText
                ,'  ',' '+CHAR(7))
            ,CHAR(7)+' ','')
        ,CHAR(7),'')
    ,CHAR(9),'    ')
        
    SET @strXML = CONVERT(XML,@strText)


    /* Validate the XML */
    
    EXEC sp_xml_preparedocument @idoc OUTPUT, @strXML
    
    
    /* Parse the XML data */

    ;WITH cteChildren (parentid, id)
    AS (
        SELECT 
             CAST(p1.parentid AS INT) AS parentid
            ,CAST(p1.id AS INT) AS id
        FROM
            OPENXML (@idoc,@rootnode,2) AS p1
        UNION ALL
        SELECT 
             CAST(p2.parentid AS INT) AS parentid
            ,CAST(p2.id AS INT) AS id
        FROM
            OPENXML (@idoc,@rootnode,2) AS p2
        INNER JOIN 
            cteChildren AS cte
            ON cte.id = p2.ParentID
        WHERE
            p2.parentid = @parentid         
        )
        INSERT INTO #ChildList
        SELECT 
            parentid
           ,id 
        FROM cteChildren
        
            
    INSERT INTO #NodeList
    SELECT 
         #ChildList.RowNum
        ,xmllist.id 
        ,xmllist.parentid
        ,xmllist.nodetype
        ,xmllist.localname
        ,CAST(xmllist.[text] AS NVARCHAR(MAX)) AS [text]
    FROM #ChildList
    INNER JOIN 
        OPENXML (@idoc,@rootnode,2) AS xmllist
        ON #ChildList.id = xmllist.id  
    WHERE
        #ChildList.RowNum > 0
        
        
    /* Display the results */

    IF OBJECT_ID('dbo.XML_Nodes') IS NOT NULL
    DROP TABLE dbo.XML_Nodes
    
                    
    ;WITH RecursiveNodes(RowNum,id,parentid,nodepath,localname,[text],nodetype)
    AS (
        SELECT
             #NodeList.RowNum
            ,#NodeList.id
            ,#NodeList.parentid
            ,CAST('/' + REPLACE(REPLACE(REPLACE(REPLACE(#NodeList.localname,'&',''),'?',''),' ',''),'.','') AS NVARCHAR(255)) AS nodepath
            ,#NodeList.localname
            ,CAST(#NodeList.[text] AS NVARCHAR(MAX)) AS [text]
            ,0 AS nodetype
        FROM #ChildList
        INNER JOIN 
            #NodeList
            ON #ChildList.id = #NodeList.id 
        WHERE
            #NodeList.parentid IS NULL
            AND #ChildList.RowNum > 0
            AND #NodeList.RowNum > 0
            
        UNION ALL

        SELECT
             n.RowNum
            ,n.id
            ,n.parentid
            ,CAST(r.nodepath + '/'+ REPLACE(REPLACE(REPLACE(REPLACE(n.localname,'&',''),'?',''),' ',''),'.','') AS NVARCHAR(255)) AS nodepath
            ,n.localname
            ,n.[text]
            ,n.nodetype
        FROM #NodeList AS n
        INNER JOIN 
            RecursiveNodes AS r
            ON n.parentid = r.id
        WHERE
            n.RowNum > 0
            AND r.RowNum > 0
            AND n.parentid >= 0
      )
    SELECT
        ROW_NUMBER() OVER (ORDER BY Result.RowNum) AS RowNum
       ,Result.id
       ,Result.parentid
       ,Result.nodepath
       ,Result.nodetype
       ,Result.nodename
       ,Result.property
       ,Result.value
       ,Result.nodecontents
    INTO dbo.XML_Nodes
    FROM
        (
        SELECT
            rn.RowNum
           ,rn.id
           ,rn.parentid
           ,rn.nodepath
           ,(CASE
                WHEN rn.nodetype = 0 THEN 'Root'
                WHEN rn.nodetype = 1 THEN 'Node'
                WHEN rn.nodetype = 2 THEN 'Property'
                ELSE 'Data'
             END) AS nodetype
           ,(CASE
                WHEN rn.nodetype = 0 THEN rn.localname
                WHEN rn.nodetype = 1 THEN rn.localname
                WHEN rn.nodetype = 2 THEN (SELECT TOP(1) localname FROM RecursiveNodes WHERE id = rn.parentid)
                ELSE NULL
             END) AS nodename
           ,(CASE
                WHEN rn.nodetype = 2 THEN rn.localname
                ELSE NULL
             END) AS property
           ,(CASE
                WHEN rn.nodetype = 2 THEN (SELECT TOP(1) [text] FROM RecursiveNodes WHERE parentid = rn.id)
                ELSE NULL
             END) AS value         
           ,(CASE
                WHEN rn.nodetype = 1 THEN (SELECT TOP(1) [text] FROM RecursiveNodes WHERE parentid = rn.id)
                WHEN rn.nodetype = 2 THEN (SELECT TOP(1) [text] FROM RecursiveNodes WHERE parentid = rn.parentid and [text] is not null)
                ELSE NULL
             END) AS nodecontents    
        FROM
            RecursiveNodes AS rn
        WHERE
            rn.localname <> '#text'
        ) AS Result
    WHERE
        Result.id >= 0
        AND (Result.id = 0
            OR property IS NOT NULL
            OR value IS NOT NULL
            OR nodecontents IS NOT NULL)
            
    SELECT
        RowNum
       ,id
       ,parentid
       ,nodepath
       ,nodetype
       ,nodename
       ,property
       ,value
       ,nodecontents
    FROM
        dbo.XML_Nodes
            
END


    /***** Usage examples *****/


    EXEC dbo.ParseXMLtoTable
        '<AccountDetailsRsp AccountNum="1" AccountStatus="AccountStatus1">
        <PlayerInfo PlayerID="1" FirstName="FirstName1" LastName="LastName1">
        <AddressList>
        <PlayerAddress>
        <Address AddressType="primary" City="City1" State="State1" Zip="Zip1"/>
        <FutureUse>Example Text1</FutureUse>
        <Phone PhoneNumber="PhoneNumber1" PhoneType="Type1" />
        <Phone PhoneNumber="PhoneNumber2" PhoneType="Type2" />
        </PlayerAddress>
        <PlayerAddress>
        <Address AddressType="billing" City="City1" State="State1" Zip="Zip1"/>
        <FutureUse>Example Text2</FutureUse>
        <Phone PhoneNumber="PhoneNumber1" PhoneType="Type1" />
        <Phone PhoneNumber="PhoneNumber2" PhoneType="Type2" />
        </PlayerAddress>
        </AddressList>
        </PlayerInfo>
        </AccountDetailsRsp>'
        ,'AccountDetailsRsp'


    EXEC dbo.ParseXMLtoTable
        '<items>
            <item id="0001" type="Donut">
                <name>Cake</name>
                <ppu>0.55</ppu>
                    <batter id="1001">Regular</batter>
                    <batter id="1002">Chocolate</batter>
                    <batter id="1003">Blueberry</batter>
                <topping id="5001">None</topping>
                <topping id="5002">Glazed</topping>
                <topping id="5005">Sugar</topping>
                <topping id="5006">Sprinkles</topping>
                <topping id="5003">Chocolate</topping>
                <topping id="5004">Maple</topping>
            </item>
        </items>'
        ,'items'

