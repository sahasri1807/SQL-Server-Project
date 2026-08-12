/*
==============================================================================
  Create application schemas (must run before tables/objects)
==============================================================================
*/
SET NOCOUNT ON;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'music')
    EXEC(N'CREATE SCHEMA music');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'app')
    EXEC(N'CREATE SCHEMA app');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'reports')
    EXEC(N'CREATE SCHEMA reports');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'security')
    EXEC(N'CREATE SCHEMA security');
GO

PRINT 'Schemas music, app, reports, security ready.';
GO
