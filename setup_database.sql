-- =============================================================================
-- HardSwap FIEI - Script de creación de Base de Datos
-- Motor: SQL Server (Microsoft SQL Server 2019+)
-- Descripción: Marketplace de hardware para estudiantes FIEI-UNFV
-- Ejecutar con: sqlcmd -S localhost -i setup_database.sql
--               o desde SQL Server Management Studio (SSMS)
-- =============================================================================

USE master;
GO

-- ============================================================
-- 1. Crear la base de datos si no existe
-- ============================================================
IF NOT EXISTS (
    SELECT name FROM sys.databases WHERE name = N'HardSwapFIEI'
)
BEGIN
    CREATE DATABASE HardSwapFIEI
        COLLATE Modern_Spanish_CI_AS; -- Soporte completo para español (tildes, ñ)
    PRINT 'Base de datos HardSwapFIEI creada exitosamente.';
END
ELSE
BEGIN
    PRINT 'La base de datos HardSwapFIEI ya existe. Continuando...';
END
GO

USE HardSwapFIEI;
GO

-- ============================================================
-- 2. Crear tipos de usuario definidos (ENUM equivalentes)
-- ============================================================

-- Usamos una tabla de lookup para simular el enum ProductStatus de Prisma
-- SQL Server no tiene ENUM nativo; se usa CHECK CONSTRAINT

-- ============================================================
-- 3. Tabla: Users
--    Equivalente al modelo User de Prisma (NextAuth + campos custom)
-- ============================================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Users')
BEGIN
    CREATE TABLE Users (
        Id              UNIQUEIDENTIFIER    NOT NULL DEFAULT NEWID(),
        Name            NVARCHAR(255)       NULL,
        Email           NVARCHAR(320)       NULL,
        EmailVerified   DATETIME2           NULL,
        Image           NVARCHAR(2048)      NULL,
        WhatsappNumber  NVARCHAR(20)        NULL,        -- Con código de país: "51987654321"
        CreatedAt       DATETIME2           NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt       DATETIME2           NOT NULL DEFAULT SYSUTCDATETIME(),

        CONSTRAINT PK_Users         PRIMARY KEY (Id),
        CONSTRAINT UQ_Users_Email   UNIQUE (Email)
    );

    PRINT 'Tabla Users creada.';
END
GO

-- ============================================================
-- 4. Tabla: Accounts
--    Equivalente al modelo Account de NextAuth (OAuth providers)
-- ============================================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Accounts')
BEGIN
    CREATE TABLE Accounts (
        Id                  UNIQUEIDENTIFIER    NOT NULL DEFAULT NEWID(),
        UserId              UNIQUEIDENTIFIER    NOT NULL,
        Type                NVARCHAR(50)        NOT NULL,
        Provider            NVARCHAR(100)       NOT NULL,    -- "microsoft-entra-id"
        ProviderAccountId   NVARCHAR(255)       NOT NULL,
        RefreshToken        NVARCHAR(MAX)       NULL,
        AccessToken         NVARCHAR(MAX)       NULL,
        ExpiresAt           INT                 NULL,        -- Unix timestamp
        TokenType           NVARCHAR(50)        NULL,
        Scope               NVARCHAR(1000)      NULL,
        IdToken             NVARCHAR(MAX)       NULL,
        SessionState        NVARCHAR(255)       NULL,

        CONSTRAINT PK_Accounts                      PRIMARY KEY (Id),
        CONSTRAINT UQ_Accounts_Provider             UNIQUE (Provider, ProviderAccountId),
        CONSTRAINT FK_Accounts_Users                FOREIGN KEY (UserId)
            REFERENCES Users(Id) ON DELETE CASCADE
    );

    PRINT 'Tabla Accounts creada.';
END
GO

-- ============================================================
-- 5. Tabla: Sessions
--    Equivalente al modelo Session de NextAuth
-- ============================================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Sessions')
BEGIN
    CREATE TABLE Sessions (
        Id              UNIQUEIDENTIFIER    NOT NULL DEFAULT NEWID(),
        SessionToken    NVARCHAR(500)       NOT NULL,
        UserId          UNIQUEIDENTIFIER    NOT NULL,
        Expires         DATETIME2           NOT NULL,

        CONSTRAINT PK_Sessions                  PRIMARY KEY (Id),
        CONSTRAINT UQ_Sessions_SessionToken     UNIQUE (SessionToken),
        CONSTRAINT FK_Sessions_Users            FOREIGN KEY (UserId)
            REFERENCES Users(Id) ON DELETE CASCADE
    );

    PRINT 'Tabla Sessions creada.';
