# Phase III – Indexing and Performance Analysis

## 1. Objective

The purpose of Phase III indexing is to improve query performance for frequently
used operations in the Music Streaming Database.

The database already contains clustered indexes created automatically through
primary keys. Additional non-clustered, INCLUDE, and filtered indexes were
created to support common query patterns.

---

## 2. Existing Indexes

The following clustered indexes already existed because the corresponding tables
use primary keys:

- Albums – Primary Key on AlbumID
- Artists – Primary Key on ArtistID
- Genres – Primary Key on GenreID
- ListeningHistory – Primary Key on HistoryID
- Playlists – Primary Key on PlaylistID
- PlaylistSongs – Composite Primary Key on PlaylistID and SongID
- Roles – Primary Key on RoleID
- Songs – Primary Key on SongID
- Subscriptions – Primary Key on SubscriptionID
- Users – Primary Key on UserID

The database also contains unique non-clustered indexes created from UNIQUE
constraints on:

- Genres.GenreName
- Roles.RoleName
- Users.Email

---

## 3. Phase III Indexes

Three additional indexes were created.

### 3.1 IX_Songs_ArtistID

Type: Non-clustered index

Table: dbo.Songs

Key column:

- ArtistID

Included columns:

- Title
- GenreID
- AlbumID
- Duration
- PlayCount
- ReleaseDate

Purpose:

This index supports queries that search for songs belonging to a particular
artist. The included columns allow frequently requested song information to be
returned directly from the index.

---

### 3.2 IX_ListeningHistory_UserID_Include

Type: Non-clustered INCLUDE index

Table: dbo.ListeningHistory

Key column:

- UserID

Included columns:

- SongID
- PlayedAt

Purpose:

This index supports queries that retrieve listening history for a particular
user. SongID and PlayedAt are included so SQL Server can retrieve the required
information without unnecessary additional lookups.

---

### 3.3 IX_Songs_PlayCount_Filtered

Type: Filtered non-clustered index

Table: dbo.Songs

Key column:

- PlayCount

Included columns:

- Title
- ArtistID

Filter condition:

PlayCount > 0

Purpose:

This index is designed for queries that only need songs that have been played.
Because songs with PlayCount = 0 are excluded, the index can be smaller than a
full-table index and can be useful for queries involving played songs.

---

## 4. Performance Testing

Performance was evaluated using SQL Server statistics:

```sql
SET STATISTICS IO ON;
SET STATISTICS TIME ON;