import jwt, { SignOptions, Secret } from 'jsonwebtoken';


export const signToken = (id: string, role: string) => {
  const secret = process.env.JWT_SECRET;
  if (!secret) {
    throw new Error('JWT_SECRET is not set');
  }
  const secretTyped: Secret = secret as Secret;
  const expiresIn = process.env.JWT_EXPIRES_IN ?? '7d';
  const options: SignOptions = { expiresIn: expiresIn as unknown as SignOptions['expiresIn'] };
  return jwt.sign({ sub: id, role }, secretTyped, options);
}