/*
==============================================================================
  test_data.sql  — Phase III sample data load (fuller than seed_reference_data)
  Run AFTER final_script.sql (tables + Phase 2 objects exist).
  Idempotent where practical — safe to re-run for demo.
==============================================================================
*/

SET NOCOUNT ON;
GO

PRINT '========== TEST DATA LOAD START ==========';
GO

/* Ensure roles / genres / demo artists-albums exist */
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
IF NOT EXISTS (SELECT 1 FROM dbo.Genres WHERE GenreName = 'Hip-Hop')
    INSERT INTO dbo.Genres (GenreName) VALUES ('Hip-Hop');
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Artists WHERE ArtistName = 'Demo Artist')
    INSERT INTO dbo.Artists (ArtistName, Country) VALUES ('Demo Artist', 'USA');
IF NOT EXISTS (SELECT 1 FROM dbo.Artists WHERE ArtistName = 'Nova Beats')
    INSERT INTO dbo.Artists (ArtistName, Country) VALUES ('Nova Beats', 'Canada');
IF NOT EXISTS (SELECT 1 FROM dbo.Artists WHERE ArtistName = 'Echo Lane')
    INSERT INTO dbo.Artists (ArtistName, Country) VALUES ('Echo Lane', 'UK');
GO

DECLARE @DemoArtist INT = (SELECT TOP 1 ArtistID FROM dbo.Artists WHERE ArtistName = 'Demo Artist');
DECLARE @Nova INT = (SELECT TOP 1 ArtistID FROM dbo.Artists WHERE ArtistName = 'Nova Beats');
DECLARE @Echo INT = (SELECT TOP 1 ArtistID FROM dbo.Artists WHERE ArtistName = 'Echo Lane');

IF @DemoArtist IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM dbo.Albums WHERE Title = 'Demo Album' AND ArtistID = @DemoArtist)
    INSERT INTO dbo.Albums (Title, ArtistID, ReleaseYear) VALUES ('Demo Album', @DemoArtist, 2024);

IF @Nova IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM dbo.Albums WHERE Title = 'Night Drive' AND ArtistID = @Nova)
    INSERT INTO dbo.Albums (Title, ArtistID, ReleaseYear) VALUES ('Night Drive', @Nova, 2023);

IF @Echo IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM dbo.Albums WHERE Title = 'Soft Rain' AND ArtistID = @Echo)
    INSERT INTO dbo.Albums (Title, ArtistID, ReleaseYear) VALUES ('Soft Rain', @Echo, 2025);
GO

DECLARE @UserRole INT = (SELECT TOP 1 RoleID FROM dbo.Roles WHERE RoleName = 'User');
DECLARE @AdminRole INT = (SELECT TOP 1 RoleID FROM dbo.Roles WHERE RoleName = 'Admin');

IF @UserRole IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Email = 'listener1@demo.com')
    INSERT INTO dbo.Users (FullName, Email, RoleID) VALUES ('Alex Listener', 'listener1@demo.com', @UserRole);

IF @UserRole IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Email = 'listener2@demo.com')
    INSERT INTO dbo.Users (FullName, Email, RoleID) VALUES ('Sam Streamer', 'listener2@demo.com', @UserRole);

IF @AdminRole IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Email = 'admin@demo.com')
    INSERT INTO dbo.Users (FullName, Email, RoleID) VALUES ('Pat Admin', 'admin@demo.com', @AdminRole);
GO

DECLARE @ArtistID INT = (SELECT TOP 1 ArtistID FROM dbo.Artists WHERE ArtistName = 'Nova Beats');
DECLARE @AlbumID INT = (SELECT TOP 1 AlbumID FROM dbo.Albums WHERE Title = 'Night Drive');
DECLARE @Pop INT = (SELECT TOP 1 GenreID FROM dbo.Genres WHERE GenreName = 'Pop');
DECLARE @Rock INT = (SELECT TOP 1 GenreID FROM dbo.Genres WHERE GenreName = 'Rock');
DECLARE @Jazz INT = (SELECT TOP 1 GenreID FROM dbo.Genres WHERE GenreName = 'Jazz');

IF @ArtistID IS NOT NULL AND @AlbumID IS NOT NULL AND @Pop IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM dbo.Songs WHERE Title = 'Midnight City')
    INSERT INTO dbo.Songs (Title, Duration, ArtistID, AlbumID, GenreID, ReleaseDate, PlayCount)
    VALUES ('Midnight City', 210, @ArtistID, @AlbumID, @Pop, '2023-05-01', 15);

IF @ArtistID IS NOT NULL AND @AlbumID IS NOT NULL AND @Rock IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM dbo.Songs WHERE Title = 'Highway Lights')
    INSERT INTO dbo.Songs (Title, Duration, ArtistID, AlbumID, GenreID, ReleaseDate, PlayCount)
    VALUES ('Highway Lights', 198, @ArtistID, @AlbumID, @Rock, '2023-06-12', 8);

