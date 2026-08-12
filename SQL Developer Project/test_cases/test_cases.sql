/*
==============================================================================
  Test cases : test_cases.sql
  Combined Phase 2 transaction tests + Phase 3 isolation / deadlock demo.

  Part A — Transactions (BEGIN / COMMIT / ROLLBACK / TRY / CATCH):
    1) Successful transactions
    2) Failed rollback
    3) Duplicate playlist song
    4) Invalid subscription
    5) Invalid song delete

  Part B — Isolation & deadlock awareness (spec 5.4):
    6) Current isolation level
    7) READ COMMITTED transactional update
    8) LOCK_TIMEOUT awareness
    9) Two-window deadlock walkthrough (comments)
   10) REPEATABLE READ transactional read

  Prerequisites: Phase 1 tables + Phase 2 migration/objects + seed / test_data
==============================================================================
*/

SET NOCOUNT ON;
SET XACT_ABORT OFF; -- allow CATCH to handle errors without aborting batch
GO

PRINT '========== TRANSACTION TESTS START ==========';
GO

/* Ensure baseline reference data */
IF NOT EXISTS (SELECT 1 FROM music.Roles WHERE RoleName = 'User')
    INSERT INTO music.Roles (RoleName) VALUES ('User');
GO

/* --------------------------------------------------------------------------
   1) SUCCESSFUL TRANSACTIONS — AddNewUser, CreatePlaylist, AddSong, subscribe
   -------------------------------------------------------------------------- */
PRINT '--- Test 1: Successful transactions ---';
GO
BEGIN TRY
    DECLARE @UserID INT;
    DECLARE @PlaylistID INT;
    DECLARE @SongID INT;
    DECLARE @SubID INT;
    DECLARE @ArtistID INT = (SELECT TOP 1 ArtistID FROM music.Artists ORDER BY ArtistID);
    DECLARE @AlbumID INT = (SELECT TOP 1 AlbumID FROM music.Albums ORDER BY AlbumID);
    DECLARE @GenreID INT = (SELECT TOP 1 GenreID FROM music.Genres ORDER BY GenreID);
    DECLARE @Email VARCHAR(100) = 'txn_success_' + REPLACE(CONVERT(VARCHAR(36), NEWID()), '-', '') + '@test.com';

    IF @ArtistID IS NULL OR @AlbumID IS NULL OR @GenreID IS NULL
        THROW 59901, 'Seed Artist/Album/Genre required before tests.', 1;

    EXEC app.AddNewUser
        @FullName = 'Txn Success User',
        @Email = @Email,
        @RoleName = 'User',
        @NewUserID = @UserID OUTPUT;

    EXEC app.CreatePlaylist
        @UserID = @UserID,
        @PlaylistName = 'Txn Success Playlist',
        @NewPlaylistID = @PlaylistID OUTPUT;

    EXEC app.AddSong
        @Title = 'Txn Success Song',
        @Duration = 210,
        @ArtistID = @ArtistID,
        @AlbumID = @AlbumID,
        @GenreID = @GenreID,
        @ReleaseDate = '2024-01-01',
        @NewSongID = @SongID OUTPUT;

    EXEC app.AddSongToPlaylist
        @PlaylistID = @PlaylistID,
        @SongID = @SongID;

    EXEC app.ManageSubscription
        @UserID = @UserID,
        @SubscriptionType = 'Premium',
        @Price = 9.99,
        @Months = 1,
        @NewSubscriptionID = @SubID OUTPUT;

    /* Log a play — should bump Songs.PlayCount via trigger */
    INSERT INTO music.ListeningHistory (UserID, SongID)
    VALUES (@UserID, @SongID);

    SELECT
        'TEST1_PASS' AS Result,
        @UserID AS UserID,
        @PlaylistID AS PlaylistID,
        @SongID AS SongID,
        @SubID AS SubscriptionID,
        app.GetSongPlayCount(@SongID) AS PlayCount;

    SELECT * FROM app.GetUserSubscriptionStatus(@UserID);
END TRY
BEGIN CATCH
    PRINT 'TEST1_FAIL: ' + ERROR_MESSAGE();
END CATCH
GO

