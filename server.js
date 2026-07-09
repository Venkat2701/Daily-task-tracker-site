const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 3000;
const DATA_FILE = path.join(__dirname, 'data.json');
const HTML_FILE = path.join(__dirname, 'daily-matrix-planner-standalone (1).html');

const server = http.createServer((req, res) => {
  // CORS Headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  // Route: Home page
  if (req.url === '/' || req.url === '/index.html' || req.url === '/daily-matrix-planner-standalone%20(1).html') {
    fs.readFile(HTML_FILE, 'utf8', (err, content) => {
      if (err) {
        res.writeHead(500, { 'Content-Type': 'text/plain' });
        res.end('Error loading application HTML file. Ensure daily-matrix-planner-standalone (1).html exists in the same directory as server.js.');
      } else {
        res.writeHead(200, { 'Content-Type': 'text/html' });
        res.end(content);
      }
    });
  } 
  // Route: API GET/POST
  else if (req.url === '/api/data') {
    if (req.method === 'GET') {
      fs.readFile(DATA_FILE, 'utf8', (err, content) => {
        if (err) {
          // File does not exist yet; send default empty state
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ dailyData: {}, lastReviewDate: null, settings: {} }));
        } else {
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(content);
        }
      });
    } else if (req.method === 'POST') {
      let body = '';
      req.on('data', chunk => {
        body += chunk.toString();
      });
      req.on('end', () => {
        try {
          // Validate JSON structure
          JSON.parse(body);
          fs.writeFile(DATA_FILE, body, 'utf8', (err) => {
            if (err) {
              res.writeHead(500, { 'Content-Type': 'application/json' });
              res.end(JSON.stringify({ success: false, error: 'Write failed: ' + err.message }));
            } else {
              res.writeHead(200, { 'Content-Type': 'application/json' });
              res.end(JSON.stringify({ success: true }));
            }
          });
        } catch (e) {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ success: false, error: 'Invalid JSON body' }));
        }
      });
    } else {
      res.writeHead(405, { 'Content-Type': 'text/plain' });
      res.end('Method Not Allowed');
    }
  } 
  // Fallback 404
  else {
    res.writeHead(404, { 'Content-Type': 'text/plain' });
    res.end('Not Found');
  }
});

server.listen(PORT, () => {
  console.log(`=======================================================`);
  console.log(` Daily Matrix Planner server started successfully!`);
  console.log(` Open your browser and navigate to:`);
  console.log(`   http://localhost:${PORT}`);
  console.log(`=======================================================`);
  console.log(` Data is saved to: ${DATA_FILE}`);
});
