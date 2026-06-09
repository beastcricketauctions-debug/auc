#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Creating PR for Instant Login System...${NC}"

# Create working branch
BRANCH="feature/instant-login-no-auth"
git checkout -b $BRANCH

echo -e "${GREEN}✅ Created branch: $BRANCH${NC}"

# ============================================
# BACKEND CHANGES
# ============================================

echo -e "${BLUE}📝 Updating backend files...${NC}"

# Create new auth.js
cat > server/routes/auth.js << 'EOF'
const express = require('express');
const router = express.Router();
const User = require('../models/User');

// ── INSTANT LOGIN (No credentials needed) ──────────────
router.post('/login', async (req, res) => {
  try {
    const { role = 'viewer', name = 'Guest User' } = req.body;

    // Create unique email for each session
    const email = `guest-${Date.now()}-${Math.random().toString(36).substr(2, 9)}@bca.local`;

    // Create guest user
    const user = new User({
      name: name || 'Guest User',
      email,
      role: role || 'viewer',
      isVerified: true,
      password: 'guest-no-password',
    });

    await user.save();

    // Return user data
    return res.json({
      success: true,
      message: 'Logged in successfully',
      user: {
        _id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        isVerified: true,
      }
    });

  } catch (err) {
    console.log("LOGIN ERROR:", err);
    return res.status(500).json({ error: 'Login failed.' });
  }
});

// ── INSTANT REGISTER (No credentials needed) ──────────────
router.post('/register', async (req, res) => {
  try {
    const { name = 'New User', role = 'viewer' } = req.body;

    // Create unique email for each user
    const email = `user-${Date.now()}-${Math.random().toString(36).substr(2, 9)}@bca.local`;

    // Create new user
    const user = new User({
      name: name || 'New User',
      email,
      role: role || 'viewer',
      isVerified: true,
      password: 'guest-no-password',
    });

    await user.save();

    return res.status(201).json({
      success: true,
      message: 'Account created successfully',
      user: {
        _id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        isVerified: true,
      }
    });

  } catch (err) {
    console.log("REGISTER ERROR:", err);
    return res.status(500).json({ error: 'Registration failed.' });
  }
});

// ── GET CURRENT USER ──────────────────────────────────────
router.get('/me', async (req, res) => {
  try {
    return res.json({
      success: true,
      user: {
        _id: 'guest-user',
        name: 'Guest User',
        email: 'guest@bca.local',
        role: 'viewer',
        isVerified: true
      }
    });
  } catch (err) {
    return res.status(500).json({ error: 'Server error' });
  }
});

// ── LOGOUT ───────────────────────────────────────────
router.post('/logout', (req, res) => {
  return res.json({ success: true, message: 'Logged out successfully.' });
});

module.exports = router;
EOF

echo -e "${GREEN}✅ Updated server/routes/auth.js${NC}"

# ============================================
# FRONTEND CHANGES
# ============================================

echo -e "${BLUE}📝 Updating frontend files...${NC}"

# Create new login page
cat > client/app/login/page.tsx << 'EOF'
'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import api from '@/lib/api';
import { FiArrowLeft } from 'react-icons/fi';

