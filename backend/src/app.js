const express = require('express');
const dotenv  = require('dotenv');
const cors    = require('cors');
const connectDB = require('./config/database');

dotenv.config({ path: require('path').join(__dirname, '..', '.env') });
connectDB();

const app = express();

app.use(cors());
app.use((req, _res, next) => { console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`); next(); });
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use('/uploads', express.static(require('path').join(__dirname, '..', 'uploads')));

app.use('/api/auth',        require('./routes/auth'));
app.use('/api/records',     require('./routes/records'));
app.use('/api/permissions', require('./routes/permissions'));
app.use('/api/audit',       require('./routes/audit'));
app.use('/api/search',      require('./routes/search'));

app.get('/', (req, res) => {
  res.json({ message: 'Medi Vault API is running', version: '1.0.0' });
});

app.use((err, req, res, next) => {
  console.error('FULL ERROR:', err);
  if (err.message.includes('Unsupported file type')) {
    return res.status(400).json({ success: false, message: err.message });
  }
  if (err.code === 'LIMIT_FILE_SIZE') {
    return res.status(400).json({ success: false, message: 'File too large. Maximum is 20MB.' });
  }
  res.status(500).json({ success: false, message: err.message });
});

const PORT = process.env.PORT || 5000;
if (process.env.NODE_ENV !== 'test') {
  app.listen(PORT, () => console.log(`Medi Vault server running on port ${PORT}`));
}

app.get('/reset-password/:token', (req, res) => {
  const token = req.params.token;
  const apiBase = process.env.BACKEND_URL || 'https://medivaultejaa.onrender.com';
  res.send(`
    <html>
      <head><title>Reset Password - MediVault</title></head>
      <body style="font-family: Arial; max-width: 400px; margin: 50px auto; padding: 20px;">
        <h2 style="color: #0F6E56;">Reset Your Password</h2>
        <form id="resetForm">
          <input type="hidden" id="token" value="${token}">
          <div style="margin-bottom: 16px;">
            <label>New Password</label><br>
            <input type="password" id="password" style="width:100%;padding:10px;margin-top:8px;border:1px solid #ccc;border-radius:8px;" placeholder="Minimum 8 characters">
          </div>
          <div style="margin-bottom: 16px;">
            <label>Confirm Password</label><br>
            <input type="password" id="confirm" style="width:100%;padding:10px;margin-top:8px;border:1px solid #ccc;border-radius:8px;" placeholder="Repeat password">
          </div>
          <button type="button" onclick="resetPassword()" style="width:100%;padding:12px;background:#0F6E56;color:white;border:none;border-radius:8px;font-size:16px;cursor:pointer;">Reset Password</button>
          <p id="message" style="margin-top:16px;text-align:center;"></p>
        </form>
        <script>
          async function resetPassword() {
            const password = document.getElementById('password').value;
            const confirm = document.getElementById('confirm').value;
            const token = document.getElementById('token').value;
            const message = document.getElementById('message');
            if (password.length < 8) { message.style.color='red'; message.textContent='Password must be at least 8 characters'; return; }
            if (password !== confirm) { message.style.color='red'; message.textContent='Passwords do not match'; return; }
            const response = await fetch('${apiBase}/api/auth/reset-password/' + token, {
              method: 'PUT',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ password })
            });
            const data = await response.json();
            if (data.success) {
              message.style.color='#0F6E56';
              message.textContent='Password reset successfully. You can now log in.';
              document.getElementById('resetForm').style.display='none';
            } else {
              message.style.color='red';
              message.textContent=data.message||'Something went wrong';
            }
          }
        </script>
      </body>
    </html>
  `);
});

module.exports = app;