/* --------------------------------------------------------------------------
   2) FAILED TRANSACTION + ROLLBACK — force failure mid-transaction
   -------------------------------------------------------------------------- */
PRINT '--- Test 2: Failed transaction rollback ---';
GO
BEGIN TRY
    DECLARE @BeforeUsers INT = (SELECT COUNT(*) FROM music.Users);
    DECLARE @RollbackEmail VARCHAR(100) = 'txn_rollback_' + REPLACE(CONVERT(VARCHAR(36), NEWID()), '-', '') + '@test.com';
    DECLARE @RoleID INT = (SELECT TOP 1 RoleID FROM music.Roles WHERE RoleName = 'User');

    BEGIN TRANSACTION;

    INSERT INTO music.Users (FullName, Email, RoleID, Status)
    VALUES ('Should Rollback', @RollbackEmail, @RoleID, 'Active');

    /* Force failure after insert */
    THROW 59902, 'Intentional failure to demonstrate ROLLBACK.', 1;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    IF EXISTS (SELECT 1 FROM music.Users WHERE Email LIKE 'txn_rollback_%@test.com'
               AND FullName = 'Should Rollback'
               AND CreatedAt >= DATEADD(MINUTE, -2, GETDATE()))
        PRINT 'TEST2_FAIL: row unexpectedly persisted after ROLLBACK.';
    ELSE
        PRINT 'TEST2_PASS: ROLLBACK removed uncommitted user insert. Error was: ' + ERROR_MESSAGE();
END CATCH
GO

/* --------------------------------------------------------------------------
   3) DUPLICATE PLAYLIST SONG — procedure + trigger path
   -------------------------------------------------------------------------- */
PRINT '--- Test 3: Duplicate playlist song ---';
GO
BEGIN TRY
    DECLARE @UID INT;
    DECLARE @PID INT;
    DECLARE @SID INT;
    DECLARE @Aid INT = (SELECT TOP 1 ArtistID FROM music.Artists ORDER BY ArtistID);
    DECLARE @Alid INT = (SELECT TOP 1 AlbumID FROM music.Albums ORDER BY AlbumID);
    DECLARE @Gid INT = (SELECT TOP 1 GenreID FROM music.Genres ORDER BY GenreID);
    DECLARE @DupEmail VARCHAR(100) = 'txn_dup_' + REPLACE(CONVERT(VARCHAR(36), NEWID()), '-', '') + '@test.com';

    EXEC app.AddNewUser @FullName='Dup Test', @Email=@DupEmail, @NewUserID=@UID OUTPUT;
    EXEC app.CreatePlaylist @UserID=@UID, @PlaylistName='Dup PL', @NewPlaylistID=@PID OUTPUT;
    EXEC app.AddSong @Title='Dup Song', @Duration=100, @ArtistID=@Aid, @AlbumID=@Alid,
         @GenreID=@Gid, @NewSongID=@SID OUTPUT;

    EXEC app.AddSongToPlaylist @PlaylistID=@PID, @SongID=@SID; -- first add OK

    BEGIN TRY
        EXEC app.AddSongToPlaylist @PlaylistID=@PID, @SongID=@SID; -- duplicate
        PRINT 'TEST3_FAIL: duplicate was allowed.';
    END TRY
    BEGIN CATCH
        PRINT 'TEST3_PASS: duplicate blocked — ' + ERROR_MESSAGE();
    END CATCH
END TRY
BEGIN CATCH
    PRINT 'TEST3_SETUP_FAIL: ' + ERROR_MESSAGE();
END CATCH
GO

/* --------------------------------------------------------------------------
   4) INVALID SUBSCRIPTION type
   -------------------------------------------------------------------------- */
PRINT '--- Test 4: Invalid subscription ---';
GO
BEGIN TRY
    DECLARE @UID4 INT;
    DECLARE @Sub4 INT;
    DECLARE @Email4 VARCHAR(100) = 'txn_badsub_' + REPLACE(CONVERT(VARCHAR(36), NEWID()), '-', '') + '@test.com';

    EXEC app.AddNewUser @FullName='Bad Sub User', @Email=@Email4, @NewUserID=@UID4 OUTPUT;

    BEGIN TRY
        EXEC app.ManageSubscription
            @UserID = @UID4,
            @SubscriptionType = 'UltraMegaInvalid',
            @Price = 1.00,
            @Months = 1,
            @NewSubscriptionID = @Sub4 OUTPUT;
        PRINT 'TEST4_FAIL: invalid subscription was accepted.';
    END TRY
    BEGIN CATCH
        PRINT 'TEST4_PASS: invalid subscription rejected — ' + ERROR_MESSAGE();
    END CATCH
