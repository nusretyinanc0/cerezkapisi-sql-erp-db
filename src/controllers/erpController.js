const { db, dbPath } = require('../database/db');
const fs = require('fs');
const path = require('path');

// 1. Özet KPI İstatistikleri
exports.getDashboardStats = (req, res) => {
  try {
    const totalProducts = db.prepare('SELECT COUNT(*) AS cnt FROM Products').get().cnt;
    const criticalStock = db.prepare('SELECT COUNT(*) AS cnt FROM Products WHERE Stock < 20').get().cnt;
    const totalSuppliers = db.prepare('SELECT COUNT(*) AS cnt FROM Suppliers').get().cnt;
    const totalCustomers = db.prepare('SELECT COUNT(*) AS cnt FROM Customers').get().cnt;
    const orderSummary = db.prepare('SELECT COUNT(*) AS cnt, COALESCE(SUM(TotalAmount), 0) AS revenue FROM Orders').get();
    const profitRow = db.prepare(`
      SELECT COALESCE(SUM(od.Quantity * (od.UnitPrice - p.PurchasePrice)), 0) AS netProfit
      FROM OrderDetails od
      INNER JOIN Products p ON od.ProductID = p.ProductID
    `).get();

    res.json({
      totalProducts,
      criticalStock,
      totalSuppliers,
      totalCustomers,
      totalOrders: orderSummary.cnt,
      totalRevenue: orderSummary.revenue,
      netProfit: profitRow.netProfit
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// 2. Bölüm 3 & 4 SQL Raporlarını Canlı Çalıştırma Endpoint'i
exports.runReportQuery = (req, res) => {
  const { reportId } = req.params;
  const reports = {
    '1': {
      title: '1. Temel Listeleme: Kritik Stok (< 20) Ürünler (AZALAN Sırada)',
      tsql: `SELECT Barcode AS [Barkod No], ProductName AS [Ürün Adı], Stock AS [Stok Miktarı], UnitType AS [Birim], Price AS [Satış Fiyatı (TL)]
FROM Products
WHERE Stock < 20
ORDER BY Stock DESC;`,
      sqlite: `SELECT Barcode AS "Barkod No", ProductName AS "Ürün Adı", Stock AS "Stok Miktarı", UnitType AS "Birim", printf('%.2f TL', Price) AS "Satış Fiyatı"
FROM Products
WHERE Stock < 20
ORDER BY Stock DESC;`
    },
    '2': {
      title: '2. Veri Birleştirme (INNER JOIN): Müşteri Sipariş ve Fatura Listesi',
      tsql: `SELECT o.InvoiceNo AS [Fatura No], c.FullName AS [Müşteri Adı], c.City AS [Şehir], o.OrderDate AS [Sipariş Tarihi], o.PaymentMethod AS [Ödeme Yöntemi], o.TotalAmount AS [Toplam Tutar (TL)]
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
ORDER BY o.OrderDate DESC;`,
      sqlite: `SELECT o.InvoiceNo AS "Fatura No", c.FullName AS "Müşteri Adı", c.City AS "Şehir", o.OrderDate AS "Sipariş Tarihi", o.PaymentMethod AS "Ödeme Yöntemi", printf('%.2f TL', o.TotalAmount) AS "Toplam Tutar"
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
ORDER BY o.OrderDate DESC;`
    },
    '3': {
      title: '3. Çoklu Birleştirme (5 Tablo Zincirleme JOIN): "Ahmet Yılmaz" Aldığı Ürünler',
      tsql: `SELECT c.FullName AS [Müşteri Adı], o.InvoiceNo AS [Fatura No], o.OrderDate AS [Sipariş Tarihi], p.Barcode AS [Barkod], p.ProductName AS [Ürün Adı], cat.CategoryName AS [Kategori], od.Quantity AS [Miktar], od.UnitPrice AS [Birim Fiyat (TL)], (od.Quantity * od.UnitPrice) AS [Satır Toplamı (TL)]
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN Products p ON od.ProductID = p.ProductID
INNER JOIN Categories cat ON p.CategoryID = cat.CategoryID
WHERE c.FullName = 'Ahmet Yılmaz'
ORDER BY o.OrderDate ASC;`,
      sqlite: `SELECT c.FullName AS "Müşteri Adı", o.InvoiceNo AS "Fatura No", o.OrderDate AS "Sipariş Tarihi", p.Barcode AS "Barkod", p.ProductName AS "Ürün Adı", cat.CategoryName AS "Kategori", od.Quantity AS "Miktar", printf('%.2f TL', od.UnitPrice) AS "Birim Fiyat", printf('%.2f TL', od.Quantity * od.UnitPrice) AS "Satır Toplamı"
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN Products p ON od.ProductID = p.ProductID
INNER JOIN Categories cat ON p.CategoryID = cat.CategoryID
WHERE c.FullName = 'Ahmet Yılmaz'
ORDER BY o.OrderDate ASC;`
    },
    '4': {
      title: '4. Gruplama ve Aggregate Fonksiyonlar (GROUP BY, COUNT, LEFT JOIN)',
      tsql: `SELECT cat.CategoryName AS [Kategori Adı], cat.AisleCode AS [Reyon Kodu], COUNT(p.ProductID) AS [Toplam Ürün Çeşidi], ISNULL(SUM(p.Stock), 0) AS [Kategorideki Toplam Stok]
FROM Categories cat
LEFT JOIN Products p ON cat.CategoryID = p.CategoryID
GROUP BY cat.CategoryID, cat.CategoryName, cat.AisleCode
ORDER BY [Toplam Ürün Çeşidi] DESC;`,
      sqlite: `SELECT cat.CategoryName AS "Kategori Adı", cat.AisleCode AS "Reyon Kodu", COUNT(p.ProductID) AS "Toplam Ürün Çeşidi", COALESCE(SUM(p.Stock), 0) AS "Kategorideki Toplam Stok"
FROM Categories cat
LEFT JOIN Products p ON cat.CategoryID = p.CategoryID
GROUP BY cat.CategoryID, cat.CategoryName, cat.AisleCode
ORDER BY "Toplam Ürün Çeşidi" DESC;`
    },
    '5': {
      title: '5. Ciro Analizi (SUM, GROUP BY, ORDER BY): Müşteri Bazlı Toplam Harcama',
      tsql: `SELECT c.CustomerID AS [Müşteri No], c.FullName AS [Müşteri Adı], c.CustomerType AS [Müşteri Tipi], c.City AS [Şehir], COUNT(o.OrderID) AS [Toplam Sipariş Sayısı], SUM(o.TotalAmount) AS [Toplam Ciro (TL)]
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.FullName, c.CustomerType, c.City
ORDER BY [Toplam Ciro (TL)] DESC;`,
      sqlite: `SELECT c.CustomerID AS "Müşteri No", c.FullName AS "Müşteri Adı", c.CustomerType AS "Müşteri Tipi", c.City AS "Şehir", COUNT(o.OrderID) AS "Sipariş Sayısı", printf('%.2f TL', SUM(o.TotalAmount)) AS "Toplam Ciro"
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.FullName, c.CustomerType, c.City
ORDER BY SUM(o.TotalAmount) DESC;`
    },
    '6': {
      title: '6. Zaman Analizi (DATEDIFF & GETDATE): Siparişlerin Üzerinden Geçen Gün Sayısı',
      tsql: `SELECT o.OrderID AS [Sipariş ID], o.InvoiceNo AS [Fatura No], c.FullName AS [Müşteri Adı], o.OrderDate AS [Sipariş Tarihi], GETDATE() AS [Bugünün Tarihi], DATEDIFF(DAY, o.OrderDate, GETDATE()) AS [Geçen Gün Sayısı]
FROM Orders o
INNER JOIN Customers c ON o.CustomerID = c.CustomerID
ORDER BY [Geçen Gün Sayısı] DESC;`,
      sqlite: `SELECT o.OrderID AS "Sipariş ID", o.InvoiceNo AS "Fatura No", c.FullName AS "Müşteri Adı", o.OrderDate AS "Sipariş Tarihi", datetime('now', 'localtime') AS "Bugünün Tarihi", CAST(julianday('now', 'localtime') - julianday(o.OrderDate) AS INTEGER) AS "Geçen Gün Sayısı"
FROM Orders o
INNER JOIN Customers c ON o.CustomerID = c.CustomerID
ORDER BY "Geçen Gün Sayısı" DESC;`
    },
    '7': {
      title: '7. Gerçek İşletme Analizi: Toptancı Vergi No, Barkod ve Net Kâr Raporu',
      tsql: `SELECT s.CompanyName AS [Toptancı Firma], s.TaxOffice AS [Vergi Dairesi], s.TaxNumber AS [Vergi No], p.Barcode AS [Barkod], p.ProductName AS [Ürün Adı], p.PurchasePrice AS [Alış (TL)], p.Price AS [Satış (TL)], SUM(od.Quantity) AS [Satılan Miktar], SUM(od.Quantity * od.UnitPrice) AS [Ciro (TL)], SUM(od.Quantity * (od.UnitPrice - p.PurchasePrice)) AS [Net Kâr (TL)]
FROM OrderDetails od
INNER JOIN Products p ON od.ProductID = p.ProductID
INNER JOIN Suppliers s ON p.SupplierID = s.SupplierID
GROUP BY s.CompanyName, s.TaxOffice, s.TaxNumber, p.Barcode, p.ProductName, p.PurchasePrice, p.Price
ORDER BY [Net Kâr (TL)] DESC;`,
      sqlite: `SELECT s.CompanyName AS "Toptancı Firma", s.TaxOffice AS "Vergi Dairesi", s.TaxNumber AS "Vergi No", p.Barcode AS "Barkod", p.ProductName AS "Ürün Adı", printf('%.2f TL', p.PurchasePrice) AS "Alış Fiyatı", printf('%.2f TL', p.Price) AS "Satış Fiyatı", SUM(od.Quantity) AS "Satılan Miktar", printf('%.2f TL', SUM(od.Quantity * od.UnitPrice)) AS "Satış Cirosu", printf('%.2f TL', SUM(od.Quantity * (od.UnitPrice - p.PurchasePrice))) AS "Net Kâr"
FROM OrderDetails od
INNER JOIN Products p ON od.ProductID = p.ProductID
INNER JOIN Suppliers s ON p.SupplierID = s.SupplierID
GROUP BY s.CompanyName, s.TaxOffice, s.TaxNumber, p.Barcode, p.ProductName, p.PurchasePrice, p.Price
ORDER BY SUM(od.Quantity * (od.UnitPrice - p.PurchasePrice)) DESC;`
    },
    'view': {
      title: 'Bölüm 4.1: CREATE VIEW vw_SiparisOzet (Sanal Tablo Görünümü)',
      tsql: `CREATE VIEW vw_SiparisOzet AS
SELECT o.InvoiceNo AS FaturaNo, c.FullName AS MusteriAdi, o.OrderDate AS SiparisTarihi, p.Barcode AS Barkod, p.ProductName AS UrunAdi, od.Quantity AS Adet, od.UnitPrice AS BirimFiyat, (od.Quantity * od.UnitPrice) AS SatirToplami
FROM Orders o
INNER JOIN Customers c ON o.CustomerID = c.CustomerID
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN Products p ON od.ProductID = p.ProductID;

SELECT * FROM vw_SiparisOzet ORDER BY SiparisTarihi DESC;`,
      sqlite: `SELECT FaturaNo AS "Fatura No", MusteriAdi AS "Müşteri Adı", SiparisTarihi AS "Sipariş Tarihi", Barkod, UrunAdi AS "Ürün Adı", Adet, printf('%.2f TL', BirimFiyat) AS "Birim Fiyat", printf('%.2f TL', SatirToplami) AS "Satır Toplamı"
FROM vw_SiparisOzet
ORDER BY SiparisTarihi DESC;`
    }
  };

  const report = reports[reportId];
  if (!report) {
    return res.status(404).json({ error: 'Rapor bulunamadı.' });
  }

  try {
    const rows = db.prepare(report.sqlite).all();
    res.json({
      title: report.title,
      tsql: report.tsql,
      rowCount: rows.length,
      rows
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// 3. Kategoriler, Toptancılar, Ürünler ve Müşteriler Listesi / Ekleme
exports.getAllData = (req, res) => {
  try {
    const categories = db.prepare('SELECT * FROM Categories ORDER BY CategoryID').all();
    const suppliers = db.prepare('SELECT * FROM Suppliers ORDER BY SupplierID').all();
    const products = db.prepare(`
      SELECT p.*, c.CategoryName, s.CompanyName AS SupplierName, s.TaxNumber AS SupplierTaxNo
      FROM Products p
      INNER JOIN Categories c ON p.CategoryID = c.CategoryID
      INNER JOIN Suppliers s ON p.SupplierID = s.SupplierID
      ORDER BY p.ProductID DESC
    `).all();
    const customers = db.prepare('SELECT * FROM Customers ORDER BY CustomerID DESC').all();
    const orders = db.prepare(`
      SELECT o.*, c.FullName AS CustomerName, c.City
      FROM Orders o
      INNER JOIN Customers c ON o.CustomerID = c.CustomerID
      ORDER BY o.OrderID DESC
    `).all();

    res.json({ categories, suppliers, products, customers, orders });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.addProduct = (req, res) => {
  const { Barcode, SKU, ProductName, UnitType, PurchasePrice, Price, Stock, CategoryID, SupplierID } = req.body;
  try {
    const stmt = db.prepare(`
      INSERT INTO Products (Barcode, SKU, ProductName, UnitType, PurchasePrice, Price, Stock, CategoryID, SupplierID)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `);
    const result = stmt.run(
      Barcode,
      SKU,
      ProductName,
      UnitType || 'Kg',
      Number(PurchasePrice),
      Number(Price),
      Number(Stock ?? 0),
      Number(CategoryID),
      Number(SupplierID)
    );
    res.status(201).json({ message: 'Barkodlu ürün başarıyla eklendi.', productId: result.lastInsertRowid });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

exports.addSupplier = (req, res) => {
  const { CompanyName, TaxOffice, TaxNumber, ContactPerson, Phone, City } = req.body;
  try {
    const stmt = db.prepare(`
      INSERT INTO Suppliers (CompanyName, TaxOffice, TaxNumber, ContactPerson, Phone, City)
      VALUES (?, ?, ?, ?, ?, ?)
    `);
    const result = stmt.run(CompanyName, TaxOffice, TaxNumber, ContactPerson, Phone, City);
    res.status(201).json({ message: 'Toptancı başarıyla eklendi.', supplierId: result.lastInsertRowid });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

exports.addCustomer = (req, res) => {
  const { FullName, CustomerType, TaxOrIdentityNo, Phone, City, Email } = req.body;
  try {
    const stmt = db.prepare(`
      INSERT INTO Customers (FullName, CustomerType, TaxOrIdentityNo, Phone, City, Email)
      VALUES (?, ?, ?, ?, ?, ?)
    `);
    const result = stmt.run(FullName, CustomerType || 'Bireysel', TaxOrIdentityNo, Phone, City, Email);
    res.status(201).json({ message: 'Müşteri başarıyla eklendi.', customerId: result.lastInsertRowid });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

// 4. Yeni Satış Faturası (Orders + OrderDetails + Stok Düşümü)
exports.createOrder = (req, res) => {
  const { CustomerID, PaymentMethod, items } = req.body;
  if (!CustomerID || !Array.isArray(items) || items.length === 0) {
    return res.status(400).json({ error: 'Müşteri ve en az 1 ürün kalemi seçilmelidir.' });
  }

  try {
    db.exec('BEGIN TRANSACTION;');

    const lastOrder = db.prepare('SELECT COUNT(*) AS cnt FROM Orders').get().cnt;
    const invoiceNo = `FTR2026${String(lastOrder + 1).padStart(5, '0')}`;

    let totalAmount = 0;
    const enrichedItems = [];

    for (const item of items) {
      const prod = db.prepare('SELECT * FROM Products WHERE ProductID = ?').get(Number(item.ProductID));
      if (!prod) {
        throw new Error(`Ürün bulunamadı (ID: ${item.ProductID})`);
      }
      const qty = Number(item.Quantity);
      if (prod.Stock < qty) {
        throw new Error(`${prod.ProductName} için yeterli stok yok! (Mevcut: ${prod.Stock}, İstenen: ${qty})`);
      }
      totalAmount += qty * prod.Price;
      enrichedItems.push({ ProductID: prod.ProductID, Quantity: qty, UnitPrice: prod.Price });
    }

    const orderInsert = db.prepare(`
      INSERT INTO Orders (InvoiceNo, CustomerID, OrderDate, PaymentMethod, TotalAmount)
      VALUES (?, ?, datetime('now', 'localtime'), ?, ?)
    `).run(invoiceNo, Number(CustomerID), PaymentMethod || 'Kredi Kartı', totalAmount);

    const orderId = orderInsert.lastInsertRowid;

    const detailStmt = db.prepare(`
      INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice)
      VALUES (?, ?, ?, ?)
    `);
    const stockStmt = db.prepare(`
      UPDATE Products SET Stock = Stock - ? WHERE ProductID = ?
    `);

    for (const it of enrichedItems) {
      detailStmt.run(orderId, it.ProductID, it.Quantity, it.UnitPrice);
      stockStmt.run(it.Quantity, it.ProductID);
    }

    db.exec('COMMIT;');
    res.status(201).json({
      message: `Fatura (${invoiceNo}) başarıyla kesildi ve stoklar güncellendi.`,
      invoiceNo,
      orderId,
      totalAmount
    });
  } catch (err) {
    try { db.exec('ROLLBACK;'); } catch (_) {}
    res.status(400).json({ error: err.message });
  }
};

// 5. Bölüm 4.2: Veri Tabanı Yedekleme (BACKUP DATABASE Simülasyonu & Fiziksel Yedek)
exports.backupDatabase = (req, res) => {
  try {
    const backupDir = path.join(__dirname, '..', '..', 'backups');
    if (!fs.existsSync(backupDir)) {
      fs.mkdirSync(backupDir, { recursive: true });
    }
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const targetBak = path.join(backupDir, `CerezKapisiDB_FullBackup_${timestamp}.bak`);
    fs.copyFileSync(dbPath, targetBak);

    res.json({
      message: 'CerezKapisiDB veri tabanı yedeği başarıyla alındı!',
      backupPath: targetBak,
      tsqlCommand: `BACKUP DATABASE CerezKapisiDB\nTO DISK = 'C:\\Yedek\\CerezKapisiDB_FullBackup.bak'\nWITH FORMAT, MEDIANAME = 'CerezKapisiDB_Yedek', NAME = 'CerezKapisiDB Tam Veri Tabanı Yedeği';`
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