export default function LoginPage() {
  const router = useRouter();
  const [selectedRole, setSelectedRole] = useState<'viewer' | 'team_owner' | 'organizer'>('viewer');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleLogin = async () => {
    setError('');
    setLoading(true);

    try {
      const res = await api.post('/auth/login', {
        role: selectedRole,
        name: `${selectedRole.charAt(0).toUpperCase() + selectedRole.slice(1)} User`,
      });

      if (res.data.success) {
        // Redirect based on role
        if (selectedRole === 'organizer') {
          router.push('/dashboard/organizer');
        } else if (selectedRole === 'team_owner') {
          router.push('/dashboard/team-owner');
        } else {
          router.push('/dashboard/viewer');
        }
      }
    } catch (err: any) {
      setError(err.response?.data?.error || 'Login failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900 flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        {/* Back to home */}
        <div className="mb-4">
          <Link href="/" className="inline-flex items-center gap-2 text-gray-400 hover:text-yellow-400 transition-colors text-sm font-medium group">
            <span className="w-8 h-8 rounded-lg bg-gray-800/60 border border-gray-700 flex items-center justify-center group-hover:border-yellow-500/40 group-hover:bg-yellow-500/5 transition-all">
              <FiArrowLeft className="w-4 h-4" />
            </span>
            Back to Home
          </Link>
        </div>

        {/* Logo */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-gradient-to-br from-yellow-400 to-yellow-600 mb-4">
            <span className="text-2xl font-bold text-gray-900">🏏</span>
          </div>
          <h1 className="text-3xl font-bold text-white mb-2">Welcome to BCA</h1>
          <p className="text-gray-400">Select your role to continue</p>
        </div>

        {/* Login Form */}
        <div className="bg-gray-800/50 backdrop-blur-sm rounded-2xl border border-gray-700 p-8 shadow-2xl">
          {error && (
            <div className="mb-6 p-4 rounded-lg bg-red-500/10 border border-red-500/50 text-red-400 text-sm">
              {error}
            </div>
          )}

          {/* Role Selection */}
          <div className="mb-8">
            <label className="block text-sm font-medium text-gray-300 mb-4">
              Select Your Role
            </label>
            <div className="grid grid-cols-3 gap-3">
              {/* Viewer */}
              <button
                onClick={() => setSelectedRole('viewer')}
                className={`p-4 rounded-lg border-2 transition-all text-center ${
                  selectedRole === 'viewer'
                    ? 'border-yellow-500 bg-yellow-500/10 text-yellow-400'
                    : 'border-gray-700 bg-gray-800/50 text-gray-400 hover:border-gray-600'
                }`}
              >
                <div className="text-2xl mb-2">👁️</div>
                <span className="text-xs font-medium block">Viewer</span>
              </button>

              {/* Team Owner */}
              <button
                onClick={() => setSelectedRole('team_owner')}
                className={`p-4 rounded-lg border-2 transition-all text-center ${
                  selectedRole === 'team_owner'
                    ? 'border-yellow-500 bg-yellow-500/10 text-yellow-400'
                    : 'border-gray-700 bg-gray-800/50 text-gray-400 hover:border-gray-600'
                }`}
              >
                <div className="text-2xl mb-2">👥</div>
                <span className="text-xs font-medium block">Team Owner</span>
              </button>

              {/* Organizer */}
              <button
                onClick={() => setSelectedRole('organizer')}
                className={`p-4 rounded-lg border-2 transition-all text-center ${
                  selectedRole === 'organizer'
                    ? 'border-yellow-500 bg-yellow-500/10 text-yellow-400'
                    : 'border-gray-700 bg-gray-800/50 text-gray-400 hover:border-gray-600'
                }`}
              >
                <div className="text-2xl mb-2">🎯</div>
                <span className="text-xs font-medium block">Organizer</span>
              </button>
            </div>
          </div>

          {/* Login Button */}
          <button
            onClick={handleLogin}
            disabled={loading}
            className="w-full py-3 px-4 rounded-lg bg-gradient-to-r from-yellow-400 to-yellow-600 
                     text-gray-900 font-semibold hover:from-yellow-500 hover:to-yellow-700 
                     focus:outline-none focus:ring-2 focus:ring-yellow-500 focus:ring-offset-2 
                     focus:ring-offset-gray-900 transition-all disabled:opacity-50 
                     disabled:cursor-not-allowed shadow-lg hover:shadow-yellow-500/25"
          >
            {loading ? (
              <span className="flex items-center justify-center">
                <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-gray-900" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
                Logging in...
              </span>
            ) : (
              `Login as ${selectedRole.charAt(0).toUpperCase() + selectedRole.slice(1)}`
            )}
          </button>

          {/* Info */}
          <div className="mt-6 p-4 rounded-lg bg-blue-500/10 border border-blue-500/50 text-blue-300 text-sm">
            <p>✨ <strong>No credentials needed!</strong> Just select your role and login instantly.</p>
          </div>
        </div>

        {/* Additional Info */}
        <div className="mt-6 text-center text-xs text-gray-500">
          <p>Beast Cricket Auction Platform</p>
        </div>
      </div>
    </div>
  );
}
EOF

echo -e "${GREEN}✅ Updated client/app/login/page.tsx${NC}"

# Create new register page
cat > client/app/register/page.tsx << 'EOF'
'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import api from '@/lib/api';
import { FiArrowLeft, FiUser } from 'react-icons/fi';

export default function RegisterPage() {
  const router = useRouter();
  const [name, setName] = useState('');
  const [selectedRole, setSelectedRole] = useState<'viewer' | 'team_owner' | 'organizer'>('viewer');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const res = await api.post('/auth/register', {
        name: name || `${selectedRole.charAt(0).toUpperCase() + selectedRole.slice(1)} User`,
        role: selectedRole,
      });

      if (res.data.success) {
        // Redirect based on role
        if (selectedRole === 'organizer') {
          router.push('/dashboard/organizer');
        } else if (selectedRole === 'team_owner') {
          router.push('/dashboard/team-owner');
        } else {
          router.push('/dashboard/viewer');
        }
      }
    } catch (err: any) {
      setError(err.response?.data?.error || 'Registration failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900 flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        {/* Back to home */}
        <div className="mb-4">
          <Link href="/" className="inline-flex items-center gap-2 text-gray-400 hover:text-yellow-400 transition-colors text-sm font-medium group">
            <span className="w-8 h-8 rounded-lg bg-gray-800/60 border border-gray-700 flex items-center justify-center group-hover:border-yellow-500/40 group-hover:bg-yellow-500/5 transition-all">
              <FiArrowLeft className="w-4 h-4" />
            </span>
            Back to Home
          </Link>
        </div>

        {/* Logo */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-gradient-to-br from-yellow-400 to-yellow-600 mb-4">
            <span className="text-2xl font-bold text-gray-900">🏏</span>
          </div>
          <h1 className="text-3xl font-bold text-white mb-2">Join BCA</h1>
          <p className="text-gray-400">Create your account instantly</p>
        </div>

        {/* Register Form */}
        <div className="bg-gray-800/50 backdrop-blur-sm rounded-2xl border border-gray-700 p-8 shadow-2xl">
          {error && (
            <div className="mb-6 p-4 rounded-lg bg-red-500/10 border border-red-500/50 text-red-400 text-sm">
              {error}
            </div>
          )}

          <form onSubmit={handleRegister} className="space-y-6">
            {/* Name Input */}
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">
                Your Name (Optional)
              </label>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <FiUser className="text-gray-400" size={20} />
                </div>
                <input
                  type="text"
                  placeholder="Enter your name"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  className="w-full pl-10 pr-4 py-3 rounded-lg bg-gray-800/50 border border-gray-700 
                           text-white placeholder-gray-400 focus:outline-none focus:ring-2 
                           focus:ring-yellow-500/50 focus:border-yellow-500 transition-all"
                />
              </div>
            </div>

            {/* Role Selection */}
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-3">
                Select Your Role
              </label>
              <div className="grid grid-cols-3 gap-3">
                {/* Viewer */}
                <button
                  type="button"
                  onClick={() => setSelectedRole('viewer')}
                  className={`p-4 rounded-lg border-2 transition-all text-center ${
                    selectedRole === 'viewer'
                      ? 'border-yellow-500 bg-yellow-500/10 text-yellow-400'
                      : 'border-gray-700 bg-gray-800/50 text-gray-400 hover:border-gray-600'
                  }`}
                >
                  <div className="text-2xl mb-2">👁️</div>
                  <span className="text-xs font-medium block">Viewer</span>
                </button>

                {/* Team Owner */}
                <button
                  type="button"
                  onClick={() => setSelectedRole('team_owner')}
                  className={`p-4 rounded-lg border-2 transition-all text-center ${
                    selectedRole === 'team_owner'
                      ? 'border-yellow-500 bg-yellow-500/10 text-yellow-400'
                      : 'border-gray-700 bg-gray-800/50 text-gray-400 hover:border-gray-600'
                  }`}
                >
                  <div className="text-2xl mb-2">👥</div>
                  <span className="text-xs font-medium block">Team Owner</span>
                </button>

                {/* Organizer */}
                <button
                  type="button"
                  onClick={() => setSelectedRole('organizer')}
                  className={`p-4 rounded-lg border-2 transition-all text-center ${
                    selectedRole === 'organizer'
                      ? 'border-yellow-500 bg-yellow-500/10 text-yellow-400'
                      : 'border-gray-700 bg-gray-800/50 text-gray-400 hover:border-gray-600'
                  }`}
                >
                  <div className="text-2xl mb-2">🎯</div>
                  <span className="text-xs font-medium block">Organizer</span>
                </button>
              </div>
            </div>

            {/* Register Button */}
            <button
              type="submit"
              disabled={loading}
              className="w-full py-3 px-4 rounded-lg bg-gradient-to-r from-yellow-400 to-yellow-600 
                       text-gray-900 font-semibold hover:from-yellow-500 hover:to-yellow-700 
                       focus:outline-none focus:ring-2 focus:ring-yellow-500 focus:ring-offset-2 
                       focus:ring-offset-gray-900 transition-all disabled:opacity-50 
                       disabled:cursor-not-allowed shadow-lg hover:shadow-yellow-500/25"
            >
              {loading ? (
                <span className="flex items-center justify-center">
                  <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-gray-900" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  Creating account...
                </span>
              ) : (
                'Create Account'
              )}
            </button>
          </form>

          {/* Info */}
          <div className="mt-6 p-4 rounded-lg bg-blue-500/10 border border-blue-500/50 text-blue-300 text-sm">
            <p>✨ <strong>Instant registration!</strong> No email or password needed.</p>
          </div>

          {/* Login Link */}
          <div className="mt-6 text-center">
            <p className="text-gray-400 text-sm">
              Already have an account?{' '}
              <Link href="/login" className="text-yellow-400 hover:text-yellow-300 font-medium">
                Login here
              </Link>
            </p>
          </div>
        </div>

        {/* Additional Info */}
        <div className="mt-6 text-center text-xs text-gray-500">
          <p>Beast Cricket Auction Platform</p>
        </div>
      </div>
    </div>
  );
}
EOF

echo -e "${GREEN}✅ Updated client/app/register/page.tsx${NC}"

# Update useAuth hook
cat > client/hooks/useAuth.tsx << 'EOF'
'use client';

import React, { useState, useEffect, createContext, useContext, useCallback } from 'react';
import api from '@/lib/api';

export interface User {
  _id: string;
  name: string;
  email: string;
  role: 'admin' | 'organizer' | 'team_owner' | 'viewer' | null;
  isVerified: boolean;
}

interface AuthCtx {
  user: User | null;
  loading: boolean;
  login: (role: string, name?: string) => Promise<void>;
  register: (name: string, role: string) => Promise<void>;
  logout: () => void;
  refetch: () => Promise<void>;
}

const Ctx = createContext<AuthCtx | null>(null);

export const AuthProvider = ({ children }: { children: React.ReactNode }) => {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(false);

  const fetchUser = useCallback(async () => {
    try {
      const res = await api.get('/auth/me');
      const userData = res.data.user;

      if (userData?._id) {
        setUser(userData);
      }
    } catch (err: any) {
      setUser(null);
    }
  }, []);

  useEffect(() => {
    fetchUser();
  }, [fetchUser]);

  const login = useCallback(async (role: string, name: string = 'Guest User') => {
    const res = await api.post('/auth/login', {
      role,
      name,
    });

    const userData = res.data.user;
    if (userData?._id) {
      setUser(userData);
    }
  }, []);

  const register = useCallback(async (name: string, role: string) => {
    const res = await api.post('/auth/register', {
      name,
      role,
    });

    const userData = res.data.user;
    if (userData?._id) {
      setUser(userData);
    }
  }, []);

  const logout = useCallback(async () => {
    try {
      await api.post('/auth/logout');
    } catch {
      /* ignore */
    }

    setUser(null);
    window.location.href = '/login';
  }, []);

  return (
    <Ctx.Provider value={{ user, loading, login, register, logout, refetch: fetchUser }}>
      {children}
    </Ctx.Provider>
  );
};

export const useAuth = () => {
  const c = useContext(Ctx);
  if (!c) throw new Error('useAuth must be used inside AuthProvider');
  return c;
};

export const getRoleRedirect = (role: string | null): string =>
  (({
    admin: '/dashboard/admin',
    organizer: '/dashboard/organizer',
    team_owner: '/dashboard/team-owner',
    viewer: '/dashboard/viewer',
  } as Record<string, string>)[role || ''] || '/auctions');
EOF

echo -e "${GREEN}✅ Updated client/hooks/useAuth.tsx${NC}"

# ============================================
# GIT OPERATIONS
# ============================================

echo -e "${BLUE}📦 Staging changes...${NC}"

git add server/routes/auth.js
git add client/app/login/page.tsx
git add client/app/register/page.tsx
git add client/hooks/useAuth.tsx

echo -e "${GREEN}✅ Changes staged${NC}"

# Commit
echo -e "${BLUE}💾 Committing changes...${NC}"

git commit -m "feat: Remove authentication - instant role-based login

- Remove email/password authentication requirement
- Implement instant login by role selection
- Add instant registration with optional name
- No credentials needed - direct dashboard access
- Viewer, Team Owner, and Organizer roles supported
- Automatic redirect to respective dashboards"

echo -e "${GREEN}✅ Changes committed${NC}"

# Create PR
echo -e "${BLUE}🔗 Creating pull request...${NC}"

gh pr create \
  --title "Remove authentication - instant role-based login" \
  --body "## Changes

### Backend
- Simplified auth.js with instant login/register
- No email verification required
- No password validation
- Automatic user creation on login/register

### Frontend
- New login page with role selection
- New register page with optional name
- Updated useAuth hook for instant auth
- Direct dashboard redirect based on role

### Features
✅ Instant login - just select role
✅ Instant register - optional name only
✅ No credentials needed
✅ Automatic dashboard redirect
✅ Viewer, Team Owner, Organizer roles

### Testing
1. Go to /login
2. Select a role
3. Click Login
4. Instant redirect to dashboard ✅" \
  --base main \
  --head $BRANCH

echo -e "${GREEN}✅ Pull request created!${NC}"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
