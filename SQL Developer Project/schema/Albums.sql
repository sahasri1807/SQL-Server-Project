CREATE TABLE Albums (
    AlbumID INT IDENTITY(1,1) PRIMARY KEY,
    Title VARCHAR(100),
    ArtistID INT,
    ReleaseYear INT,
    FOREIGN KEY (ArtistID) REFERENCES Artists(ArtistID)
);
