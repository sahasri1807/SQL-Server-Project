# Music Streaming Database System

## Team members : Nunemuntala Sahasri (N10010782), Kelvin Idoko (N01777723) and Hassana Abdullahi (N10000326)

##  Project Overview
This project is a SQL Server-based Music Streaming Database System designed using Transact-SQL (T-SQL). It simulates a real-world music streaming platform where users can stream songs, create playlists, track listening history, and manage subscriptions.

The system is fully backend-driven with no frontend, no ORM, and no GUI tools. It focuses on relational database design, normalization, procedural logic, security, transactions, and performance optimization.

---

## Business case
A streaming service needs one place that stores users, songs, playlists, plays, and who is paying. If that data is messy — duplicate emails, the same song twice on a playlist, play counts that don’t match history, someone deleting a song that’s still on playlists — the app breaks and they lose money / trust. We built a SQL Server database that keeps that data clean, lets staff and users do those jobs through procedures, and stays fast when there’s more listening history.

## Business scenario
Daily life of the platform:

A listener signs up, searches songs, makes a playlist, plays tracks, upgrades to Premium.
An artist uploads a song to an album/genre.
The company needs to know play counts, listening history, and who is on which plan.
Admins can do everything; a normal user should not create accounts or delete songs.
Example: user plays a song → a history row is saved → play count goes up automatically. They try to add the same song to a playlist twice → blocked. They try to delete a song that’s still on a playlist → blocked.

Problem it’s solving

Problem without a proper DB	What we do
- Artist name typed on every song (duplicates, typos)
- Normalized tables: song points at ArtistID
- Two accounts with the same email
- Unique email + AddNewUser check
- Playlist with the same song twice
- Procedure + trigger + composite key
- Play count doesn’t match what people actually played
- Trigger on listening history
- Delete a popular song and break playlists/history
- Delete trigger blocks it
- Half a subscription saved if something fails
- Transactions + rollback
- Users doing admin stuff
- SQL Server roles GRANT/DENY
- Slow “songs by this artist” / “this user’s history”
- Indexes
---

##  Database Features

The system includes the following core modules:

- User management with role-based access control
- Song, artist, album, and genre management
- Playlist creation and song mapping
- Listening history tracking
- Subscription management system
- Security roles and permissions
- Stored procedures, functions, views, and triggers
- Transaction handling and indexing optimization

---

## Team members

| Name | Student # | GitHub username | Main code contributions |
|------|-----------|-----------------|-------------------------|
| Nunemuntala Sahasri | N10010782 | [sahasri1807] | views/, triggers/, migrations/, security/, test_cases/, optimization/, deploy scripts |
| Kelvin Idoko | N01777723 | [KelvinIdoko] | schema/Roles.sql, Users.sql, Artists.sql, procedures/ |
| Hassana Abdullahi | N10000326 | [hafsatuhassana] | schema/ (Albums→Subscriptions), seed/test_data, functions/, views/ |

**Collaboration:** `ER Diagram.png` and `Course Specific Phase 1.pdf` were produced together by all three members.

--- 
##  Schema Overview (Phase 1 — actual columns)

The database is normalized to **Third Normal Form (3NF)** and includes:

| Table | Columns | Keys |
|-------|---------|------|
| **Roles** | RoleID, RoleName | PK RoleID |
| **Users** | UserID, FullName, Email, RoleID, CreatedAt (+ Phase 2: Status) | PK UserID; FK RoleID → Roles |
| **Artists** | ArtistID, ArtistName, Country | PK ArtistID |
| **Albums** | AlbumID, Title, ArtistID, ReleaseYear | PK AlbumID; FK ArtistID → Artists |
| **Genres** | GenreID, GenreName | PK GenreID |
| **Songs** | SongID, Title, Duration, ArtistID, AlbumID, GenreID, ReleaseDate, **PlayCount** | PK SongID; FKs → Artists, Albums, Genres |
| **Playlists** | PlaylistID, UserID, PlaylistName, CreatedAt | PK PlaylistID; FK UserID → Users |
| **PlaylistSongs** | PlaylistID, SongID, AddedAt | PK (PlaylistID, SongID); FKs → Playlists, Songs |
| **ListeningHistory** | HistoryID, UserID, SongID, PlayedAt | PK HistoryID; FKs → Users, Songs |
| **Subscriptions** | SubscriptionID, Type, Price, StartDate, EndDate (+ Phase 2: UserID) | PK SubscriptionID; FK UserID → Users (Phase 2) |

Relationships ensure data consistency, referential integrity, and elimination of redundancy.

Phase 1 `CREATE TABLE` scripts live in `schema/`.

---

## Phase 2 — Procedural T-SQL, Security & Tests

### Adaptations from Phase 1 schema
- **Songs.PlayCount already exists** — `trg_LogStreamingActivity` increments it on `ListeningHistory` INSERT; `GetSongPlayCount` reads `Songs.PlayCount` (not a derived COUNT).
- **Subscriptions had no UserID** and **Users had no Status** — required for `ManageSubscription`, `CreatePlaylist` (active user), and `GetUserSubscriptionStatus`. Minimal idempotent migration: `migrations/001_Phase2_SchemaExtensions.sql` (adds `Users.Status`, `Subscriptions.UserID` + FK). No new tables invented.

## Phase 3 optimization

