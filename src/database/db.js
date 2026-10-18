const { DatabaseSync } = require('node:sqlite');
const path = require('path');
const fs = require('fs');

const dataDir = path.join(__dirname, '..', '..', 'data');
if (!fs.existsSync(dataDir)) {
  fs.mkdirSync(dataDir, { recursive: true });
}

const dbPath = path.join(dataDir, 'CerezKapisiDB.sqlite');
const db = new DatabaseSync(dbPath);

// Foreign Key kısıtlamalarını aktif et
db.exec('PRAGMA foreign_keys = ON;');

function initDatabase() {
  db.exec(`
    CREATE TABLE IF NOT EXISTS Categories (
      CategoryID INTEGER PRIMARY KEY AUTOINCREMENT,
      CategoryName TEXT NOT NULL,
      TaxRate REAL NOT NULL DEFAULT 1.00,
      AisleCode TEXT
    );

    CREATE TABLE IF NOT EXISTS Suppliers (
      SupplierID INTEGER PRIMARY KEY AUTOINCREMENT,
      CompanyName TEXT NOT NULL,
      TaxOffice TEXT NOT NULL,
      TaxNumber TEXT NOT NULL UNIQUE,
      ContactPerson TEXT,
      Phone TEXT,
      City TEXT
    );

    CREATE TABLE IF NOT EXISTS Products (
      ProductID INTEGER PRIMARY KEY AUTOINCREMENT,
      Barcode TEXT NOT NULL UNIQUE,
      SKU TEXT NOT NULL UNIQUE,
      ProductName TEXT NOT NULL,
      UnitType TEXT NOT NULL DEFAULT 'Kg',
      PurchasePrice REAL NOT NULL,
      Price REAL NOT NULL,
      Stock INTEGER NOT NULL DEFAULT 0,
      CategoryID INTEGER NOT NULL,
      SupplierID INTEGER NOT NULL,
      FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID),
      FOREIGN KEY (SupplierID) REFERENCES Suppliers(SupplierID)
    );

    CREATE TABLE IF NOT EXISTS Customers (
      CustomerID INTEGER PRIMARY KEY AUTOINCREMENT,
      FullName TEXT NOT NULL,
      CustomerType TEXT NOT NULL DEFAULT 'Bireysel',
      TaxOrIdentityNo TEXT,
      Phone TEXT,
      City TEXT,
      Email TEXT NOT NULL UNIQUE
    );

    CREATE TABLE IF NOT EXISTS Orders (
      OrderID INTEGER PRIMARY KEY AUTOINCREMENT,
      InvoiceNo TEXT NOT NULL UNIQUE,
      CustomerID INTEGER NOT NULL,
      OrderDate TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
      PaymentMethod TEXT NOT NULL DEFAULT 'Kredi Kartı',
      TotalAmount REAL NOT NULL,
      FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
    );

    CREATE TABLE IF NOT EXISTS OrderDetails (
      DetailID INTEGER PRIMARY KEY AUTOINCREMENT,
      OrderID INTEGER NOT NULL,
      ProductID INTEGER NOT NULL,
      Quantity INTEGER NOT NULL,
      UnitPrice REAL NOT NULL,
      FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
      FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
    );

    DROP VIEW IF EXISTS vw_SiparisOzet;
    CREATE VIEW vw_SiparisOzet AS
    SELECT 
      o.InvoiceNo AS FaturaNo,
      c.FullName AS MusteriAdi,
      o.OrderDate AS SiparisTarihi,
      p.Barcode AS Barkod,
      p.ProductName AS UrunAdi,
      od.Quantity AS Adet,
      od.UnitPrice AS BirimFiyat,
      ROUND(od.Quantity * od.UnitPrice, 2) AS SatirToplami
    FROM Orders o
    INNER JOIN Customers c ON o.CustomerID = c.CustomerID
    INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
    INNER JOIN Products p ON od.ProductID = p.ProductID;
  `);

  // Seed data if empty
  const count = db.prepare('SELECT COUNT(*) as cnt FROM Categories').get().cnt;
  if (count === 0) {
    db.exec(`
      INSERT INTO Categories (CategoryName, TaxRate, AisleCode) VALUES
      ('Kavrulmuş Kuruyemiş', 1.00, 'RYN-A1'),
      ('Çiğ Kuruyemiş', 1.00, 'RYN-A2'),
      ('Kuru Meyve & Pestil', 1.00, 'RYN-B1'),
      ('Lokum & Şekerleme', 10.00, 'RYN-C1'),
      ('Kahve & Baharat', 10.00, 'RYN-D1');

      INSERT INTO Suppliers (CompanyName, TaxOffice, TaxNumber, ContactPerson, Phone, City) VALUES
      ('Antep Bereket Fıstık & Gıda Toptan Ltd. Şti.', 'Şahinbey V.D.', '1740852963', 'Mehmet Özkan', '03422154410', 'Gaziantep'),
      ('Karadeniz Fındık Tarım Ürünleri A.Ş.', 'Giresun V.D.', '5240963147', 'Hasan Çebi', '04542168890', 'Giresun'),
      ('Ege İncir ve Kayısı İhracat Paz. Tic. A.Ş.', 'Efeler V.D.', '3360741852', 'Selim Aydın', '02562123344', 'Aydın'),
      ('Safranbolu Hacıoğlu Lokum & Şekerleme San. Ltd.', 'Safranbolu V.D.', '7410258963', 'Kemal Hacıoğlu', '03707125566', 'Karabük'),
      ('Eminönü Kurukahve ve Baharat İthalat A.Ş.', 'Mercan V.D.', '3890456123', 'Orhan Veli', '02125112233', 'İstanbul');

      INSERT INTO Products (Barcode, SKU, ProductName, UnitType, PurchasePrice, Price, Stock, CategoryID, SupplierID) VALUES
      ('8690504000011', 'CRZ-KVR-001', 'Kavrulmuş Antep Fıstığı (Ana Çıtlak)', 'Kg', 520.00, 740.00, 45, 1, 1),
      ('8690504000028', 'CRZ-KVR-002', 'Çifte Kavrulmuş Giresun Fındığı', 'Kg', 340.00, 490.00, 14, 1, 2),
      ('8690504000035', 'CRZ-KVR-003', 'Tuzlu Kavrulmuş Kabak Çekirdeği (Nevşehir)', 'Kg', 190.00, 280.00, 60, 1, 1),
      ('8690504000042', 'CRZ-CIG-001', 'Çiğ Badem İçi (Datça İri Boy)', 'Kg', 390.00, 560.00, 18, 2, 3),
      ('8690504000059', 'CRZ-CIG-002', 'Çiğ Kelebek Ceviz İçi (Yerli)', 'Kg', 360.00, 520.00, 11, 2, 2),
      ('8690504000066', 'CRZ-CIG-003', 'Çiğ Kaju (Jumbo Boy)', 'Kg', 410.00, 590.00, 32, 2, 1),
      ('8690504000073', 'CRZ-MYV-001', 'Aydın Dağ İnciri (Saray Lop)', 'Kg', 290.00, 430.00, 28, 3, 3),
      ('8690504000080', 'CRZ-MYV-002', 'Malatya Gün Kurusu Kayısı', 'Kg', 260.00, 380.00, 16, 3, 3),
      ('8690504000097', 'CRZ-LKM-001', 'Narlı & Antep Fıstıklı Fitil Lokum', 'Kg', 310.00, 460.00, 9,  4, 4),
      ('8690504000103', 'CRZ-LKM-002', 'Çifte Kavrulmuş Safranbolu Lokumu (1 Kg Kutu)', 'Kutu', 210.00, 320.00, 25, 4, 4),
      ('8690504000110', 'CRZ-KHV-001', 'Taş Değirmen Taze Çekilmiş Türk Kahvesi', 'Kg', 320.00, 480.00, 19, 5, 5),
      ('8690504000127', 'CRZ-KHV-002', 'İpek Pul Biber (Özel Harfiyat 500gr Paket)', 'Paket', 110.00, 180.00, 50, 5, 5);

      INSERT INTO Customers (FullName, CustomerType, TaxOrIdentityNo, Phone, City, Email) VALUES
      ('Ahmet Yılmaz', 'Bireysel', '14589632147', '05324112233', 'İstanbul', 'ahmet.yilmaz@email.com'),
      ('Ayşe Kaya', 'Bireysel', '25896314785', '05443221100', 'Ankara', 'ayse.kaya@email.com'),
      ('Mehmet Demir', 'Kurumsal', '6120489532', '05336547896', 'İzmir', 'satinalma@demirotel.com.tr'),
      ('Zeynep Şahin', 'Bireysel', '36985214701', '05059874563', 'Bursa', 'zeynep.sahin@email.com'),
      ('Caner Erkin', 'Kurumsal', '8450123698', '05301597532', 'Antalya', 'tedarik@akdenizkafe.com'),
      ('Elif Aksoy', 'Bireysel', '47852369104', '05428529631', 'Gaziantep', 'elif.aksoy@email.com');

      INSERT INTO Orders (InvoiceNo, CustomerID, OrderDate, PaymentMethod, TotalAmount) VALUES
      ('FTR202600001', 1, '2026-09-15 11:20:00', 'Kredi Kartı', 1710.00),
      ('FTR202600002', 2, '2026-09-20 14:45:00', 'Nakit',       1050.00),
      ('FTR202600003', 3, '2026-09-25 10:15:00', 'Havale/EFT',  3840.00),
      ('FTR202600004', 1, '2026-10-01 16:30:00', 'Kredi Kartı', 1220.00),
      ('FTR202600005', 4, '2026-10-04 18:10:00', 'Kredi Kartı', 940.00),
      ('FTR202600006', 5, '2026-10-08 09:50:00', 'Havale/EFT',  2930.00),
      ('FTR202600007', 6, '2026-10-10 13:05:00', 'Nakit',       810.00),
      ('FTR202600008', 2, '2026-10-12 17:40:00', 'Kredi Kartı', 1420.00),
      ('FTR202600009', 3, '2026-10-15 11:00:00', 'Havale/EFT',  2360.00),
      ('FTR202600010', 1, '2026-10-17 15:25:00', 'Kredi Kartı', 960.00);

      INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice) VALUES
      (1, 1, 1, 740.00), (1, 2, 1, 490.00), (1, 11, 1, 480.00),
      (2, 4, 1, 560.00), (2, 2, 1, 490.00),
      (3, 1, 2, 740.00), (3, 6, 4, 590.00),
      (4, 5, 2, 520.00), (4, 12, 1, 180.00),
      (5, 9, 1, 460.00), (5, 11, 1, 480.00),
      (6, 4, 2, 560.00), (6, 7, 3, 430.00), (6, 5, 1, 520.00),
      (7, 7, 1, 430.00), (7, 8, 1, 380.00),
      (8, 3, 2, 280.00), (8, 7, 2, 430.00),
      (9, 6, 2, 590.00), (9, 10, 2, 320.00), (9, 12, 3, 180.00),
      (10, 11, 2, 480.00);
    `);
  }
}

initDatabase();

module.exports = { db, dbPath };
