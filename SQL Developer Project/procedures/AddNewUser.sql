/*
==============================================================================
  Procedure : app.AddNewUser
  Purpose   : Insert a new user with unique email and default application role.
  Uses      : Users (FullName, Email, RoleID, Status), Roles (RoleName)
==============================================================================
*/
CREATE OR ALTER PROCEDURE app.AddNewUser
    @FullName   VARCHAR(100),
    @Email      VARCHAR(100),
    @RoleName   VARCHAR(50) = 'User',   -- default application role from Roles
    @NewUserID  INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @RoleID INT;
    DECLARE @ErrorMessage NVARCHAR(4000);

    BEGIN TRY
        /* ---- Validation ---- */
        IF @FullName IS NULL OR LTRIM(RTRIM(@FullName)) = ''
            THROW 50001, 'FullName is required.', 1;

        IF @Email IS NULL OR LTRIM(RTRIM(@Email)) = ''
            THROW 50002, 'Email is required.', 1;

        IF @Email NOT LIKE '%_@_%.__%'
            THROW 50003, 'Email format is invalid.', 1;

        IF EXISTS (SELECT 1 FROM music.Users WHERE Email = @Email)
            THROW 50004, 'Email already exists. User not created.', 1;

        SELECT @RoleID = RoleID
        FROM music.Roles
        WHERE RoleName = @RoleName;

        IF @RoleID IS NULL
            THROW 50005, 'Specified RoleName does not exist in Roles.', 1;

        BEGIN TRANSACTION;

        INSERT INTO music.Users (FullName, Email, RoleID, Status)
        VALUES (@FullName, @Email, @RoleID, 'Active');

        SET @NewUserID = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        PRINT 'User created successfully. UserID = ' + CAST(@NewUserID AS VARCHAR(20));
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @ErrorMessage = ERROR_MESSAGE();
        SET @NewUserID = NULL;
        THROW 50099, @ErrorMessage, 1;
    END CATCH
END;
GO
