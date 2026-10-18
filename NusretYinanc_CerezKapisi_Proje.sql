-- ==========================================================================================
-- PROJE ADI      : ÇerezKapısı - Barkodlu Kuruyemiş Satış, Stok ve Toptancı Veri Yönetim Sistemi
-- VERİ TABANI    : CerezKapisiDB
-- HAZIRLAYAN     : Nusret Yınanç
-- DOSYA ADI      : NusretYinanc_CerezKapisi_Proje.sql
-- AÇIKLAMA       : Bu betik (script); veri tabanı oluşturma (DDL), örnek veri girişi (DML),
--                  raporlama/analiz sorguları (DQL), görünüm (VIEW) ve yedekleme (BACKUP)
--                  adımlarının tamamını tek dosyada içerir.
-- ==========================================================================================

-- ==========================================================================================
-- BÖLÜM 1: VERİ TABANI TASARIMI (LOGICAL DESIGN VE DDL)
-- ==========================================================================================

-- 1. Veri Tabanı Oluşturma
-- Eğer aynı isimde veri tabanı varsa silip sıfırdan temiz kurulum yapabilmek için kontrol:
IF DB_ID('CerezKapisiDB') IS NOT NULL
BEGIN
    ALTER DATABASE CerezKapisiDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE CerezKapisiDB;
END
GO

CREATE DATABASE CerezKapisiDB;
GO

USE CerezKapisiDB;
GO

-- 2. Tablo Gereksinimleri
-- İpucu gereği Foreign Key (Yabancı Anahtar) bağımlılıklarına dikkat edilerek;
-- Önce ana tablolar (Categories, Suppliers, Customers), sonra bağımlı tablolar (Products, Orders, OrderDetails) oluşturulmuştur.

-- A. Tablo: Categories (Kategoriler)
-- Kuruyemiş dükkanındaki ürün gruplarını, reyon kodlarını ve kategori bazlı KDV oranlarını tutar.
CREATE TABLE Categories (
    CategoryID INT IDENTITY(1,1) PRIMARY KEY,               -- Otomatik artan (Identity 1,1) Birincil Anahtar
    CategoryName VARCHAR(50) NOT NULL,                      -- Kategori adı, boş geçilemez (Not Null)
    TaxRate DECIMAL(4,2) NOT NULL DEFAULT 1.00,             -- Gerçek işletme detayı: KDV Oranı (%1, %10 vb.)
    AisleCode VARCHAR(15) NULL                              -- Gerçek işletme detayı: Depo/Tezgah Reyon Kodu
);
GO

-- EK GERÇEK İŞLETME TABLOSU: Suppliers (Toptancılar / Tedarikçiler)
-- Ürünlerin hangi toptancıdan alındığını, vergi dairesi ve 10 haneli vergi numarasını tutar.
CREATE TABLE Suppliers (
    SupplierID INT IDENTITY(1,1) PRIMARY KEY,               -- Otomatik artan Toptancı ID
    CompanyName VARCHAR(100) NOT NULL,                      -- Toptancı Firma Resmi Ünvanı
    TaxOffice VARCHAR(50) NOT NULL,                         -- Bağlı olduğu Vergi Dairesi
    TaxNumber VARCHAR(10) NOT NULL UNIQUE,                  -- 10 Haneli Vergi Kimlik Numarası (Benzersiz/Unique)
    ContactPerson VARCHAR(50) NULL,                         -- İlgili Plasiyer / Satış Temsilcisi
    Phone VARCHAR(15) NULL,                                 -- İletişim Telefonu
    City VARCHAR(20) NULL                                   -- Toptancının bulunduğu şehir
);
GO

