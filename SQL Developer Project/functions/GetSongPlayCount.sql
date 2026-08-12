/*
==============================================================================
  Function  : dbo.GetSongPlayCount
  Type      : Scalar function
  Purpose   : Return play count for a song.
  Source    : Songs.PlayCount (Phase 1 column exists; also kept in sync by
              trigger trg_LogStreamingActivity). ListeningHistory COUNT is
              available as a cross-check via optional comment below.
==============================================================================
*/ 
CREATE OR ALTER FUNCTION dbo.GetSongPlayCount
(
    @SongID INT
)
RETURNS INT
AS
BEGIN
    DECLARE @PlayCount INT;

    SELECT @PlayCount = PlayCount
    FROM dbo.Songs
    WHERE SongID = @SongID;

    /* If song does not exist, return NULL; otherwise return stored PlayCount */
    RETURN @PlayCount;
END;
GO
