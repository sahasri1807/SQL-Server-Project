/*
==============================================================================
  optimization/execution_plans.sql
  Phase III — Execution plan capture using SET SHOWPLAN_TEXT
  Spec: "Execution plan capture (e.g., SET SHOWPLAN_TEXT)"

  IMPORTANT:
  - SHOWPLAN_TEXT does NOT execute the query; it returns the estimated plan.
  - Run AFTER indexes.sql and test_data.sql for meaningful plans.
==============================================================================
*/

SET NOCOUNT ON;
GO

PRINT '========== EXECUTION PLAN CAPTURE (SHOWPLAN_TEXT) ==========';
GO

PRINT '--- PLAN 1: Songs by ArtistID ---';
GO
SET SHOWPLAN_TEXT ON;
GO
SELECT s.SongID, s.Title, s.GenreID, s.AlbumID, s.Duration, s.PlayCount, s.ReleaseDate
FROM dbo.Songs AS s
WHERE s.ArtistID = 1;
GO
SET SHOWPLAN_TEXT OFF;
GO

PRINT '--- PLAN 2: ListeningHistory by UserID ---';
GO
SET SHOWPLAN_TEXT ON;
GO
SELECT lh.HistoryID, lh.UserID, lh.SongID, lh.PlayedAt
FROM dbo.ListeningHistory AS lh
WHERE lh.UserID = 1;
GO
SET SHOWPLAN_TEXT OFF;
GO

PRINT '--- PLAN 3: Songs with PlayCount > 0 ---';
GO
SET SHOWPLAN_TEXT ON;
GO
SELECT s.SongID, s.Title, s.ArtistID, s.PlayCount
FROM dbo.Songs AS s
WHERE s.PlayCount > 0
ORDER BY s.PlayCount DESC;
GO
SET SHOWPLAN_TEXT OFF;
GO

PRINT '========== SHOWPLAN CAPTURE COMPLETE ==========';
PRINT 'Also run optimization/performance_test.sql for STATISTICS IO/TIME.';
GO
