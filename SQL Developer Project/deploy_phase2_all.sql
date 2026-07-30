/*
  Auto-generated concatenated Phase 2 deploy script.
  Select your music database in SSMS, then Execute.
  Generated for SQL Server 2016+ (CREATE OR ALTER requires 2016 SP1).
  Regenerate: bash "SQL Developer Project/build_deploy_phase2_all.sh"
*/
SET NOCOUNT ON;
PRINT 'Phase 2 deploy starting on: ' + DB_NAME();
GO

PRINT '>>> Running migrations/001_Phase2_SchemaExtensions.sql';
GO
/*
==============================================================================
  Migration: 001_Phase2_SchemaExtensions.sql
  Purpose  : Minimal Phase 2 extensions required by procedures/functions.
  Why      : Phase 1 Subscriptions has no UserID link, and Users has no Status.
             Instructor Phase 2 needs ManageSubscription + active-user checks.
  Notes    : Idempotent — safe to re-run. Does NOT invent new tables.
==============================================================================
*/

SET NOCOUNT ON;
GO

/* --------------------------------------------------------------------------
   1) Users.Status — used by CreatePlaylist (active user) and ManageSubscription
   -------------------------------------------------------------------------- */
IF COL_LENGTH('dbo.Users', 'Status') IS NULL
BEGIN
    ALTER TABLE dbo.Users
        ADD Status VARCHAR(20) NOT NULL
            CONSTRAINT DF_Users_Status DEFAULT ('Active');
    PRINT 'Added Users.Status (default Active).';
END
ELSE
    PRINT 'Users.Status already exists — skipped.';
GO

/* --------------------------------------------------------------------------
   2) Subscriptions.UserID — links a subscription row to a user
   Phase 1 Subscriptions columns: SubscriptionID, Type, Price, StartDate, EndDate
   -------------------------------------------------------------------------- */
IF COL_LENGTH('dbo.Subscriptions', 'UserID') IS NULL
BEGIN
    ALTER TABLE dbo.Subscriptions
        ADD UserID INT NULL;
    PRINT 'Added Subscriptions.UserID (nullable pending FK).';
END
ELSE
    PRINT 'Subscriptions.UserID already exists — skipped.';
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE name = 'FK_Subscriptions_Users'
      AND parent_object_id = OBJECT_ID('dbo.Subscriptions')
)
BEGIN
    ALTER TABLE dbo.Subscriptions
        ADD CONSTRAINT FK_Subscriptions_Users
        FOREIGN KEY (UserID) REFERENCES dbo.Users(UserID);
    PRINT 'Added FK_Subscriptions_Users.';
END
ELSE
    PRINT 'FK_Subscriptions_Users already exists — skipped.';
GO

PRINT 'Phase 2 schema extensions complete.';
GO

GO

PRINT '>>> Running schema/seed_reference_data.sql';
GO
/*
==============================================================================
  Seed : seed_reference_data.sql
  Purpose : Minimal reference rows so Phase 2 procedures can be demonstrated.
            Idempotent inserts for Roles, Genres, and a sample Artist/Album.
==============================================================================
*/
SET NOCOUNT ON;
GO

/* Application roles (table dbo.Roles) — distinct from SQL Server Music* roles */
IF NOT EXISTS (SELECT 1 FROM dbo.Roles WHERE RoleName = 'Admin')
    INSERT INTO dbo.Roles (RoleName) VALUES ('Admin');
IF NOT EXISTS (SELECT 1 FROM dbo.Roles WHERE RoleName = 'User')
    INSERT INTO dbo.Roles (RoleName) VALUES ('User');
IF NOT EXISTS (SELECT 1 FROM dbo.Roles WHERE RoleName = 'Artist')
    INSERT INTO dbo.Roles (RoleName) VALUES ('Artist');
IF NOT EXISTS (SELECT 1 FROM dbo.Roles WHERE RoleName = 'Moderator')
    INSERT INTO dbo.Roles (RoleName) VALUES ('Moderator');
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Genres WHERE GenreName = 'Pop')
    INSERT INTO dbo.Genres (GenreName) VALUES ('Pop');
IF NOT EXISTS (SELECT 1 FROM dbo.Genres WHERE GenreName = 'Rock')
    INSERT INTO dbo.Genres (GenreName) VALUES ('Rock');