END TRY
BEGIN CATCH
    PRINT 'TEST4_SETUP_FAIL: ' + ERROR_MESSAGE();
END CATCH
GO

/* --------------------------------------------------------------------------
   5) INVALID SONG DELETE — blocked when in PlaylistSongs / ListeningHistory
   -------------------------------------------------------------------------- */
PRINT '--- Test 5: Invalid song delete ---';
GO
BEGIN TRY
    DECLARE @UID5 INT;
    DECLARE @PID5 INT;
    DECLARE @SID5 INT;
    DECLARE @Aid5 INT = (SELECT TOP 1 ArtistID FROM music.Artists ORDER BY ArtistID);
    DECLARE @Alid5 INT = (SELECT TOP 1 AlbumID FROM music.Albums ORDER BY AlbumID);
    DECLARE @Gid5 INT = (SELECT TOP 1 GenreID FROM music.Genres ORDER BY GenreID);
    DECLARE @Email5 VARCHAR(100) = 'txn_del_' + REPLACE(CONVERT(VARCHAR(36), NEWID()), '-', '') + '@test.com';

    EXEC app.AddNewUser @FullName='Delete Test', @Email=@Email5, @NewUserID=@UID5 OUTPUT;
    EXEC app.CreatePlaylist @UserID=@UID5, @PlaylistName='Del PL', @NewPlaylistID=@PID5 OUTPUT;
    EXEC app.AddSong @Title='Protected Song', @Duration=120, @ArtistID=@Aid5, @AlbumID=@Alid5,
         @GenreID=@Gid5, @NewSongID=@SID5 OUTPUT;
    EXEC app.AddSongToPlaylist @PlaylistID=@PID5, @SongID=@SID5;

    BEGIN TRY
        DELETE FROM music.Songs WHERE SongID = @SID5;
        PRINT 'TEST5_FAIL: protected song was deleted.';
    END TRY
    BEGIN CATCH
        PRINT 'TEST5_PASS: song delete blocked — ' + ERROR_MESSAGE();
    END CATCH

    /* Song with only listening history should also be blocked */
    DECLARE @SID5b INT;
    EXEC app.AddSong @Title='History Only Song', @Duration=90, @ArtistID=@Aid5, @AlbumID=@Alid5,
         @GenreID=@Gid5, @NewSongID=@SID5b OUTPUT;
    INSERT INTO music.ListeningHistory (UserID, SongID) VALUES (@UID5, @SID5b);

    BEGIN TRY
        DELETE FROM music.Songs WHERE SongID = @SID5b;
        PRINT 'TEST5B_FAIL: history-referenced song was deleted.';
    END TRY
    BEGIN CATCH
        PRINT 'TEST5B_PASS: history-referenced delete blocked — ' + ERROR_MESSAGE();
    END CATCH
END TRY
BEGIN CATCH
    PRINT 'TEST5_SETUP_FAIL: ' + ERROR_MESSAGE();
END CATCH
GO

PRINT '========== TRANSACTION TESTS COMPLETE ==========';
GO

/* ==========================================================================
   PART B — ISOLATION / DEADLOCK DEMO (spec 5.4)
   ========================================================================== */

PRINT '========== ISOLATION / DEADLOCK DEMO START ==========';
GO

/* --------------------------------------------------------------------------
   6) Show current isolation level
   -------------------------------------------------------------------------- */
PRINT '--- Test 6: Current isolation level ---';
DBCC USEROPTIONS;
GO

/* --------------------------------------------------------------------------
   7) READ COMMITTED short transaction with TRY/CATCH
   -------------------------------------------------------------------------- */
