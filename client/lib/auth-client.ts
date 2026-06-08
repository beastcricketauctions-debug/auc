import axios from 'axios';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:5000';
const api = axios.create({
  baseURL: API_URL,
  withCredentials: true,
});

export interface User {
  id: string;
  email: string;
  name: string;
  image?: string;
  role?: string;
  isAdmin?: boolean;
}

export interface AuthResponse {
  user: User;
  session: any;
}

export const authClient = {
  // Email/Password Sign Up
  signUp: async (data: { name: string; email: string; password: string }) => {
    const response = await api.post<AuthResponse>('/api/auth/sign-up/email', data);
    return response.data;
  },

  // Email/Password Sign In
  signIn: async (data: { email: string; password: string }) => {
    const response = await api.post<AuthResponse>('/api/auth/sign-in/email', data);
    return response.data;
  },

  // Google OAuth Sign In
  signInWithGoogle: async () => {
    const redirectUrl = `${API_URL}/api/auth/sign-in/google?redirectURL=${encodeURIComponent(
      window.location.origin + '/auctions'
    )}`;
    window.location.href = redirectUrl;
  },

  // Get Current Session
  getSession: async () => {
    try {
      const response = await api.get('/api/auth/session');
      return response.data;
    } catch (error) {
      return null;
    }
  },

  // Sign Out
  signOut: async () => {
    try {
      await api.post('/api/auth/sign-out');
      localStorage.removeItem('user');
      return true;
    } catch (error) {
      return false;
    }
  },
};

export default authClient;