IF NOT EXISTS (SELECT 1 FROM dbo.Genres WHERE GenreName = 'Jazz')
    INSERT INTO dbo.Genres (GenreName) VALUES ('Jazz');
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Artists WHERE ArtistName = 'Demo Artist')
    INSERT INTO dbo.Artists (ArtistName, Country) VALUES ('Demo Artist', 'USA');
GO

DECLARE @ArtistID INT = (SELECT TOP 1 ArtistID FROM dbo.Artists WHERE ArtistName = 'Demo Artist');

IF @ArtistID IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM dbo.Albums WHERE Title = 'Demo Album' AND ArtistID = @ArtistID)
    INSERT INTO dbo.Albums (Title, ArtistID, ReleaseYear)
    VALUES ('Demo Album', @ArtistID, 2024);
GO

PRINT 'Reference seed data applied.';
GO

GO

PRINT '>>> Running functions/GetSongPlayCount.sql';
GO
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

GO

PRINT '>>> Running functions/GetUserSubscriptionStatus.sql';
GO
/*
==============================================================================
  Function  : dbo.GetUserSubscriptionStatus
  Type      : Multi-statement table-valued function (SQL Server 2016 compatible)
  Purpose   : Return current subscription type/status for a user.
  Uses      : Subscriptions (UserID, Type, Price, StartDate, EndDate),
              Users (Status)
  Note      : Requires migrations/001_Phase2_SchemaExtensions.sql
==============================================================================
*/
CREATE OR ALTER FUNCTION dbo.GetUserSubscriptionStatus
(
    @UserID INT
)
RETURNS @Result TABLE
(
    UserID             INT,
    FullName           VARCHAR(100),
    UserStatus         VARCHAR(20),
    SubscriptionID     INT,
    SubscriptionType   VARCHAR(50),
    Price              DECIMAL(10,2),
    StartDate          DATE,
    EndDate            DATE,
    SubscriptionStatus VARCHAR(20)
)
AS
BEGIN
    INSERT INTO @Result (
        UserID, FullName, UserStatus, SubscriptionID, SubscriptionType,
        Price, StartDate, EndDate, SubscriptionStatus
    )
    SELECT TOP (1)
        u.UserID,
        u.FullName,
        u.Status,
        s.SubscriptionID,
        s.Type,
        s.Price,
        s.StartDate,
        s.EndDate,
        CASE
            WHEN s.SubscriptionID IS NULL THEN 'None'
            WHEN s.EndDate IS NULL OR s.EndDate >= CAST(GETDATE() AS DATE) THEN 'Current'
            ELSE 'Expired'
        END
    FROM dbo.Users AS u
    LEFT JOIN dbo.Subscriptions AS s
        ON s.UserID = u.UserID
    WHERE u.UserID = @UserID
    ORDER BY
        CASE
            WHEN s.EndDate IS NULL OR s.EndDate >= CAST(GETDATE() AS DATE) THEN 0
            ELSE 1
        END,
        s.StartDate DESC;

    RETURN;
END;
GO

GO

PRINT '>>> Running views/vw_UserListeningHistory.sql';
GO
/*
==============================================================================
  View : dbo.vw_UserListeningHistory
  Purpose : User name, song title, artist, date played.
  Columns include UserID for row-level / filtered access patterns.
==============================================================================
*/
CREATE OR ALTER VIEW dbo.vw_UserListeningHistory
AS
SELECT
    lh.HistoryID,
    u.UserID,
    u.FullName AS UserName,
    s.SongID,
    s.Title AS SongTitle,
    a.ArtistName,
    lh.PlayedAt
FROM dbo.ListeningHistory AS lh
INNER JOIN dbo.Users AS u ON u.UserID = lh.UserID
INNER JOIN dbo.Songs AS s ON s.SongID = lh.SongID
LEFT JOIN dbo.Artists AS a ON a.ArtistID = s.ArtistID;
GO

GO

PRINT '>>> Running views/vw_SongDetails.sql';
GO
/*
==============================================================================
  View : dbo.vw_SongDetails
  Purpose : Song, artist, album, genre, and play count in one reporting view.
==============================================================================
*/
CREATE OR ALTER VIEW dbo.vw_SongDetails
AS
SELECT
    s.SongID,
    s.Title AS SongTitle,
    s.Duration,
    s.ReleaseDate,
    s.PlayCount,
    a.ArtistID,
    a.ArtistName,
    al.AlbumID,
    al.Title AS AlbumTitle,
    g.GenreID,
    g.GenreName
