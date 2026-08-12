CREATE TABLE PlaylistSongs (
    PlaylistID INT NOT NULL,
    SongID INT NOT NULL,
    AddedAt DATETIME DEFAULT GETDATE(),

    PRIMARY KEY (PlaylistID, SongID),

    FOREIGN KEY (PlaylistID) REFERENCES Playlists(PlaylistID),
    FOREIGN KEY (SongID) REFERENCES Songs(SongID)
); 
