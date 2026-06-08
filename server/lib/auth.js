const { betterAuth } = require('better-auth');
const { mongodbAdapter } = require('better-auth/adapters/mongodb');

const auth = betterAuth({
  database: mongodbAdapter({
    uri: process.env.MONGODB_URI,
    databaseName: 'beast-cricket-auction',
  }),
  secret: process.env.BETTER_AUTH_SECRET || process.env.JWT_SECRET || 'change-me-in-production',
  baseURL: process.env.BACKEND_URL || 'http://localhost:5000',
  basePath: '/api/auth',
  
  socialProviders: {
    google: {
      clientId: process.env.GOOGLE_CLIENT_ID || '',
      clientSecret: process.env.GOOGLE_CLIENT_SECRET || '',
      redirectURL: `${process.env.BACKEND_URL || 'http://localhost:5000'}/api/auth/callback/google`,
    },
  },
  
  emailAndPassword: {
    enabled: true,
    autoSignUpOnSignIn: false,
    minPasswordLength: 6,
    requireEmailVerification: false,
  },
  
  session: {
    expiresIn: 60 * 60 * 24 * 7,
    updateAge: 60 * 60 * 24,
    cookieCache: {
      enabled: true,
      maxAge: 5 * 60,
    },
  },
  
  user: {
    additionalFields: {
      role: {
        type: 'string',
        default: 'viewer',
      },
      isAdmin: {
        type: 'boolean',
        default: false,
      },
    },
  },
  
  callbacks: {
    async onSignUpWithPassword({ user, password }) {
      // Check if email is admin email
      const isAdmin = user.email.toLowerCase() === (process.env.ADMIN_EMAIL || '').toLowerCase();
      
      if (isAdmin) {
        // Update user to admin
        await require('../models/User').findByIdAndUpdate(user.id, {
          role: 'admin',
          isAdmin: true,
        });
      }
      
      console.log('✅ New user registered with email/password:', user.email, isAdmin ? '(ADMIN)' : '');
      return user;
    },
    async onSignInWithSocialProvider({ user, provider }) {
      // Check if email is admin email
      const isAdmin = user.email.toLowerCase() === (process.env.ADMIN_EMAIL || '').toLowerCase();
      
      if (isAdmin) {
        // Update user to admin
        await require('../models/User').findByIdAndUpdate(user.id, {
          role: 'admin',
          isAdmin: true,
        });
      }
      
      console.log(`✅ User signed in with ${provider}:`, user.email, isAdmin ? '(ADMIN)' : '');
      return user;
    },
  },
});

module.exports = { auth };