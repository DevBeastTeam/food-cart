import React, { useState } from 'react';
import { Lock, Mail, Shield, ArrowRight } from 'lucide-react';
import { api, setAuthToken, setCurrentAdminUser } from '../api';

export default function LoginModal({ onLoginSuccess, showToast }) {
  const [email, setEmail] = useState('admin@foodcourt.pk');
  const [password, setPassword] = useState('admin123');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      setLoading(true);
      const res = await api.login(email.trim(), password);
      if (res.token) {
        setAuthToken(res.token);
        setCurrentAdminUser(res.user);
        showToast(`Welcome back, ${res.user.name}!`);
        onLoginSuccess(res.user);
      }
    } catch (err) {
      showToast(err.message || 'Login failed. Check credentials.', 'error');
    } finally {
      setLoading(false);
    }
  };

  const handleQuickDemoFill = () => {
    setEmail('admin@foodcourt.pk');
    setPassword('admin123');
  };

  return (
    <div className="modal-overlay" style={{ background: '#070B14' }}>
      <div 
        className="modal-content" 
        style={{ 
          maxWidth: 440, 
          padding: '36px 32px',
          border: '1px solid rgba(124, 58, 237, 0.3)',
          boxShadow: '0 20px 50px rgba(0, 0, 0, 0.8)' 
        }}
      >
        <div style={{ textAlign: 'center', marginBottom: 28 }}>
          <div style={{
            width: 56,
            height: 56,
            borderRadius: 16,
            background: 'var(--primary-gradient)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            margin: '0 auto 16px',
            boxShadow: '0 8px 24px rgba(124, 58, 237, 0.5)'
          }}>
            <Shield size={28} color="white" />
          </div>
          <h2 style={{ fontSize: 22, fontWeight: 900, color: 'white' }}>FoodCourt Admin Panel</h2>
          <p style={{ fontSize: 13, color: 'var(--text-muted)', marginTop: 4 }}>
            Enter your credentials to manage app data, orders, deals, and menus.
          </p>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label className="form-label">Admin Email Address</label>
            <div style={{ position: 'relative' }}>
              <Mail size={16} style={{ position: 'absolute', left: 12, top: 12, color: 'var(--text-dim)' }} />
              <input 
                type="email" 
                className="form-input" 
                style={{ paddingLeft: 38 }}
                value={email}
                onChange={e => setEmail(e.target.value)}
                placeholder="admin@foodcourt.pk"
                required
              />
            </div>
          </div>

          <div className="form-group" style={{ marginBottom: 24 }}>
            <label className="form-label">Password</label>
            <div style={{ position: 'relative' }}>
              <Lock size={16} style={{ position: 'absolute', left: 12, top: 12, color: 'var(--text-dim)' }} />
              <input 
                type="password" 
                className="form-input" 
                style={{ paddingLeft: 38 }}
                value={password}
                onChange={e => setPassword(e.target.value)}
                placeholder="••••••••"
                required
              />
            </div>
          </div>

          <button 
            type="submit" 
            className="btn btn-primary" 
            style={{ width: '100%', padding: '12px', fontSize: '14px' }}
            disabled={loading}
          >
            {loading ? 'Authenticating...' : 'Sign In to Admin Hub'} <ArrowRight size={16} />
          </button>
        </form>

        <div style={{ marginTop: 24, paddingTop: 20, borderTop: '1px solid var(--border-color)', textAlign: 'center' }}>
          <button 
            type="button"
            className="btn btn-sm btn-secondary" 
            style={{ width: '100%' }}
            onClick={handleQuickDemoFill}
          >
            Fill Demo Credentials (admin@foodcourt.pk)
          </button>
        </div>
      </div>
    </div>
  );
}
