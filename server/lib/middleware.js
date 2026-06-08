const { auth } = require('./auth');

// Middleware to attach user to request
const authMiddleware = async (req, res, next) => {
  try {
    const session = await auth.api.getSession({ headers: req.headers });
    if (session?.user) {
      req.user = session.user;
      req.session = session;
    }
    next();
  } catch (error) {
    console.error('Auth middleware error:', error);
    next();
  }
};

// Middleware to require authentication
const requireAuth = (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({ error: 'Unauthorized - Please login' });
  }
  next();
};

// Middleware to require admin
const requireAdmin = (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({ error: 'Unauthorized - Please login' });
  }
  if (req.user.role !== 'admin' && !req.user.isAdmin) {
    return res.status(403).json({ error: 'Forbidden - Admin access required' });
  }
  next();
};

module.exports = { authMiddleware, requireAuth, requireAdmin };