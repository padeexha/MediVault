const express = require('express');
const dotenv  = require('dotenv');
const cors    = require('cors');
const connectDB = require('./config/database');

// Load .env from the project root (one level above /src)
dotenv.config({ path: require('path').join(__dirname, '..', '.env') });

// Open the MongoDB connection before registering routes so every request
// handler can use the Mongoose models against the same shared connection.
connectDB();

const app = express();

app.use(cors());
// Request logger — handy for tracing API calls in dev and production logs
app.use((req, _res, next) => { console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`); next(); });
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
// Serve locally saved uploads (used as fallback when Firebase is not configured)
app.use('/uploads', express.static(require('path').join(__dirname, '..', 'uploads')));

app.use('/api/auth',           require('./routes/auth'));
app.use('/api/records',        require('./routes/records'));
app.use('/api/permissions',    require('./routes/permissions'));
app.use('/api/audit',          require('./routes/audit'));
app.use('/api/search',         require('./routes/search'));
app.use('/api/health-profile', require('./routes/healthProfile'));

app.get('/', (req, res) => {
  res.json({ message: 'Medi Vault API is running', version: '1.0.0' });
});

// Global error handler — catches errors passed via next(err) or thrown by multer
app.use((err, req, res, next) => {
  console.error('FULL ERROR:', err);
  // Multer throws these specific codes/messages for file validation failures
  if (err.message.includes('Unsupported file type')) {
    return res.status(400).json({ success: false, message: err.message });
  }
  if (err.code === 'LIMIT_FILE_SIZE') {
    return res.status(400).json({ success: false, message: 'File too large. Maximum is 20MB.' });
  }
  res.status(500).json({ success: false, message: err.message });
});

const PORT = process.env.PORT || 5000;
// Skip starting the server when running tests — tests import the app directly
if (process.env.NODE_ENV !== 'test') {
  app.listen(PORT, () => console.log(`Medi Vault server running on port ${PORT}`));
}

// Self-contained HTML page served for password reset links sent via email.
// The page embeds inline JS that calls the API, so no separate frontend is needed.
app.get('/reset-password/:token', (req, res) => {
  const token = req.params.token;
  const apiBase = process.env.BACKEND_URL || 'https://medivaultejaa.onrender.com';
  res.send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Reset Password — MediVault</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      background: linear-gradient(135deg, #0a1628 0%, #0d2137 50%, #0a1628 100%);
      padding: 24px;
    }
    .card {
      background: rgba(255,255,255,0.07);
      backdrop-filter: blur(20px);
      border: 1px solid rgba(255,255,255,0.12);
      border-radius: 20px;
      padding: 36px 32px;
      width: 100%;
      max-width: 420px;
    }
    .logo {
      text-align: center;
      margin-bottom: 28px;
    }
    .logo-text {
      font-size: 22px;
      font-weight: 700;
      color: #fff;
      letter-spacing: 0.5px;
    }
    .logo-text span { color: #3DD598; }
    h2 {
      color: #fff;
      font-size: 20px;
      font-weight: 700;
      margin-bottom: 6px;
    }
    .subtitle {
      color: rgba(255,255,255,0.55);
      font-size: 13px;
      margin-bottom: 24px;
      line-height: 1.5;
    }
    label {
      display: block;
      color: rgba(255,255,255,0.75);
      font-size: 13px;
      font-weight: 600;
      margin-bottom: 6px;
    }
    .input-wrap {
      position: relative;
      margin-bottom: 16px;
    }
    input[type=password] {
      width: 100%;
      padding: 12px 44px 12px 14px;
      background: rgba(255,255,255,0.06);
      border: 1px solid rgba(255,255,255,0.15);
      border-radius: 12px;
      color: #fff;
      font-size: 15px;
      outline: none;
      transition: border-color 0.2s;
    }
    input[type=password]::placeholder { color: rgba(255,255,255,0.3); }
    input[type=password]:focus { border-color: #3DD598; }
    input[type=password].error { border-color: #FF6B6B; }
    .toggle-eye {
      position: absolute;
      right: 12px;
      top: 50%;
      transform: translateY(-50%);
      background: none;
      border: none;
      cursor: pointer;
      color: rgba(255,255,255,0.4);
      font-size: 18px;
      line-height: 1;
      padding: 2px;
    }
    .rules {
      background: rgba(255,255,255,0.04);
      border: 1px solid rgba(255,255,255,0.1);
      border-radius: 12px;
      padding: 14px 16px;
      margin-bottom: 20px;
    }
    .rules-title {
      color: rgba(255,255,255,0.6);
      font-size: 12px;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.6px;
      margin-bottom: 10px;
    }
    .rule {
      display: flex;
      align-items: center;
      gap: 8px;
      font-size: 13px;
      color: rgba(255,255,255,0.45);
      margin-bottom: 6px;
      transition: color 0.2s;
    }
    .rule:last-child { margin-bottom: 0; }
    .rule.met { color: #3DD598; }
    .rule .dot {
      width: 16px;
      height: 16px;
      border-radius: 50%;
      border: 1.5px solid rgba(255,255,255,0.25);
      flex-shrink: 0;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 10px;
      transition: all 0.2s;
    }
    .rule.met .dot {
      background: #3DD598;
      border-color: #3DD598;
      color: #fff;
    }
    .match-row {
      font-size: 13px;
      color: rgba(255,255,255,0.45);
      min-height: 18px;
      margin-bottom: 20px;
      margin-top: -8px;
    }
    .match-row.ok { color: #3DD598; }
    .match-row.bad { color: #FF6B6B; }
    button[type=submit] {
      width: 100%;
      padding: 14px;
      background: linear-gradient(135deg, #3DD598, #0F6E56);
      border: none;
      border-radius: 12px;
      color: #fff;
      font-size: 15px;
      font-weight: 700;
      cursor: pointer;
      transition: opacity 0.2s;
    }
    button[type=submit]:disabled { opacity: 0.5; cursor: not-allowed; }
    button[type=submit]:not(:disabled):hover { opacity: 0.9; }
    .spinner {
      display: inline-block;
      width: 16px; height: 16px;
      border: 2px solid rgba(255,255,255,0.4);
      border-top-color: #fff;
      border-radius: 50%;
      animation: spin 0.7s linear infinite;
      vertical-align: middle;
      margin-right: 6px;
    }
    @keyframes spin { to { transform: rotate(360deg); } }
    .error-banner {
      background: rgba(255,107,107,0.15);
      border: 1px solid rgba(255,107,107,0.35);
      border-radius: 10px;
      color: #FF6B6B;
      font-size: 13px;
      padding: 10px 14px;
      margin-top: 12px;
      text-align: center;
    }
    /* success state */
    #successView {
      display: none;
      text-align: center;
    }
    .success-icon {
      width: 72px; height: 72px;
      background: rgba(61,213,152,0.15);
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 20px;
      font-size: 32px;
    }
    .success-title {
      color: #fff;
      font-size: 22px;
      font-weight: 700;
      margin-bottom: 10px;
    }
    .success-body {
      color: rgba(255,255,255,0.6);
      font-size: 14px;
      line-height: 1.6;
      margin-bottom: 28px;
    }
    .open-app-btn {
      display: inline-block;
      padding: 13px 32px;
      background: linear-gradient(135deg, #3DD598, #0F6E56);
      border-radius: 12px;
      color: #fff;
      font-weight: 700;
      font-size: 15px;
      text-decoration: none;
      cursor: pointer;
      border: none;
      width: 100%;
    }
  </style>
</head>
<body>
  <div class="card">
    <div class="logo">
      <div class="logo-text">Medi<span>Vault</span></div>
    </div>

    <!-- Reset form -->
    <div id="formView">
      <h2>Set a new password</h2>
      <p class="subtitle">Choose a strong password for your account. You'll use it to sign in going forward.</p>

      <div class="input-wrap">
        <label for="password">New Password</label>
        <input type="password" id="password" placeholder="Enter new password" oninput="onPasswordInput()" autocomplete="new-password">
        <button class="toggle-eye" type="button" onclick="toggleVis('password', this)" aria-label="Show password">👁</button>
      </div>

      <div class="rules" id="rules">
        <div class="rules-title">Password must include</div>
        <div class="rule" id="r-len"><span class="dot"></span> At least 8 characters</div>
        <div class="rule" id="r-upper"><span class="dot"></span> One uppercase letter (A–Z)</div>
        <div class="rule" id="r-lower"><span class="dot"></span> One lowercase letter (a–z)</div>
        <div class="rule" id="r-digit"><span class="dot"></span> One number (0–9)</div>
        <div class="rule" id="r-special"><span class="dot"></span> One special character (!@#\$%^&amp;*…)</div>
      </div>

      <div class="input-wrap">
        <label for="confirm">Confirm Password</label>
        <input type="password" id="confirm" placeholder="Repeat new password" oninput="onConfirmInput()" autocomplete="new-password">
        <button class="toggle-eye" type="button" onclick="toggleVis('confirm', this)" aria-label="Show password">👁</button>
      </div>
      <div class="match-row" id="matchMsg"></div>

      <button type="submit" id="submitBtn" onclick="doReset()" disabled>Reset Password</button>
      <div id="errorBanner" class="error-banner" style="display:none"></div>
    </div>

    <!-- Success state -->
    <div id="successView">
      <div class="success-icon">✅</div>
      <div class="success-title">Password reset!</div>
      <p class="success-body">Your password has been updated successfully.<br>Open the MediVault app and sign in with your new password.</p>
      <button class="open-app-btn" onclick="window.close()">Close this page</button>
    </div>
  </div>

  <script>
    const rules = {
      len:     { el: document.getElementById('r-len'),     test: p => p.length >= 8 },
      upper:   { el: document.getElementById('r-upper'),   test: p => /[A-Z]/.test(p) },
      lower:   { el: document.getElementById('r-lower'),   test: p => /[a-z]/.test(p) },
      digit:   { el: document.getElementById('r-digit'),   test: p => /[0-9]/.test(p) },
      special: { el: document.getElementById('r-special'), test: p => /[^A-Za-z0-9]/.test(p) },
    };

    function allRulesMet(p) {
      return Object.values(rules).every(r => r.test(p));
    }

    function onPasswordInput() {
      const p = document.getElementById('password').value;
      Object.values(rules).forEach(r => {
        const met = r.test(p);
        r.el.classList.toggle('met', met);
        r.el.querySelector('.dot').textContent = met ? '✓' : '';
      });
      onConfirmInput();
    }

    function onConfirmInput() {
      const p = document.getElementById('password').value;
      const c = document.getElementById('confirm').value;
      const msg = document.getElementById('matchMsg');
      const btn = document.getElementById('submitBtn');
      const confirmInput = document.getElementById('confirm');

      if (c.length === 0) {
        msg.textContent = '';
        msg.className = 'match-row';
        confirmInput.classList.remove('error');
      } else if (p === c) {
        msg.textContent = '✓ Passwords match';
        msg.className = 'match-row ok';
        confirmInput.classList.remove('error');
      } else {
        msg.textContent = 'Passwords do not match';
        msg.className = 'match-row bad';
        confirmInput.classList.add('error');
      }

      btn.disabled = !(allRulesMet(p) && p === c && c.length > 0);
    }

    function toggleVis(id, btn) {
      const input = document.getElementById(id);
      const show = input.type === 'password';
      input.type = show ? 'text' : 'password';
      btn.textContent = show ? '🙈' : '👁';
    }

    async function doReset() {
      const password = document.getElementById('password').value;
      const btn = document.getElementById('submitBtn');
      const errorBanner = document.getElementById('errorBanner');

      btn.disabled = true;
      btn.innerHTML = '<span class="spinner"></span>Resetting…';
      errorBanner.style.display = 'none';

      try {
        const response = await fetch('${apiBase}/api/auth/reset-password/${token}', {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ password }),
        });
        const data = await response.json();
        if (data.success) {
          document.getElementById('formView').style.display = 'none';
          document.getElementById('successView').style.display = 'block';
        } else {
          errorBanner.textContent = data.message || 'Something went wrong. Please try again.';
          errorBanner.style.display = 'block';
          btn.disabled = false;
          btn.textContent = 'Reset Password';
        }
      } catch (_) {
        errorBanner.textContent = 'Network error. Please check your connection and try again.';
        errorBanner.style.display = 'block';
        btn.disabled = false;
        btn.textContent = 'Reset Password';
      }
    }
  </script>
</body>
</html>`);
});

module.exports = app;