PRINT '--- Test 7: READ COMMITTED transactional update ---';
GO

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRY
    BEGIN TRANSACTION;

    UPDATE music.Songs
    SET PlayCount = PlayCount
    WHERE SongID = (SELECT TOP 1 SongID FROM music.Songs ORDER BY SongID);

    COMMIT TRANSACTION;
    PRINT 'TEST7_PASS: READ COMMITTED update committed.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT 'TEST7_FAIL: ' + ERROR_MESSAGE();
END CATCH
GO

/* --------------------------------------------------------------------------
   8) Lock timeout awareness (LOCK_TIMEOUT)
   -------------------------------------------------------------------------- */
PRINT '--- Test 8: LOCK_TIMEOUT awareness ---';
GO

BEGIN TRY
    SET LOCK_TIMEOUT 1000; -- 1 second

    BEGIN TRANSACTION;

    UPDATE music.Songs WITH (ROWLOCK, UPDLOCK)
    SET Title = Title
    WHERE SongID = (SELECT TOP 1 SongID FROM music.Songs ORDER BY SongID);

    PRINT 'Held UPDLOCK inside transaction (demo). Releasing...';

    COMMIT TRANSACTION;
    PRINT 'TEST8_PASS: Lock demo transaction committed.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT 'TEST8_INFO: Caught lock/transaction error: ' + ERROR_MESSAGE();
END CATCH
GO

SET LOCK_TIMEOUT -1; -- reset to default (wait forever)
GO

/* --------------------------------------------------------------------------
<<<<<<< HEAD
   9) TWO-SESSION DEADLOCK DEMO (manual — instructor Q&A)

   Window A:
     BEGIN TRAN;
     UPDATE music.Songs SET PlayCount = PlayCount WHERE SongID = 1;
     -- wait, then:
     UPDATE music.Users SET FullName = FullName WHERE UserID = 1;

   Window B (run after Window A first update):
     BEGIN TRAN;
     UPDATE music.Users SET FullName = FullName WHERE UserID = 1;
     UPDATE music.Songs SET PlayCount = PlayCount WHERE SongID = 1;

   One session will be chosen as deadlock victim (error 1205).
   Always ROLLBACK both windows afterward.

   Catch pattern for victim session:
     BEGIN TRY
       ... updates ...
     END TRY
     BEGIN CATCH
       IF ERROR_NUMBER() = 1205
         PRINT 'Deadlock victim — transaction rolled back / retry.';
       IF @@TRANCOUNT > 0 ROLLBACK;
     END CATCH
=======
   9) SIMPLE TRANSACTION LOCK TEST
>>>>>>> c267762 (added ss)
   -------------------------------------------------------------------------- */
PRINT '--- Test 9: Simple transaction lock test ---';
GO

BEGIN TRY

    BEGIN TRANSACTION;

    UPDATE dbo.Songs
    SET PlayCount = PlayCount
    WHERE SongID = (SELECT TOP 1 SongID FROM dbo.Songs ORDER BY SongID);

    IF @@TRANCOUNT = 1
        PRINT 'TEST9_PASS: Transaction lock was created successfully.';
    ELSE
        PRINT 'TEST9_FAIL: Transaction was not started.';

    ROLLBACK TRANSACTION;

END TRY
BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT 'TEST9_FAIL: ' + ERROR_MESSAGE();

END CATCH
GO

/* --------------------------------------------------------------------------
   10) REPEATABLE READ short demo
   -------------------------------------------------------------------------- */
PRINT '--- Test 10: REPEATABLE READ transactional read ---';
GO

SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN TRY
    BEGIN TRANSACTION;

    SELECT TOP 3 SongID, Title, PlayCount
    FROM music.Songs
    ORDER BY SongID;

    COMMIT TRANSACTION;
    PRINT 'TEST10_PASS: REPEATABLE READ read committed.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT 'TEST10_FAIL: ' + ERROR_MESSAGE();
END CATCH
GO

-- Reset to default
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
GO

PRINT '========== ISOLATION / DEADLOCK DEMO COMPLETE ==========';
PRINT '========== ALL TEST CASES COMPLETE ==========';
GO

/* --------------------------------------------------------------------------
   11) DUPLICATE USER EMAIL
   -------------------------------------------------------------------------- */
PRINT '--- Test 11: Duplicate user email ---';
GO