END
GO

-- ============================================================
-- 6. Tabla: VerificationTokens
--    Equivalente al modelo VerificationToken de NextAuth
-- ============================================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'VerificationTokens')
BEGIN
    CREATE TABLE VerificationTokens (
        Identifier  NVARCHAR(320)   NOT NULL,
        Token       NVARCHAR(500)   NOT NULL,
        Expires     DATETIME2       NOT NULL,

        CONSTRAINT PK_VerificationTokens   PRIMARY KEY (Identifier, Token),
        CONSTRAINT UQ_VerificationTokens   UNIQUE (Token)
    );

    PRINT 'Tabla VerificationTokens creada.';
END
GO

-- ============================================================
-- 7. Tabla: Categories
--    Equivalente al modelo Category de Prisma
-- ============================================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Categories')
BEGIN
    CREATE TABLE Categories (
        Id          UNIQUEIDENTIFIER    NOT NULL DEFAULT NEWID(),
        Name        NVARCHAR(100)       NOT NULL,
        CreatedAt   DATETIME2           NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt   DATETIME2           NOT NULL DEFAULT SYSUTCDATETIME(),

        CONSTRAINT PK_Categories        PRIMARY KEY (Id),
        CONSTRAINT UQ_Categories_Name   UNIQUE (Name)
    );

    PRINT 'Tabla Categories creada.';
END
GO

-- ============================================================
-- 8. Tabla: Products
--    Equivalente al modelo Product de Prisma
--    NOTA: imageUrls y tags (arrays en PostgreSQL) se normalizan
--          en tablas separadas (ProductImages, ProductTags)
-- ============================================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Products')
BEGIN
    CREATE TABLE Products (
        Id          UNIQUEIDENTIFIER    NOT NULL DEFAULT NEWID(),
        Title       NVARCHAR(80)        NOT NULL,
        Description NVARCHAR(500)       NOT NULL,
        Price       INT                 NOT NULL,           -- En centavos (ej: 1500 = S/ 15.00)
        Status      NVARCHAR(20)        NOT NULL DEFAULT 'AVAILABLE',
        UserId      UNIQUEIDENTIFIER    NOT NULL,
        CategoryId  UNIQUEIDENTIFIER    NOT NULL,
        CreatedAt   DATETIME2           NOT NULL DEFAULT SYSUTCDATETIME(),
        ExpiresAt   DATETIME2           NOT NULL,           -- CreatedAt + 14 días
        UpdatedAt   DATETIME2           NOT NULL DEFAULT SYSUTCDATETIME(),

        CONSTRAINT PK_Products              PRIMARY KEY (Id),
        CONSTRAINT FK_Products_Users        FOREIGN KEY (UserId)
            REFERENCES Users(Id) ON DELETE CASCADE,
        CONSTRAINT FK_Products_Categories   FOREIGN KEY (CategoryId)
            REFERENCES Categories(Id),                      -- ON DELETE RESTRICT (default)
        CONSTRAINT CK_Products_Status       CHECK (Status IN ('AVAILABLE', 'RESERVED', 'SOLD', 'EXPIRED')),
        CONSTRAINT CK_Products_Price        CHECK (Price > 0),
        CONSTRAINT CK_Products_Title        CHECK (LEN(LTRIM(RTRIM(Title))) >= 3),
        CONSTRAINT CK_Products_ExpiresAt    CHECK (ExpiresAt > CreatedAt)
    );

    PRINT 'Tabla Products creada.';
END
GO

-- ============================================================
-- 9. Tabla: ProductImages
--    Normalización del array imageUrls[] de Prisma/PostgreSQL
--    SQL Server no tiene tipo array nativo; se usa tabla hija
-- ============================================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ProductImages')
BEGIN
    CREATE TABLE ProductImages (
        Id          INT                 NOT NULL IDENTITY(1,1),
        ProductId   UNIQUEIDENTIFIER    NOT NULL,
        ImageUrl    NVARCHAR(2048)      NOT NULL,
        SortOrder   TINYINT             NOT NULL DEFAULT 0,    -- 0 = imagen principal

        CONSTRAINT PK_ProductImages             PRIMARY KEY (Id),
        CONSTRAINT FK_ProductImages_Products    FOREIGN KEY (ProductId)
            REFERENCES Products(Id) ON DELETE CASCADE,
        CONSTRAINT CK_ProductImages_SortOrder   CHECK (SortOrder BETWEEN 0 AND 2)  -- Máx 3 imágenes
    );

    PRINT 'Tabla ProductImages creada.';
