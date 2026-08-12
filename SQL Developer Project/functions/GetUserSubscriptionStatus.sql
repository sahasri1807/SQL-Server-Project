/*
==============================================================================
  Function  : dbo.GetUserSubscriptionStatus
  Type      : Multi-statement table-valued function (SQL Server 2016 compatible)
  Purpose   : Return current subscription type/status for a user.
  Uses      : Subscriptions (UserID, Type, Price, StartDate, EndDate),
              Users (Status)
  Note      : Requires migrations/001_Phase2_SchemaExtensions.sql
==============================================================================
*/ 
CREATE OR ALTER FUNCTION dbo.GetUserSubscriptionStatus
(
    @UserID INT
)
RETURNS @Result TABLE
(
    UserID             INT,
    FullName           VARCHAR(100),
    UserStatus         VARCHAR(20),
    SubscriptionID     INT,
    SubscriptionType   VARCHAR(50),
    Price              DECIMAL(10,2),
    StartDate          DATE,
    EndDate            DATE,
    SubscriptionStatus VARCHAR(20)
)
AS
BEGIN
    INSERT INTO @Result (
        UserID, FullName, UserStatus, SubscriptionID, SubscriptionType,
        Price, StartDate, EndDate, SubscriptionStatus
    )
    SELECT TOP (1)
        u.UserID,
        u.FullName,
        u.Status,
        s.SubscriptionID,
        s.Type,
        s.Price,
        s.StartDate,
        s.EndDate,
        CASE
            WHEN s.SubscriptionID IS NULL THEN 'None'
            WHEN s.EndDate IS NULL OR s.EndDate >= CAST(GETDATE() AS DATE) THEN 'Current'
            ELSE 'Expired'
        END
    FROM dbo.Users AS u
    LEFT JOIN dbo.Subscriptions AS s
        ON s.UserID = u.UserID
    WHERE u.UserID = @UserID
    ORDER BY
        CASE
            WHEN s.EndDate IS NULL OR s.EndDate >= CAST(GETDATE() AS DATE) THEN 0
            ELSE 1
        END,
        s.StartDate DESC;

    RETURN;
END;
GO