BEGIN TRY
    DECLARE @Email11 VARCHAR(100) =
        'txn_duplicate_email_' +
        REPLACE(CONVERT(VARCHAR(36), NEWID()), '-', '') +
        '@test.com';

    DECLARE @UID11 INT;

    /* Create first user */
    EXEC dbo.AddNewUser
        @FullName = 'Duplicate Email User 1',
        @Email = @Email11,
        @RoleName = 'User',
        @NewUserID = @UID11 OUTPUT;

    /* Try creating second user with same email */
    BEGIN TRY
        EXEC dbo.AddNewUser
            @FullName = 'Duplicate Email User 2',
            @Email = @Email11,
            @RoleName = 'User',
            @NewUserID = @UID11 OUTPUT;

        PRINT 'TEST11_FAIL: Duplicate email was accepted.';
    END TRY
    BEGIN CATCH
        PRINT 'TEST11_PASS: Duplicate email rejected — ' + ERROR_MESSAGE();
    END CATCH

END TRY
BEGIN CATCH
    PRINT 'TEST11_SETUP_FAIL: ' + ERROR_MESSAGE();
END CATCH
GO


/* --------------------------------------------------------------------------
   12) INVALID PLAYLIST USER
   -------------------------------------------------------------------------- */
PRINT '--- Test 12: Invalid playlist user ---';
GO

BEGIN TRY

    DECLARE @Playlist12 INT;

    BEGIN TRY
        EXEC dbo.CreatePlaylist
            @UserID = -999999,
            @PlaylistName = 'Invalid User Playlist',
            @NewPlaylistID = @Playlist12 OUTPUT;

        PRINT 'TEST12_FAIL: Playlist was created for an invalid user.';
    END TRY
    BEGIN CATCH
        PRINT 'TEST12_PASS: Invalid user rejected — ' + ERROR_MESSAGE();
    END CATCH

END TRY
BEGIN CATCH
    PRINT 'TEST12_SETUP_FAIL: ' + ERROR_MESSAGE();
END CATCH
GO


/* --------------------------------------------------------------------------
   13) INVALID SONG DURATION
   -------------------------------------------------------------------------- */
PRINT '--- Test 13: Invalid song duration ---';
GO

BEGIN TRY

    DECLARE @Song13 INT;
    DECLARE @Aid13 INT =
        (SELECT TOP 1 ArtistID FROM dbo.Artists ORDER BY ArtistID);
    DECLARE @Alid13 INT =
        (SELECT TOP 1 AlbumID FROM dbo.Albums ORDER BY AlbumID);
    DECLARE @Gid13 INT =
        (SELECT TOP 1 GenreID FROM dbo.Genres ORDER BY GenreID);

    BEGIN TRY
        EXEC dbo.AddSong
            @Title = 'Invalid Duration Song',
            @Duration = -100,
            @ArtistID = @Aid13,
            @AlbumID = @Alid13,
            @GenreID = @Gid13,
            @NewSongID = @Song13 OUTPUT;

        PRINT 'TEST13_FAIL: Negative song duration was accepted.';
    END TRY
    BEGIN CATCH
        PRINT 'TEST13_PASS: Invalid duration rejected — ' + ERROR_MESSAGE();
    END CATCH

END TRY
BEGIN CATCH
    PRINT 'TEST13_SETUP_FAIL: ' + ERROR_MESSAGE();
END CATCH
GO


/* --------------------------------------------------------------------------
   14) SUBSCRIPTION TRANSACTION ROLLBACK
   -------------------------------------------------------------------------- */
PRINT '--- Test 14: Subscription transaction rollback ---';
GO

BEGIN TRY

    DECLARE @UID14 INT;
    DECLARE @Sub14 INT;
    DECLARE @Email14 VARCHAR(100) =
        'txn_subrollback_' +
        REPLACE(CONVERT(VARCHAR(36), NEWID()), '-', '') +
        '@test.com';

    EXEC dbo.AddNewUser
        @FullName = 'Subscription Rollback User',
        @Email = @Email14,
        @RoleName = 'User',
        @NewUserID = @UID14 OUTPUT;

    BEGIN TRANSACTION;

    EXEC dbo.ManageSubscription
        @UserID = @UID14,
        @SubscriptionType = 'Premium',
        @Price = 9.99,
        @Months = 1,
        @NewSubscriptionID = @Sub14 OUTPUT;

    /* Force failure after subscription creation */
    THROW 59914, 'Intentional subscription failure.', 1;

    COMMIT TRANSACTION;

