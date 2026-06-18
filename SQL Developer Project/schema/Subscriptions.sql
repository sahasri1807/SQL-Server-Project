CREATE TABLE Subscriptions (
    SubscriptionID INT IDENTITY(1,1) PRIMARY KEY,
    Type VARCHAR(50) NOT NULL,
    Price DECIMAL(10,2) NOT NULL,
    StartDate DATE,
    EndDate DATE
);