/*
==============================================================================
  View : reports.vw_SongDetails
  Purpose : Song, artist, album, genre, and play count in one reporting view.
==============================================================================
*/
CREATE OR ALTER VIEW reports.vw_SongDetails
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
FROM music.Songs AS s
LEFT JOIN music.Artists AS a ON a.ArtistID = s.ArtistID
LEFT JOIN music.Albums AS al ON al.AlbumID = s.AlbumID
LEFT JOIN music.Genres AS g ON g.GenreID = s.GenreID;
GO
