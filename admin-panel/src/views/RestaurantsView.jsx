import React, { useState } from 'react';
import { Store, Plus, Edit2, Trash2, Star, Eye, EyeOff, MapPin, DollarSign, Clock } from 'lucide-react';
import { api } from '../api';

export default function RestaurantsView({ restaurants, onRefresh, showToast }) {
  const [modalOpen, setModalOpen] = useState(false);
  const [editingRestaurant, setEditingRestaurant] = useState(null);
  const [saving, setSaving] = useState(false);

  const [formData, setFormData] = useState({
    name: '',
    cuisine: '',
    imageUrl: '',
    rating: 4.9,
    reviewCount: 500,
    deliveryTime: '20-30 min',
    deliveryFee: 49,
    minOrder: 300,
    distance: '1.8 km',
    address: 'Gulberg III, Lahore',
    badge: '🔥 Top Pick',
    isFeatured: true,
    isVisible: true,
    categories: ['All', 'Biryani', 'Pulao']
  });

  const openAddModal = () => {
    setEditingRestaurant(null);
    setFormData({
      name: '',
      cuisine: 'Biryani • Pulao • Desi Ghee',
      imageUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947?w=600&q=80',
      rating: 4.9,
      reviewCount: 350,
      deliveryTime: '20-30 min',
      deliveryFee: 49,
      minOrder: 300,
      distance: '2.0 km',
      address: 'Gulberg III, Lahore',
      badge: '✨ New Branch',
      isFeatured: false,
      isVisible: true,
      categories: ['All']
    });
    setModalOpen(true);
  };

  const openEditModal = (r) => {
    setEditingRestaurant(r);
    setFormData({
      name: r.name,
      cuisine: r.cuisine,
      imageUrl: r.imageUrl || '',
      rating: r.rating || 4.9,
      reviewCount: r.reviewCount || 100,
      deliveryTime: r.deliveryTime || '25 min',
      deliveryFee: r.deliveryFee !== undefined ? r.deliveryFee : 49,
      minOrder: r.minOrder || 300,
      distance: r.distance || '2.0 km',
      address: r.address || '',
      badge: r.badge || '',
      isFeatured: Boolean(r.isFeatured),
      isVisible: r.isVisible !== false,
      categories: r.categories || ['All']
    });
    setModalOpen(true);
  };

  const handleToggleVisibility = async (r) => {
    try {
      const res = await api.toggleRestaurantVisibility(r.id, !r.isVisible);
      showToast(res.message);
      onRefresh();
    } catch (err) {
      showToast(err.message || 'Failed to update visibility', 'error');
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to delete this restaurant?')) return;
    try {
      await api.deleteRestaurant(id);
      showToast('Restaurant deleted successfully');
      onRefresh();
    } catch (err) {
      showToast(err.message || 'Failed to delete restaurant', 'error');
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!formData.name || !formData.cuisine) {
      showToast('Name and cuisine description are required', 'error');
      return;
    }

    try {
      setSaving(true);
      if (editingRestaurant) {
        await api.updateRestaurant(editingRestaurant.id, formData);
        showToast('Restaurant updated successfully');
      } else {
        await api.createRestaurant(formData);
        showToast('Restaurant created successfully');
      }
      setModalOpen(false);
      onRefresh();
    } catch (err) {
      showToast(err.message || 'Error saving restaurant', 'error');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <div>
          <h2 style={{ fontSize: 22, fontWeight: 800 }}>Restaurants, Kitchens & Branches</h2>
          <p style={{ fontSize: 13, color: 'var(--text-muted)' }}>
            Manage partner restaurants, central kitchens, menus, and delivery pricing.
          </p>
        </div>
        <button className="btn btn-primary" onClick={openAddModal}>
          <Plus size={16} /> Add Restaurant / Branch
        </button>
      </div>

      <div className="panel">
        <div className="table-responsive">
          <table className="data-table">
            <thead>
              <tr>
                <th>Restaurant / Branch</th>
                <th>Cuisine & Specialities</th>
                <th>Rating & Reviews</th>
                <th>Delivery Details</th>
                <th>Featured</th>
                <th>Visibility</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {(!restaurants || restaurants.length === 0) ? (
                <tr>
                  <td colSpan="7" style={{ textAlign: 'center', padding: '30px', color: 'var(--text-muted)' }}>
                    No restaurants found.
                  </td>
                </tr>
              ) : (
                restaurants.map(r => (
                  <tr key={r.id}>
                    <td>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                        <img 
                          src={r.imageUrl} 
                          alt="" 
                          style={{ width: 48, height: 48, borderRadius: 10, objectFit: 'cover' }} 
                        />
                        <div>
                          <div style={{ fontWeight: 800, color: '#FFFFFF' }}>{r.name}</div>
                          <div style={{ fontSize: '11px', color: 'var(--text-dim)', display: 'flex', alignItems: 'center', gap: 3, marginTop: 2 }}>
                            <MapPin size={11} /> {r.address}
                          </div>
                        </div>
                      </div>
                    </td>
                    <td>
                      <div style={{ fontSize: '12.5px', color: '#C4B5FD', fontWeight: 600 }}>
                        {r.cuisine}
                      </div>
                      {r.badge && (
                        <span style={{ 
                          fontSize: '10.5px', 
                          background: 'rgba(245, 158, 11, 0.15)', 
                          color: '#FBBF24', 
                          padding: '2px 6px', 
                          borderRadius: 4,
                          display: 'inline-block',
                          marginTop: 4 
                        }}>
                          {r.badge}
                        </span>
                      )}
                    </td>
                    <td>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 4, fontWeight: 800, color: '#FBBF24' }}>
                        <Star size={13} fill="#FBBF24" /> {r.rating}
                      </div>
                      <div style={{ fontSize: '11px', color: 'var(--text-dim)' }}>
                        {r.reviewCount} reviews
                      </div>
                    </td>
                    <td>
                      <div style={{ fontSize: '12px' }}>
                        Fee: <strong>Rs. {r.deliveryFee}</strong>
                      </div>
                      <div style={{ fontSize: '11.5px', color: 'var(--text-dim)' }}>
                        {r.deliveryTime} • Min: Rs. {r.minOrder}
                      </div>
                    </td>
                    <td>
                      <span className={`badge ${r.isFeatured ? 'badge-active' : 'badge-expired'}`}>
                        {r.isFeatured ? 'Featured ⭐' : 'Normal'}
                      </span>
                    </td>
                    <td>
                      <label className="switch">
                        <input 
                          type="checkbox" 
                          checked={r.isVisible !== false}
                          onChange={() => handleToggleVisibility(r)}
                        />
                        <span className="slider"></span>
                      </label>
                    </td>
                    <td>
                      <div style={{ display: 'flex', gap: '6px' }}>
                        <button 
                          className="btn btn-sm btn-secondary"
                          onClick={() => openEditModal(r)}
                        >
                          <Edit2 size={13} />
                        </button>
                        <button 
                          className="btn btn-sm btn-danger"
                          onClick={() => handleDelete(r.id)}
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
                {editingRestaurant ? 'Edit Restaurant / Kitchen' : 'Add New Restaurant'}
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
                  <label className="form-label">Restaurant Name *</label>
                  <input 
                    type="text" 
                    className="form-input" 
                    value={formData.name}
                    onChange={e => setFormData({ ...formData, name: e.target.value })}
                    placeholder="e.g. Bannu Beef Pulao & Nalli Nihari"
                    required
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Cuisines / Subtitle *</label>
                  <input 
                    type="text" 
                    className="form-input" 
                    value={formData.cuisine}
                    onChange={e => setFormData({ ...formData, cuisine: e.target.value })}
                    placeholder="e.g. Pulao • Bara Gosht (Beef) • Nihari"
                    required
                  />
                </div>

                <div className="form-grid-2">
                  <div className="form-group">
                    <label className="form-label">Delivery Fee (Rs.)</label>
                    <input 
                      type="number" 
                      className="form-input" 
                      value={formData.deliveryFee}
                      onChange={e => setFormData({ ...formData, deliveryFee: Number(e.target.value) })}
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">Min Order (Rs.)</label>
                    <input 
                      type="number" 
                      className="form-input" 
                      value={formData.minOrder}
                      onChange={e => setFormData({ ...formData, minOrder: Number(e.target.value) })}
                    />
                  </div>
                </div>

                <div className="form-grid-2">
                  <div className="form-group">
                    <label className="form-label">Estimated Delivery Time</label>
                    <input 
                      type="text" 
                      className="form-input" 
                      value={formData.deliveryTime}
                      onChange={e => setFormData({ ...formData, deliveryTime: e.target.value })}
                      placeholder="20-30 min"
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">Distance / Radius</label>
                    <input 
                      type="text" 
                      className="form-input" 
                      value={formData.distance}
                      onChange={e => setFormData({ ...formData, distance: e.target.value })}
                      placeholder="1.8 km"
                    />
                  </div>
                </div>

                <div className="form-group">
                  <label className="form-label">Full Address / Location</label>
                  <input 
                    type="text" 
                    className="form-input" 
                    value={formData.address}
                    onChange={e => setFormData({ ...formData, address: e.target.value })}
                    placeholder="Shop 12, Block K, Gulberg III, Lahore"
                  />
                </div>

                <div className="form-grid-2">
                  <div className="form-group">
                    <label className="form-label">Badge Text</label>
                    <input 
                      type="text" 
                      className="form-input" 
                      value={formData.badge}
                      onChange={e => setFormData({ ...formData, badge: e.target.value })}
                      placeholder="🔥 Top Pick or ✨ Free Delivery"
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">Rating (1.0 - 5.0)</label>
                    <input 
                      type="number" 
                      step="0.1" 
                      className="form-input" 
                      value={formData.rating}
                      onChange={e => setFormData({ ...formData, rating: Number(e.target.value) })}
                    />
                  </div>
                </div>

                <div className="form-group">
                  <label className="form-label">Image URL</label>
                  <input 
                    type="url" 
                    className="form-input" 
                    value={formData.imageUrl}
                    onChange={e => setFormData({ ...formData, imageUrl: e.target.value })}
                    placeholder="https://images.unsplash.com/photo-..."
                  />
                </div>

                <div style={{ display: 'flex', gap: 24, marginTop: 12 }}>
                  <label style={{ display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer' }}>
                    <input 
                      type="checkbox" 
                      checked={formData.isFeatured}
                      onChange={e => setFormData({ ...formData, isFeatured: e.target.checked })}
                    />
                    <span style={{ fontSize: 13, fontWeight: 700 }}>Featured on Home Screen</span>
                  </label>

                  <label style={{ display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer' }}>
                    <input 
                      type="checkbox" 
                      checked={formData.isVisible}
                      onChange={e => setFormData({ ...formData, isVisible: e.target.checked })}
                    />
                    <span style={{ fontSize: 13, fontWeight: 700 }}>Visible in App</span>
                  </label>
                </div>
              </div>

              <div className="modal-footer">
                <button type="button" className="btn btn-secondary" onClick={() => setModalOpen(false)}>
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary" disabled={saving}>
                  {saving ? 'Saving...' : (editingRestaurant ? 'Update Restaurant' : 'Create Restaurant')}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