FROM dbo.Songs AS s
LEFT JOIN dbo.Artists AS a ON a.ArtistID = s.ArtistID
LEFT JOIN dbo.Albums AS al ON al.AlbumID = s.AlbumID
LEFT JOIN dbo.Genres AS g ON g.GenreID = s.GenreID;
GO

GO

PRINT '>>> Running views/vw_UserPlaylistDetails.sql';
GO
/*
==============================================================================
  View : dbo.vw_UserPlaylistDetails
  Purpose : User, playlist, and songs (filter-friendly via UserID / PlaylistID).
==============================================================================
*/
CREATE OR ALTER VIEW dbo.vw_UserPlaylistDetails
AS
SELECT
    u.UserID,
    u.FullName AS UserName,
    p.PlaylistID,
    p.PlaylistName,
    p.CreatedAt AS PlaylistCreatedAt,
    s.SongID,
    s.Title AS SongTitle,
    a.ArtistName,
    ps.AddedAt
FROM dbo.Playlists AS p
INNER JOIN dbo.Users AS u ON u.UserID = p.UserID
LEFT JOIN dbo.PlaylistSongs AS ps ON ps.PlaylistID = p.PlaylistID
LEFT JOIN dbo.Songs AS s ON s.SongID = ps.SongID
LEFT JOIN dbo.Artists AS a ON a.ArtistID = s.ArtistID;
GO

GO

PRINT '>>> Running procedures/AddNewUser.sql';
GO
/*
==============================================================================
  Procedure : dbo.AddNewUser
  Purpose   : Insert a new user with unique email and default application role.
  Uses      : Users (FullName, Email, RoleID, Status), Roles (RoleName)
==============================================================================
*/
CREATE OR ALTER PROCEDURE dbo.AddNewUser
    @FullName   VARCHAR(100),
    @Email      VARCHAR(100),
    @RoleName   VARCHAR(50) = 'User',   -- default application role from Roles
    @NewUserID  INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @RoleID INT;
    DECLARE @ErrorMessage NVARCHAR(4000);

    BEGIN TRY
        /* ---- Validation ---- */
        IF @FullName IS NULL OR LTRIM(RTRIM(@FullName)) = ''
            THROW 50001, 'FullName is required.', 1;

        IF @Email IS NULL OR LTRIM(RTRIM(@Email)) = ''
            THROW 50002, 'Email is required.', 1;

        IF @Email NOT LIKE '%_@_%.__%'
            THROW 50003, 'Email format is invalid.', 1;

        IF EXISTS (SELECT 1 FROM dbo.Users WHERE Email = @Email)
            THROW 50004, 'Email already exists. User not created.', 1;

        SELECT @RoleID = RoleID
        FROM dbo.Roles
        WHERE RoleName = @RoleName;

        IF @RoleID IS NULL
            THROW 50005, 'Specified RoleName does not exist in Roles.', 1;

        BEGIN TRANSACTION;

        INSERT INTO dbo.Users (FullName, Email, RoleID, Status)
        VALUES (@FullName, @Email, @RoleID, 'Active');

        SET @NewUserID = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        PRINT 'User created successfully. UserID = ' + CAST(@NewUserID AS VARCHAR(20));
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @ErrorMessage = ERROR_MESSAGE();
        SET @NewUserID = NULL;
        THROW 50099, @ErrorMessage, 1;
    END CATCH
END;
GO

GO

PRINT '>>> Running procedures/AddSong.sql';
GO
/*
==============================================================================
  Procedure : dbo.AddSong
  Purpose   : Artist uploads a song; validates Artist, Album, and Genre exist.
  Uses      : Songs, Artists, Albums, Genres (Phase 1 column names)
==============================================================================
*/
CREATE OR ALTER PROCEDURE dbo.AddSong
    @Title       VARCHAR(100),
    @Duration    INT,
    @ArtistID    INT,
    @AlbumID     INT,
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

GO

PRINT '>>> Running procedures/CreatePlaylist.sql';
GO
/*
==============================================================================
  Procedure : dbo.CreatePlaylist
  Purpose   : Create a playlist for an active user.
  Uses      : Playlists (UserID, PlaylistName), Users (Status)
==============================================================================
*/
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

GO

