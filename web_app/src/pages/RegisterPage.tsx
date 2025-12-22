import React, { useState } from 'react';

const RegisterPage: React.FC = () => {
    const [username, setUsername] = useState('');
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        console.log('Registered:', { username, email, password });
    };

    return (
        <div style={{ display: 'flex', minHeight: '100vh', backgroundColor: '#f5f5f5' }}>
            {/* Left Side - Decorative */}
            <div style={{
                flex: 1,
                background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                padding: '2rem',
                color: '#fff'
            }}>
                <div style={{ textAlign: 'center' }}>
                    <img 
                        src="https://via.placeholder.com/300" 
                        alt="Register" 
                        style={{ width: '100%', maxWidth: '300px', borderRadius: '12px', marginBottom: '2rem' }}
                    />
                    <h2 style={{ fontSize: '2rem', marginBottom: '1rem' }}>Welcome!</h2>
                    <p style={{ fontSize: '1rem', opacity: 0.9 }}>Join our community and start your learning journey today.</p>
                </div>
            </div>

            {/* Right Side - Register Form */}
            <div style={{
                flex: 1,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                padding: '2rem'
            }}>
                <div style={{ width: '100%', maxWidth: '400px' }}>
                    <h1 style={{ fontSize: '2.5rem', color: '#333', marginBottom: '1rem', textAlign: 'center' }}>Register</h1>
                    <p style={{ color: '#666', marginBottom: '2rem', textAlign: 'center' }}>Create your account to get started</p>

                    <form onSubmit={handleSubmit}>
                        <div style={{ marginBottom: '1.5rem' }}>
                            <label style={{ display: 'block', marginBottom: '0.5rem', color: '#333', fontWeight: '500' }}>Username:</label>
                            <input 
                                type="text" 
                                value={username} 
                                onChange={(e) => setUsername(e.target.value)} 
                                required 
                                style={{ width: '100%', padding: '0.75rem', borderRadius: '6px', border: '1px solid #ddd', boxSizing: 'border-box' }} 
                            />
                        </div>
                        <div style={{ marginBottom: '1.5rem' }}>
                            <label style={{ display: 'block', marginBottom: '0.5rem', color: '#333', fontWeight: '500' }}>Email:</label>
                            <input 
                                type="email" 
                                value={email} 
                                onChange={(e) => setEmail(e.target.value)} 
                                required 
                                style={{ width: '100%', padding: '0.75rem', borderRadius: '6px', border: '1px solid #ddd', boxSizing: 'border-box' }} 
                            />
                        </div>
                        <div style={{ marginBottom: '2rem' }}>
                            <label style={{ display: 'block', marginBottom: '0.5rem', color: '#333', fontWeight: '500' }}>Password:</label>
                            <input 
                                type="password" 
                                value={password} 
                                onChange={(e) => setPassword(e.target.value)} 
                                required 
                                style={{ width: '100%', padding: '0.75rem', borderRadius: '6px', border: '1px solid #ddd', boxSizing: 'border-box' }} 
                            />
                        </div>
                        <button type="submit" style={{ 
                            width: '100%', 
                            padding: '0.75rem', 
                            backgroundColor: '#667eea', 
                            color: '#fff', 
                            border: 'none', 
                            borderRadius: '6px', 
                            cursor: 'pointer',
                            fontSize: '1rem',
                            fontWeight: '600',
                            transition: 'background-color 0.3s'
                        }}>
                            Register
                        </button>
                    </form>
                </div>
            </div>
        </div>
    );
};

export default RegisterPage;