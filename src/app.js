const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const erpController = require('./controllers/erpController');

const PORT = process.env.PORT || 3050;

function createResWrapper(res) {
  let statusCode = 200;
  return {
    status(code) {
      statusCode = code;
      return this;
    },
    json(data) {
      res.writeHead(statusCode, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify(data));
    }
  };
}

function parseJsonBody(req) {
  return new Promise((resolve) => {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      try {
        resolve(body ? JSON.parse(body) : {});
      } catch (_) {
        resolve({});
      }
    });
  });
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);
  const pathname = url.pathname;
  const method = req.method;
  const wrappedRes = createResWrapper(res);

  // Static files
  if (method === 'GET' && (pathname === '/' || pathname === '/index.html')) {
    const htmlPath = path.join(__dirname, 'public', 'index.html');
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    return res.end(fs.readFileSync(htmlPath));
  }

  if (method === 'GET' && pathname === '/er-diagram.png') {
    const pngPath = path.join(__dirname, '..', 'NusretYinanc_CerezKapisi_Proje.png');
    res.writeHead(200, { 'Content-Type': 'image/png' });
    return res.end(fs.readFileSync(pngPath));
  }

  // API Routes
  if (method === 'GET' && pathname === '/api/stats') {
    return erpController.getDashboardStats(req, wrappedRes);
  }

  if (method === 'GET' && pathname.startsWith('/api/reports/')) {
    const reportId = pathname.split('/api/reports/')[1];
    req.params = { reportId };
    return erpController.runReportQuery(req, wrappedRes);
  }

  if (method === 'GET' && pathname === '/api/data') {
    return erpController.getAllData(req, wrappedRes);
  }

  if (method === 'POST' && pathname === '/api/products') {
    req.body = await parseJsonBody(req);
    return erpController.addProduct(req, wrappedRes);
  }

  if (method === 'POST' && pathname === '/api/suppliers') {
    req.body = await parseJsonBody(req);
    return erpController.addSupplier(req, wrappedRes);
  }

  if (method === 'POST' && pathname === '/api/customers') {
    req.body = await parseJsonBody(req);
    return erpController.addCustomer(req, wrappedRes);
  }

  if (method === 'POST' && pathname === '/api/orders') {
    req.body = await parseJsonBody(req);
    return erpController.createOrder(req, wrappedRes);
  }

  if (method === 'POST' && pathname === '/api/backup') {
    return erpController.backupDatabase(req, wrappedRes);
  }

  res.writeHead(404, { 'Content-Type': 'application/json; charset=utf-8' });
  res.end(JSON.stringify({ error: 'Sayfa veya endpoint bulunamadı.' }));
});

server.listen(PORT, () => {
  console.log(`========================================================================`);
  console.log(`🥜 ÇerezKapısı SQL Veri Yönetim & ERP Sistemi Çalışıyor!`);
  console.log(`🌐 Web Paneli : http://localhost:${PORT}`);
  console.log(`🗄️  Veri Tabanı: CerezKapisiDB (İlişkisel SQL Motoru Aktif)`);
  console.log(`========================================================================`);
});
