CREATE TABLE music.Albums (
    AlbumID INT IDENTITY(1,1) PRIMARY KEY,
    Title VARCHAR(100),
    ArtistID INT,
    ReleaseYear INT,
    FOREIGN KEY (ArtistID) REFERENCES music.Artists(ArtistID)
);