-- B. Tablo: Products (Ürünler)
-- Barkodlu kuruyemiş ürünlerini, toptancı alış maliyetini, perakende satış fiyatını ve stok adedini/kilosunu tutar.
CREATE TABLE Products (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,                -- Otomatik artan Birincil Anahtar
    Barcode VARCHAR(13) NOT NULL UNIQUE,                    -- Gerçek işletme detayı: EAN-13 Barkod Numarası (Benzersiz)
    SKU VARCHAR(20) NOT NULL UNIQUE,                        -- Gerçek işletme detayı: Stok Takip Kodu (Örn: CRZ-ANT-001)
    ProductName VARCHAR(100) NOT NULL,                      -- Ürün adı, boş geçilemez (Not Null)
    UnitType VARCHAR(15) NOT NULL DEFAULT 'Kg',             -- Birim bilgisi (Kg, Paket, Koli)
    PurchasePrice DECIMAL(10,2) NOT NULL,                   -- Gerçek işletme detayı: Toptancıdan Alış/Maliyet Fiyatı
    Price DECIMAL(10,2) NOT NULL,                           -- Perakende Satış Fiyatı (Yönergedeki zorunlu sütun)
    Stock INT NOT NULL DEFAULT 0,                           -- Stok adedi/kilosu (Varsayılan değer 0)
    CategoryID INT NOT NULL,                                -- Categories tablosuna bağlanan Yabancı Anahtar (FK)
    SupplierID INT NOT NULL,                                -- Suppliers (Toptancılar) tablosuna bağlanan Yabancı Anahtar (FK)
    CONSTRAINT FK_Products_Categories FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID),
    CONSTRAINT FK_Products_Suppliers FOREIGN KEY (SupplierID) REFERENCES Suppliers(SupplierID)
);
GO

-- C. Tablo: Customers (Müşteriler)
-- Perakende ve kurumsal müşterilerin iletişim, şehir ve fatura kimlik bilgilerini tutar.
CREATE TABLE Customers (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,               -- Otomatik artan Birincil Anahtar
    FullName VARCHAR(50) NOT NULL,                          -- Müşteri adı soyadı
    CustomerType VARCHAR(15) NOT NULL DEFAULT 'Bireysel',   -- Bireysel / Kurumsal müşteri ayrımı
    TaxOrIdentityNo VARCHAR(11) NULL,                       -- T.C. Kimlik No (11 hane) veya Vergi No (10 hane)
    Phone VARCHAR(15) NULL,                                 -- Müşteri telefonu
    City VARCHAR(20) NULL,                                  -- Şehir bilgisi
    Email VARCHAR(100) NOT NULL UNIQUE                      -- E-posta adresi (Unique/Benzersiz olmalı)
);
GO

-- D. Tablo: Orders (Siparişler / Satış Faturaları)
-- Müşterilere kesilen satış fişlerinin/faturalarının ana başlık bilgilerini tutar.
CREATE TABLE Orders (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,                  -- Otomatik artan Birincil Anahtar
    InvoiceNo VARCHAR(20) NOT NULL UNIQUE,                  -- Gerçek işletme detayı: Fatura/Fiş Numarası (Benzersiz)
    CustomerID INT NOT NULL,                                -- Customers tablosuna bağlanan Yabancı Anahtar (FK)
    OrderDate DATETIME NOT NULL DEFAULT GETDATE(),          -- Sipariş tarihi (Varsayılan değer GETDATE())
    PaymentMethod VARCHAR(20) NOT NULL DEFAULT 'Kredi Kartı', -- Ödeme tipi (Kredi Kartı, Nakit, Havale/EFT)
    TotalAmount DECIMAL(10,2) NOT NULL,                     -- Toplam sipariş tutarı
    CONSTRAINT FK_Orders_Customers FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);
GO

-- E. Tablo: OrderDetails (Sipariş Detayları - Ara Tablo)
-- Bir siparişte (faturada) hangi barkodlu üründen kaç adet/kg alındığını ve satış anındaki birim fiyatını tutar.
CREATE TABLE OrderDetails (
    DetailID INT IDENTITY(1,1) PRIMARY KEY,                 -- Otomatik artan Birincil Anahtar
    OrderID INT NOT NULL,                                   -- Orders tablosuna bağlanan Yabancı Anahtar (FK)
    ProductID INT NOT NULL,                                 -- Products tablosuna bağlanan Yabancı Anahtar (FK)
    Quantity INT NOT NULL,                                  -- Kaç adet/kg alındığı
    UnitPrice DECIMAL(10,2) NOT NULL,                       -- Gerçek işletme detayı: Satış anındaki birim fiyat
    CONSTRAINT FK_OrderDetails_Orders FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
    CONSTRAINT FK_OrderDetails_Products FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);
GO


-- ==========================================================================================
-- BÖLÜM 2: VERİ GİRİŞİ (DML - INSERT)
-- ==========================================================================================

