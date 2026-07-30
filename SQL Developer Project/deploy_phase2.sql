/*
==============================================================================
  Deploy guide : deploy_phase2.sql
  Run each file below IN ORDER in SSMS against your music database.
  (Phase 1 style — no forced USE; select the database in the SSMS dropdown.)

  Prerequisites:
    - All schema/*.sql Phase 1 CREATE TABLE scripts already executed
==============================================================================

  ORDER OF EXECUTION
  ------------------
  1. migrations/001_Phase2_SchemaExtensions.sql
  2. schema/seed_reference_data.sql
  3. functions/GetSongPlayCount.sql
  4. functions/GetUserSubscriptionStatus.sql
  5. views/vw_UserListeningHistory.sql
  6. views/vw_SongDetails.sql
  7. views/vw_UserPlaylistDetails.sql
  8. procedures/AddNewUser.sql
  9. procedures/AddSong.sql
 10. procedures/CreatePlaylist.sql
 11. procedures/AddSongToPlaylist.sql
 12. procedures/ManageSubscription.sql
 13. procedures/SearchSongsDynamic.sql
 14. procedures/ReportArtistSongCounts.sql
 15. procedures/ProcessSongsDynamicCursor.sql
 16. triggers/PreventDuplicatePlaylistSongs.sql
 17. triggers/LogStreamingActivity.sql
 18. triggers/PreventInvalidSongDelete.sql
 19. security/permissions.sql
 20. test_cases/transaction_tests.sql

  Tip: For one-shot deploy, run deploy_phase2_all.sql (concatenated script).
*/

PRINT 'Open deploy_phase2.sql for the execution order checklist.';
PRINT 'Or execute deploy_phase2_all.sql for a single-batch deploy.';
PRINT 'Current database: ' + DB_NAME();
GO
