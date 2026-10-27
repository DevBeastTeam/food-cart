import React, { useState } from 'react';
import { Users, Plus, Edit2, Trash2, Shield, Bike, User, DollarSign, Ban, CheckCircle } from 'lucide-react';
import { api } from '../api';
import CustomDropdown from '../components/CustomDropdown';

export default function UsersView({ users, onRefresh, showToast }) {
  const [roleFilter, setRoleFilter] = useState('All');
  const [modalOpen, setModalOpen] = useState(false);
  const [walletModalUser, setWalletModalUser] = useState(null);
  const [walletAmount, setWalletAmount] = useState(1000);
  const [editingUser, setEditingUser] = useState(null);
  const [saving, setSaving] = useState(false);

  const [formData, setFormData] = useState({
    name: '',
    email: '',
    phone: '',
    city: 'Lahore',
    role: 'client',
    membershipTier: 'FoodCourt Member ⭐',
    walletBalance: 1000
  });

  const filteredUsers = (users || []).filter(u => {
    if (roleFilter === 'All') return true;
    return u.role === roleFilter;
  });

  const openAddModal = () => {
    setEditingUser(null);
    setFormData({
      name: '',
      email: '',
      phone: '+92 300 0000000',
      city: 'Lahore',
      role: 'client',
      membershipTier: 'FoodCourt Member ⭐',
      walletBalance: 1000
    });
    setModalOpen(true);
  };

  const openEditModal = (u) => {
    setEditingUser(u);
    setFormData({
      name: u.name,
      email: u.email,
      phone: u.phone || '',
      city: u.city || 'Lahore',
      role: u.role || 'client',
      membershipTier: u.membershipTier || 'FoodCourt Member ⭐',
      walletBalance: u.walletBalance || 0
    });
    setModalOpen(true);
  };

  const handleToggleStatus = async (user) => {
    try {
      const res = await api.toggleUserStatus(user.id);
      showToast(res.message);
      onRefresh();
    } catch (err) {
      showToast(err.message || 'Failed to update user status', 'error');
    }
  };

  const handleAddFunds = async (e) => {
    e.preventDefault();
    if (!walletModalUser) return;
    try {
      const res = await api.adjustUserWallet(walletModalUser.id, walletAmount);
      showToast(res.message);
      setWalletModalUser(null);
      onRefresh();
    } catch (err) {
      showToast(err.message || 'Failed to adjust wallet', 'error');
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to delete this user?')) return;
    try {
      await api.deleteUser(id);
      showToast('User removed');
      onRefresh();
    } catch (err) {
      showToast(err.message || 'Failed to delete user', 'error');
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!formData.name || !formData.email) {
      showToast('Name and email are required', 'error');
      return;
    }

    try {
      setSaving(true);
      if (editingUser) {
        await api.updateUser(editingUser.id, formData);
        showToast('User updated successfully');
      } else {
        await api.createUser(formData);
        showToast('New user registered');
      }
      setModalOpen(false);
      onRefresh();
    } catch (err) {
      showToast(err.message || 'Error saving user', 'error');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <div>
          <h2 style={{ fontSize: 22, fontWeight: 800 }}>User Management & Permissions</h2>
          <p style={{ fontSize: 13, color: 'var(--text-muted)' }}>
            Manage registered customers, delivery riders, and admin access with wallet credit operations.
          </p>
        </div>
        <button className="btn btn-primary" onClick={openAddModal}>
          <Plus size={16} /> Register New User
        </button>
      </div>

      {/* Role Filter Tabs */}
      <div className="panel" style={{ padding: '16px 20px', marginBottom: 20 }}>
        <div style={{ display: 'flex', gap: 10 }}>
          {[
            { id: 'All', label: 'All Users', count: users?.length || 0 },
            { id: 'client', label: 'Customers', count: (users || []).filter(u => u.role === 'client').length },
            { id: 'rider', label: 'Delivery Riders', count: (users || []).filter(u => u.role === 'rider').length },
            { id: 'admin', label: 'Administrators', count: (users || []).filter(u => u.role === 'admin').length }
          ].map(tab => (
            <button
              key={tab.id}
              className={`btn btn-sm ${roleFilter === tab.id ? 'btn-primary' : 'btn-secondary'}`}
              onClick={() => setRoleFilter(tab.id)}
              style={{ borderRadius: 20 }}
            >
              {tab.label} ({tab.count})
            </button>
          ))}
        </div>
      </div>

      <div className="panel">
        <div className="table-responsive">
          <table className="data-table">
            <thead>
              <tr>
                <th>User & Contact</th>
                <th>Role & Permissions</th>
                <th>City / Territory</th>
                <th>Wallet Balance</th>
                <th>Account Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredUsers.length === 0 ? (
                <tr>
                  <td colSpan="6" style={{ textAlign: 'center', padding: '30px', color: 'var(--text-muted)' }}>
                    No users found for this role.
                  </td>
                </tr>
              ) : (
                filteredUsers.map(u => (
                  <tr key={u.id}>
                    <td>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                        <div style={{
                          width: 38,
                          height: 38,
                          borderRadius: '50%',
                          background: u.role === 'admin' ? 'linear-gradient(135deg, #F59E0B, #D97706)' : 
                                      u.role === 'rider' ? 'linear-gradient(135deg, #3B82F6, #1D4ED8)' :
                                      'var(--primary-gradient)',
                          color: 'white',
                          fontWeight: 800,
                          fontSize: 13,
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center'
                        }}>
                          {u.name[0]?.toUpperCase() || 'U'}
                        </div>
                        <div>
                          <div style={{ fontWeight: 800, color: '#FFFFFF' }}>{u.name}</div>
                          <div style={{ fontSize: '11px', color: 'var(--text-dim)' }}>
                            {u.email} • {u.phone}
                          </div>
                        </div>
                      </div>
                    </td>
                    <td>
                      <span style={{
                        display: 'inline-flex',
                        alignItems: 'center',
                        gap: 4,
                        fontSize: '11px',
                        fontWeight: 800,
                        padding: '3px 8px',
                        borderRadius: 6,
                        background: u.role === 'admin' ? 'rgba(245, 158, 11, 0.15)' :
                                    u.role === 'rider' ? 'rgba(59, 130, 246, 0.15)' :
                                    'rgba(124, 58, 237, 0.15)',
                        color: u.role === 'admin' ? '#FBBF24' :
                               u.role === 'rider' ? '#60A5FA' :
                               '#C4B5FD'
                      }}>
                        {u.role === 'admin' ? <Shield size={11} /> : 
                         u.role === 'rider' ? <Bike size={11} /> : <User size={11} />}
                        {u.role?.toUpperCase()}
                      </span>
                      <div style={{ fontSize: '11px', color: 'var(--text-dim)', marginTop: 2 }}>
                        {u.membershipTier}
                      </div>
                    </td>
                    <td style={{ fontSize: '12px' }}>
                      {u.city || 'Lahore'}
                    </td>
                    <td>
                      <span style={{ fontWeight: 800, color: '#34D399', fontSize: 13 }}>
                        Rs. {(u.walletBalance || 0).toLocaleString()}
                      </span>
                      <button 
                        style={{
                          background: 'transparent',
                          border: 'none',
                          color: '#A78BFA',
                          fontSize: '11px',
                          display: 'block',
                          cursor: 'pointer',
                          fontWeight: 700,
                          marginTop: 2
                        }}
                        onClick={() => {
                          setWalletModalUser(u);
                          setWalletAmount(1000);
                        }}
                      >
                        + Credit Funds
                      </button>
                    </td>
                    <td>
                      <span className={`badge ${u.status === 'active' ? 'badge-active' : 'badge-cancelled'}`}>
                        {u.status === 'active' ? 'Active' : 'Suspended'}
                      </span>
                    </td>
                    <td>
                      <div style={{ display: 'flex', gap: '6px' }}>
                        <button 
                          className="btn btn-sm btn-secondary"
                          onClick={() => openEditModal(u)}
                          title="Edit user"
                        >
                          <Edit2 size={13} />
                        </button>
                        <button 
                          className="btn btn-sm btn-secondary"
                          style={{ color: u.status === 'active' ? '#EF4444' : '#10B981' }}
                          onClick={() => handleToggleStatus(u)}
                          title={u.status === 'active' ? 'Block user' : 'Unblock user'}
                        >
                          {u.status === 'active' ? <Ban size={13} /> : <CheckCircle size={13} />}
                        </button>
                        <button 
                          className="btn btn-sm btn-danger"
                          onClick={() => handleDelete(u.id)}
                          title="Delete user"
                        >
                          <Trash2 size={13} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Credit Wallet Modal */}
      {walletModalUser && (
        <div className="modal-overlay" onClick={() => setWalletModalUser(null)}>
          <div className="modal-content" onClick={e => e.stopPropagation()}>
            <div className="modal-header">
              <div className="modal-title">
                Credit Wallet for {walletModalUser.name}
              </div>
              <button 
                style={{ background: 'transparent', border: 'none', color: 'var(--text-muted)', cursor: 'pointer', fontSize: 18 }}
                onClick={() => setWalletModalUser(null)}
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleAddFunds}>
              <div className="modal-body">
                <p style={{ fontSize: 13, color: 'var(--text-muted)', marginBottom: 16 }}>
                  Current Wallet Balance: <strong>Rs. {walletModalUser.walletBalance || 0}</strong>
                </p>

                <div className="form-group">
                  <label className="form-label">Amount to Add (Rs.)</label>
                  <input 
                    type="number" 
                    className="form-input" 
                    value={walletAmount}
                    onChange={e => setWalletAmount(Number(e.target.value))}
                    min="100"
                    step="100"
                    required
                  />
                </div>
              </div>

              <div className="modal-footer">
                <button type="button" className="btn btn-secondary" onClick={() => setWalletModalUser(null)}>
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary">
                  Confirm Credit
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Add / Edit User Modal */}
      {modalOpen && (
        <div className="modal-overlay" onClick={() => setModalOpen(false)}>
          <div className="modal-content" onClick={e => e.stopPropagation()}>
            <div className="modal-header">
              <div className="modal-title">
                {editingUser ? 'Edit User Profile & Role' : 'Register New User'}
              </div>
              <button 
                style={{ background: 'transparent', border: 'none', color: 'var(--text-muted)', cursor: 'pointer', fontSize: 18 }}
                onClick={() => setModalOpen(false)}
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleSubmit}>
              <div className="modal-body">
                <div className="form-group">
                  <label className="form-label">Full Name *</label>
                  <input 
                    type="text" 
                    className="form-input" 
                    value={formData.name}
                    onChange={e => setFormData({ ...formData, name: e.target.value })}
                    placeholder="e.g. Hassan Raza"
                    required
                  />
                </div>

                <div className="form-grid-2">
                  <div className="form-group">
                    <label className="form-label">Email Address *</label>
                    <input 
                      type="email" 
                      className="form-input" 
                      value={formData.email}
                      onChange={e => setFormData({ ...formData, email: e.target.value })}
                      placeholder="user@foodcourt.pk"
                      required
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">Phone Number</label>
                    <input 
                      type="text" 
                      className="form-input" 
                      value={formData.phone}
                      onChange={e => setFormData({ ...formData, phone: e.target.value })}
                      placeholder="+92 300 1234567"
                    />
                  </div>
                </div>

                <div className="form-grid-2">
                  <div className="form-group">
                    <label className="form-label">Role & Permission</label>
                    <CustomDropdown
                      value={formData.role}
                      onChange={val => setFormData({ ...formData, role: val })}
                      options={[
                        { value: 'client', label: 'Customer (Client App)' },
                        { value: 'rider', label: 'Delivery Rider (Rider Dashboard)' },
                        { value: 'admin', label: 'Administrator (Full Admin Panel)' },
                      ]}
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">City</label>
                    <input 
                      type="text" 
                      className="form-input" 
                      value={formData.city}
                      onChange={e => setFormData({ ...formData, city: e.target.value })}
                      placeholder="Lahore"
                    />
                  </div>
                </div>

                <div className="form-grid-2">
                  <div className="form-group">
                    <label className="form-label">Membership Tier</label>
                    <input 
                      type="text" 
                      className="form-input" 
                      value={formData.membershipTier}
                      onChange={e => setFormData({ ...formData, membershipTier: e.target.value })}
                      placeholder="FoodCourt Member ⭐"
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">Initial Wallet Balance (Rs.)</label>
                    <input 
                      type="number" 
                      className="form-input" 
                      value={formData.walletBalance}
                      onChange={e => setFormData({ ...formData, walletBalance: Number(e.target.value) })}
                    />
                  </div>
                </div>
              </div>

              <div className="modal-footer">
                <button type="button" className="btn btn-secondary" onClick={() => setModalOpen(false)}>
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary" disabled={saving}>
                  {saving ? 'Saving...' : (editingUser ? 'Update User' : 'Register User')}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
