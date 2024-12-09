exec sp_executesql N'SELECT
clmns.name AS [Name],
clmns.column_id AS [ID],
clmns.is_nullable AS [Nullable],
clmns.is_computed AS [Computed],
CAST(ISNULL(cik.index_column_id, 0) AS bit) AS [InPrimaryKey],
clmns.is_ansi_padded AS [AnsiPaddingStatus],
CAST(clmns.is_rowguidcol AS bit) AS [RowGuidCol],
CAST(ISNULL(COLUMNPROPERTY(clmns.object_id, clmns.name, N''IsDeterministic''),0) AS bit) AS [IsDeterministic],
CAST(ISNULL(COLUMNPROPERTY(clmns.object_id, clmns.name, N''IsPrecise''),0) AS bit) AS [IsPrecise],
CAST(ISNULL(cc.is_persisted, 0) AS bit) AS [IsPersisted],
ISNULL(clmns.collation_name, N'''') AS [Collation],
CAST(ISNULL((select TOP 1 1 from sys.foreign_key_columns AS colfk where colfk.parent_column_id = clmns.column_id and colfk.parent_object_id = clmns.object_id), 0) AS bit) AS [IsForeignKey],
clmns.is_identity AS [Identity],
CAST(ISNULL(ic.seed_value,0) AS bigint) AS [IdentitySeed],
CAST(ISNULL(ic.increment_value,0) AS bigint) AS [IdentityIncrement],
(case when clmns.default_object_id = 0 then N'''' when d.parent_object_id > 0 then N'''' else d.name end) AS [Default],
(case when clmns.default_object_id = 0 then N'''' when d.parent_object_id > 0 then N'''' else schema_name(d.schema_id) end) AS [DefaultSchema],
(case when clmns.rule_object_id = 0 then N'''' else r.name end) AS [Rule],
(case when clmns.rule_object_id = 0 then N'''' else schema_name(r.schema_id) end) AS [RuleSchema],
ISNULL(ic.is_not_for_replication, 0) AS [NotForReplication],
CAST(COLUMNPROPERTY(clmns.object_id, clmns.name, N''IsFulltextIndexed'') AS bit) AS [IsFullTextIndexed],
CAST(COLUMNPROPERTY(clmns.object_id, clmns.name, N''StatisticalSemantics'') AS int) AS [StatisticalSemantics],
CAST(clmns.is_filestream AS bit) AS [IsFileStream],
CAST(clmns.is_sparse AS bit) AS [IsSparse],
CAST(clmns.is_column_set AS bit) AS [IsColumnSet],
usrt.name AS [DataType],
s1clmns.name AS [DataTypeSchema],
ISNULL(baset.name, N'''') AS [SystemType],
CAST(CASE WHEN baset.name IN (N''nchar'', N''nvarchar'') AND clmns.max_length <> -1 THEN clmns.max_length/2 ELSE clmns.max_length END AS int) AS [Length],
CAST(clmns.precision AS int) AS [NumericPrecision],
CAST(clmns.scale AS int) AS [NumericScale],
ISNULL(xscclmns.name, N'''') AS [XmlSchemaNamespace],
ISNULL(s2clmns.name, N'''') AS [XmlSchemaNamespaceSchema],
ISNULL( (case clmns.is_xml_document when 1 then 2 else 1 end), 0) AS [XmlDocumentConstraint],
CASE WHEN usrt.is_table_type = 1 THEN N''structured'' ELSE N'''' END AS [UserType]
FROM
sys.tables AS tbl
INNER JOIN sys.all_columns AS clmns ON clmns.object_id=tbl.object_id
LEFT OUTER JOIN sys.indexes AS ik ON ik.object_id = clmns.object_id and 1=ik.is_primary_key
LEFT OUTER JOIN sys.index_columns AS cik ON cik.index_id = ik.index_id and cik.column_id = clmns.column_id and cik.object_id = clmns.object_id and 0 = cik.is_included_column
LEFT OUTER JOIN sys.computed_columns AS cc ON cc.object_id = clmns.object_id and cc.column_id = clmns.column_id
LEFT OUTER JOIN sys.identity_columns AS ic ON ic.object_id = clmns.object_id and ic.column_id = clmns.column_id
LEFT OUTER JOIN sys.objects AS d ON d.object_id = clmns.default_object_id
LEFT OUTER JOIN sys.objects AS r ON r.object_id = clmns.rule_object_id
LEFT OUTER JOIN sys.types AS usrt ON usrt.user_type_id = clmns.user_type_id
LEFT OUTER JOIN sys.schemas AS s1clmns ON s1clmns.schema_id = usrt.schema_id
LEFT OUTER JOIN sys.types AS baset ON (baset.user_type_id = clmns.system_type_id and baset.user_type_id = baset.system_type_id) or ((baset.system_type_id = clmns.system_type_id) and (baset.user_type_id = clmns.user_type_id) and (baset.is_user_defined = 0) and (baset.is_assembly_type = 1)) 
LEFT OUTER JOIN sys.xml_schema_collections AS xscclmns ON xscclmns.xml_collection_id = clmns.xml_collection_id
LEFT OUTER JOIN sys.schemas AS s2clmns ON s2clmns.schema_id = xscclmns.schema_id
WHERE
(clmns.name=@_msparam_0)and((tbl.name=@_msparam_1 and SCHEMA_NAME(tbl.schema_id)=@_msparam_2))',N'@_msparam_0 nvarchar(4000),@_msparam_1 nvarchar(4000),@_msparam_2 nvarchar(4000)',@_msparam_0=N'OL_City',@_msparam_1=N'Owner_Level',@_msparam_2=N'dbo'