/*
==============================================================================
  Trigger : dbo.trg_PreventDuplicatePlaylistSongs
  Table   : dbo.PlaylistSongs
  Type    : INSTEAD OF INSERT
  Purpose : Friendly rejection of duplicate (PlaylistID, SongID) pairs.
            Phase 1 already has composite PK; this adds explicit messaging.
==============================================================================
*/
CREATE OR ALTER TRIGGER dbo.trg_PreventDuplicatePlaylistSongs
ON dbo.PlaylistSongs
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted AS i
        INNER JOIN dbo.PlaylistSongs AS ps
            ON ps.PlaylistID = i.PlaylistID
           AND ps.SongID = i.SongID
    )
    BEGIN
        THROW 51001, 'Duplicate playlist song blocked by trigger (PlaylistID + SongID).', 1;
        RETURN;
    END

    /* Also block duplicates within the same multi-row INSERT batch */
    IF EXISTS (
        SELECT PlaylistID, SongID
        FROM inserted
        GROUP BY PlaylistID, SongID
        HAVING COUNT(*) > 1
    )
    BEGIN
        THROW 51002, 'Duplicate PlaylistID+SongID values found in the same INSERT batch.', 1;
        RETURN;
    END

    INSERT INTO dbo.PlaylistSongs (PlaylistID, SongID, AddedAt)
    SELECT
        i.PlaylistID,
        i.SongID,
        ISNULL(i.AddedAt, GETDATE())
    FROM inserted AS i;
END;
GO