PRINT '>>> Running procedures/AddSongToPlaylist.sql';
GO
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

GO

PRINT '>>> Running procedures/ManageSubscription.sql';
GO
/*
==============================================================================
  Procedure : dbo.ManageSubscription
  Purpose   : Upgrade/change a user's subscription and update user Status
              inside a single transaction.
  Uses      : Subscriptions (Type, Price, StartDate, EndDate, UserID),
              Users (Status)
  Note      : Requires migrations/001_Phase2_SchemaExtensions.sql
==============================================================================
*/
CREATE OR ALTER PROCEDURE dbo.ManageSubscription
    @UserID           INT,
    @SubscriptionType VARCHAR(50),
    @Price            DECIMAL(10,2),
    @Months           INT = 1,
    @NewSubscriptionID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @StartDate DATE = CAST(GETDATE() AS DATE);
    DECLARE @EndDate DATE;
    DECLARE @NewStatus VARCHAR(20);

    BEGIN TRY
        IF @UserID IS NULL OR NOT EXISTS (SELECT 1 FROM dbo.Users WHERE UserID = @UserID)
            THROW 50041, 'UserID does not exist.', 1;

        IF @SubscriptionType IS NULL OR LTRIM(RTRIM(@SubscriptionType)) = ''
            THROW 50042, 'SubscriptionType is required.', 1;

        IF @SubscriptionType NOT IN ('Free', 'Basic', 'Premium', 'Family')
            THROW 50043, 'Invalid subscription type. Allowed: Free, Basic, Premium, Family.', 1;

        IF @Price IS NULL OR @Price < 0
            THROW 50044, 'Price must be zero or positive.', 1;

        IF @Months IS NULL OR @Months <= 0
            THROW 50045, 'Months must be a positive integer.', 1;

        SET @EndDate = DATEADD(MONTH, @Months, @StartDate);
        SET @NewStatus = CASE
            WHEN @SubscriptionType = 'Free' THEN 'Active'
            ELSE 'Active'
        END;

        BEGIN TRANSACTION;

        /* Close any open subscription for this user */
        UPDATE dbo.Subscriptions
        SET EndDate = DATEADD(DAY, -1, @StartDate)
        WHERE UserID = @UserID
          AND (EndDate IS NULL OR EndDate >= @StartDate);

        INSERT INTO dbo.Subscriptions (Type, Price, StartDate, EndDate, UserID)
        VALUES (@SubscriptionType, @Price, @StartDate, @EndDate, @UserID);

        SET @NewSubscriptionID = SCOPE_IDENTITY();

        UPDATE dbo.Users
        SET Status = @NewStatus
        WHERE UserID = @UserID;

        COMMIT TRANSACTION;

        PRINT 'Subscription updated. SubscriptionID = '
            + CAST(@NewSubscriptionID AS VARCHAR(20))
            + '; User Status = ' + @NewStatus;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @ErrorMessage = ERROR_MESSAGE();
        SET @NewSubscriptionID = NULL;
        THROW 50099, @ErrorMessage, 1;
    END CATCH
END;
GO

GO

PRINT '>>> Running procedures/SearchSongsDynamic.sql';
GO
/*
==============================================================================
  Procedure : dbo.SearchSongsDynamic
  Purpose   : Search songs with optional Genre / Artist / Title filters using
              dynamic SQL and sp_executesql (parameterized — SQL injection safe).
  Uses      : Songs.Title, Artists.ArtistName, Genres.GenreName, Songs.PlayCount
==============================================================================
*/
CREATE OR ALTER PROCEDURE dbo.SearchSongsDynamic
    @GenreName  VARCHAR(50)  = NULL,
    @ArtistName VARCHAR(100) = NULL,
    @Title      VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @ErrorMessage NVARCHAR(4000);

    BEGIN TRY
        SET @SQL = N'
SELECT
    s.SongID,
    s.Title,
    a.ArtistName,
    g.GenreName,
    al.Title AS AlbumTitle,
    s.Duration,
    s.PlayCount,
    s.ReleaseDate
