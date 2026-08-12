/*
==============================================================================
  Procedure : dbo.ManageSubscription
  Purpose   : Upgrade/change a user's subscription and update user Status
              inside a single transaction.
  Uses      : Subscriptions (Type, Price, StartDate, EndDate, UserID),
              Users (Status)
  Note      : Requires migrations/001_Phase2_SchemaExtensions.sql
==============================================================================
*/
    @UserID           INT,
    @SubscriptionType VARCHAR(50),
    @Price            DECIMAL(10,2),
    @Months           INT = 1,
    @NewSubscriptionID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @StartDate DATE = CAST(GETDATE() AS DATE);
    DECLARE @EndDate DATE;
    DECLARE @NewStatus VARCHAR(20);

    BEGIN TRY
        IF @UserID IS NULL OR NOT EXISTS (SELECT 1 FROM dbo.Users WHERE UserID = @UserID)
            THROW 50041, 'UserID does not exist.', 1;

        IF @SubscriptionType IS NULL OR LTRIM(RTRIM(@SubscriptionType)) = ''
            THROW 50042, 'SubscriptionType is required.', 1;

        IF @SubscriptionType NOT IN ('Free', 'Basic', 'Premium', 'Family')
            THROW 50043, 'Invalid subscription type. Allowed: Free, Basic, Premium, Family.', 1;

        IF @Price IS NULL OR @Price < 0
            THROW 50044, 'Price must be zero or positive.', 1;

        IF @Months IS NULL OR @Months <= 0
            THROW 50045, 'Months must be a positive integer.', 1;

        SET @EndDate = DATEADD(MONTH, @Months, @StartDate);
        SET @NewStatus = CASE
            WHEN @SubscriptionType = 'Free' THEN 'Active'
            ELSE 'Active'
        END;

        BEGIN TRANSACTION;

        /* Close any open subscription for this user */
        UPDATE dbo.Subscriptions
        SET EndDate = DATEADD(DAY, -1, @StartDate)
        WHERE UserID = @UserID
          AND (EndDate IS NULL OR EndDate >= @StartDate);

        INSERT INTO dbo.Subscriptions (Type, Price, StartDate, EndDate, UserID)
        VALUES (@SubscriptionType, @Price, @StartDate, @EndDate, @UserID);

        SET @NewSubscriptionID = SCOPE_IDENTITY();

        UPDATE dbo.Users
        SET Status = @NewStatus
        WHERE UserID = @UserID;

        COMMIT TRANSACTION;

        PRINT 'Subscription updated. SubscriptionID = '
            + CAST(@NewSubscriptionID AS VARCHAR(20))
            + '; User Status = ' + @NewStatus;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @ErrorMessage = ERROR_MESSAGE();
        SET @NewSubscriptionID = NULL;
        THROW 50099, @ErrorMessage, 1;
    END CATCH
END;
GO
