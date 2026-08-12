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
