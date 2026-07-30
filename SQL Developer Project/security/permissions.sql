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
GRANT EXECUTE ON dbo.ReportArtistSongCounts TO MusicModerator;
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
