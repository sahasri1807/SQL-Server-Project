/*
==============================================================================
  Procedure : app.ProcessSongsDynamicCursor
  Purpose   : DYNAMIC cursor that walks Songs and builds table/column info
              via dynamic SQL (sp_executesql) for each processed song row.
  Cursor    : DECLARE / OPEN / FETCH / WHILE / CLOSE / DEALLOCATE (DYNAMIC)
==============================================================================
*/
CREATE OR ALTER PROCEDURE app.ProcessSongsDynamicCursor
    @MinPlayCount INT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SongID INT;
    DECLARE @Title VARCHAR(100);
    DECLARE @PlayCount INT;
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @Info NVARCHAR(400);

    DECLARE @Results TABLE (
        SongID    INT,
        Title     VARCHAR(100),
        PlayCount INT,
        MetaInfo  NVARCHAR(400)
    );

    /* DYNAMIC cursor — reflects committed changes made during the loop */
    DECLARE song_cursor CURSOR DYNAMIC LOCAL FOR
        SELECT SongID, Title, PlayCount
        FROM music.Songs
        WHERE PlayCount >= @MinPlayCount
        ORDER BY SongID;

    BEGIN TRY
        OPEN song_cursor;

        FETCH NEXT FROM song_cursor
            INTO @SongID, @Title, @PlayCount;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @SQL = N'
SELECT @out = CONCAT(
    ''SongID='', CAST(@id AS VARCHAR(20)),
    ''; Cols='', CAST(COUNT(*) AS VARCHAR(20)),
    ''; Table=Songs'')
FROM sys.columns
WHERE object_id = OBJECT_ID(''music.Songs'');';

            EXEC sys.sp_executesql
                @SQL,
                N'@id INT, @out NVARCHAR(400) OUTPUT',
                @id  = @SongID,
                @out = @Info OUTPUT;

            INSERT INTO @Results (SongID, Title, PlayCount, MetaInfo)
            VALUES (@SongID, @Title, @PlayCount, @Info);

            FETCH NEXT FROM song_cursor
                INTO @SongID, @Title, @PlayCount;
        END

        CLOSE song_cursor;
        DEALLOCATE song_cursor;

        SELECT SongID, Title, PlayCount, MetaInfo
        FROM @Results
        ORDER BY SongID;
    END TRY
    BEGIN CATCH
        IF CURSOR_STATUS('local', 'song_cursor') >= -1
        BEGIN
            IF CURSOR_STATUS('local', 'song_cursor') > -1
                CLOSE song_cursor;
            DEALLOCATE song_cursor;
        END;
        /* THROW must follow a semicolon-terminated statement */
        THROW;
    END CATCH
END;
GO
