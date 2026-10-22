import React, { useState } from 'react';
import { Utensils, Plus, Edit2, Trash2, Star, Eye, EyeOff, Flame, Search } from 'lucide-react';
import { api } from '../api';
import ImageUploadField from '../components/ImageUploadField';

export default function MenuItemsView({ foodItems, restaurants, categories, onRefresh, showToast }) {
  const [modalOpen, setModalOpen] = useState(false);
  const [editingItem, setEditingItem] = useState(null);
  const [saving, setSaving] = useState(false);
  const [selectedCategory, setSelectedCategory] = useState('All');
  const [searchQuery, setSearchQuery] = useState('');

  const [formData, setFormData] = useState({
    name: '',
    restaurantId: 'rest_1',
    category: 'Biryani',
    price: 850,
    description: '',
    imageUrl: '',
    rating: 4.9,
    calories: 650,
    isPopular: true,
    isVegetarian: false,
    isVisible: true,
    badges: ['Desi Ghee', 'Special Platter']
  });

  const filteredItems = (foodItems || []).filter(item => {
    const matchCat = selectedCategory === 'All' || item.category === selectedCategory;
    const matchQuery = !searchQuery.trim() || 
      item.name.toLowerCase().includes(searchQuery.toLowerCase()) || 
      item.category.toLowerCase().includes(searchQuery.toLowerCase());
    return matchCat && matchQuery;
  });

  const openAddModal = () => {
    setEditingItem(null);
    setFormData({
      name: '',
      restaurantId: restaurants && restaurants.length > 0 ? restaurants[0].id : 'rest_1',
      category: 'Biryani',
      price: 850,
      description: 'Slow-cooked in pure desi ghee with secret potli spices.',
      imageUrl: 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=500&q=80',
      rating: 4.9,
      calories: 620,
      isPopular: true,
      isVegetarian: false,
      isVisible: true,
      badges: ['Desi Ghee', 'Chef Special']
    });
    setModalOpen(true);
  };

  const openEditModal = (item) => {
    setEditingItem(item);
    setFormData({
      name: item.name,
      restaurantId: item.restaurantId,
      category: item.category,
      price: item.price,
      description: item.description || '',
      imageUrl: item.imageUrl || '',
      rating: item.rating || 4.9,
      calories: item.calories || 450,
      isPopular: Boolean(item.isPopular),
      isVegetarian: Boolean(item.isVegetarian),
      isVisible: item.isVisible !== false,
      badges: item.badges || []
    });
    setModalOpen(true);
  };

  const handleTogglePopular = async (item) => {
    try {
      const res = await api.toggleFoodItemPopular(item.id, !item.isPopular);
      showToast(res.message);
      onRefresh();
    } catch (err) {
      showToast(err.message || 'Failed to update', 'error');
    }
  };

  const handleToggleVisibility = async (item) => {
    try {
      const res = await api.toggleFoodItemVisibility(item.id, !item.isVisible);
      showToast(res.message);
      onRefresh();
    } catch (err) {
      showToast(err.message || 'Failed to update', 'error');
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Delete this food item from the menu?')) return;
    try {
      await api.deleteFoodItem(id);
      showToast('Food item removed');
      onRefresh();
    } catch (err) {
      showToast(err.message || 'Failed to delete', 'error');
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!formData.name || formData.price === undefined) {
      showToast('Name and price are required', 'error');
      return;
    }

    try {
      setSaving(true);
      if (editingItem) {
        await api.updateFoodItem(editingItem.id, formData);
        showToast('Dish updated successfully');
      } else {
        await api.createFoodItem(formData);
        showToast('Dish added to menu');
      }
      setModalOpen(false);
      onRefresh();
    } catch (err) {
      showToast(err.message || 'Error saving dish', 'error');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <div>
          <h2 style={{ fontSize: 22, fontWeight: 800 }}>Food Items & Menu Management</h2>
          <p style={{ fontSize: 13, color: 'var(--text-muted)' }}>
            Manage all Pakistani dishes, pricing, calories, tags, and spotlight popularity.
          </p>
        </div>
        <button className="btn btn-primary" onClick={openAddModal}>
          <Plus size={16} /> Add Food Item
        </button>
      </div>

      {/* Filter and Search Bar */}
      <div className="panel" style={{ padding: '16px 20px', marginBottom: 20 }}>
        <div style={{ display: 'flex', gap: 16, alignItems: 'center', flexWrap: 'wrap' }}>
          <div style={{ position: 'relative', flex: '1', minWidth: 220 }}>
            <Search size={16} style={{ position: 'absolute', left: 12, top: 12, color: 'var(--text-dim)' }} />
            <input 
              type="text" 
              className="form-input" 
              placeholder="Search dishes (e.g. Bannu Pulao, Nihari, Karahi, Zarda)..."
              style={{ paddingLeft: 36 }}
              value={searchQuery}
              onChange={e => setSearchQuery(e.target.value)}
            />
          </div>

          <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
            <span style={{ fontSize: 12.5, fontWeight: 700, color: 'var(--text-muted)' }}>Category:</span>
            <select 
              className="form-select" 
              style={{ width: 'auto', minWidth: 160 }}
              value={selectedCategory}
              onChange={e => setSelectedCategory(e.target.value)}
            >
              <option value="All">All Categories ({foodItems?.length || 0})</option>
              {(categories || []).filter(c => c.name !== 'All').map(c => (
                <option key={c.id} value={c.name}>{c.name}</option>
              ))}
            </select>
          </div>
        </div>
      </div>

      <div className="panel">
        <div className="table-responsive">
          <table className="data-table">
            <thead>
              <tr>
                <th>Dish Name & Image</th>
                <th>Category</th>
                <th>Price</th>
                <th>Rating & Cals</th>
                <th>Popular (Shahi Menu)</th>
                <th>Visibility</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredItems.length === 0 ? (
                <tr>
                  <td colSpan="7" style={{ textAlign: 'center', padding: '30px', color: 'var(--text-muted)' }}>
                    No dishes found matching criteria.
                  </td>
                </tr>
              ) : (
                filteredItems.map(item => (
                  <tr key={item.id}>
                    <td>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                        <img 
                          src={item.imageUrl} 
                          alt="" 
                          style={{ width: 44, height: 44, borderRadius: 8, objectFit: 'cover' }} 
                        />
                        <div>
                          <div style={{ fontWeight: 800, color: '#FFFFFF' }}>{item.name}</div>
                          <div style={{ fontSize: '11px', color: 'var(--text-dim)', maxWidth: 260, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                            {item.description}
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
                        {item.category}
                      </span>
                    </td>
                    <td style={{ fontWeight: 800, color: '#34D399', fontSize: 14 }}>
                      Rs. {item.price}
                    </td>
                    <td>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 4, fontWeight: 700, color: '#FBBF24', fontSize: 12 }}>
                        <Star size={12} fill="#FBBF24" /> {item.rating}
                      </div>
                      <div style={{ fontSize: '11px', color: 'var(--text-dim)' }}>
                        {item.calories} kcal
                      </div>
                    </td>
                    <td>
                      <button 
                        style={{
                          background: item.isPopular ? 'rgba(245, 158, 11, 0.2)' : 'rgba(255, 255, 255, 0.05)',
                          border: `1px solid ${item.isPopular ? '#F59E0B' : 'var(--border-color)'}`,
                          color: item.isPopular ? '#FBBF24' : 'var(--text-muted)',
                          padding: '4px 10px',
                          borderRadius: '20px',
                          fontSize: '11px',
                          fontWeight: 700,
                          cursor: 'pointer',
                          display: 'flex',
                          alignItems: 'center',
                          gap: 4
                        }}
                        onClick={() => handleTogglePopular(item)}
                      >
                        <Flame size={12} /> {item.isPopular ? 'Popular' : 'Standard'}
                      </button>
                    </td>
                    <td>
                      <label className="switch">
                        <input 
                          type="checkbox" 
                          checked={item.isVisible !== false}
                          onChange={() => handleToggleVisibility(item)}
                        />
                        <span className="slider"></span>
                      </label>
                    </td>
                    <td>
                      <div style={{ display: 'flex', gap: '6px' }}>
                        <button 
                          className="btn btn-sm btn-secondary"
                          onClick={() => openEditModal(item)}
                        >
                          <Edit2 size={13} />
                        </button>
                        <button 
                          className="btn btn-sm btn-danger"
                          onClick={() => handleDelete(item.id)}
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
                {editingItem ? 'Edit Food Dish' : 'Add Dish to Menu'}
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
                  <label className="form-label">Dish Name *</label>
                  <input 
                    type="text" 
                    className="form-input" 
                    value={formData.name}
                    onChange={e => setFormData({ ...formData, name: e.target.value })}
                    placeholder="e.g. Special Bannu Beef Yakhni Pulao"
                    required
                  />
                </div>

                <div className="form-grid-2">
                  <div className="form-group">
                    <label className="form-label">Category *</label>
                    <select 
                      className="form-select"
                      value={formData.category}
                      onChange={e => setFormData({ ...formData, category: e.target.value })}
                    >
                      {(categories || []).filter(c => c.name !== 'All').map(c => (
                        <option key={c.id} value={c.name}>{c.name}</option>
                      ))}
                    </select>
                  </div>

                  <div className="form-group">
                    <label className="form-label">Price (Rs.) *</label>
                    <input 
                      type="number" 
                      className="form-input" 
                      value={formData.price}
                      onChange={e => setFormData({ ...formData, price: Number(e.target.value) })}
                      required
                    />
                  </div>
                </div>

                <div className="form-group">
                  <label className="form-label">Description & Ingredients</label>
                  <textarea 
                    className="form-textarea" 
                    rows="2"
                    value={formData.description}
                    onChange={e => setFormData({ ...formData, description: e.target.value })}
                    placeholder="Slow cooked with aged basmati, garlic pods, and tender beef cuts..."
                  />
                </div>

                <div className="form-grid-2">
                  <div className="form-group">
                    <label className="form-label">Calories (kcal)</label>
                    <input 
                      type="number" 
                      className="form-input" 
                      value={formData.calories}
                      onChange={e => setFormData({ ...formData, calories: Number(e.target.value) })}
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">Rating</label>
                    <input 
                      type="number" 
                      step="0.1" 
                      className="form-input" 
                      value={formData.rating}
                      onChange={e => setFormData({ ...formData, rating: Number(e.target.value) })}
                    />
                  </div>
                </div>

                <ImageUploadField 
                  label="Dish Photo / Image"
                  value={formData.imageUrl}
                  onChange={url => setFormData({ ...formData, imageUrl: url })}
                  placeholder="https://... or upload picture directly from PC"
                  category="dishes"
                />

                <div style={{ display: 'flex', gap: 20, marginTop: 12, flexWrap: 'wrap' }}>
                  <label style={{ display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer' }}>
                    <input 
                      type="checkbox" 
                      checked={formData.isPopular}
                      onChange={e => setFormData({ ...formData, isPopular: e.target.checked })}
                    />
                    <span style={{ fontSize: 13, fontWeight: 700 }}>Show in Shahi Popular Selection</span>
                  </label>

                  <label style={{ display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer' }}>
                    <input 
                      type="checkbox" 
                      checked={formData.isVegetarian}
                      onChange={e => setFormData({ ...formData, isVegetarian: e.target.checked })}
                    />
                    <span style={{ fontSize: 13, fontWeight: 700 }}>Vegetarian Dish</span>
                  </label>

                  <label style={{ display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer' }}>
                    <input 
                      type="checkbox" 
                      checked={formData.isVisible}
                      onChange={e => setFormData({ ...formData, isVisible: e.target.checked })}
                    />
                    <span style={{ fontSize: 13, fontWeight: 700 }}>Visible in Mobile App</span>
                  </label>
                </div>
              </div>

              <div className="modal-footer">
                <button type="button" className="btn btn-secondary" onClick={() => setModalOpen(false)}>
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary" disabled={saving}>
                  {saving ? 'Saving...' : (editingItem ? 'Update Dish' : 'Add to Menu')}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
