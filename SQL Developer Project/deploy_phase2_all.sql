PRINT 'Deploying Music Streaming Database Phase 2';
GO

:r migrations/001_Phase2_SchemaExtensions.sql
:r schema/seed_reference_data.sql

:r functions/GetSongPlayCount.sql
:r functions/GetUserSubscriptionStatus.sql

:r views/vw_UserListeningHistory.sql
:r views/vw_SongDetails.sql
:r views/vw_UserPlaylistDetails.sql

:r procedures/AddNewUser.sql
:r procedures/AddSong.sql
:r procedures/CreatePlaylist.sql
:r procedures/AddSongToPlaylist.sql
:r procedures/ManageSubscription.sql
:r procedures/SearchSongsDynamic.sql
:r procedures/ReportArtistSongCounts.sql
:r procedures/ProcessSongsDynamicCursor.sql

:r triggers/PreventDuplicatePlaylistSongs.sql
:r triggers/LogStreamingActivity.sql
:r triggers/PreventInvalidSongDelete.sql

:r security/permissions.sql

PRINT 'Phase 2 Deployment Completed';
GO

PRINT 'Next: test_cases/test_cases.sql';
GO