-- Görev 1: 5 adet Kategori ekleyin (ve Toptancı kayıtlarını oluşturun)
INSERT INTO Categories (CategoryName, TaxRate, AisleCode) VALUES
('Kavrulmuş Kuruyemiş', 1.00, 'RYN-A1'),
('Çiğ Kuruyemiş', 1.00, 'RYN-A2'),
('Kuru Meyve & Pestil', 1.00, 'RYN-B1'),
('Lokum & Şekerleme', 10.00, 'RYN-C1'),
('Kahve & Baharat', 10.00, 'RYN-D1');

-- Toptancı (Suppliers) Veri Girişi (Vergi Dairesi ve 10 Haneli Vergi Numaralarıyla)
INSERT INTO Suppliers (CompanyName, TaxOffice, TaxNumber, ContactPerson, Phone, City) VALUES
('Antep Bereket Fıstık & Gıda Toptan Ltd. Şti.', 'Şahinbey V.D.', '1740852963', 'Mehmet Özkan', '03422154410', 'Gaziantep'),
('Karadeniz Fındık Tarım Ürünleri A.Ş.', 'Giresun V.D.', '5240963147', 'Hasan Çebi', '04542168890', 'Giresun'),
('Ege İncir ve Kayısı İhracat Paz. Tic. A.Ş.', 'Efeler V.D.', '3360741852', 'Selim Aydın', '02562123344', 'Aydın'),
('Safranbolu Hacıoğlu Lokum & Şekerleme San. Ltd.', 'Safranbolu V.D.', '7410258963', 'Kemal Hacıoğlu', '03707125566', 'Karabük'),
('Eminönü Kurukahve ve Baharat İthalat A.Ş.', 'Mercan V.D.', '3890456123', 'Orhan Veli', '02125112233', 'İstanbul');
GO

-- Görev 2: Her kategoriye ait olacak şekilde toplamda 12 Ürün ekleyin (Barkodlu, Alış ve Satış Fiyatlı)
-- Not: Bazı ürünlerin stokları 20'nin altında girilmiştir (Bölüm 3 - 1. Sorgu testi için).
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
GO

-- Görev 3: 6 adet Müşteri kaydı oluşturun ("Ahmet Yılmaz" dahil)
INSERT INTO Customers (FullName, CustomerType, TaxOrIdentityNo, Phone, City, Email) VALUES
('Ahmet Yılmaz', 'Bireysel', '14589632147', '05324112233', 'İstanbul', 'ahmet.yilmaz@email.com'),
('Ayşe Kaya', 'Bireysel', '25896314785', '05443221100', 'Ankara', 'ayse.kaya@email.com'),
('Mehmet Demir', 'Kurumsal', '6120489532', '05336547896', 'İzmir', 'satinalma@demirotel.com.tr'),
('Zeynep Şahin', 'Bireysel', '36985214701', '05059874563', 'Bursa', 'zeynep.sahin@email.com'),
('Caner Erkin', 'Kurumsal', '8450123698', '05301597532', 'Antalya', 'tedarik@akdenizkafe.com'),
('Elif Aksoy', 'Bireysel', '47852369104', '05428529631', 'Gaziantep', 'elif.aksoy@email.com');
GO

-- Görev 4: Farklı tarihlerde yapılmış 10 Sipariş (Orders) ve bu siparişlere ait Sipariş Detayları (OrderDetails) girin
INSERT INTO Orders (InvoiceNo, CustomerID, OrderDate, PaymentMethod, TotalAmount) VALUES
('FTR202600001', 1, '2026-09-15 11:20:00', 'Kredi Kartı', 1710.00), -- Ahmet Yılmaz (1. Sipariş)
('FTR202600002', 2, '2026-09-20 14:45:00', 'Nakit',       1050.00), -- Ayşe Kaya
('FTR202600003', 3, '2026-09-25 10:15:00', 'Havale/EFT',  3840.00), -- Mehmet Demir (Kurumsal)
('FTR202600004', 1, '2026-10-01 16:30:00', 'Kredi Kartı', 1220.00), -- Ahmet Yılmaz (2. Sipariş)
('FTR202600005', 4, '2026-10-04 18:10:00', 'Kredi Kartı', 940.00),  -- Zeynep Şahin
('FTR202600006', 5, '2026-10-08 09:50:00', 'Havale/EFT',  2930.00), -- Caner Erkin (Kurumsal)
('FTR202600007', 6, '2026-10-10 13:05:00', 'Nakit',       810.00),  -- Elif Aksoy
('FTR202600008', 2, '2026-10-12 17:40:00', 'Kredi Kartı', 1420.00), -- Ayşe Kaya (2. Sipariş)
('FTR202600009', 3, '2026-10-15 11:00:00', 'Havale/EFT',  2360.00), -- Mehmet Demir (2. Sipariş)
('FTR202600010', 1, '2026-10-17 15:25:00', 'Kredi Kartı', 960.00);  -- Ahmet Yılmaz (3. Sipariş)

