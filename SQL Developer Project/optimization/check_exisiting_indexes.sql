USE MusicStreamingDB;
GO

SELECT
    t.name AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    i.is_unique,
    i.is_primary_key,
    i.is_unique_constraint
FROM sys.indexes AS i
INNER JOIN sys.tables AS t
    ON i.object_id = t.object_id
WHERE t.is_ms_shipped = 0
  AND i.name IS NOT NULL
ORDER BY t.name, i.index_id;
GO

EXEC sp_helpindex 'dbo.Songs';
GO

EXEC sp_helpindex 'dbo.ListeningHistory';
GO

EXEC sp_helpindex 'dbo.PlaylistSongs';
GO

EXEC sp_helpindex 'dbo.Subscriptions';
GO