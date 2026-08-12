CREATE TABLE music.Playlists (
    PlaylistID INT IDENTITY(1,1) PRIMARY KEY,
    UserID INT,
    PlaylistName VARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE(),

    FOREIGN KEY (UserID) REFERENCES music.Users(UserID)
); 