-- Sipariş Kalemleri (OrderDetails): Hangi faturada hangi üründen kaç adet/kg ve hangi birim fiyattan satıldı
INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice) VALUES
-- Sipariş 1 (Ahmet Yılmaz: 1 Kg Antep Fıstığı [740] + 1 Kg Giresun Fındığı [490] + 1 Kg Türk Kahvesi [480] = 1710 TL)
(1, 1, 1, 740.00),
(1, 2, 1, 490.00),
(1, 11, 1, 480.00),

-- Sipariş 2 (Ayşe Kaya: 1 Kg Çiğ Badem [560] + 1 Kg Giresun Fındığı [490] = 1050 TL)
(2, 4, 1, 560.00),
(2, 2, 1, 490.00),

-- Sipariş 3 (Mehmet Demir: 3 Kg Antep Fıstığı [2220] + 2 Kg Çiğ Kaju [1180] + 1 Kutu Safranbolu Lokumu [320]... düzeltme: 3*740=2220 + 2*590=1180 + 1*440 değil, tam tutar uyumu için: 3 Kg Antep Fıstığı [2220] + 2 Kg Narlı Lokum [920] + 2.5 yerine 5 Paket Pul Biber [900] -> 2 Kg Antep Fıstığı [1480] + 4 Kg Çiğ Kaju [2360] = 3840 TL)
(3, 1, 2, 740.00),
(3, 6, 4, 590.00),

-- Sipariş 4 (Ahmet Yılmaz: 1 Kg Aydın İnciri [430] + 1 Kg Malatya Kayısı [380] + 1 Kg Narlı Fitil Lokum [460] -> 430+330 değil: 2 Kg Çiğ Ceviz [1040] + 1 Paket Pul Biber [180] = 1220 TL)
(4, 5, 2, 520.00),
(4, 12, 1, 180.00),

-- Sipariş 5 (Zeynep Şahin: 1 Kg Narlı Fitil Lokum [460] + 1 Kg Türk Kahvesi [480] = 940 TL)
(5, 9, 1, 460.00),
(5, 11, 1, 480.00),

-- Sipariş 6 (Caner Erkin: 2 Kg Antep Fıstığı [1480] + 2 Kg Giresun Fındığı [980] + 1 Kg Türk Kahvesi [470 -> 480] -> 3 Kg Giresun Fındığı [1470] + 2 Kg Antep Fıstığı [1480] = 2950 yerine: 2 Kg Çiğ Badem [1120] + 3 Kg Aydın İnciri [1290] + 1 Kg Çiğ Ceviz [520] = 2930 TL)
(6, 4, 2, 560.00),
(6, 7, 3, 430.00),
(6, 5, 1, 520.00),

-- Sipariş 7 (Elif Aksoy: 1 Kg Aydın İnciri [430] + 1 Kg Malatya Kayısı [380] = 810 TL)
(7, 7, 1, 430.00),
(7, 8, 1, 380.00),

-- Sipariş 8 (Ayşe Kaya: 2 Kg Kabak Çekirdeği [560] + 2 Kg Aydın İnciri [860] = 1420 TL)
(8, 3, 2, 280.00),
(8, 7, 2, 430.00),

-- Sipariş 9 (Mehmet Demir: 2 Kg Çiğ Kaju [1180] + 2 Kg Çiğ Kaju yerine 2 Kutu Safranbolu Lokumu [640] + 3 Paket Pul Biber [540] = 2360 TL)
(9, 6, 2, 590.00),
(9, 10, 2, 320.00),
(9, 12, 3, 180.00),

-- Sipariş 10 (Ahmet Yılmaz: 2 Kutu Safranbolu Lokumu [640] + 1 Kutu Safranbolu Lokumu [320] -> 2 Kg Türk Kahvesi [960] = 960 TL)
(10, 11, 2, 480.00);
GO


