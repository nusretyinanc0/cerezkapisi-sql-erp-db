-- ==========================================================================================
-- BÖLÜM 4: İLERİ SEVİYE VERİ TABANI NESNELERİ (VIEW VE BACKUP)
-- Dosya: sql/04_view_ve_backup.sql
-- ==========================================================================================

USE CerezKapisiDB;
GO

-- 1. View (Görünüm) Oluşturma: vw_SiparisOzet
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

SELECT * FROM vw_SiparisOzet ORDER BY SiparisTarihi DESC;
GO

-- 2. Yedekleme (Backup):
BACKUP DATABASE CerezKapisiDB
TO DISK = 'C:\Yedek\CerezKapisiDB_FullBackup.bak'
WITH FORMAT,
     MEDIANAME = 'CerezKapisiDB_Yedek',
     NAME = 'CerezKapisiDB Tam Veri Tabanı Yedeği';
GO
