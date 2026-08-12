CREATE TABLE music.Songs (
    SongID INT IDENTITY(1,1) PRIMARY KEY,
    Title VARCHAR(100),
    Duration INT,
    ArtistID INT,
    AlbumID INT,
    GenreID INT,
    ReleaseDate DATE,
    PlayCount INT DEFAULT 0,

    FOREIGN KEY (ArtistID) REFERENCES music.Artists(ArtistID),
    FOREIGN KEY (AlbumID) REFERENCES music.Albums(AlbumID),
    FOREIGN KEY (GenreID) REFERENCES music.Genres(GenreID)
);