-- ==========================================================================================
-- BÖLÜM 3: SORGULAMA VE ANALİZ (DQL - SELECT VE JOINS)
-- ==========================================================================================

-- 1. Temel Listeleme:
-- Soru: Stok miktarı 20'den az olan ürünlerin adını ve stok miktarını (barkod ve birim bilgileriyle),
--       stok miktarına göre "AZALAN" sırada listeleyin.
-- Kullanılacaklar: SELECT, WHERE, ORDER BY.
SELECT 
    Barcode AS [Barkod No],
    ProductName AS [Ürün Adı],
    Stock AS [Stok Miktarı],
    UnitType AS [Birim],
    Price AS [Satış Fiyatı (TL)]
FROM Products
WHERE Stock < 20
ORDER BY Stock DESC;
GO

-- 2. Veri Birleştirme (JOIN):
-- Soru: Hangi müşteri, hangi tarihte sipariş vermiş? Sonuçta Müşteri Adı, Şehir,
--       Sipariş Tarihi ve Toplam Tutar (ve Fatura No) gözüksün.
-- Kullanılacaklar: INNER JOIN (Customers ve Orders tabloları).
SELECT 
    o.InvoiceNo AS [Fatura No],
    c.FullName AS [Müşteri Adı],
    c.City AS [Şehir],
    o.OrderDate AS [Sipariş Tarihi],
    o.PaymentMethod AS [Ödeme Yöntemi],
    o.TotalAmount AS [Toplam Tutar (TL)]
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
ORDER BY o.OrderDate DESC;
GO

-- 3. Çoklu Birleştirme ve Detay Raporu:
-- Soru: "Ahmet Yılmaz" isimli müşterinin aldığı ürünlerin isimlerini, fiyatlarını ve kategorilerini listeleyin.
-- Kullanılacaklar: JOIN (Customers, Orders, OrderDetails, Products, Categories tabloları zincirleme bağlanacak).
SELECT 
    c.FullName AS [Müşteri Adı],
    o.InvoiceNo AS [Fatura No],
    o.OrderDate AS [Sipariş Tarihi],
    p.Barcode AS [Barkod],
    p.ProductName AS [Ürün Adı],
    cat.CategoryName AS [Kategori],
    od.Quantity AS [Miktar],
    od.UnitPrice AS [Birim Fiyat (TL)],
    (od.Quantity * od.UnitPrice) AS [Satır Toplamı (TL)]
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN Products p ON od.ProductID = p.ProductID
INNER JOIN Categories cat ON p.CategoryID = cat.CategoryID
WHERE c.FullName = 'Ahmet Yılmaz'
ORDER BY o.OrderDate ASC;
GO

-- 4. Gruplama ve Aggregate Fonksiyonlar:
-- Soru: Hangi kategoride toplam kaç adet ürünümüz (ürün çeşidimiz) var? (Örn: Kavrulmuş Kuruyemiş - 3 ürün).
-- Kullanılacaklar: GROUP BY, COUNT(), LEFT JOIN.
SELECT 
    cat.CategoryName AS [Kategori Adı],
    cat.AisleCode AS [Reyon Kodu],
    COUNT(p.ProductID) AS [Toplam Ürün Çeşidi],
    ISNULL(SUM(p.Stock), 0) AS [Kategorideki Toplam Stok]
FROM Categories cat
LEFT JOIN Products p ON cat.CategoryID = p.CategoryID
GROUP BY cat.CategoryID, cat.CategoryName, cat.AisleCode
ORDER BY [Toplam Ürün Çeşidi] DESC;
GO

-- 5. Ciro Analizi (Zor):
-- Soru: Her müşterinin şirkete kazandırdığı toplam ciro nedir? En çok harcama yapan müşteriden en aza doğru sıralayın.
-- Kullanılacaklar: SUM(), GROUP BY, ORDER BY.
SELECT 
    c.CustomerID AS [Müşteri No],
    c.FullName AS [Müşteri Adı],
    c.CustomerType AS [Müşteri Tipi],
    c.City AS [Şehir],
    COUNT(o.OrderID) AS [Toplam Sipariş Sayısı],
    SUM(o.TotalAmount) AS [Toplam Ciro (TL)]
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.FullName, c.CustomerType, c.City
ORDER BY [Toplam Ciro (TL)] DESC;
GO

