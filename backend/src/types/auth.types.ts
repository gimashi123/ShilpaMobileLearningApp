export interface UserDetails {
  id: string;
  name: string;
  email: string;
  role: string;
  student?: {
    grade?: number;
    age?: number;
  };
  // 👇 NEW – what Flutter will read
  disabilityType: string;
  signGameXp?: number;
}

export interface AuthResponse {
  token: string;
  user: UserDetails;
}
