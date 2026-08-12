USE MusicStreamingDB;
GO

SET NOCOUNT ON;
GO

/* ============================================================
   PHASE III - PERFORMANCE TESTING
   Music Streaming Database
   ============================================================ */


/* ------------------------------------------------------------
   TEST 1: Search songs by ArtistID
   Uses the IX_Songs_ArtistID index created in Phase III.
   ------------------------------------------------------------ */

PRINT '========== TEST 1: SONG SEARCH BY ARTIST ==========';

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT
    s.SongID,
    s.Title,
    s.GenreID,
    s.AlbumID,
    s.Duration,
    s.PlayCount,
    s.ReleaseDate
FROM dbo.Songs AS s
WHERE s.ArtistID = (
    SELECT TOP 1 ArtistID
    FROM dbo.Artists
    ORDER BY ArtistID
);

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO


/* ------------------------------------------------------------
   TEST 2: User listening history
   Uses IX_ListeningHistory_UserID_Include.
   ------------------------------------------------------------ */

PRINT '========== TEST 2: USER LISTENING HISTORY ==========';

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT
    lh.HistoryID,
    lh.UserID,
    lh.SongID,
    lh.PlayedAt
FROM dbo.ListeningHistory AS lh
WHERE lh.UserID = (
    SELECT TOP 1 UserID
    FROM dbo.Users
    ORDER BY UserID
);

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO


/* ------------------------------------------------------------
   TEST 3: Songs that have been played
   Uses IX_Songs_PlayCount_Filtered.
   ------------------------------------------------------------ */

PRINT '========== TEST 3: PLAYED SONGS ==========';

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT
    s.SongID,
    s.Title,
    s.ArtistID,
    s.PlayCount
FROM dbo.Songs AS s
WHERE s.PlayCount > 0
ORDER BY s.PlayCount DESC;

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO


/* ------------------------------------------------------------
   INDEX VERIFICATION
   ------------------------------------------------------------ */

PRINT '========== PHASE III INDEX VERIFICATION ==========';

SELECT
    t.name AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    i.is_unique,
    i.is_primary_key,
    i.has_filter,
    i.filter_definition
FROM sys.indexes AS i
INNER JOIN sys.tables AS t
    ON i.object_id = t.object_id
WHERE i.name IN
(
    'IX_Songs_ArtistID',
    'IX_ListeningHistory_UserID_Include',
    'IX_Songs_PlayCount_Filtered'
)
ORDER BY t.name, i.name;
GO