-- 6. Zaman Analizi:
-- Soru: Bugünün tarihine göre, siparişlerin üzerinden kaç gün geçtiğini hesaplayan bir sorgu yazın.
-- Kullanılacaklar: DATEDIFF(), GETDATE().
SELECT 
    o.OrderID AS [Sipariş ID],
    o.InvoiceNo AS [Fatura No],
    c.FullName AS [Müşteri Adı],
    o.OrderDate AS [Sipariş Tarihi],
    GETDATE() AS [Bugünün Tarihi],
    DATEDIFF(DAY, o.OrderDate, GETDATE()) AS [Geçen Gün Sayısı]
FROM Orders o
INNER JOIN Customers c ON o.CustomerID = c.CustomerID
ORDER BY [Geçen Gün Sayısı] DESC;
GO

-- 7. EK GERÇEK İŞLETME SORGUSU: Toptancı Vergi No, Barkod ve Net Kâr Analizi
-- Açıklama: Hangi toptancıdan (Vergi No ile) alınan hangi barkodlu üründen toplam kaç adet satılmış,
--           ne kadar ciro ve ne kadar NET KÂR elde edilmiş?
SELECT 
    s.CompanyName AS [Toptancı Firma],
    s.TaxOffice AS [Vergi Dairesi],
    s.TaxNumber AS [Vergi No],
    p.Barcode AS [Barkod],
    p.ProductName AS [Ürün Adı],
    p.PurchasePrice AS [Alış Maliyeti (TL)],
    p.Price AS [Satış Fiyatı (TL)],
    SUM(od.Quantity) AS [Satılan Toplam Miktar],
    SUM(od.Quantity * od.UnitPrice) AS [Toplam Satış Cirosu (TL)],
    SUM(od.Quantity * (od.UnitPrice - p.PurchasePrice)) AS [Net Kâr (TL)]
FROM OrderDetails od
INNER JOIN Products p ON od.ProductID = p.ProductID
INNER JOIN Suppliers s ON p.SupplierID = s.SupplierID
GROUP BY s.CompanyName, s.TaxOffice, s.TaxNumber, p.Barcode, p.ProductName, p.PurchasePrice, p.Price
ORDER BY [Net Kâr (TL)] DESC;
GO


-- ==========================================================================================
-- BÖLÜM 4: İLERİ SEVİYE VERİ TABANI NESNELERİ
-- ==========================================================================================

-- 1. View (Görünüm) Oluşturma:
-- Sürekli uzun JOIN sorguları yazmamak için; Müşteri Adı, Sipariş Tarihi, Ürün Adı ve Adet
-- (ve ek olarak Fatura No, Barkod) bilgilerini tek bir tablodaymış gibi getiren vw_SiparisOzet isminde bir VIEW oluşturun.
-- Konu: CREATE VIEW.
CREATE VIEW vw_SiparisOzet AS
SELECT 
    o.InvoiceNo AS FaturaNo,
    c.FullName AS MusteriAdi,
    o.OrderDate AS SiparisTarihi,
    p.Barcode AS Barkod,
    p.ProductName AS UrunAdi,
    od.Quantity AS Adet,
    od.UnitPrice AS BirimFiyat,
    (od.Quantity * od.UnitPrice) AS SatirToplami
FROM Orders o
INNER JOIN Customers c ON o.CustomerID = c.CustomerID
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN Products p ON od.ProductID = p.ProductID;
GO

-- Oluşturulan View'ın test edilmesi:
SELECT * FROM vw_SiparisOzet ORDER BY SiparisTarihi DESC;
GO

-- 2. Yedekleme (Backup):
-- Projenizi tamamladıktan sonra CerezKapisiDB veri tabanının C:\Yedek\ klasörüne yedeğini alan T-SQL komutunu yazın.
-- Konu: BACKUP DATABASE.
-- Not: C:\Yedek\ klasörünün diskte mevcut olması gerekir.
BACKUP DATABASE CerezKapisiDB
TO DISK = 'C:\Yedek\CerezKapisiDB_FullBackup.bak'
WITH FORMAT,
     MEDIANAME = 'CerezKapisiDB_Yedek',
     NAME = 'CerezKapisiDB Tam Veri Tabanı Yedeği';
GO