END
GO

-- ============================================================
-- 10. Tabla: ProductTags
--     Normalización del array tags[] de Prisma/PostgreSQL
--     Usado para subcategorías (llenado por IA en futuras versiones)
-- ============================================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ProductTags')
BEGIN
    CREATE TABLE ProductTags (
        Id          INT                 NOT NULL IDENTITY(1,1),
        ProductId   UNIQUEIDENTIFIER    NOT NULL,
        Tag         NVARCHAR(100)       NOT NULL,

        CONSTRAINT PK_ProductTags           PRIMARY KEY (Id),
        CONSTRAINT FK_ProductTags_Products  FOREIGN KEY (ProductId)
            REFERENCES Products(Id) ON DELETE CASCADE
    );

    PRINT 'Tabla ProductTags creada.';
END
GO

-- ============================================================
-- 11. Índices para optimización de consultas frecuentes
-- ============================================================

-- Catálogo: productos disponibles y no vencidos, más recientes primero
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Products_Catalog' AND object_id = OBJECT_ID('Products'))
BEGIN
    CREATE INDEX IX_Products_Catalog
        ON Products (Status, ExpiresAt, CreatedAt DESC)
        INCLUDE (Title, Description, Price, UserId, CategoryId);
    PRINT 'Índice IX_Products_Catalog creado.';
END
GO

-- Dashboard: productos por usuario
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Products_UserId' AND object_id = OBJECT_ID('Products'))
BEGIN
    CREATE INDEX IX_Products_UserId
        ON Products (UserId, CreatedAt DESC);
    PRINT 'Índice IX_Products_UserId creado.';
END
GO

-- Búsqueda full-text en título (para búsqueda local si se necesita server-side)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Products_Title' AND object_id = OBJECT_ID('Products'))
BEGIN
    CREATE INDEX IX_Products_Title
        ON Products (Title);
    PRINT 'Índice IX_Products_Title creado.';
END
GO

-- Imágenes por producto (para cargar imágenes en orden)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_ProductImages_ProductId' AND object_id = OBJECT_ID('ProductImages'))
BEGIN
    CREATE INDEX IX_ProductImages_ProductId
        ON ProductImages (ProductId, SortOrder ASC);
    PRINT 'Índice IX_ProductImages_ProductId creado.';
END
GO

-- Tags por producto
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_ProductTags_ProductId' AND object_id = OBJECT_ID('ProductTags'))
BEGIN
    CREATE INDEX IX_ProductTags_ProductId
        ON ProductTags (ProductId);
    PRINT 'Índice IX_ProductTags_ProductId creado.';
END
GO

-- Sesiones por usuario (limpieza de sesiones expiradas)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Sessions_Expires' AND object_id = OBJECT_ID('Sessions'))
BEGIN
    CREATE INDEX IX_Sessions_Expires ON Sessions (Expires);
    PRINT 'Índice IX_Sessions_Expires creado.';
END
GO

-- ============================================================
-- 12. Trigger: auto-actualizar UpdatedAt en Products
-- ============================================================
IF OBJECT_ID('TR_Products_UpdatedAt', 'TR') IS NOT NULL
    DROP TRIGGER TR_Products_UpdatedAt;
GO

CREATE TRIGGER TR_Products_UpdatedAt
ON Products
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Products
    SET UpdatedAt = SYSUTCDATETIME()
    FROM Products p
    INNER JOIN inserted i ON p.Id = i.Id;
END
GO

-- ============================================================
-- 13. Trigger: auto-actualizar UpdatedAt en Users
-- ============================================================
IF OBJECT_ID('TR_Users_UpdatedAt', 'TR') IS NOT NULL
    DROP TRIGGER TR_Users_UpdatedAt;
GO

CREATE TRIGGER TR_Users_UpdatedAt
ON Users
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Users
    SET UpdatedAt = SYSUTCDATETIME()
    FROM Users u
    INNER JOIN inserted i ON u.Id = i.Id;