Indexes in `optimization/indexes.sql`: PK clustered defaults; `IX_Songs_ArtistID` (NC+INCLUDE); `IX_ListeningHistory_UserID_Include`; `IX_Songs_PlayCount_Filtered`

Also: `performance_test.sql` (STATISTICS), `execution_plans.sql` (SHOWPLAN_TEXT), `performance_notes.md`, `check_exisiting_indexes.sql`, `test_data.sql`


### Folder structure
```
SQL Developer Project/
  schema/                 -- Phase 1 tables + seed_reference_data.sql
  migrations/             -- Phase 2 minimal ALTERs
  procedures/             -- stored procedures + cursor reports
  functions/              -- UDFs
  views/                  -- reporting / filter-friendly views
  triggers/               -- DML triggers
  security/               -- permissions
  test_cases/             -- test_cases.sql + test_data.sql
  optimization/           -- indexes + query optimization + performance tests
  final_script.sql        -- complete Phase 1 + Phase 2 + Phase 3 deployment

```

### Objects delivered

#### Stored procedures (`procedures/`)
| Object | Description |
|--------|-------------|
| `AddNewUser` | Insert user; validate unique Email; assign default Role (`User`) |
| `AddSong` | Upload song; validate Artist / Album / Genre |
| `CreatePlaylist` | Validate Active user; insert playlist |
| `AddSongToPlaylist` | Prevent duplicates; BEGIN TRAN / COMMIT / ROLLBACK |
| `ManageSubscription` | Upgrade subscription + update user Status (transaction) |
| `SearchSongsDynamic` | Dynamic SQL via `sp_executesql`; optional Genre / Artist / Title |
| `ReportArtistSongCounts` | **STATIC cursor** — artists + song counts |
| `ProcessSongsDynamicCursor` | **DYNAMIC cursor** + dynamic SQL metadata per song |

Each procedure uses parameters, validation, `IF`, `TRY/CATCH`, and transactions for DML.

#### Functions (`functions/`)
| Object | Description |
|--------|-------------|
| `GetUserSubscriptionStatus(@UserID)` | Inline TVF — subscription type/status |
| `GetSongPlayCount(@SongID)` | Scalar — `Songs.PlayCount` |

#### Views (`views/`)
| Object | Description |
|--------|-------------|
| `vw_UserListeningHistory` | User name, song title, artist, PlayedAt (+ UserID filter column) |
| `vw_SongDetails` | Song, artist, album, genre, PlayCount |
| `vw_UserPlaylistDetails` | User, playlist, songs (+ UserID / PlaylistID) |

#### Triggers (`triggers/`)
| Object | Description |
|--------|-------------|
| `trg_PreventDuplicatePlaylistSongs` | INSTEAD OF INSERT on PlaylistSongs |
| `trg_LogStreamingActivity` | AFTER INSERT on ListeningHistory → increment Songs.PlayCount |
| `trg_PreventInvalidSongDelete` | INSTEAD OF DELETE on Songs if referenced by PlaylistSongs or ListeningHistory |

#### Security (`security/permissions.sql`)
SQL Server roles: **MusicAdmin**, **MusicUser**, **MusicArtist**, **MusicModerator** with GRANT / REVOKE / DENY. Includes commented permission smoke tests per role.

#### Tests (`test_cases/test_cases.sql`)
Covers successful transactions, failed ROLLBACK, duplicate playlist song, invalid subscription, and invalid song delete (`BEGIN` / `COMMIT` / `ROLLBACK` / `TRY` / `CATCH`).

---

## How to run in SSMS (order)

1. Create a database (e.g. `MusicStreamingDB`) and **select it** in the SSMS database dropdown.
2. Enable **Query → SQLCMD Mode** (required for `:r` includes in `final_script.sql`).
3. Open and execute `final_script.sql`  
   (creates Phase 1 tables + Phase 2 objects + Phase 3 indexes in one run).
4. Execute `test_cases/test_data.sql` (sample data).
5. Execute `test_cases/test_cases.sql` (transaction + isolation tests).
6. Optional: run `optimization/performance_test.sql` and `optimization/execution_plans.sql`.
7. Optional: uncomment the permission test harness at the bottom of `security/permissions.sql`.

### Quick smoke checks after deploy
```sql
EXEC app.SearchSongsDynamic @GenreName = 'Pop';
EXEC app.ReportArtistSongCounts;
EXEC app.ProcessSongsDynamicCursor @MinPlayCount = 0;
SELECT * FROM reports.vw_SongDetails;
SELECT app.GetSongPlayCount(1);
SELECT * FROM app.GetUserSubscriptionStatus(1);
```

---

##  Security Implementation

- Role-based access control (Admin, User, Artist, Moderator) — application `Roles` table **and** SQL Server `Music*` roles
- GRANT, REVOKE, DENY permissions applied
- Row-level access supported via filter-friendly view columns (`UserID`, `PlaylistID`)
- Access restricted based on user roles

---

##  Key Functionalities

- Stored Procedures (5+ plus dynamic SQL + 2 cursor procedures)
- User Defined Functions (2+)
- Views for abstraction and reporting
- Triggers for enforcing data integrity
- Transaction management using TRY...CATCH
- Cursor-based processing
- Dynamic SQL implementation

---

##  Optimization

- Clustered and non-clustered indexes implemented
- Query execution plan analysis performed
- Performance improved using indexing strategies






















