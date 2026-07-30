/*
==============================================================================
  Procedure : dbo.AddSongToPlaylist
  Purpose   : Add a song to a playlist; prevent duplicates; transactional.
  Uses      : PlaylistSongs (PlaylistID, SongID), Playlists, Songs
==============================================================================
*/
CREATE OR ALTER PROCEDURE dbo.AddSongToPlaylist
    @PlaylistID INT,
    @SongID     INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @ErrorMessage NVARCHAR(4000);

    BEGIN TRY
        IF @PlaylistID IS NULL OR NOT EXISTS (SELECT 1 FROM dbo.Playlists WHERE PlaylistID = @PlaylistID)
            THROW 50031, 'PlaylistID does not exist.', 1;

        IF @SongID IS NULL OR NOT EXISTS (SELECT 1 FROM dbo.Songs WHERE SongID = @SongID)
            THROW 50032, 'SongID does not exist.', 1;

        IF EXISTS (
            SELECT 1
            FROM dbo.PlaylistSongs
            WHERE PlaylistID = @PlaylistID
              AND SongID = @SongID
        )
            THROW 50033, 'Song already exists in this playlist. Duplicate not allowed.', 1;

        BEGIN TRANSACTION;

        INSERT INTO dbo.PlaylistSongs (PlaylistID, SongID)
        VALUES (@PlaylistID, @SongID);

        COMMIT TRANSACTION;

        PRINT 'Song added to playlist successfully.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @ErrorMessage = ERROR_MESSAGE();
        THROW 50099, @ErrorMessage, 1;
    END CATCH
END;
GO
