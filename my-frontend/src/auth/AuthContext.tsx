// contexts/AuthContext.tsx
import React, { createContext, useState, useContext, useEffect } from 'react';

// Types based on your backend response
interface StudentInfo {
    grade?: number;
    age?: number;
}

interface User {
    id: string;
    name: string;
    email: string;
    role: string;
    disabilityType?: string;
    student?: StudentInfo;
}

interface AuthResponse {
    token: string;
    user: User;
}

interface AuthContextType {
    user: User | null;
    loading: boolean;
    error: string | null;
    login: (email: string, password: string) => Promise<void>;
    register: (userData: RegisterData) => Promise<void>;
    logout: () => void;
    fetchUserProfile: () => Promise<void>;
}

interface RegisterData {
    name: string;
    email: string;
    password: string;
    role?: string;
    disabilityType?: string;
    grade?: number;
    age?: number;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const useAuth = () => {
    const context = useContext(AuthContext);
    if (!context) {
        throw new Error('useAuth must be used within an AuthProvider');
    }
    return context;
};

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
    const [user, setUser] = useState<User | null>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);

    const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:5000/api';

    // Fetch user profile using the token
    const fetchUserProfile = async () => {
        try {
            const token = localStorage.getItem('token');

            if (!token) {
                setLoading(false);
                return;
            }

            const response = await fetch(`${API_URL}/auth/me`, {
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'Content-Type': 'application/json'
                }
            });

            const data = await response.json();

            if (!response.ok) {
                throw new Error(data.message || 'Failed to fetch user profile');
            }

            // Assuming your successResponse format
            setUser(data.data);
        } catch (err) {
            console.error('Fetch profile error:', err);
            localStorage.removeItem('token');
        } finally {
            setLoading(false);
        }
    };

    // Login function
    const login = async (email: string, password: string) => {
        try {
            setLoading(true);
            setError(null);

            const response = await fetch(`${API_URL}/auth/login`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ email, password }),
            });

            const data = await response.json();

            if (!response.ok) {
                throw new Error(data.message || 'Login failed');
            }

            // Store token and user data
            const authData: AuthResponse = data.data;
            localStorage.setItem('token', authData.token);
            setUser(authData.user);

        } catch (err) {
            setError(err instanceof Error ? err.message : 'Login failed');
            throw err;
        } finally {
            setLoading(false);
        }
    };

    // Register function
    const register = async (userData: RegisterData) => {
        try {
            setLoading(true);
            setError(null);

            const response = await fetch(`${API_URL}/auth/register`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(userData),
            });

            const data = await response.json();

            if (!response.ok) {
                throw new Error(data.message || 'Registration failed');
            }

            // Store token and user data
            const authData: AuthResponse = data.data;
            localStorage.setItem('token', authData.token);
            setUser(authData.user);

        } catch (err) {
            setError(err instanceof Error ? err.message : 'Registration failed');
            throw err;
        } finally {
            setLoading(false);
        }
    };

    // Logout function
    const logout = () => {
        localStorage.removeItem('token');
        setUser(null);
    };

    // Check for existing session on mount
    useEffect(() => {
        fetchUserProfile();
    }, []);

    return (
        <AuthContext.Provider value={{
            user,
            loading,
            error,
            login,
            register,
            logout,
            fetchUserProfile
        }}>
            {children}
        </AuthContext.Provider>
    );
};