END TRY
BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.Subscriptions
        WHERE SubscriptionID = @Sub14
    )
        PRINT 'TEST14_PASS: Subscription was rolled back.';
    ELSE
        PRINT 'TEST14_FAIL: Subscription still exists after ROLLBACK.';

END CATCH
GO


/* --------------------------------------------------------------------------
   15) LISTENING HISTORY / PLAY COUNT TRIGGER
   -------------------------------------------------------------------------- */
PRINT '--- Test 15: Listening history PlayCount trigger ---';
GO

BEGIN TRY

    DECLARE @UID15 INT;
    DECLARE @SID15 INT;
    DECLARE @BeforePlayCount15 INT;
    DECLARE @AfterPlayCount15 INT;

    DECLARE @Aid15 INT =
        (SELECT TOP 1 ArtistID FROM dbo.Artists ORDER BY ArtistID);
    DECLARE @Alid15 INT =
        (SELECT TOP 1 AlbumID FROM dbo.Albums ORDER BY AlbumID);
    DECLARE @Gid15 INT =
        (SELECT TOP 1 GenreID FROM dbo.Genres ORDER BY GenreID);

    DECLARE @Email15 VARCHAR(100) =
        'txn_trigger_' +
        REPLACE(CONVERT(VARCHAR(36), NEWID()), '-', '') +
        '@test.com';

    EXEC dbo.AddNewUser
        @FullName = 'Trigger Test User',
        @Email = @Email15,
        @RoleName = 'User',
        @NewUserID = @UID15 OUTPUT;

    EXEC dbo.AddSong
        @Title = 'Trigger Test Song',
        @Duration = 180,
        @ArtistID = @Aid15,
        @AlbumID = @Alid15,
        @GenreID = @Gid15,
        @NewSongID = @SID15 OUTPUT;

    SET @BeforePlayCount15 =
        dbo.GetSongPlayCount(@SID15);

    /* Add three listening-history records */
    INSERT INTO dbo.ListeningHistory (UserID, SongID)
    VALUES (@UID15, @SID15);

    INSERT INTO dbo.ListeningHistory (UserID, SongID)
    VALUES (@UID15, @SID15);

    INSERT INTO dbo.ListeningHistory (UserID, SongID)
    VALUES (@UID15, @SID15);

    SET @AfterPlayCount15 =
        dbo.GetSongPlayCount(@SID15);

    IF @AfterPlayCount15 = @BeforePlayCount15 + 3
        PRINT 'TEST15_PASS: PlayCount trigger incremented correctly.';
    ELSE
        PRINT 'TEST15_FAIL: PlayCount did not increment correctly.';

END TRY
BEGIN CATCH
    PRINT 'TEST15_FAIL: ' + ERROR_MESSAGE();
END CATCH
GO


/* --------------------------------------------------------------------------
   16) VALID SONG DELETE
   -------------------------------------------------------------------------- */
PRINT '--- Test 16: Valid song delete ---';
GO

BEGIN TRY

    DECLARE @SID16 INT;

    DECLARE @Aid16 INT =
        (SELECT TOP 1 ArtistID FROM dbo.Artists ORDER BY ArtistID);
    DECLARE @Alid16 INT =
        (SELECT TOP 1 AlbumID FROM dbo.Albums ORDER BY AlbumID);
    DECLARE @Gid16 INT =
        (SELECT TOP 1 GenreID FROM dbo.Genres ORDER BY GenreID);

    EXEC dbo.AddSong
        @Title = 'Safe Delete Song',
        @Duration = 150,
        @ArtistID = @Aid16,
        @AlbumID = @Alid16,
        @GenreID = @Gid16,
        @NewSongID = @SID16 OUTPUT;

    /* Delete unreferenced song */
    DELETE FROM dbo.Songs
    WHERE SongID = @SID16;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.Songs
        WHERE SongID = @SID16
    )
        PRINT 'TEST16_PASS: Unreferenced song deleted successfully.';
    ELSE
        PRINT 'TEST16_FAIL: Unreferenced song still exists.';

