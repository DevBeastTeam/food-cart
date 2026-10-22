import React, { useState } from 'react';
import { Tag, Plus, Edit2, Trash2, Eye, EyeOff, Calendar, Clock, CheckCircle, AlertCircle } from 'lucide-react';
import { api } from '../api';
import ImageUploadField from '../components/ImageUploadField';

export default function DealsOffersView({ deals, onRefresh, showToast }) {
  const [modalOpen, setModalOpen] = useState(false);
  const [editingDeal, setEditingDeal] = useState(null);
  const [saving, setSaving] = useState(false);

  const [formData, setFormData] = useState({
    code: '',
    title: '',
    discountPercent: 20,
    description: '',
    imageUrl: '',
    category: 'All',
    startDate: new Date().toISOString().split('T')[0],
    endDate: '2026-12-31',
    startTime: '00:00',
    endTime: '23:59',
    minOrder: 500,
    maxDiscount: 1000,
    isVisible: true
  });

  const openAddModal = () => {
    setEditingDeal(null);
    setFormData({
      code: '',
      title: '',
      discountPercent: 25,
      description: '',
      imageUrl: 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=700&q=80',
      category: 'All',
      startDate: new Date().toISOString().split('T')[0],
      endDate: '2026-12-31',
      startTime: '00:00',
      endTime: '23:59',
      minOrder: 500,
      maxDiscount: 1000,
      isVisible: true
    });
    setModalOpen(true);
  };

  const openEditModal = (deal) => {
    setEditingDeal(deal);
    setFormData({
      code: deal.code,
      title: deal.title,
      discountPercent: deal.discountPercent,
      description: deal.description || '',
      imageUrl: deal.imageUrl || '',
      category: deal.category || 'All',
      startDate: deal.startDate || new Date().toISOString().split('T')[0],
      endDate: deal.endDate || '2026-12-31',
      startTime: deal.startTime || '00:00',
      endTime: deal.endTime || '23:59',
      minOrder: deal.minOrder || 0,
      maxDiscount: deal.maxDiscount || 1000,
      isVisible: deal.isVisible !== false
    });
    setModalOpen(true);
  };

  const handleToggleVisibility = async (deal) => {
    try {
      const res = await api.toggleDealVisibility(deal.id, !deal.isVisible);
      showToast(res.message);
      onRefresh();
    } catch (err) {
      showToast(err.message || 'Failed to update deal', 'error');
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to delete this deal?')) return;
    try {
      await api.deleteDeal(id);
      showToast('Deal deleted successfully');
      onRefresh();
    } catch (err) {
      showToast(err.message || 'Failed to delete deal', 'error');
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!formData.code || !formData.title) {
      showToast('Please enter both Deal Title and Promo Code', 'error');
      return;
    }

    try {
      setSaving(true);
      if (editingDeal) {
        await api.updateDeal(editingDeal.id, formData);
        showToast('Deal updated successfully');
      } else {
        await api.createDeal(formData);
        showToast('New deal created successfully');
      }
      setModalOpen(false);
      onRefresh();
    } catch (err) {
      showToast(err.message || 'Error saving deal', 'error');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <div>
          <h2 style={{ fontSize: 22, fontWeight: 800 }}>Deals, Offers & Scheduled Promotions</h2>
          <p style={{ fontSize: 13, color: 'var(--text-muted)' }}>
            Configure deals with automated start/end dates and times. Deals activate and expire automatically per schedule.
          </p>
        </div>
        <button className="btn btn-primary" onClick={openAddModal}>
          <Plus size={16} /> Create Scheduled Deal
        </button>
      </div>

      <div className="panel">
        <div className="table-responsive">
          <table className="data-table">
            <thead>
              <tr>
                <th>Promo Code & Title</th>
                <th>Discount</th>
                <th>Schedule (Start / End Date)</th>
                <th>Daily Hours</th>
                <th>Auto Status</th>
                <th>Visibility</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {(!deals || deals.length === 0) ? (
                <tr>
                  <td colSpan="7" style={{ textAlign: 'center', padding: '30px', color: 'var(--text-muted)' }}>
                    No deals created yet. Click "Create Scheduled Deal" to add one.
                  </td>
                </tr>
              ) : (
                deals.map(deal => (
                  <tr key={deal.id}>
                    <td>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                        {deal.imageUrl && (
                          <img 
                            src={deal.imageUrl} 
                            alt="" 
                            style={{ width: 44, height: 44, borderRadius: 8, objectFit: 'cover' }} 
                          />
                        )}
                        <div>
                          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                            <span style={{ 
                              background: 'rgba(124, 58, 237, 0.25)', 
                              color: '#C4B5FD', 
                              padding: '2px 8px', 
                              borderRadius: 4, 
                              fontFamily: 'monospace', 
                              fontWeight: 800, 
                              fontSize: '12px' 
                            }}>
                              {deal.code}
                            </span>
                            <span style={{ fontWeight: 700 }}>{deal.title}</span>
                          </div>
                          <div style={{ fontSize: '11px', color: 'var(--text-dim)', marginTop: 2 }}>
                            {deal.category} • Min Order: Rs. {deal.minOrder}
                          </div>
                        </div>
                      </div>
                    </td>
                    <td>
                      <span style={{ fontSize: '15px', fontWeight: 800, color: '#34D399' }}>
                        {deal.discountPercent}% OFF
                      </span>
                      <div style={{ fontSize: '11px', color: 'var(--text-dim)' }}>
                        Up to Rs. {deal.maxDiscount}
                      </div>
                    </td>
                    <td>
                      <div style={{ fontSize: '12px', display: 'flex', alignItems: 'center', gap: 4 }}>
                        <Calendar size={13} color="var(--primary-light)" />
                        <span>{deal.startDate}</span>
                      </div>
                      <div style={{ fontSize: '12px', color: 'var(--text-muted)', display: 'flex', alignItems: 'center', gap: 4, marginTop: 2 }}>
                        <span>to {deal.endDate}</span>
                      </div>
                    </td>
                    <td>
                      <div style={{ fontSize: '12px', display: 'flex', alignItems: 'center', gap: 4 }}>
                        <Clock size={13} color="#FBBF24" />
                        <span>{deal.startTime || '00:00'} - {deal.endTime || '23:59'}</span>
                      </div>
                    </td>
                    <td>
                      {deal.status === 'active' ? (
                        <span className="badge badge-active">
                          <CheckCircle size={10} style={{ marginRight: 3 }} /> Active (Live)
                        </span>
                      ) : (
                        <span className="badge badge-expired">
                          <AlertCircle size={10} style={{ marginRight: 3 }} /> Expired / Inactive
                        </span>
                      )}
                    </td>
                    <td>
                      <label className="switch">
                        <input 
                          type="checkbox" 
                          checked={deal.isVisible !== false}
                          onChange={() => handleToggleVisibility(deal)}
                        />
                        <span className="slider"></span>
                      </label>
                    </td>
                    <td>
                      <div style={{ display: 'flex', gap: '6px' }}>
                        <button 
                          className="btn btn-sm btn-secondary"
                          onClick={() => openEditModal(deal)}
                        >
                          <Edit2 size={13} />
                        </button>
                        <button 
                          className="btn btn-sm btn-danger"
                          onClick={() => handleDelete(deal.id)}
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

      {/* Add / Edit Modal */}
      {modalOpen && (
        <div className="modal-overlay" onClick={() => setModalOpen(false)}>
          <div className="modal-content" onClick={e => e.stopPropagation()}>
            <div className="modal-header">
              <div className="modal-title">
                {editingDeal ? 'Edit Scheduled Deal' : 'Create New Scheduled Deal'}
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
                <div className="form-grid-2">
                  <div className="form-group">
                    <label className="form-label">Promo Code *</label>
                    <input 
                      type="text" 
                      className="form-input" 
                      value={formData.code}
                      onChange={e => setFormData({ ...formData, code: e.target.value.toUpperCase() })}
                      placeholder="e.g. SHAHI50"
                      required
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">Discount Percentage (%) *</label>
                    <input 
                      type="number" 
                      className="form-input" 
                      value={formData.discountPercent}
                      onChange={e => setFormData({ ...formData, discountPercent: Number(e.target.value) })}
                      min="1"
                      max="100"
                      required
                    />
                  </div>
                </div>

                <div className="form-group">
                  <label className="form-label">Deal Title *</label>
                  <input 
                    type="text" 
                    className="form-input" 
                    value={formData.title}
                    onChange={e => setFormData({ ...formData, title: e.target.value })}
                    placeholder="e.g. Royal Shahi Feast 40% Off"
                    required
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Description</label>
                  <textarea 
                    className="form-textarea" 
                    rows="2"
                    value={formData.description}
                    onChange={e => setFormData({ ...formData, description: e.target.value })}
                    placeholder="Details about items included, discount caps, terms..."
                  />
                </div>

                <div className="form-grid-2">
                  <div className="form-group">
                    <label className="form-label">Start Date *</label>
                    <input 
                      type="date" 
                      className="form-input" 
                      value={formData.startDate}
                      onChange={e => setFormData({ ...formData, startDate: e.target.value })}
                      required
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">End Date (Expiration) *</label>
                    <input 
                      type="date" 
                      className="form-input" 
                      value={formData.endDate}
                      onChange={e => setFormData({ ...formData, endDate: e.target.value })}
                      required
                    />
                  </div>
                </div>

                <div className="form-grid-2">
                  <div className="form-group">
                    <label className="form-label">Start Time (Daily) *</label>
                    <input 
                      type="time" 
                      className="form-input" 
                      value={formData.startTime}
                      onChange={e => setFormData({ ...formData, startTime: e.target.value })}
                      required
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">End Time (Daily) *</label>
                    <input 
                      type="time" 
                      className="form-input" 
                      value={formData.endTime}
                      onChange={e => setFormData({ ...formData, endTime: e.target.value })}
                      required
                    />
                  </div>
                </div>

                <div className="form-grid-2">
                  <div className="form-group">
                    <label className="form-label">Min Order Required (Rs.)</label>
                    <input 
                      type="number" 
                      className="form-input" 
                      value={formData.minOrder}
                      onChange={e => setFormData({ ...formData, minOrder: Number(e.target.value) })}
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">Max Discount Cap (Rs.)</label>
                    <input 
                      type="number" 
                      className="form-input" 
                      value={formData.maxDiscount}
                      onChange={e => setFormData({ ...formData, maxDiscount: Number(e.target.value) })}
                    />
                  </div>
                </div>

                <ImageUploadField 
                  label="Deal Banner / Voucher Image"
                  value={formData.imageUrl}
                  onChange={url => setFormData({ ...formData, imageUrl: url })}
                  placeholder="https://... or upload deal image directly from PC"
                  category="deals"
                />

                <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginTop: 12 }}>
                  <label className="switch">
                    <input 
                      type="checkbox" 
                      checked={formData.isVisible}
                      onChange={e => setFormData({ ...formData, isVisible: e.target.checked })}
                    />
                    <span className="slider"></span>
                  </label>
                  <span style={{ fontSize: 13, fontWeight: 700 }}>
                    {formData.isVisible ? 'Deal is Visible to Customers' : 'Deal is Hidden'}
                  </span>
                </div>
              </div>

              <div className="modal-footer">
                <button type="button" className="btn btn-secondary" onClick={() => setModalOpen(false)}>
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary" disabled={saving}>
                  {saving ? 'Saving...' : (editingDeal ? 'Update Deal' : 'Create Deal')}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