END
GO

-- ============================================================
-- 14. Trigger: auto-actualizar UpdatedAt en Categories
-- ============================================================
IF OBJECT_ID('TR_Categories_UpdatedAt', 'TR') IS NOT NULL
    DROP TRIGGER TR_Categories_UpdatedAt;
GO

CREATE TRIGGER TR_Categories_UpdatedAt
ON Categories
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Categories
    SET UpdatedAt = SYSUTCDATETIME()
    FROM Categories c
    INNER JOIN inserted i ON c.Id = i.Id;
END
GO

-- ============================================================
-- 15. Vista: vw_CatalogProducts
--     Equivalente a getAvailableProducts() de Prisma
--     Usada por la pantalla de catálogo en Flutter
-- ============================================================
IF OBJECT_ID('vw_CatalogProducts', 'V') IS NOT NULL
    DROP VIEW vw_CatalogProducts;
GO

CREATE VIEW vw_CatalogProducts
AS
SELECT
    p.Id,
    p.Title,
    p.Description,
    p.Price,
    p.Status,
    p.CreatedAt,
    p.ExpiresAt,
    -- Categoría
    c.Id   AS CategoryId,
    c.Name AS CategoryName,
    -- Vendedor
    u.Id   AS UserId,
    u.Name AS UserName,
    u.WhatsappNumber
FROM Products p
INNER JOIN Categories c ON p.CategoryId = c.Id
INNER JOIN Users      u ON p.UserId      = u.Id
WHERE
    p.Status    = 'AVAILABLE'
    AND p.ExpiresAt > SYSUTCDATETIME();
GO

-- ============================================================
-- 16. Vista: vw_UserDashboard
--     Equivalente a getUserWithProducts() de Prisma
--     Usada por la pantalla de dashboard en Flutter
-- ============================================================
IF OBJECT_ID('vw_UserDashboard', 'V') IS NOT NULL
    DROP VIEW vw_UserDashboard;
GO

CREATE VIEW vw_UserDashboard
AS
SELECT
    p.Id,
    p.Title,
    p.Description,
    p.Price,
    p.Status,
    p.CreatedAt,
    p.ExpiresAt,
    p.UpdatedAt,
    -- Categoría
    c.Id   AS CategoryId,
    c.Name AS CategoryName,
    -- Propietario
    p.UserId
FROM Products p
INNER JOIN Categories c ON p.CategoryId = c.Id;
GO

-- ============================================================
-- 17. Stored Procedure: sp_MarkProductAsSold
--     Equivalente a markAsSold() de products.ts
-- ============================================================
IF OBJECT_ID('sp_MarkProductAsSold', 'P') IS NOT NULL
    DROP PROCEDURE sp_MarkProductAsSold;
GO

CREATE PROCEDURE sp_MarkProductAsSold
    @ProductId  UNIQUEIDENTIFIER,
    @UserId     UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Products
    SET Status = 'SOLD'
    WHERE Id = @ProductId
      AND UserId = @UserId
      AND Status = 'AVAILABLE';

    SELECT @@ROWCOUNT AS RowsAffected;
END
GO

-- ============================================================
-- 18. Stored Procedure: sp_DeleteProduct
--     Equivalente a deleteProduct() de products.ts
-- ============================================================
IF OBJECT_ID('sp_DeleteProduct', 'P') IS NOT NULL
    DROP PROCEDURE sp_DeleteProduct;
GO

CREATE PROCEDURE sp_DeleteProduct
    @ProductId  UNIQUEIDENTIFIER,
    @UserId     UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM Products
    WHERE Id = @ProductId
      AND UserId = @UserId;

    SELECT @@ROWCOUNT AS RowsAffected;
END
GO

-- ============================================================
-- 19. Stored Procedure: sp_CreateProduct
--     Equivalente a createProduct() de products.ts
-- ============================================================
IF OBJECT_ID('sp_CreateProduct', 'P') IS NOT NULL
    DROP PROCEDURE sp_CreateProduct;
GO

