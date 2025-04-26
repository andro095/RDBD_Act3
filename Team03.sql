-- Assignment-4

-- Team Member Names: Dev Bharatbhai Patel
--					  Diego Bolaños Osejo
--					  Andre Sebastian Rodriguez Ovalle

-- Task-2
-- USE AmalgamatedBIGCO;
-- GO

-- New Necessary Table Creation

-- 1. INVOICE Table
CREATE TABLE Sales.Invoice (
    invoiceId INT PRIMARY KEY IDENTITY(1,1),
    orderId INT NOT NULL,
    orderType NVARCHAR(10) NOT NULL CHECK (orderType IN ('B2B', 'B2C')),
    invoiceDate DATETIME NOT NULL,
    totalAmount DECIMAL(10, 2) NOT NULL,
    status NVARCHAR(50),
    FOREIGN KEY (orderId) REFERENCES Sales.OrdersB2B(orderId) ON DELETE CASCADE,
    FOREIGN KEY (orderId) REFERENCES Sales.OrdersB2C(orderId) ON DELETE CASCADE 
);

-- 2. PAYMENT Table
CREATE TABLE Sales.PAYMENT (
    paymentId INT PRIMARY KEY IDENTITY(1,1),
    invoiceId INT NOT NULL, 
    paymentDate DATETIME NOT NULL,
    paymentMethod NVARCHAR(50) NOT NULL,
    amount MONEY NOT NULL,
    FOREIGN KEY (invoiceId) REFERENCES Sales.Invoice(invoiceId)
);

-- 3. ACCOUNT Table
CREATE TABLE HR.Account (
    userId NVARCHAR(50) PRIMARY KEY,
    username NVARCHAR(100) NOT NULL UNIQUE,
    passwordHash VARBINARY(MAX) NOT NULL,
    email NVARCHAR(255) NOT NULL UNIQUE,
    createdDate DATETIME DEFAULT GETDATE()
);


-- 4. AUDIT Table
CREATE TABLE Sales.Audit (
    auditId BIGINT PRIMARY KEY IDENTITY(1,1),
    auditDate DATE NOT NULL,
    auditTime TIME NOT NULL,
    userId NVARCHAR(50) NOT NULL, 
    action NVARCHAR(100) NOT NULL,
    details NVARCHAR(MAX),
    FOREIGN KEY (userId) REFERENCES HR.Account(userId)
);

-- 5. PERMISSIONROLE Table
CREATE TABLE HR.PermissionRole (
    roleId INT PRIMARY KEY IDENTITY(1,1),
    roleName NVARCHAR(100) NOT NULL UNIQUE,
    description NVARCHAR(MAX)
);

-- 6. ACCOUNTROLE Table
CREATE TABLE HR.AccountRole (
    accountRoleId INT PRIMARY KEY IDENTITY(1,1),
    userId NVARCHAR(50) NOT NULL, 
    roleId INT NOT NULL,
    FOREIGN KEY (userId) REFERENCES HR.Account(userId),
    FOREIGN KEY (roleId) REFERENCES HR.PermissionRole(roleId)
);

-- 7. LOG Table
CREATE TABLE Sales.Log (
    logId BIGINT PRIMARY KEY IDENTITY(1,1),
    logDate DATE NOT NULL,
    logTime TIME NOT NULL,
    event NVARCHAR(255) NOT NULL,
    details NVARCHAR(MAX)
);

-- 8. REMEMBERLOGIN Table (Temporary Table)
CREATE TABLE HR.RememberLogin (
    sessionId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    userId NVARCHAR(50) NOT NULL,
    loginTime DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (userId) REFERENCES HR.Account(userId)
);


-- Stored Procedures

------  Sales.Invoice Table ----------------------------
-- Insert Invoice
CREATE PROCEDURE Sales.InsertInvoice
    @orderId INT,
    @orderType NVARCHAR(50),
    @invoiceDate DATETIME,
    @totalAmount DECIMAL,
    @status NVARCHAR(50)
AS
BEGIN
    IF @orderType = 'B2B'
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM Sales.OrdersB2B WHERE orderId = @orderId)
        BEGIN
            RAISERROR('The orderId does not exist in OrdersB2B.', 16, 1);
            RETURN;
        END
    END
    ELSE IF @orderType = 'B2C'
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM Sales.OrdersB2C WHERE orderId = @orderId)
        BEGIN
            RAISERROR('The orderId does not exist in OrdersB2C.', 16, 1);
            RETURN;
        END
    END
    
    INSERT INTO Sales.Invoice (orderId, orderType, invoiceDate, totalAmount, status)
    VALUES (@orderId, @orderType, @invoiceDate, @totalAmount, @status);
END;


-- Update Invoice
CREATE PROCEDURE Sales.UpdateInvoice
    @invoiceId INT,
    @orderId INT,
    @invoiceType NVARCHAR(50),
    @invoiceDate DATETIME,
    @totalAmount DECIMAL,
    @status NVARCHAR(50)
