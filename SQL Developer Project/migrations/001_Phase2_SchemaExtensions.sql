/*
==============================================================================
  Migration: 001_Phase2_SchemaExtensions.sql
  Purpose  : Minimal Phase 2 extensions required by procedures/functions.
  Why      : Phase 1 Subscriptions has no UserID link, and Users has no Status.
             Instructor Phase 2 needs ManageSubscription + active-user checks.
  Notes    : Idempotent — safe to re-run. Does NOT invent new tables.
==============================================================================
*/

SET NOCOUNT ON;
GO

/* --------------------------------------------------------------------------
   1) Users.Status — used by CreatePlaylist (active user) and ManageSubscription
   -------------------------------------------------------------------------- */
IF COL_LENGTH('dbo.Users', 'Status') IS NULL
BEGIN
    ALTER TABLE dbo.Users
        ADD Status VARCHAR(20) NOT NULL
            CONSTRAINT DF_Users_Status DEFAULT ('Active');
    PRINT 'Added Users.Status (default Active).';
END
ELSE
    PRINT 'Users.Status already exists — skipped.';
GO

/* --------------------------------------------------------------------------
   2) Subscriptions.UserID — links a subscription row to a user
   Phase 1 Subscriptions columns: SubscriptionID, Type, Price, StartDate, EndDate
   -------------------------------------------------------------------------- */
IF COL_LENGTH('dbo.Subscriptions', 'UserID') IS NULL
BEGIN
    ALTER TABLE dbo.Subscriptions
        ADD UserID INT NULL;
    PRINT 'Added Subscriptions.UserID (nullable pending FK).';
END
ELSE
    PRINT 'Subscriptions.UserID already exists — skipped.';
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE name = 'FK_Subscriptions_Users'
      AND parent_object_id = OBJECT_ID('dbo.Subscriptions')
)
BEGIN
    ALTER TABLE dbo.Subscriptions
        ADD CONSTRAINT FK_Subscriptions_Users
        FOREIGN KEY (UserID) REFERENCES dbo.Users(UserID);
    PRINT 'Added FK_Subscriptions_Users.';
END
ELSE
    PRINT 'FK_Subscriptions_Users already exists — skipped.';
GO

PRINT 'Phase 2 schema extensions complete.';
GO
