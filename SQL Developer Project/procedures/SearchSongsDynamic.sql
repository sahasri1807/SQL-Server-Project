/*
==============================================================================
  Procedure : app.SearchSongsDynamic
  Purpose   : Search songs with optional Genre / Artist / Title filters using
              dynamic SQL and sp_executesql (parameterized — SQL injection safe).
  Uses      : Songs.Title, Artists.ArtistName, Genres.GenreName, Songs.PlayCount
==============================================================================
*/
CREATE OR ALTER PROCEDURE app.SearchSongsDynamic
    @GenreName  VARCHAR(50)  = NULL,
    @ArtistName VARCHAR(100) = NULL,
    @Title      VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @ErrorMessage NVARCHAR(4000);

    BEGIN TRY
        SET @SQL = N'
SELECT
    s.SongID,
    s.Title,
    a.ArtistName,
    g.GenreName,
    al.Title AS AlbumTitle,
    s.Duration,
    s.PlayCount,
    s.ReleaseDate
FROM music.Songs AS s
INNER JOIN music.Artists AS a ON a.ArtistID = s.ArtistID
LEFT JOIN music.Genres AS g ON g.GenreID = s.GenreID
LEFT JOIN music.Albums AS al ON al.AlbumID = s.AlbumID
WHERE 1 = 1';

        IF @GenreName IS NOT NULL AND LTRIM(RTRIM(@GenreName)) <> ''
            SET @SQL += N'
  AND g.GenreName LIKE ''%'' + @pGenreName + ''%''';

        IF @ArtistName IS NOT NULL AND LTRIM(RTRIM(@ArtistName)) <> ''
            SET @SQL += N'
  AND a.ArtistName LIKE ''%'' + @pArtistName + ''%''';

        IF @Title IS NOT NULL AND LTRIM(RTRIM(@Title)) <> ''
            SET @SQL += N'
  AND s.Title LIKE ''%'' + @pTitle + ''%''';

        SET @SQL += N'
ORDER BY s.PlayCount DESC, s.Title;';

        EXEC sys.sp_executesql
            @SQL,
            N'@pGenreName VARCHAR(50), @pArtistName VARCHAR(100), @pTitle VARCHAR(100)',
            @pGenreName  = @GenreName,
            @pArtistName = @ArtistName,
            @pTitle      = @Title;
    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ERROR_MESSAGE();
        THROW 50099, @ErrorMessage, 1;
    END CATCH
END;
GO
