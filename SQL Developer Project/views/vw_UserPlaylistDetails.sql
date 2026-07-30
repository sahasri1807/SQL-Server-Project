/*
==============================================================================
  View : dbo.vw_UserPlaylistDetails
  Purpose : User, playlist, and songs (filter-friendly via UserID / PlaylistID).
==============================================================================
*/
CREATE OR ALTER VIEW dbo.vw_UserPlaylistDetails
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
FROM dbo.Playlists AS p
INNER JOIN dbo.Users AS u ON u.UserID = p.UserID
LEFT JOIN dbo.PlaylistSongs AS ps ON ps.PlaylistID = p.PlaylistID
LEFT JOIN dbo.Songs AS s ON s.SongID = ps.SongID
LEFT JOIN dbo.Artists AS a ON a.ArtistID = s.ArtistID;
GO
