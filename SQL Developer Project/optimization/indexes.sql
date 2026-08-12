USE MusicStreamingDB;
GO

SET NOCOUNT ON;
GO

/* ============================================================
   PHASE III - INDEX CREATION
   Music Streaming Database
   ============================================================ */


/* ------------------------------------------------------------
   1. Non-clustered index for song searches by ArtistID
   Includes frequently returned song information.
   ------------------------------------------------------------ */

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_Songs_ArtistID'
      AND object_id = OBJECT_ID('dbo.Songs')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_Songs_ArtistID
    ON dbo.Songs (ArtistID)
    INCLUDE (Title, GenreID, AlbumID, Duration, PlayCount, ReleaseDate);

    PRINT 'Created IX_Songs_ArtistID.';
END
ELSE
    PRINT 'IX_Songs_ArtistID already exists.';
GO


/* ------------------------------------------------------------
   2. INCLUDE index for listening history queries
   Supports queries filtering by UserID and retrieving SongID
   and PlayedAt without requiring additional lookups.
   ------------------------------------------------------------ */

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_ListeningHistory_UserID_Include'
      AND object_id = OBJECT_ID('dbo.ListeningHistory')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_ListeningHistory_UserID_Include
    ON dbo.ListeningHistory (UserID)
    INCLUDE (SongID, PlayedAt);

    PRINT 'Created IX_ListeningHistory_UserID_Include.';
END
ELSE
    PRINT 'IX_ListeningHistory_UserID_Include already exists.';
GO


/* ------------------------------------------------------------
   3. Filtered index for songs that have been played
   Only indexes songs where PlayCount > 0.
   ------------------------------------------------------------ */

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_Songs_PlayCount_Filtered'
      AND object_id = OBJECT_ID('dbo.Songs')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_Songs_PlayCount_Filtered
    ON dbo.Songs (PlayCount)
    INCLUDE (Title, ArtistID)
    WHERE PlayCount > 0;

    PRINT 'Created IX_Songs_PlayCount_Filtered.';
END
ELSE
    PRINT 'IX_Songs_PlayCount_Filtered already exists.';
GO


/* ------------------------------------------------------------
   Verify Phase III indexes
   ------------------------------------------------------------ */

SELECT
    t.name AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    i.is_unique,
    i.is_primary_key
FROM sys.indexes AS i
INNER JOIN sys.tables AS t
    ON i.object_id = t.object_id
WHERE i.name IN (
    'IX_Songs_ArtistID',
    'IX_ListeningHistory_UserID_Include',
    'IX_Songs_PlayCount_Filtered'
)
ORDER BY t.name, i.name;
GO