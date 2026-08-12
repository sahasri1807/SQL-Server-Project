/*
==============================================================================
  View : reports.vw_UserPlaylistDetails
  Purpose : User, playlist, and songs (filter-friendly via UserID / PlaylistID).
==============================================================================
*/
CREATE OR ALTER VIEW reports.vw_UserPlaylistDetails
AS
SELECT
    u.UserID,
    u.FullName AS UserName,
    p.PlaylistID,
    p.PlaylistName,
    p.CreatedAt AS PlaylistCreatedAt,
    s.SongID,
    s.Title AS SongTitle,
    a.ArtistName,
    ps.AddedAt
FROM music.Playlists AS p
INNER JOIN music.Users AS u ON u.UserID = p.UserID
LEFT JOIN music.PlaylistSongs AS ps ON ps.PlaylistID = p.PlaylistID
LEFT JOIN music.Songs AS s ON s.SongID = ps.SongID
LEFT JOIN music.Artists AS a ON a.ArtistID = s.ArtistID;
GO
