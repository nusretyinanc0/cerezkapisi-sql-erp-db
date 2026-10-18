-- ==========================================================================================
-- BÖLÜM 1: VERİ TABANI TASARIMI (LOGICAL DESIGN VE DDL)
-- Dosya: sql/01_ddl_tablolar.sql
-- ==========================================================================================

CREATE DATABASE CerezKapisiDB;
GO

USE CerezKapisiDB;
GO

-- A. Tablo: Categories (Kategoriler)
CREATE TABLE Categories (
    CategoryID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName VARCHAR(50) NOT NULL,
    TaxRate DECIMAL(4,2) NOT NULL DEFAULT 1.00,
    AisleCode VARCHAR(15) NULL
);
GO

-- Ek Tablo: Suppliers (Toptancılar ve Vergi Numaraları)
CREATE TABLE Suppliers (
    SupplierID INT IDENTITY(1,1) PRIMARY KEY,
    CompanyName VARCHAR(100) NOT NULL,
    TaxOffice VARCHAR(50) NOT NULL,
    TaxNumber VARCHAR(10) NOT NULL UNIQUE,
    ContactPerson VARCHAR(50) NULL,
    Phone VARCHAR(15) NULL,
    City VARCHAR(20) NULL
);
GO

-- B. Tablo: Products (Barkodlu Ürünler)
CREATE TABLE Products (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    Barcode VARCHAR(13) NOT NULL UNIQUE,
    SKU VARCHAR(20) NOT NULL UNIQUE,
    ProductName VARCHAR(100) NOT NULL,
    UnitType VARCHAR(15) NOT NULL DEFAULT 'Kg',
    PurchasePrice DECIMAL(10,2) NOT NULL,
    Price DECIMAL(10,2) NOT NULL,
    Stock INT NOT NULL DEFAULT 0,
    CategoryID INT NOT NULL,
    SupplierID INT NOT NULL,
    CONSTRAINT FK_Products_Categories FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID),
    CONSTRAINT FK_Products_Suppliers FOREIGN KEY (SupplierID) REFERENCES Suppliers(SupplierID)
);
GO

-- C. Tablo: Customers (Müşteriler)
CREATE TABLE Customers (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    FullName VARCHAR(50) NOT NULL,
    CustomerType VARCHAR(15) NOT NULL DEFAULT 'Bireysel',
    TaxOrIdentityNo VARCHAR(11) NULL,
    Phone VARCHAR(15) NULL,
    City VARCHAR(20) NULL,
    Email VARCHAR(100) NOT NULL UNIQUE
);
GO

-- D. Tablo: Orders (Siparişler / Satış Faturaları)
CREATE TABLE Orders (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    InvoiceNo VARCHAR(20) NOT NULL UNIQUE,
    CustomerID INT NOT NULL,
    OrderDate DATETIME NOT NULL DEFAULT GETDATE(),
    PaymentMethod VARCHAR(20) NOT NULL DEFAULT 'Kredi Kartı',
    TotalAmount DECIMAL(10,2) NOT NULL,
    CONSTRAINT FK_Orders_Customers FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);
GO

-- E. Tablo: OrderDetails (Sipariş Detayları - Ara Tablo)
CREATE TABLE OrderDetails (
    DetailID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,
    CONSTRAINT FK_OrderDetails_Orders FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
    CONSTRAINT FK_OrderDetails_Products FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);
GO
