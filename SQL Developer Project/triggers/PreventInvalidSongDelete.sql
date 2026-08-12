/*
==============================================================================
  Trigger : music.trg_PreventInvalidSongDelete
  Table   : music.Songs
  Type    : INSTEAD OF DELETE
  Purpose : Prevent deleting a song that is referenced by PlaylistSongs or
            ListeningHistory. Allows delete only when no references exist.
==============================================================================
*/
CREATE OR ALTER TRIGGER music.trg_PreventInvalidSongDelete
ON music.Songs
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM deleted AS d
        INNER JOIN music.PlaylistSongs AS ps ON ps.SongID = d.SongID
    )
    BEGIN
        THROW 51011, 'Cannot delete song: it exists in one or more playlists (PlaylistSongs).', 1;
        RETURN;
    END

    IF EXISTS (
        SELECT 1
        FROM deleted AS d
        INNER JOIN music.ListeningHistory AS lh ON lh.SongID = d.SongID
    )
    BEGIN
        THROW 51012, 'Cannot delete song: it has listening history (ListeningHistory).', 1;
        RETURN;
    END

    DELETE s
    FROM music.Songs AS s
    INNER JOIN deleted AS d ON d.SongID = s.SongID;
END;
GO
