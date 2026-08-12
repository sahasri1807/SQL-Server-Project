/*
==============================================================================
  View : reports.vw_UserListeningHistory
  Purpose : User name, song title, artist, date played.
  Columns include UserID for row-level / filtered access patterns.
==============================================================================
*/
CREATE OR ALTER VIEW reports.vw_UserListeningHistory
AS
SELECT
    lh.HistoryID,
    u.UserID,
    u.FullName AS UserName,
    s.SongID,
    s.Title AS SongTitle,
    a.ArtistName,
    lh.PlayedAt
FROM music.ListeningHistory AS lh
INNER JOIN music.Users AS u ON u.UserID = lh.UserID
INNER JOIN music.Songs AS s ON s.SongID = lh.SongID
LEFT JOIN music.Artists AS a ON a.ArtistID = s.ArtistID;
GO
