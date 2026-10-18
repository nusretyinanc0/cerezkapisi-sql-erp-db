# 🥜 ÇerezKapısı — SQL Veri Yönetim ve ERP Sistemi (`CerezKapisiDB`)

[![SQL Server](https://img.shields.io/badge/SQL_Server-T--SQL-CC2927?style=flat-square&logo=microsoftsqlserver&logoColor=white)](./NusretYinanc_CerezKapisi_Proje.sql)
[![Node.js](https://img.shields.io/badge/Node.js-SQL_Engine-339933?style=flat-square&logo=nodedotjs&logoColor=white)](./src/app.js)
[![Architecture](https://img.shields.io/badge/Mimari-İlişkisel_Veri_Tabanı_(3NF)-2563EB?style=flat-square)](./NusretYinanc_CerezKapisi_Proje.png)

**ÇerezKapısı**; barkodlu ürün envanterini, toptancı vergi kayıtlarını, alış/satış maliyetlerini ve müşteri sipariş faturalarını yönetmek üzere tasarlanmış ilişkisel bir veri tabanı (**SQL Server / T-SQL**) ve canlı raporlama projesidir.

---



## 📐 Veri Tabanı Mimarisi (`CerezKapisiDB`)

Sistem birbirine bağlı **6 ilişkisel tablo** ve **1 görünüm (`VIEW`)** üzerinden çalışır:

* **`Categories`**: Ürün kategorileri, KDV oranları ve reyon kodları.
* **`Suppliers`**: Toptancı firma ünvanları, vergi daireleri ve 10 haneli vergi numaraları (`UNIQUE`).
* **`Products`**: `EAN-13` barkodlu ürünler, alış maliyetleri, satış fiyatları ve stok miktarları.
* **`Customers`**: Bireysel ve kurumsal müşteri iletişim/fatura bilgileri.
* **`Orders` & `OrderDetails`**: Müşterilere kesilen satış faturaları ve sipariş kalem detayları.
* **`vw_SiparisOzet` (`VIEW`)**: Müşteri, fatura, tarih, barkod, ürün ve adet bilgilerini birleştiren sanal tablo.

![CerezKapisiDB ER Diyagramı](./NusretYinanc_CerezKapisi_Proje.png)

---

## 📁 Klasör Yapısı

```text
cerezkapisi-sql-proje/
├── sql/                                      # Modüler SQL betikleri (DDL, DML, DQL, View & Backup)
├── src/                                      # Canlı ERP & SQL Raporlama Web Uygulaması
├── rapor_gorselleri/                         # Sorgu çıktılarının SSMS ekran görüntüleri
├── NusretYinanc_CerezKapisi_Proje.sql        # Tek parça proje SQL dosyası
├── NusretYinanc_CerezKapisi_Proje.docx       # Word proje raporu
├── NusretYinanc_CerezKapisi_Proje.png        # İlişkisel veri tabanı diyagramı
└── package.json
```

---

## 🚀 Canlı Web Panelini Çalıştırma

Sorguları tarayıcı üzerinden canlı çalıştırmak, barkodlu ürün/toptancı eklemek ve fatura kesmek için:

```bash
npm start
```

Sunucu başladığında **`http://localhost:3050`** adresinden yönetim paneline erişebilirsiniz.

---
**Hazırlayan:** Nusret Yınanç