DECLARE @EchoArtist INT = (SELECT TOP 1 ArtistID FROM dbo.Artists WHERE ArtistName = 'Echo Lane');
DECLARE @EchoAlbum INT = (SELECT TOP 1 AlbumID FROM dbo.Albums WHERE Title = 'Soft Rain');

IF @EchoArtist IS NOT NULL AND @EchoAlbum IS NOT NULL AND @Jazz IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM dbo.Songs WHERE Title = 'Quiet Morning')
    INSERT INTO dbo.Songs (Title, Duration, ArtistID, AlbumID, GenreID, ReleaseDate, PlayCount)
    VALUES ('Quiet Morning', 240, @EchoArtist, @EchoAlbum, @Jazz, '2025-01-20', 3);
GO

DECLARE @U1 INT = (SELECT TOP 1 UserID FROM dbo.Users WHERE Email = 'listener1@demo.com');
DECLARE @U2 INT = (SELECT TOP 1 UserID FROM dbo.Users WHERE Email = 'listener2@demo.com');

IF @U1 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.Playlists WHERE UserID = @U1 AND PlaylistName = 'Gym Mix')
    INSERT INTO dbo.Playlists (UserID, PlaylistName) VALUES (@U1, 'Gym Mix');

IF @U2 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.Playlists WHERE UserID = @U2 AND PlaylistName = 'Focus')
    INSERT INTO dbo.Playlists (UserID, PlaylistName) VALUES (@U2, 'Focus');
GO

DECLARE @U1 INT = (SELECT TOP 1 UserID FROM dbo.Users WHERE Email = 'listener1@demo.com');
DECLARE @PL INT = (SELECT TOP 1 PlaylistID FROM dbo.Playlists WHERE PlaylistName = 'Gym Mix');
DECLARE @S1 INT = (SELECT TOP 1 SongID FROM dbo.Songs WHERE Title = 'Midnight City');
DECLARE @S2 INT = (SELECT TOP 1 SongID FROM dbo.Songs WHERE Title = 'Highway Lights');
DECLARE @S3 INT = (SELECT TOP 1 SongID FROM dbo.Songs WHERE Title = 'Quiet Morning');

IF @PL IS NOT NULL AND @S1 IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM dbo.PlaylistSongs WHERE PlaylistID = @PL AND SongID = @S1)
    INSERT INTO dbo.PlaylistSongs (PlaylistID, SongID) VALUES (@PL, @S1);

IF @PL IS NOT NULL AND @S2 IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM dbo.PlaylistSongs WHERE PlaylistID = @PL AND SongID = @S2)
    INSERT INTO dbo.PlaylistSongs (PlaylistID, SongID) VALUES (@PL, @S2);
GO

DECLARE @U1 INT = (SELECT TOP 1 UserID FROM dbo.Users WHERE Email = 'listener1@demo.com');
DECLARE @U2 INT = (SELECT TOP 1 UserID FROM dbo.Users WHERE Email = 'listener2@demo.com');
DECLARE @S1 INT = (SELECT TOP 1 SongID FROM dbo.Songs WHERE Title = 'Midnight City');
DECLARE @S2 INT = (SELECT TOP 1 SongID FROM dbo.Songs WHERE Title = 'Highway Lights');
DECLARE @S3 INT = (SELECT TOP 1 SongID FROM dbo.Songs WHERE Title = 'Quiet Morning');

IF @U1 IS NOT NULL AND @S1 IS NOT NULL
    INSERT INTO dbo.ListeningHistory (UserID, SongID, PlayedAt) VALUES (@U1, @S1, DATEADD(HOUR, -2, GETDATE()));

IF @U1 IS NOT NULL AND @S2 IS NOT NULL
    INSERT INTO dbo.ListeningHistory (UserID, SongID, PlayedAt) VALUES (@U1, @S2, DATEADD(HOUR, -1, GETDATE()));

IF @U2 IS NOT NULL AND @S3 IS NOT NULL
    INSERT INTO dbo.ListeningHistory (UserID, SongID, PlayedAt) VALUES (@U2, @S3, DATEADD(MINUTE, -30, GETDATE()));
GO

DECLARE @U1 INT = (SELECT TOP 1 UserID FROM dbo.Users WHERE Email = 'listener1@demo.com');

IF @U1 IS NOT NULL
   AND COL_LENGTH('dbo.Subscriptions', 'UserID') IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM dbo.Subscriptions WHERE UserID = @U1 AND Type = 'Premium')
    INSERT INTO dbo.Subscriptions (Type, Price, StartDate, EndDate, UserID)
    VALUES ('Premium', 9.99, CAST(GETDATE() AS DATE), DATEADD(YEAR, 1, CAST(GETDATE() AS DATE)), @U1);
GO

PRINT '========== TEST DATA LOAD COMPLETE ==========';
PRINT 'Quick check:';
SELECT COUNT(*) AS Users FROM dbo.Users;
SELECT COUNT(*) AS Songs FROM dbo.Songs;
SELECT COUNT(*) AS PlayHistory FROM dbo.ListeningHistory;
GO