END TRY
BEGIN CATCH
    PRINT 'TEST16_FAIL: ' + ERROR_MESSAGE();
END CATCH
GO


/* --------------------------------------------------------------------------
   17) UPDATE TRANSACTION ROLLBACK
   -------------------------------------------------------------------------- */
PRINT '--- Test 17: Update transaction rollback ---';
GO

BEGIN TRY

    DECLARE @UID17 INT;
    DECLARE @OriginalName17 VARCHAR(100);
    DECLARE @Email17 VARCHAR(100) =
        'txn_updaterollback_' +
        REPLACE(CONVERT(VARCHAR(36), NEWID()), '-', '') +
        '@test.com';

    EXEC dbo.AddNewUser
        @FullName = 'Original Transaction Name',
        @Email = @Email17,
        @RoleName = 'User',
        @NewUserID = @UID17 OUTPUT;

    SET @OriginalName17 =
        (SELECT FullName
         FROM dbo.Users
         WHERE UserID = @UID17);

    BEGIN TRY

        BEGIN TRANSACTION;

        UPDATE dbo.Users
        SET FullName = 'Changed Name That Should Rollback'
        WHERE UserID = @UID17;

        /* Force transaction failure */
        THROW 59917, 'Intentional update failure.', 1;

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        IF EXISTS
        (
            SELECT 1
            FROM dbo.Users
            WHERE UserID = @UID17
              AND FullName = @OriginalName17
        )
            PRINT 'TEST17_PASS: UPDATE was successfully rolled back.';
        ELSE
            PRINT 'TEST17_FAIL: UPDATE was not rolled back.';

    END CATCH

END TRY
BEGIN CATCH
    PRINT 'TEST17_SETUP_FAIL: ' + ERROR_MESSAGE();
END CATCH
GO


/* --------------------------------------------------------------------------
   18) REMOVE SONG FROM PLAYLIST
   -------------------------------------------------------------------------- */
PRINT '--- Test 18: Remove song from playlist ---';
GO

BEGIN TRY

    DECLARE @UID18 INT;
    DECLARE @PID18 INT;
    DECLARE @SID18 INT;

    DECLARE @Aid18 INT =
        (SELECT TOP 1 ArtistID FROM dbo.Artists ORDER BY ArtistID);
    DECLARE @Alid18 INT =
        (SELECT TOP 1 AlbumID FROM dbo.Albums ORDER BY AlbumID);
    DECLARE @Gid18 INT =
        (SELECT TOP 1 GenreID FROM dbo.Genres ORDER BY GenreID);

    DECLARE @Email18 VARCHAR(100) =
        'txn_remove_' +
        REPLACE(CONVERT(VARCHAR(36), NEWID()), '-', '') +
        '@test.com';

    EXEC dbo.AddNewUser
        @FullName = 'Remove Song User',
        @Email = @Email18,
        @RoleName = 'User',
        @NewUserID = @UID18 OUTPUT;

    EXEC dbo.CreatePlaylist
        @UserID = @UID18,
        @PlaylistName = 'Remove Song Playlist',
        @NewPlaylistID = @PID18 OUTPUT;

    EXEC dbo.AddSong
        @Title = 'Remove From Playlist Song',
        @Duration = 200,
        @ArtistID = @Aid18,
        @AlbumID = @Alid18,
        @GenreID = @Gid18,
        @NewSongID = @SID18 OUTPUT;

    /* Add song to playlist */
    EXEC dbo.AddSongToPlaylist
        @PlaylistID = @PID18,
        @SongID = @SID18;

    /* Remove song from playlist */
    DELETE FROM dbo.PlaylistSongs
    WHERE PlaylistID = @PID18
      AND SongID = @SID18;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.PlaylistSongs
        WHERE PlaylistID = @PID18
          AND SongID = @SID18
    )
        PRINT 'TEST18_PASS: Song removed from playlist successfully.';
    ELSE
        PRINT 'TEST18_FAIL: Song still exists in playlist.';

END TRY
BEGIN CATCH
    PRINT 'TEST18_FAIL: ' + ERROR_MESSAGE();
END CATCH
GO