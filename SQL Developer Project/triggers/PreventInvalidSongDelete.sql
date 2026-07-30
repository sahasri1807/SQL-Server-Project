/*
==============================================================================
  Trigger : dbo.trg_PreventInvalidSongDelete
  Table   : dbo.Songs
  Type    : INSTEAD OF DELETE
  Purpose : Prevent deleting a song that is referenced by PlaylistSongs or
            ListeningHistory. Allows delete only when no references exist.
==============================================================================
*/
CREATE OR ALTER TRIGGER dbo.trg_PreventInvalidSongDelete
ON dbo.Songs
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM deleted AS d
        INNER JOIN dbo.PlaylistSongs AS ps ON ps.SongID = d.SongID
    )
    BEGIN
        THROW 51011, 'Cannot delete song: it exists in one or more playlists (PlaylistSongs).', 1;
        RETURN;
    END

    IF EXISTS (
        SELECT 1
        FROM deleted AS d
        INNER JOIN dbo.ListeningHistory AS lh ON lh.SongID = d.SongID
    )
    BEGIN
        THROW 51012, 'Cannot delete song: it has listening history (ListeningHistory).', 1;
        RETURN;
    END

    DELETE s
    FROM dbo.Songs AS s
    INNER JOIN deleted AS d ON d.SongID = s.SongID;
END;
GO
