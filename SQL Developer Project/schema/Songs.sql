CREATE TABLE Songs (
    SongID INT IDENTITY(1,1) PRIMARY KEY,
    Title VARCHAR(100),
    Duration INT,
    ArtistID INT,
    AlbumID INT,
    GenreID INT,
    ReleaseDate DATE,
    PlayCount INT DEFAULT 0,

    FOREIGN KEY (ArtistID) REFERENCES Artists(ArtistID),
    FOREIGN KEY (AlbumID) REFERENCES Albums(AlbumID),
    FOREIGN KEY (GenreID) REFERENCES Genres(GenreID)
);
