/*
==============================================================================
  Trigger : music.trg_LogStreamingActivity
  Table   : music.ListeningHistory
  Type    : AFTER INSERT
  Purpose : When a play is logged, increment Songs.PlayCount.
  Note    : Songs.PlayCount EXISTS in Phase 1 schema — no derivation needed.
==============================================================================
*/
CREATE OR ALTER TRIGGER music.trg_LogStreamingActivity
ON music.ListeningHistory
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    /* Increment PlayCount for each newly inserted listening row */
    UPDATE s
    SET PlayCount = ISNULL(s.PlayCount, 0) + x.PlayIncrements
    FROM music.Songs AS s
    INNER JOIN (
        SELECT SongID, COUNT(*) AS PlayIncrements
        FROM inserted
        GROUP BY SongID
    ) AS x ON x.SongID = s.SongID;
END;
GO
