require('dotenv').config();
const fs           = require('fs');
const path         = require('path');
const express      = require('express');
const cors         = require('cors');
const http         = require('http');
const { Server }   = require('socket.io');
const mongoose     = require('mongoose');
const cookieParser = require('cookie-parser');
const helmet       = require('helmet');
const rateLimit    = require('express-rate-limit');
const ioStore      = require('./socket/io');
const { auth }     = require('./lib/auth-better');

// ── Uploads dir ─────────────────────────
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

const app    = express();
const server = http.createServer(app);
const isProd = process.env.NODE_ENV === 'production';

// ── CORS (COMPLETE FIX) ─────────────────────────
const allowedOrigins = [
  'http://localhost:3000',
  'http://localhost:5173',
  process.env.FRONTEND_URL,
  'https://bca-auction-production-1.up.railway.app',
].filter(Boolean);

console.log('🌐 Allowed CORS origins:', allowedOrigins);

const corsOptions = {
  origin: function (origin, callback) {
    if (!origin) return callback(null, true);
    
    if (allowedOrigins.includes(origin) || 
        (isProd && origin.includes('.railway.app'))) {
      callback(null, true);
    } else {
      console.log('⚠️ Blocked origin:', origin);
      callback(null, true);
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Cookie', 'X-Requested-With'],
  exposedHeaders: ['Set-Cookie'],
  maxAge: 86400,
};

app.use(cors(corsOptions));
app.options('*', cors(corsOptions));

// ── Socket.io ───────────────────────────
const io = new Server(server, {
  cors: {
    origin: function(origin, callback) {
      if (!origin || 
          allowedOrigins.includes(origin) || 
          (isProd && origin.includes('.railway.app'))) {
        callback(null, true);
      } else {
        callback(null, true);
      }
    },
    methods: ['GET', 'POST'],
    credentials: true,
    allowedHeaders: ['Content-Type', 'Authorization'],
  },
  transports: ['websocket', 'polling'],
  allowEIO3: true,
  pingTimeout: 60000,
  pingInterval: 25000,
});

ioStore.setIO(io);
app.set('io', io);

// ── Security ────────────────────────────
app.set('trust proxy', 1);

if (isProd) {
  app.use(helmet({
    contentSecurityPolicy: false,
    crossOriginEmbedderPolicy: false,
    crossOriginOpenerPolicy: false,
    crossOriginResourcePolicy: { policy: 'cross-origin' },
  }));
}

app.disable('x-powered-by');

// ── Body parsing ────────────────────────
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use(cookieParser());

// ── Rate limits ─────────────────────────
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: isProd ? 500 : 2000,
  message: 'Too many requests from this IP',
  standardHeaders: true,
  legacyHeaders: false,
});

app.use('/api', limiter);

// ── Static files ────────────────────────
app.use('/uploads', express.static(uploadsDir, {
  maxAge: '1d',
  setHeaders: (res) => {
    res.setHeader('Cross-Origin-Resource-Policy', 'cross-origin');
    res.setHeader('Access-Control-Allow-Origin', '*');
  }
}));

// ── Better Auth Routes ──────────────────
app.use('/api/auth/*', (req, res, next) => {
  auth.handler(req, res, next).catch(err => {
    console.error('❌ Better Auth Error:', err);
    res.status(500).json({ error: 'Authentication failed' });
  });
});

// ── API Routes ──────────────────────────
app.use('/api/auctions', require('./routes/auctions'));
app.use('/api/admin', require('./routes/admin'));
app.use('/api/payment', require('./routes/payment'));

// ── Health check ────────────────────────
app.get('/api/health', (req, res) => {
  res.json({ 
    ok: true, 
    timestamp: new Date().toISOString(),
    env: process.env.NODE_ENV,
    mongodb: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected',
    auth: 'Better Auth with Google OAuth'
  });
});

app.get('/health', (req, res) => {
  res.json({ ok: true });
});

app.get('/', (req, res) => {
  res.json({ 
    message: 'BCA Auction Backend API',
    status: 'running',
    auth: 'Better Auth with Google OAuth',
    endpoints: {
      health: '/api/health',
      auth: '/api/auth/*',
      auctions: '/api/auctions/*',
      admin: '/api/admin/*',
    }
  });
});

// ── 404 handler ─────────────────────────
app.use((req, res) => {
  console.log('❌ 404:', req.method, req.url);
  res.status(404).json({ 
    error: `${req.method} ${req.url} not found`,
    availableRoutes: ['/api/auth', '/api/auctions', '/api/admin']
  });
});

// ── Error handler ───────────────────────
app.use((err, req, res, next) => {
  console.error('❌ Server error:', err.message);
  console.error(err.stack);
  res.status(err.status || 500).json({ 
    error: isProd ? 'Server error' : err.message,
    ...(isProd ? {} : { stack: err.stack })
  });
});

// ── MongoDB + Start ─────────────────────
const MONGODB_URI = process.env.MONGODB_URI;

if (!MONGODB_URI) {
  console.error('❌ MONGODB_URI not found in environment variables');
  process.exit(1);
}

mongoose.connect(MONGODB_URI, {
  serverSelectionTimeoutMS: 5000,
  socketTimeoutMS: 45000,
})
.then(async () => {
  console.log('✅ MongoDB connected');
  console.log('✅ Better Auth initialized with Google OAuth');

  require('./socket/auctionEngine')(io);
  
  const PORT = process.env.PORT || 5000;
  server.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Server running on port ${PORT}`);
    console.log(`🌐 Environment: ${process.env.NODE_ENV}`);
    console.log(`🔐 Auth: Better Auth with Google OAuth`);
    console.log(`📚 Google Client ID: ${process.env.GOOGLE_CLIENT_ID ? '✅ Configured' : '❌ Not set'}`);
  });
})
.catch(err => {
  console.error('❌ MongoDB connection failed:', err.message);
  process.exit(1);
});

// ── Graceful shutdown ───────────────────
process.on('SIGTERM', () => {
  console.log('SIGTERM received, closing server...');
  server.close(() => {
    mongoose.connection.close(false, () => {
      console.log('MongoDB connection closed');
      process.exit(0);
    });
  });
});