AS
BEGIN
    UPDATE Sales.Invoice
    SET orderId = @orderId,
        orderType = @invoiceType,
        invoiceDate = @invoiceDate,
        totalAmount = @totalAmount,
        status = @status
    WHERE invoiceId = @invoiceId;
END;


-- Delete Invoice
CREATE PROCEDURE Sales.DeleteInvoice
    @invoiceId INT
AS
BEGIN
    DELETE FROM Sales.Invoice
    WHERE invoiceId = @invoiceId;
END;


------- Sales.Payment Table ----------------------------
-- Insert Payment
CREATE PROCEDURE Sales.InsertPayment
    @invoiceId INT,
    @paymentDate DATETIME,
    @amount DECIMAL(10, 2),
    @paymentMethod NVARCHAR(50)
AS
BEGIN
    INSERT INTO Sales.Payment (invoiceId, paymentDate, amount, paymentMethod)
    VALUES (@invoiceId, @paymentDate, @amount, @paymentMethod);
END;

-- Get Payment by Invoice Number
CREATE PROCEDURE Sales.GetPaymentsByInvoice
    @invoiceId INT
AS
BEGIN
    SELECT * 
    FROM Sales.Payment
    WHERE invoiceId = @invoiceId;
END;

-- Update Payment Method
CREATE PROCEDURE Sales.UpdatePaymentStatus
    @paymentId INT,
	@paymentMethod NVARCHAR(50)
AS
BEGIN
    UPDATE Sales.Payment
    SET paymentMethod = @paymentMethod
    WHERE paymentId = @paymentId;
END;


------- HR.Account Table ----------------------------
-- Insert Account
CREATE PROCEDURE HR.InsertAccount
    @username NVARCHAR(50),
    @password VARBINARY(MAX),
    @email NVARCHAR(50),
    @createdDate DATETIME
AS
BEGIN
    INSERT INTO HR.Account (username, passwordHash, email, createdDate)
    VALUES (@username, @password, @email, @createdDate);
END;

-- Get Account
CREATE PROCEDURE HR.GetAccountById
    @accountId INT
AS
BEGIN
    SELECT * 
    FROM HR.Account
    WHERE userId = @accountId;
END;

-- Update Account
CREATE PROCEDURE HR.UpdateAccount
    @accountId INT,
    @createdDate DATETIME
AS
BEGIN
    UPDATE HR.Account
    SET createdDate = @createdDate
    WHERE userId = @accountId;
END;

------- HR.Audit Table ----------------------------

-- Insert AuditLogs
CREATE PROCEDURE Sales.InsertAuditLog
	@userid INT,
    @action NVARCHAR(255),
    @auditDate DATE,
	@auditTime DATETIME
AS
BEGIN
    INSERT INTO Sales.Audit (userId, action, auditDate, auditTime)
    VALUES (@userid, @action, @auditDate, @auditTime);
END;

-- Get AuditLogs
CREATE PROCEDURE Sales.GetAuditLogsByDate
    @startDate DATETIME,
    @endDate DATETIME
AS
BEGIN
    SELECT * 
    FROM Sales.Audit
    WHERE auditDate BETWEEN @startDate AND @endDate;
END;


------- HR.AccountRole Table ----------------------------

-- Assign Role to Account
CREATE PROCEDURE HR.AssignRoleToAccount
    @accountId INT,
    @roleId INT
AS
BEGIN
    INSERT INTO HR.AccountRole (userId, roleId)
    VALUES (@accountId, @roleId);
END;


-- Get Role by Account
CREATE PROCEDURE HR.GetRolesByAccount
    @accountId INT
AS
BEGIN
    SELECT r.roleId, r.roleName 
    FROM HR.AccountRole ar
    INNER JOIN HR.PermissionRole r ON ar.roleId = r.roleId
    WHERE ar.userId = @accountId;
END;



-- Testing the Store Procedures

-- Sales.Invoice
EXEC Sales.InsertInvoice @orderId = 1, @orderType = 'B2C', @invoiceDate = '2015-12-07 07:20:03.000', @totalAmount = 2063.73, @status = 'Paid';

EXEC Sales.UpdateInvoice @invoiceId = 7, @orderId = 1, @invoiceType = 'B2C', @invoiceDate = '2015-12-18 07:20:03.000', @totalAmount = 120.00, @status = 'Unpaid';

EXEC Sales.DeleteInvoice @invoiceId = 7;

-- Sales.Payment
EXEC Sales.InsertPayment @invoiceId = 8, @amount = 100.00, @paymentDate = '2024-12-12', @paymentMethod = 'Credit Card';

EXEC Sales.GetPaymentsByInvoice @invoiceId = 8;

EXEC Sales.UpdatePaymentStatus @paymentID = 3, @paymentMethod= 'Debit Card';



