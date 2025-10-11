export interface UserDetails {
    id: string;
    name: string;
    email: string;
    role: string;
    student?: {
        grade?: number;
        age?: number;
    }
}

export interface AuthResponse {
    token: string;
    user: UserDetails;
}