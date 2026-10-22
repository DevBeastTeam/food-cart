import React, { useState } from 'react';
import { Soup, Plus, Edit2, Trash2, Star, Eye, EyeOff, ShieldCheck } from 'lucide-react';
import { api } from '../api';
import ImageUploadField from '../components/ImageUploadField';

export default function DaigDishesView({ daigDishes, onRefresh, showToast }) {
  const [modalOpen, setModalOpen] = useState(false);
  const [editingDaig, setEditingDaig] = useState(null);
  const [saving, setSaving] = useState(false);

  const [formData, setFormData] = useState({
    name: '',
    urduName: '',
    description: '',
    category: 'Biryani & Pulao',
    fullDaigPrice: 12000,
    halfDaigPrice: 6500,
    fullDaigWeight: '12 KG (Serves 35-40 Persons)',
    halfDaigWeight: '6 KG (Serves 18-20 Persons)',
    imageUrl: '',
    rating: 4.9,
    badge: '👑 Royal Wedding Deg',
    deliveryNotice: 'Order 3-4 hours in advance for fresh dum cooking',
    isVisible: true,
    includes: ['Atta-sealed Hot Daig', 'Spicy Zeera Raita Tub (2 Litre)', 'Fresh Salad']
  });

  const openAddModal = () => {
    setEditingDaig(null);
    setFormData({
      name: '',
      urduName: '',
      description: 'Slow-simmered on coal dum with pure desi ghee and aromatic royal spices.',
      category: 'Biryani & Pulao',
      fullDaigPrice: 12000,
      halfDaigPrice: 6500,
      fullDaigWeight: '12 KG (Serves 35-40 Persons)',
      halfDaigWeight: '6 KG (Serves 18-20 Persons)',
      imageUrl: 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=700&q=80',
      rating: 4.9,
      badge: '⭐ Dawat Special',
      deliveryNotice: 'Order 3-4 hours in advance for fresh dum cooking',
      isVisible: true,
      includes: ['Atta-sealed Hot Daig', 'Spicy Zeera Raita Tub (2 Litre)', 'Fresh Salad']
    });
    setModalOpen(true);
  };

  const openEditModal = (d) => {
    setEditingDaig(d);
    setFormData({
      name: d.name,
      urduName: d.urduName || '',
      description: d.description || '',
      category: d.category || 'Biryani & Pulao',
      fullDaigPrice: d.fullDaigPrice,
      halfDaigPrice: d.halfDaigPrice,
      fullDaigWeight: d.fullDaigWeight || '12 KG (Serves 35-40 Persons)',
      halfDaigWeight: d.halfDaigWeight || '6 KG (Serves 18-20 Persons)',
      imageUrl: d.imageUrl || '',
      rating: d.rating || 4.9,
      badge: d.badge || '',
      deliveryNotice: d.deliveryNotice || 'Order 3-4 hours in advance for fresh dum cooking',
      isVisible: d.isVisible !== false,
      includes: d.includes || []
    });
    setModalOpen(true);
  };

  const handleToggleVisibility = async (d) => {
    try {
      const res = await api.toggleDaigVisibility(d.id, !d.isVisible);
      showToast(res.message);
      onRefresh();
    } catch (err) {
      showToast(err.message || 'Failed to toggle visibility', 'error');
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Delete this Daig item?')) return;
    try {
      await api.deleteDaigItem(id);
      showToast('Daig item removed');
      onRefresh();
    } catch (err) {
      showToast(err.message || 'Failed to delete', 'error');
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!formData.name || !formData.fullDaigPrice || !formData.halfDaigPrice) {
      showToast('Please fill in Daig title and pricing', 'error');
      return;
    }

    try {
      setSaving(true);
      if (editingDaig) {
        await api.updateDaigItem(editingDaig.id, formData);
        showToast('Daig updated successfully');
      } else {
        await api.createDaigItem(formData);
        showToast('Daig item added');
      }
      setModalOpen(false);
      onRefresh();
    } catch (err) {
      showToast(err.message || 'Error saving Daig', 'error');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <div>
          <h2 style={{ fontSize: 22, fontWeight: 800 }}>Pakwan Center & Shahi Daig Catering</h2>
          <p style={{ fontSize: 13, color: 'var(--text-muted)' }}>
            Manage whole cauldrons (Full & Half Daigs) for weddings, family dawats, and religious niyaz.
          </p>
        </div>
        <button className="btn btn-primary" onClick={openAddModal}>
          <Plus size={16} /> Add Daig Item
        </button>
      </div>

      <div className="panel">
        <div className="table-responsive">
          <table className="data-table">
            <thead>
              <tr>
                <th>Daig Dish (English & Urdu)</th>
                <th>Category</th>
                <th>Full Daig (12 KG)</th>
                <th>Half Daig (6 KG)</th>
                <th>Advance Notice</th>
                <th>Visibility</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {(!daigDishes || daigDishes.length === 0) ? (
                <tr>
                  <td colSpan="7" style={{ textAlign: 'center', padding: '30px', color: 'var(--text-muted)' }}>
                    No Daig items found.
                  </td>
                </tr>
              ) : (
                daigDishes.map(d => (
                  <tr key={d.id}>
                    <td>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                        <img 
                          src={d.imageUrl} 
                          alt="" 
                          style={{ width: 48, height: 48, borderRadius: 10, objectFit: 'cover' }} 
                        />
                        <div>
                          <div style={{ fontWeight: 800, color: '#FFFFFF', fontSize: '13.5px' }}>
                            {d.name}
                          </div>
                          {d.urduName && (
                            <div style={{ fontSize: '13px', color: '#FBBF24', direction: 'rtl', textAlign: 'left', fontWeight: 600 }}>
                              {d.urduName}
                            </div>
                          )}
                          <div style={{ fontSize: '11px', color: 'var(--text-dim)', marginTop: 2 }}>
                            {d.badge}
                          </div>
                        </div>
                      </div>
                    </td>
                    <td>
                      <span style={{ 
                        fontSize: '11.5px', 
                        fontWeight: 700, 
                        background: 'rgba(124, 58, 237, 0.15)', 
                        color: '#C4B5FD', 
                        padding: '3px 8px', 
                        borderRadius: 6 
                      }}>
                        {d.category}
                      </span>
                    </td>
                    <td>
                      <div style={{ fontWeight: 800, color: '#34D399', fontSize: '14px' }}>
                        Rs. {d.fullDaigPrice?.toLocaleString()}
                      </div>
                      <div style={{ fontSize: '11px', color: 'var(--text-dim)' }}>
                        Serves 35-40
                      </div>
                    </td>
                    <td>
                      <div style={{ fontWeight: 800, color: '#34D399', fontSize: '14px' }}>
                        Rs. {d.halfDaigPrice?.toLocaleString()}
                      </div>
                      <div style={{ fontSize: '11px', color: 'var(--text-dim)' }}>
                        Serves 18-20
                      </div>
                    </td>
                    <td style={{ fontSize: '12px', color: 'var(--text-muted)', maxWidth: 160 }}>
                      {d.deliveryNotice}
                    </td>
                    <td>
                      <label className="switch">
                        <input 
                          type="checkbox" 
                          checked={d.isVisible !== false}
                          onChange={() => handleToggleVisibility(d)}
                        />
                        <span className="slider"></span>
                      </label>
                    </td>
                    <td>
                      <div style={{ display: 'flex', gap: '6px' }}>
                        <button 
                          className="btn btn-sm btn-secondary"
                          onClick={() => openEditModal(d)}
                        >
                          <Edit2 size={13} />
                        </button>
                        <button 
                          className="btn btn-sm btn-danger"
                          onClick={() => handleDelete(d.id)}
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

      {/* Modal */}
      {modalOpen && (
        <div className="modal-overlay" onClick={() => setModalOpen(false)}>
          <div className="modal-content" onClick={e => e.stopPropagation()}>
            <div className="modal-header">
              <div className="modal-title">
                {editingDaig ? 'Edit Daig Item' : 'Add New Pakwan Center Daig'}
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
                    <label className="form-label">Dish Name (English) *</label>
                    <input 
                      type="text" 
                      className="form-input" 
                      value={formData.name}
                      onChange={e => setFormData({ ...formData, name: e.target.value })}
                      placeholder="e.g. Shahi Chicken Degi Biryani"
                      required
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">Urdu Name (شاہی نام)</label>
                    <input 
                      type="text" 
                      className="form-input" 
                      style={{ direction: 'rtl' }}
                      value={formData.urduName}
                      onChange={e => setFormData({ ...formData, urduName: e.target.value })}
                      placeholder="شاہی چکن دیگی بریانی"
                    />
                  </div>
                </div>

                <div className="form-grid-2">
                  <div className="form-group">
                    <label className="form-label">Category</label>
                    <select 
                      className="form-select"
                      value={formData.category}
                      onChange={e => setFormData({ ...formData, category: e.target.value })}
                    >
                      <option value="Biryani & Pulao">Biryani & Pulao</option>
                      <option value="Qorma & Karahi">Qorma & Karahi</option>
                      <option value="Haleem & Nihari">Haleem & Nihari</option>
                      <option value="Sweet & Desserts">Sweet & Desserts</option>
                    </select>
                  </div>

                  <div className="form-group">
                    <label className="form-label">Badge Label</label>
                    <input 
                      type="text" 
                      className="form-input" 
                      value={formData.badge}
                      onChange={e => setFormData({ ...formData, badge: e.target.value })}
                      placeholder="👑 Most Ordered Deg"
                    />
                  </div>
                </div>

                <div className="form-grid-2">
                  <div className="form-group">
                    <label className="form-label">Full Daig Price (Rs.) *</label>
                    <input 
                      type="number" 
                      className="form-input" 
                      value={formData.fullDaigPrice}
                      onChange={e => setFormData({ ...formData, fullDaigPrice: Number(e.target.value) })}
                      required
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">Half Daig Price (Rs.) *</label>
                    <input 
                      type="number" 
                      className="form-input" 
                      value={formData.halfDaigPrice}
                      onChange={e => setFormData({ ...formData, halfDaigPrice: Number(e.target.value) })}
                      required
                    />
                  </div>
                </div>

                <div className="form-group">
                  <label className="form-label">Description</label>
                  <textarea 
                    className="form-textarea" 
                    rows="2"
                    value={formData.description}
                    onChange={e => setFormData({ ...formData, description: e.target.value })}
                    placeholder="Slow simmered in coal dum with basmati rice, tender meat cuts..."
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Advance Notice Requirement</label>
                  <input 
                    type="text" 
                    className="form-input" 
                    value={formData.deliveryNotice}
                    onChange={e => setFormData({ ...formData, deliveryNotice: e.target.value })}
                    placeholder="Order 3-4 hours in advance for fresh dum cooking"
                  />
                </div>

                <ImageUploadField 
                  label="Daig Photograph / Display Image"
                  value={formData.imageUrl}
                  onChange={url => setFormData({ ...formData, imageUrl: url })}
                  placeholder="https://... or upload photo directly from PC"
                  category="daigs"
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
                    {formData.isVisible ? 'Visible in Mobile App' : 'Hidden from Mobile App'}
                  </span>
                </div>
              </div>

              <div className="modal-footer">
                <button type="button" className="btn btn-secondary" onClick={() => setModalOpen(false)}>
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary" disabled={saving}>
                  {saving ? 'Saving...' : (editingDaig ? 'Update Daig' : 'Create Daig')}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
