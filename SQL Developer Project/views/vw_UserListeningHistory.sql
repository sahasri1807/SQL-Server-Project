/*
==============================================================================
  View : dbo.vw_UserListeningHistory
  Purpose : User name, song title, artist, date played.
  Columns include UserID for row-level / filtered access patterns.
==============================================================================
*/
CREATE OR ALTER VIEW dbo.vw_UserListeningHistory
AS
SELECT
    lh.HistoryID,
    u.UserID,
    u.FullName AS UserName,
    s.SongID,
    s.Title AS SongTitle,
    a.ArtistName,
    lh.PlayedAt
FROM dbo.ListeningHistory AS lh
INNER JOIN dbo.Users AS u ON u.UserID = lh.UserID
INNER JOIN dbo.Songs AS s ON s.SongID = lh.SongID
LEFT JOIN dbo.Artists AS a ON a.ArtistID = s.ArtistID;
GO
