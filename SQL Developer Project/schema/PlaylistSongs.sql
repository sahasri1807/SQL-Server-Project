CREATE TABLE music.PlaylistSongs (
    PlaylistID INT NOT NULL,
    SongID INT NOT NULL,
    AddedAt DATETIME DEFAULT GETDATE(),

    PRIMARY KEY (PlaylistID, SongID),

    FOREIGN KEY (PlaylistID) REFERENCES music.Playlists(PlaylistID),
    FOREIGN KEY (SongID) REFERENCES music.Songs(SongID)
); 