FROM dbo.Songs AS s
INNER JOIN dbo.Artists AS a ON a.ArtistID = s.ArtistID
LEFT JOIN dbo.Genres AS g ON g.GenreID = s.GenreID
LEFT JOIN dbo.Albums AS al ON al.AlbumID = s.AlbumID
WHERE 1 = 1';

        IF @GenreName IS NOT NULL AND LTRIM(RTRIM(@GenreName)) <> ''
            SET @SQL += N'
  AND g.GenreName LIKE ''%'' + @pGenreName + ''%''';

        IF @ArtistName IS NOT NULL AND LTRIM(RTRIM(@ArtistName)) <> ''
            SET @SQL += N'
  AND a.ArtistName LIKE ''%'' + @pArtistName + ''%''';

        IF @Title IS NOT NULL AND LTRIM(RTRIM(@Title)) <> ''
            SET @SQL += N'
  AND s.Title LIKE ''%'' + @pTitle + ''%''';

        SET @SQL += N'
ORDER BY s.PlayCount DESC, s.Title;';

        EXEC sys.sp_executesql
            @SQL,
            N'@pGenreName VARCHAR(50), @pArtistName VARCHAR(100), @pTitle VARCHAR(100)',
            @pGenreName  = @GenreName,
            @pArtistName = @ArtistName,
            @pTitle      = @Title;
    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ERROR_MESSAGE();
        THROW 50099, @ErrorMessage, 1;
    END CATCH
END;
GO

GO

PRINT '>>> Running procedures/ReportArtistSongCounts.sql';
GO
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
    DECLARE @SongCount INT;

    /* Result staging table for a clean result set */
    DECLARE @Report TABLE (
        ArtistID   INT,
        ArtistName VARCHAR(100),
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

GO

PRINT '>>> Running procedures/ProcessSongsDynamicCursor.sql';
GO
/*
==============================================================================
  Procedure : dbo.ProcessSongsDynamicCursor
  Purpose   : DYNAMIC cursor that walks Songs and builds table/column info
              via dynamic SQL (sp_executesql) for each processed song row.
  Cursor    : DECLARE / OPEN / FETCH / WHILE / CLOSE / DEALLOCATE (DYNAMIC)
==============================================================================
*/
CREATE OR ALTER PROCEDURE dbo.ProcessSongsDynamicCursor
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
        FROM dbo.Songs
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
WHERE object_id = OBJECT_ID(''dbo.Songs'');';

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

GO

PRINT '>>> Running triggers/PreventDuplicatePlaylistSongs.sql';
GO
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

GO

PRINT '>>> Running triggers/LogStreamingActivity.sql';
GO
/*
==============================================================================
  Trigger : dbo.trg_LogStreamingActivity
  Table   : dbo.ListeningHistory
  Type    : AFTER INSERT
  Purpose : When a play is logged, increment Songs.PlayCount.
  Note    : Songs.PlayCount EXISTS in Phase 1 schema — no derivation needed.
==============================================================================
*/
CREATE OR ALTER TRIGGER dbo.trg_LogStreamingActivity
ON dbo.ListeningHistory
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    /* Increment PlayCount for each newly inserted listening row */
    UPDATE s
    SET PlayCount = ISNULL(s.PlayCount, 0) + x.PlayIncrements
    FROM dbo.Songs AS s
    INNER JOIN (
        SELECT SongID, COUNT(*) AS PlayIncrements
        FROM inserted
        GROUP BY SongID
    ) AS x ON x.SongID = s.SongID;
END;
GO

GO

PRINT '>>> Running triggers/PreventInvalidSongDelete.sql';
GO
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

GO

PRINT '>>> Running security/permissions.sql';
GO
/*
==============================================================================
  Security : permissions.sql
  Purpose  : Create SQL Server database roles and GRANT/REVOKE/DENY for
             MusicAdmin, MusicUser, MusicArtist, MusicModerator.
  Also     : Permission smoke tests for each role (commented login section).
  Note     : Application Roles table (schema/Roles.sql) is separate from
             these SQL Server database roles.
==============================================================================
*/

SET NOCOUNT ON;
GO

/* --------------------------------------------------------------------------
   Create database roles (idempotent)
   -------------------------------------------------------------------------- */
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'MusicAdmin' AND type = 'R')
    CREATE ROLE MusicAdmin;
GO
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'MusicUser' AND type = 'R')
    CREATE ROLE MusicUser;
GO
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'MusicArtist' AND type = 'R')
    CREATE ROLE MusicArtist;
GO
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'MusicModerator' AND type = 'R')
    CREATE ROLE MusicModerator;
GO

/* --------------------------------------------------------------------------
   MusicAdmin — full control over music objects
   -------------------------------------------------------------------------- */
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo TO MusicAdmin;
GRANT EXECUTE ON SCHEMA::dbo TO MusicAdmin;
GO

/* --------------------------------------------------------------------------
   MusicUser — listen, manage own playlists, read catalog
   -------------------------------------------------------------------------- */
GRANT SELECT ON dbo.Songs TO MusicUser;
GRANT SELECT ON dbo.Artists TO MusicUser;
GRANT SELECT ON dbo.Albums TO MusicUser;
GRANT SELECT ON dbo.Genres TO MusicUser;
GRANT SELECT ON dbo.Playlists TO MusicUser;
GRANT SELECT ON dbo.PlaylistSongs TO MusicUser;
GRANT SELECT ON dbo.ListeningHistory TO MusicUser;
GRANT SELECT ON dbo.Subscriptions TO MusicUser;
GRANT SELECT ON dbo.vw_UserListeningHistory TO MusicUser;
GRANT SELECT ON dbo.vw_SongDetails TO MusicUser;
GRANT SELECT ON dbo.vw_UserPlaylistDetails TO MusicUser;

GRANT INSERT, UPDATE ON dbo.Playlists TO MusicUser;
GRANT INSERT, DELETE ON dbo.PlaylistSongs TO MusicUser;
GRANT INSERT ON dbo.ListeningHistory TO MusicUser;

GRANT EXECUTE ON dbo.CreatePlaylist TO MusicUser;
GRANT EXECUTE ON dbo.AddSongToPlaylist TO MusicUser;
GRANT EXECUTE ON dbo.SearchSongsDynamic TO MusicUser;
GRANT EXECUTE ON dbo.ManageSubscription TO MusicUser;
GRANT EXECUTE ON dbo.GetSongPlayCount TO MusicUser;
GRANT SELECT ON dbo.GetUserSubscriptionStatus TO MusicUser;

/* Users cannot manage other users or drop songs */
DENY INSERT, UPDATE, DELETE ON dbo.Users TO MusicUser;
DENY DELETE ON dbo.Songs TO MusicUser;
DENY EXECUTE ON dbo.AddNewUser TO MusicUser;
DENY EXECUTE ON dbo.AddSong TO MusicUser;
GO

/* --------------------------------------------------------------------------
   MusicArtist — upload songs, manage artist catalog read/write
   -------------------------------------------------------------------------- */
GRANT SELECT ON dbo.Songs TO MusicArtist;
GRANT SELECT ON dbo.Artists TO MusicArtist;
GRANT SELECT ON dbo.Albums TO MusicArtist;
GRANT SELECT ON dbo.Genres TO MusicArtist;
GRANT SELECT ON dbo.vw_SongDetails TO MusicArtist;

GRANT INSERT, UPDATE ON dbo.Songs TO MusicArtist;
GRANT INSERT, UPDATE ON dbo.Albums TO MusicArtist;
GRANT EXECUTE ON dbo.AddSong TO MusicArtist;
GRANT EXECUTE ON dbo.SearchSongsDynamic TO MusicArtist;
GRANT EXECUTE ON dbo.GetSongPlayCount TO MusicArtist;
IF OBJECT_ID(N'dbo.ReportArtistSongCounts', N'P') IS NOT NULL
    GRANT EXECUTE ON dbo.ReportArtistSongCounts TO MusicArtist;

DENY DELETE ON dbo.ListeningHistory TO MusicArtist;
DENY EXECUTE ON dbo.AddNewUser TO MusicArtist;
DENY EXECUTE ON dbo.ManageSubscription TO MusicArtist;
GO

/* --------------------------------------------------------------------------
   MusicModerator — review/moderate content; limited admin
   -------------------------------------------------------------------------- */
GRANT SELECT ON SCHEMA::dbo TO MusicModerator;
GRANT UPDATE ON dbo.Songs TO MusicModerator;
GRANT UPDATE ON dbo.Users TO MusicModerator;
GRANT DELETE ON dbo.PlaylistSongs TO MusicModerator;
GRANT EXECUTE ON dbo.SearchSongsDynamic TO MusicModerator;
IF OBJECT_ID(N'dbo.ReportArtistSongCounts', N'P') IS NOT NULL
    GRANT EXECUTE ON dbo.ReportArtistSongCounts TO MusicModerator;
IF OBJECT_ID(N'dbo.ProcessSongsDynamicCursor', N'P') IS NOT NULL
    GRANT EXECUTE ON dbo.ProcessSongsDynamicCursor TO MusicModerator;
GRANT EXECUTE ON dbo.GetSongPlayCount TO MusicModerator;

DENY EXECUTE ON dbo.AddNewUser TO MusicModerator;
DENY DELETE ON dbo.Users TO MusicModerator;
REVOKE INSERT ON dbo.Subscriptions TO MusicModerator; -- ensure no insert unless granted
GO

PRINT 'Database roles and permissions applied.';
GO

/* ==========================================================================
   Permission test harness
   Creates test logins/users mapped to each role, runs smoke checks, then
   cleans up. Requires permission to create logins (often needs sysadmin).
   Run the block below manually in SSMS when validating security.
   ========================================================================== */

/*
-- Optional: set a password and run as a privileged admin
USE master;
GO
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'test_music_admin')
    CREATE LOGIN test_music_admin WITH PASSWORD = N'Test!Pass123', CHECK_POLICY = OFF;
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'test_music_user')
    CREATE LOGIN test_music_user WITH PASSWORD = N'Test!Pass123', CHECK_POLICY = OFF;
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'test_music_artist')
    CREATE LOGIN test_music_artist WITH PASSWORD = N'Test!Pass123', CHECK_POLICY = OFF;
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'test_music_mod')
    CREATE LOGIN test_music_mod WITH PASSWORD = N'Test!Pass123', CHECK_POLICY = OFF;
GO

-- Switch to your music database first, then:
-- USE [YourMusicDB];
GO
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'test_music_admin')
    CREATE USER test_music_admin FOR LOGIN test_music_admin;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'test_music_user')
    CREATE USER test_music_user FOR LOGIN test_music_user;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'test_music_artist')
    CREATE USER test_music_artist FOR LOGIN test_music_artist;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'test_music_mod')
    CREATE USER test_music_mod FOR LOGIN test_music_mod;
GO

ALTER ROLE MusicAdmin ADD MEMBER test_music_admin;
ALTER ROLE MusicUser ADD MEMBER test_music_user;
ALTER ROLE MusicArtist ADD MEMBER test_music_artist;
ALTER ROLE MusicModerator ADD MEMBER test_music_mod;
GO

-- ---- MusicAdmin test (expect SUCCESS) ----
EXECUTE AS USER = 'test_music_admin';
SELECT TOP 1 * FROM dbo.Songs;
REVERT;
GO

-- ---- MusicUser test (expect FAIL on AddSong / DELETE Songs) ----
EXECUTE AS USER = 'test_music_user';
BEGIN TRY
    EXEC dbo.SearchSongsDynamic @Title = N'a';  -- should succeed
    PRINT 'MusicUser SearchSongsDynamic: OK';
END TRY
BEGIN CATCH
    PRINT 'MusicUser SearchSongsDynamic FAILED: ' + ERROR_MESSAGE();
END CATCH

BEGIN TRY
    DECLARE @id INT;
    EXEC dbo.AddSong @Title='X', @Duration=1, @ArtistID=1, @AlbumID=1, @GenreID=1, @NewSongID=@id OUTPUT;
    PRINT 'MusicUser AddSong unexpectedly succeeded';
END TRY
BEGIN CATCH
    PRINT 'MusicUser AddSong correctly denied/failed: ' + ERROR_MESSAGE();
END CATCH
REVERT;
GO

-- ---- MusicArtist test (expect SUCCESS on AddSong if FKs valid) ----
EXECUTE AS USER = 'test_music_artist';
SELECT TOP 1 SongID FROM dbo.Songs;
REVERT;
GO

-- ---- MusicModerator test (expect SUCCESS on SELECT, DENY AddNewUser) ----
EXECUTE AS USER = 'test_music_mod';
BEGIN TRY
    DECLARE @uid INT;
    EXEC dbo.AddNewUser @FullName='Hack', @Email='hack@example.com', @NewUserID=@uid OUTPUT;
    PRINT 'MusicModerator AddNewUser unexpectedly succeeded';
END TRY
BEGIN CATCH
    PRINT 'MusicModerator AddNewUser correctly denied: ' + ERROR_MESSAGE();
END CATCH
REVERT;
GO
*/

GO

PRINT 'Phase 2 deploy complete. Next: test_cases/transaction_tests.sql';
GO
