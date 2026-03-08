const API_BASE_URL = 'http://localhost:5000/api';

interface ApiResponse<T> {
  success: boolean;
  message: string;
  data?: T;
  errors?: any;
}

export interface RegisterData {
  name: string;
  email: string;
  role: 'parent' | 'teacher' | 'student';
  password: string;
  disabilityType?: string;
  grade?: number;
  age?: number;
}

export interface LoginData {
  email: string;
  password: string;
}

export interface User {
  id: string;
  name: string;
  email: string;
  role: 'parent' | 'teacher' | 'student';
  disabilityType?: string;
  student?: {
    grade?: number;
    age?: number;
  };
}

export interface AuthResponse {
  token: string;
  user: User;
}

class ApiService {
  private async request<T>(
    endpoint: string,
    method: string = 'GET',
    data?: any
  ): Promise<ApiResponse<T>> {
    const url = `${API_BASE_URL}${endpoint}`;
    const token = localStorage.getItem('token');
    
    const headers: HeadersInit = {
      'Content-Type': 'application/json',
    };
    
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    const config: RequestInit = {
      method,
      headers,
    };

    if (data) {
      config.body = JSON.stringify(data);
    }

    try {
      const response = await fetch(url, config);
      const result = await response.json();
      
      if (!response.ok) {
        throw new Error(result.message || 'Request failed');
      }
      
      return result;
    } catch (error) {
      console.error('API Error:', error);
      throw error;
    }
  }

  // Auth endpoints
  async register(data: RegisterData): Promise<ApiResponse<AuthResponse>> {
    return this.request<AuthResponse>('/auth/register', 'POST', data);
  }

  async login(data: LoginData): Promise<ApiResponse<AuthResponse>> {
    return this.request<AuthResponse>('/auth/login', 'POST', data);
  }

  async getMe(): Promise<ApiResponse<User>> {
    return this.request<User>('/auth/me', 'GET');
  }

  // Token management
  static setToken(token: string): void {
    localStorage.setItem('token', token);
  }

  static getToken(): string | null {
    return localStorage.getItem('token');
  }

  static removeToken(): void {
    localStorage.removeItem('token');
  }

  static isAuthenticated(): boolean {
    return !!this.getToken();
  }
}

export const api = new ApiService();