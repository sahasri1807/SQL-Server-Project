/*
==============================================================================
  Seed : seed_reference_data.sql
  Purpose : Minimal reference rows so Phase 2 procedures can be demonstrated.
            Idempotent inserts for Roles, Genres, and a sample Artist/Album.
==============================================================================
*/ 
SET NOCOUNT ON;
GO

/* Application roles (table music.Roles) — distinct from SQL Server Music* roles */
IF NOT EXISTS (SELECT 1 FROM music.Roles WHERE RoleName = 'Admin')
    INSERT INTO music.Roles (RoleName) VALUES ('Admin');
IF NOT EXISTS (SELECT 1 FROM music.Roles WHERE RoleName = 'User')
    INSERT INTO music.Roles (RoleName) VALUES ('User');
IF NOT EXISTS (SELECT 1 FROM music.Roles WHERE RoleName = 'Artist')
    INSERT INTO music.Roles (RoleName) VALUES ('Artist');
IF NOT EXISTS (SELECT 1 FROM music.Roles WHERE RoleName = 'Moderator')
    INSERT INTO music.Roles (RoleName) VALUES ('Moderator');
GO

IF NOT EXISTS (SELECT 1 FROM music.Genres WHERE GenreName = 'Pop')
    INSERT INTO music.Genres (GenreName) VALUES ('Pop');
IF NOT EXISTS (SELECT 1 FROM music.Genres WHERE GenreName = 'Rock')
    INSERT INTO music.Genres (GenreName) VALUES ('Rock');
IF NOT EXISTS (SELECT 1 FROM music.Genres WHERE GenreName = 'Jazz')
    INSERT INTO music.Genres (GenreName) VALUES ('Jazz');
GO

IF NOT EXISTS (SELECT 1 FROM music.Artists WHERE ArtistName = 'Demo Artist')
    INSERT INTO music.Artists (ArtistName, Country) VALUES ('Demo Artist', 'USA');
GO

DECLARE @ArtistID INT = (SELECT TOP 1 ArtistID FROM music.Artists WHERE ArtistName = 'Demo Artist');

IF @ArtistID IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM music.Albums WHERE Title = 'Demo Album' AND ArtistID = @ArtistID)
    INSERT INTO music.Albums (Title, ArtistID, ReleaseYear)
    VALUES ('Demo Album', @ArtistID, 2024);
GO

PRINT 'Reference seed data applied.';
GO
