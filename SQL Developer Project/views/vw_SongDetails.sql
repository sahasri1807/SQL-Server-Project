/*
==============================================================================
  View : dbo.vw_SongDetails
  Purpose : Song, artist, album, genre, and play count in one reporting view.
==============================================================================
*/
CREATE OR ALTER VIEW dbo.vw_SongDetails
AS
SELECT
    s.SongID,
    s.Title AS SongTitle,
    s.Duration,
    s.ReleaseDate,
    s.PlayCount,
    a.ArtistID,
    a.ArtistName,
    al.AlbumID,
    al.Title AS AlbumTitle,
    g.GenreID,
    g.GenreName
FROM dbo.Songs AS s
LEFT JOIN dbo.Artists AS a ON a.ArtistID = s.ArtistID
LEFT JOIN dbo.Albums AS al ON al.AlbumID = s.AlbumID
LEFT JOIN dbo.Genres AS g ON g.GenreID = s.GenreID;
GO
