/*
==============================================================================
  final_script.sql  — Phase III full deployment 
  Database : select MusicStreamingDB (or your DB) in the SSMS dropdown first.
  REQUIRED : Query -> SQLCMD Mode  (so :r includes work)

  Order:
    0) Create schemas (music, app, reports, security)
    1) Phase 1 CREATE TABLE scripts
    2) Phase 2 migration + seed + functions/views/procedures/triggers/security
    3) Phase 3 indexes

  After this file: run test_data.sql, then test_cases/test_cases.sql
==============================================================================
*/

PRINT '========== FINAL SCRIPT START ==========';
PRINT 'Database: ' + DB_NAME();
GO

/* -------------------- Create schemas -------------------- */
PRINT '>>> schema/00_CreateSchemas.sql';
:r schema/00_CreateSchemas.sql

/* -------------------- Phase 1 schema -------------------- */
PRINT '>>> schema/Roles.sql';
:r schema/Roles.sql
PRINT '>>> schema/Users.sql';
:r schema/Users.sql
PRINT '>>> schema/Artists.sql';
:r schema/Artists.sql
PRINT '>>> schema/Albums.sql';
:r schema/Albums.sql
PRINT '>>> schema/Genres.sql';
:r schema/Genres.sql
PRINT '>>> schema/Songs.sql';
:r schema/Songs.sql
PRINT '>>> schema/Playlists.sql';
:r schema/Playlists.sql
PRINT '>>> schema/PlaylistSongs.sql';
:r schema/PlaylistSongs.sql
PRINT '>>> schema/ListeningHistory.sql';
:r schema/ListeningHistory.sql
PRINT '>>> schema/Subscriptions.sql';
:r schema/Subscriptions.sql

/* -------------------- Phase 2 -------------------- */
PRINT '>>> migrations/001_Phase2_SchemaExtensions.sql';
:r migrations/001_Phase2_SchemaExtensions.sql
PRINT '>>> schema/seed_reference_data.sql';
:r schema/seed_reference_data.sql

PRINT '>>> functions';
:r functions/GetSongPlayCount.sql
:r functions/GetUserSubscriptionStatus.sql

PRINT '>>> views';
:r views/vw_UserListeningHistory.sql
:r views/vw_SongDetails.sql
:r views/vw_UserPlaylistDetails.sql

PRINT '>>> procedures';
:r procedures/AddNewUser.sql
:r procedures/AddSong.sql
:r procedures/CreatePlaylist.sql
:r procedures/AddSongToPlaylist.sql
:r procedures/ManageSubscription.sql
:r procedures/SearchSongsDynamic.sql
:r procedures/ReportArtistSongCounts.sql
:r procedures/ProcessSongsDynamicCursor.sql

PRINT '>>> triggers';
:r triggers/PreventDuplicatePlaylistSongs.sql
:r triggers/LogStreamingActivity.sql
:r triggers/PreventInvalidSongDelete.sql

PRINT '>>> security/permissions.sql';
:r security/permissions.sql

/* -------------------- Phase 3 indexes -------------------- */
PRINT '>>> optimization/indexes.sql';
:r optimization/indexes.sql

PRINT '========== FINAL SCRIPT COMPLETE ==========';
PRINT 'Next: test_cases/test_data.sql then test_cases/test_cases.sql';
GO
