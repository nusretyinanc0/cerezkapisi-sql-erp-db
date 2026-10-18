-- ==========================================================================================
-- BÖLÜM 3: SORGULAMA VE ANALİZ (DQL - SELECT VE JOINS)
-- Dosya: sql/03_dql_sorgular.sql
-- ==========================================================================================

USE CerezKapisiDB;
GO

-- 1. Temel Listeleme: Stok miktarı 20'den az olan ürünlerin AZALAN sırada listesi
SELECT Barcode AS [Barkod No], ProductName AS [Ürün Adı], Stock AS [Stok Miktarı], UnitType AS [Birim], Price AS [Satış Fiyatı (TL)]
FROM Products
WHERE Stock < 20
ORDER BY Stock DESC;

-- 2. Veri Birleştirme (JOIN): Müşteri siparişleri
SELECT o.InvoiceNo AS [Fatura No], c.FullName AS [Müşteri Adı], c.City AS [Şehir], o.OrderDate AS [Sipariş Tarihi], o.PaymentMethod AS [Ödeme Yöntemi], o.TotalAmount AS [Toplam Tutar (TL)]
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
ORDER BY o.OrderDate DESC;

-- 3. Çoklu Birleştirme ve Detay Raporu: "Ahmet Yılmaz" isimli müşterinin aldığı ürünler (5 Tablo JOIN)
SELECT c.FullName AS [Müşteri Adı], o.InvoiceNo AS [Fatura No], o.OrderDate AS [Sipariş Tarihi], p.Barcode AS [Barkod], p.ProductName AS [Ürün Adı], cat.CategoryName AS [Kategori], od.Quantity AS [Miktar], od.UnitPrice AS [Birim Fiyat (TL)], (od.Quantity * od.UnitPrice) AS [Satır Toplamı (TL)]
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN Products p ON od.ProductID = p.ProductID
INNER JOIN Categories cat ON p.CategoryID = cat.CategoryID
WHERE c.FullName = 'Ahmet Yılmaz'
ORDER BY o.OrderDate ASC;

-- 4. Gruplama ve Aggregate Fonksiyonlar: Kategorilere göre ürün sayısı (LEFT JOIN & GROUP BY)
SELECT cat.CategoryName AS [Kategori Adı], cat.AisleCode AS [Reyon Kodu], COUNT(p.ProductID) AS [Toplam Ürün Çeşidi], ISNULL(SUM(p.Stock), 0) AS [Kategorideki Toplam Stok]
FROM Categories cat
LEFT JOIN Products p ON cat.CategoryID = p.CategoryID
GROUP BY cat.CategoryID, cat.CategoryName, cat.AisleCode
ORDER BY [Toplam Ürün Çeşidi] DESC;

-- 5. Ciro Analizi (Zor): Müşteri bazlı toplam ciro
SELECT c.CustomerID AS [Müşteri No], c.FullName AS [Müşteri Adı], c.CustomerType AS [Müşteri Tipi], c.City AS [Şehir], COUNT(o.OrderID) AS [Toplam Sipariş Sayısı], SUM(o.TotalAmount) AS [Toplam Ciro (TL)]
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.FullName, c.CustomerType, c.City
ORDER BY [Toplam Ciro (TL)] DESC;

-- 6. Zaman Analizi: Siparişlerin üzerinden geçen gün sayısı (DATEDIFF & GETDATE)
SELECT o.OrderID AS [Sipariş ID], o.InvoiceNo AS [Fatura No], c.FullName AS [Müşteri Adı], o.OrderDate AS [Sipariş Tarihi], GETDATE() AS [Bugünün Tarihi], DATEDIFF(DAY, o.OrderDate, GETDATE()) AS [Geçen Gün Sayısı]
FROM Orders o
INNER JOIN Customers c ON o.CustomerID = c.CustomerID
ORDER BY [Geçen Gün Sayısı] DESC;

-- 7. Ek Gerçek İşletme Sorgusu: Toptancı Vergi No, Barkod ve Net Kâr Analizi
SELECT s.CompanyName AS [Toptancı Firma], s.TaxOffice AS [Vergi Dairesi], s.TaxNumber AS [Vergi No], p.Barcode AS [Barkod], p.ProductName AS [Ürün Adı], p.PurchasePrice AS [Alış Maliyeti (TL)], p.Price AS [Satış Fiyatı (TL)], SUM(od.Quantity) AS [Satılan Toplam Miktar], SUM(od.Quantity * od.UnitPrice) AS [Toplam Satış Cirosu (TL)], SUM(od.Quantity * (od.UnitPrice - p.PurchasePrice)) AS [Net Kâr (TL)]
FROM OrderDetails od
INNER JOIN Products p ON od.ProductID = p.ProductID
INNER JOIN Suppliers s ON p.SupplierID = s.SupplierID
GROUP BY s.CompanyName, s.TaxOffice, s.TaxNumber, p.Barcode, p.ProductName, p.PurchasePrice, p.Price
ORDER BY [Net Kâr (TL)] DESC;
GO