CREATE PROCEDURE sp_CreateProduct
    @Title       NVARCHAR(80),
    @Description NVARCHAR(500),
    @Price       INT,              -- En centavos
    @CategoryId  UNIQUEIDENTIFIER,
    @UserId      UNIQUEIDENTIFIER,
    @ExpiresAt   DATETIME2
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NewId UNIQUEIDENTIFIER = NEWID();

    -- Verificar que la categoría existe
    IF NOT EXISTS (SELECT 1 FROM Categories WHERE Id = @CategoryId)
    BEGIN
        RAISERROR ('La categoría seleccionada no existe.', 16, 1);
        RETURN;
    END

    INSERT INTO Products (Id, Title, Description, Price, Status, CategoryId, UserId, CreatedAt, ExpiresAt, UpdatedAt)
    VALUES (@NewId, @Title, @Description, @Price, 'AVAILABLE', @CategoryId, @UserId, SYSUTCDATETIME(), @ExpiresAt, SYSUTCDATETIME());

    SELECT @NewId AS ProductId;
END
GO

-- ============================================================
-- 20. Stored Procedure: sp_ExpireOldProducts
--     Tarea de mantenimiento: marcar productos vencidos
--     Ejecutar periódicamente (ej. SQL Server Agent Job)
-- ============================================================
IF OBJECT_ID('sp_ExpireOldProducts', 'P') IS NOT NULL
    DROP PROCEDURE sp_ExpireOldProducts;
GO

CREATE PROCEDURE sp_ExpireOldProducts
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Products
    SET Status = 'EXPIRED'
    WHERE ExpiresAt <= SYSUTCDATETIME()
      AND Status = 'AVAILABLE';

    PRINT CONCAT(@@ROWCOUNT, ' productos marcados como EXPIRED.');
END
GO

-- ============================================================
-- 21. Datos semilla (Seed): Categorías del marketplace
--     Equivalente al seed manual de Prisma
-- ============================================================
PRINT 'Insertando categorías semilla...';

MERGE INTO Categories AS target
USING (VALUES
    (NEWID(), N'Microcontroladores'),
    (NEWID(), N'Placas de Desarrollo'),
    (NEWID(), N'Micrófonos'),
    (NEWID(), N'Cámaras'),
    (NEWID(), N'Sensores'),
    (NEWID(), N'Baterías'),
    (NEWID(), N'RF / Wireless'),
    (NEWID(), N'Herramientas'),
    (NEWID(), N'Cables y Conectores'),
    (NEWID(), N'Otros')
) AS source (Id, Name)
ON target.Name = source.Name
WHEN NOT MATCHED THEN
    INSERT (Id, Name)
    VALUES (source.Id, source.Name);

PRINT CONCAT(@@ROWCOUNT, ' categoría(s) insertada(s).');
GO

-- ============================================================
-- 22. Datos semilla (Seed): Usuario administrador de prueba
-- ============================================================
DECLARE @AdminId UNIQUEIDENTIFIER = NEWID();

IF NOT EXISTS (SELECT 1 FROM Users WHERE Email = N'admin@unfv.edu.pe')
BEGIN
    INSERT INTO Users (Id, Name, Email, CreatedAt, UpdatedAt)
    VALUES (@AdminId, N'Administrador FIEI', N'admin@unfv.edu.pe', SYSUTCDATETIME(), SYSUTCDATETIME());
    PRINT 'Usuario admin de prueba insertado.';
END
GO

-- ============================================================
-- 23. Verificación final del esquema
-- ============================================================
PRINT '';
PRINT '=== VERIFICACIÓN DEL ESQUEMA ===';

SELECT
    t.name AS Tabla,
    COUNT(c.column_id) AS NumColumnas
FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id
WHERE t.name IN ('Users', 'Accounts', 'Sessions', 'VerificationTokens', 'Categories', 'Products', 'ProductImages', 'ProductTags')
GROUP BY t.name
ORDER BY t.name;

PRINT '';
PRINT 'Categorías insertadas:';
SELECT Id, Name FROM Categories ORDER BY Name;

PRINT '';
PRINT '=== SETUP COMPLETADO EXITOSAMENTE ===';
PRINT 'Base de datos: HardSwapFIEI';
PRINT 'Tablas: Users, Accounts, Sessions, VerificationTokens, Categories, Products, ProductImages, ProductTags';
PRINT 'Vistas: vw_CatalogProducts, vw_UserDashboard';
PRINT 'Stored Procs: sp_CreateProduct, sp_MarkProductAsSold, sp_DeleteProduct, sp_ExpireOldProducts';
GO
