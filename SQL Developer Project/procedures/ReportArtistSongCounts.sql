/*
==============================================================================
  Procedure : dbo.ReportArtistSongCounts
  Purpose   : STATIC cursor report — artists and their song counts.
  Cursor    : DECLARE / OPEN / FETCH / WHILE / CLOSE / DEALLOCATE (STATIC)
==============================================================================
*/
CREATE OR ALTER PROCEDURE dbo.ReportArtistSongCounts
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ArtistID INT;
    DECLARE @ArtistName VARCHAR(100);
    DECLARE 
        SongCount  INT
    );

    DECLARE artist_cursor CURSOR STATIC LOCAL FOR
        SELECT
            a.ArtistID,
            a.ArtistName,
            COUNT(s.SongID) AS SongCount
        FROM dbo.Artists AS a
        LEFT JOIN dbo.Songs AS s ON s.ArtistID = a.ArtistID
        GROUP BY a.ArtistID, a.ArtistName
        ORDER BY COUNT(s.SongID) DESC, a.ArtistName;

    BEGIN TRY
        OPEN artist_cursor;

        FETCH NEXT FROM artist_cursor
            INTO @ArtistID, @ArtistName, @SongCount;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            INSERT INTO @Report (ArtistID, ArtistName, SongCount)
            VALUES (@ArtistID, @ArtistName, @SongCount);

            FETCH NEXT FROM artist_cursor
                INTO @ArtistID, @ArtistName, @SongCount;
        END

        CLOSE artist_cursor;
        DEALLOCATE artist_cursor;

        SELECT ArtistID, ArtistName, SongCount
        FROM @Report
        ORDER BY SongCount DESC, ArtistName;
    END TRY
    BEGIN CATCH
        IF CURSOR_STATUS('local', 'artist_cursor') >= -1
        BEGIN
            IF CURSOR_STATUS('local', 'artist_cursor') > -1
                CLOSE artist_cursor;
            DEALLOCATE artist_cursor;
        END;
        /* THROW must follow a semicolon-terminated statement */
        THROW;
    END CATCH
END;
GO
