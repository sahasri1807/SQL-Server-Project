/*
==============================================================================
  Procedure : dbo.AddSong
  Purpose   : Artist uploads a song; validates Artist, Album, and Genre exist.
  Uses      : Songs, Artists, Albums, Genres (Phase 1 column names)
==============================================================================
*/
    @GenreID     INT,
    @ReleaseDate DATE = NULL,
    @NewSongID   INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @ErrorMessage NVARCHAR(4000);

    BEGIN TRY
        IF @Title IS NULL OR LTRIM(RTRIM(@Title)) = ''
            THROW 50011, 'Song Title is required.', 1;

        IF @Duration IS NULL OR @Duration <= 0
            THROW 50012, 'Duration must be a positive number of seconds.', 1;

        IF @ArtistID IS NULL OR NOT EXISTS (SELECT 1 FROM dbo.Artists WHERE ArtistID = @ArtistID)
            THROW 50013, 'ArtistID does not exist.', 1;

        IF @AlbumID IS NULL OR NOT EXISTS (SELECT 1 FROM dbo.Albums WHERE AlbumID = @AlbumID)
            THROW 50014, 'AlbumID does not exist.', 1;

        IF @GenreID IS NULL OR NOT EXISTS (SELECT 1 FROM dbo.Genres WHERE GenreID = @GenreID)
            THROW 50015, 'GenreID does not exist.', 1;

        /* Album should belong to the same artist when ArtistID is set on album */
        IF EXISTS (
            SELECT 1
            FROM dbo.Albums
            WHERE AlbumID = @AlbumID
              AND ArtistID IS NOT NULL
              AND ArtistID <> @ArtistID
        )
            THROW 50016, 'Album does not belong to the specified Artist.', 1;

        BEGIN TRANSACTION;

        INSERT INTO dbo.Songs (Title, Duration, ArtistID, AlbumID, GenreID, ReleaseDate, PlayCount)
        VALUES (@Title, @Duration, @ArtistID, @AlbumID, @GenreID, @ReleaseDate, 0);

        SET @NewSongID = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        PRINT 'Song added. SongID = ' + CAST(@NewSongID AS VARCHAR(20));
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @ErrorMessage = ERROR_MESSAGE();
        SET @NewSongID = NULL;
        THROW 50099, @ErrorMessage, 1;
    END CATCH
END;
GO
