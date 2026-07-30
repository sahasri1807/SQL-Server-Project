#!/usr/bin/env bash
# Rebuild deploy_phase2_all.sql from individual Phase 2 scripts (order = deploy_phase2.sql).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
OUT="$ROOT/deploy_phase2_all.sql"

FILES=(
  migrations/001_Phase2_SchemaExtensions.sql
  schema/seed_reference_data.sql
  functions/GetSongPlayCount.sql
  functions/GetUserSubscriptionStatus.sql
  views/vw_UserListeningHistory.sql
  views/vw_SongDetails.sql
  views/vw_UserPlaylistDetails.sql
  procedures/AddNewUser.sql
  procedures/AddSong.sql
  procedures/CreatePlaylist.sql
  procedures/AddSongToPlaylist.sql
  procedures/ManageSubscription.sql
  procedures/SearchSongsDynamic.sql
  procedures/ReportArtistSongCounts.sql
  procedures/ProcessSongsDynamicCursor.sql
  triggers/PreventDuplicatePlaylistSongs.sql
  triggers/LogStreamingActivity.sql
  triggers/PreventInvalidSongDelete.sql
  security/permissions.sql
)

{
  cat <<'EOF'
/*
  Auto-generated concatenated Phase 2 deploy script.
  Select your music database in SSMS, then Execute.
  Generated for SQL Server 2016+ (CREATE OR ALTER requires 2016 SP1).
  Regenerate: bash "SQL Developer Project/build_deploy_phase2_all.sh"
*/
SET NOCOUNT ON;
PRINT 'Phase 2 deploy starting on: ' + DB_NAME();
GO

EOF

  for rel in "${FILES[@]}"; do
    echo "PRINT '>>> Running ${rel}';"
    echo "GO"
    cat "$ROOT/$rel"
    echo ""
    echo "GO"
    echo ""
  done

  cat <<'EOF'
PRINT 'Phase 2 deploy complete. Next: test_cases/transaction_tests.sql';
GO
EOF
} > "$OUT"

echo "Wrote $OUT"
