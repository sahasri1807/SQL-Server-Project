/*
==============================================================================
  Procedure : dbo.CreatePlaylist
  Purpose   : Create a playlist for an active user.
  Uses      : Playlists (UserID, PlaylistName), Users (Status)
==============================================================================*/
CREATE OR ALTER PROCEDURE dbo.CreatePlaylist
    @UserID         INT,
    @PlaylistName   VARCHAR(100),
    @NewPlaylistID  INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @UserStatus VARCHAR(20);

    BEGIN TRY
        IF @UserID IS NULL
            THROW 50021, 'UserID is required.', 1;

        IF @PlaylistName IS NULL OR LTRIM(RTRIM(@PlaylistName)) = ''
            THROW 50022, 'PlaylistName is required.', 1;

        SELECT @UserStatus = Status
        FROM dbo.Users
        WHERE UserID = @UserID;

        IF @UserStatus IS NULL
            THROW 50023, 'User does not exist.', 1;

        IF @UserStatus <> 'Active'
            THROW 50024, 'User is not Active. Cannot create playlist.', 1;

        BEGIN TRANSACTION;

        INSERT INTO dbo.Playlists (UserID, PlaylistName)
        VALUES (@UserID, @PlaylistName);

        SET @NewPlaylistID = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        PRINT 'Playlist created. PlaylistID = ' + CAST(@NewPlaylistID AS VARCHAR(20));
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @ErrorMessage = ERROR_MESSAGE();
        SET @NewPlaylistID = NULL;
        THROW 50099, @ErrorMessage, 1;
    END CATCH
END;
GO
