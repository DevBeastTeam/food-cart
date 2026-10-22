import React, { useState } from 'react';
import { Image, Plus, Edit2, Trash2, Eye, EyeOff, Sparkles, ArrowRight } from 'lucide-react';
import { api } from '../api';
import ImageUploadField from '../components/ImageUploadField';

export default function BannersView({ banners, onRefresh, showToast }) {
  const [modalOpen, setModalOpen] = useState(false);
  const [editingBanner, setEditingBanner] = useState(null);
  const [saving, setSaving] = useState(false);

  const [formData, setFormData] = useState({
    tagText: 'SPECIAL OFFER',
    title: '40% OFF',
    dishesText: 'Shahi Qorma, Beef Kabab, Degi Biryani, Mutton Karahi, Zarda',
    buttonText: 'Order Now',
    bgGradient: ['#6C3CE9', '#8B5CF6', '#A855F7'],
    imageUrl: 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=600&q=80',
    isVisible: true,
    linkCategory: 'Biryani'
  });

  const openAddModal = () => {
    setEditingBanner(null);
    setFormData({
      tagText: 'SPECIAL OFFER',
      title: '50% OFF WEEKEND',
      dishesText: 'Degi Biryani, Shinwari Karahi, Dum Pukht Mutton, Shahi Kheer',
      buttonText: 'Order Now',
      bgGradient: ['#6C3CE9', '#8B5CF6', '#A855F7'],
      imageUrl: 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=600&q=80',
      isVisible: true,
      linkCategory: 'Biryani'
    });
    setModalOpen(true);
  };

  const openEditModal = (b) => {
    setEditingBanner(b);
    setFormData({
      tagText: b.tagText || 'SPECIAL OFFER',
      title: b.title || '',
      dishesText: b.dishesText || '',
      buttonText: b.buttonText || 'Order Now',
      bgGradient: b.bgGradient || ['#6C3CE9', '#8B5CF6', '#A855F7'],
      imageUrl: b.imageUrl || '',
      isVisible: b.isVisible !== false,
      linkCategory: b.linkCategory || 'All'
    });
    setModalOpen(true);
  };

  const handleToggleVisibility = async (b) => {
    try {
      const res = await api.toggleBannerVisibility(b.id, !b.isVisible);
      showToast(res.message);
      onRefresh();
    } catch (err) {
      showToast(err.message || 'Failed to update visibility', 'error');
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Delete this banner?')) return;
    try {
      await api.deleteBanner(id);
      showToast('Banner removed');
      onRefresh();
    } catch (err) {
      showToast(err.message || 'Failed to delete banner', 'error');
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!formData.title) {
      showToast('Title is required', 'error');
      return;
    }

    try {
      setSaving(true);
      if (editingBanner) {
        await api.updateBanner(editingBanner.id, formData);
        showToast('Banner updated');
      } else {
        await api.createBanner(formData);
        showToast('Banner created');
      }
      setModalOpen(false);
      onRefresh();
    } catch (err) {
      showToast(err.message || 'Error saving banner', 'error');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <div>
          <h2 style={{ fontSize: 22, fontWeight: 800 }}>Hero Promo Banners</h2>
          <p style={{ fontSize: 13, color: 'var(--text-muted)' }}>
            Design high-converting promo banners displayed prominently at the top of the mobile home screen.
          </p>
        </div>
        <button className="btn btn-primary" onClick={openAddModal}>
          <Plus size={16} /> Create Promo Banner
        </button>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(340px, 1fr))', gap: '20px' }}>
        {(!banners || banners.length === 0) ? (
          <div className="panel" style={{ textAlign: 'center', padding: '30px', color: 'var(--text-muted)', gridColumn: '1 / -1' }}>
            No promo banners available. Click "Create Promo Banner" to add one.
          </div>
        ) : (
          banners.map(b => (
            <div key={b.id} className="panel" style={{ padding: 20 }}>
              {/* Live Preview Card */}
              <div 
                style={{
                  background: `linear-gradient(135deg, ${b.bgGradient?.[0] || '#6C3CE9'}, ${b.bgGradient?.[1] || '#8B5CF6'}, ${b.bgGradient?.[2] || '#A855F7'})`,
                  borderRadius: '16px',
                  padding: '16px',
                  position: 'relative',
                  overflow: 'hidden',
                  marginBottom: 16,
                  color: 'white',
                  boxShadow: '0 8px 20px rgba(108, 60, 233, 0.35)'
                }}
              >
                {/* Background decorative image */}
                {b.imageUrl && (
                  <img 
                    src={b.imageUrl} 
                    alt="" 
                    style={{
                      position: 'absolute',
                      right: -15,
                      bottom: -15,
                      width: 120,
                      height: 120,
                      borderRadius: '50%',
                      opacity: 0.25,
                      objectFit: 'cover'
                    }}
                  />
                )}

                <div style={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: 4,
                  background: 'rgba(255, 255, 255, 0.2)',
                  padding: '3px 8px',
                  borderRadius: 4,
                  fontSize: '10px',
                  fontWeight: 800,
                  letterSpacing: '0.8px',
                  marginBottom: 8
                }}>
                  <Sparkles size={12} color="#FBBF24" /> {b.tagText || 'SPECIAL OFFER'}
                </div>

                <div style={{ fontSize: 24, fontWeight: 900, lineHeight: 1.1, marginBottom: 4 }}>
                  {b.title}
                </div>

                <div style={{ fontSize: 11.5, opacity: 0.9, lineHeight: 1.3, marginBottom: 14, maxWidth: '80%' }}>
                  {b.dishesText}
                </div>

                <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
                  <div style={{
                    background: 'white',
                    color: '#6C3CE9',
                    padding: '5px 12px',
                    borderRadius: 16,
                    fontSize: '11px',
                    fontWeight: 800,
                    display: 'flex',
                    alignItems: 'center',
                    gap: 4
                  }}>
                    {b.buttonText || 'Order Now'} <ArrowRight size={12} />
                  </div>
                </div>
              </div>

              {/* Controls */}
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                  <label className="switch">
                    <input 
                      type="checkbox" 
                      checked={b.isVisible !== false}
                      onChange={() => handleToggleVisibility(b)}
                    />
                    <span className="slider"></span>
                  </label>
                  <span style={{ fontSize: 12, fontWeight: 700 }}>
                    {b.isVisible !== false ? 'Live on App' : 'Hidden'}
                  </span>
                </div>

                <div style={{ display: 'flex', gap: 6 }}>
                  <button className="btn btn-sm btn-secondary" onClick={() => openEditModal(b)}>
                    <Edit2 size={13} /> Edit
                  </button>
                  <button className="btn btn-sm btn-danger" onClick={() => handleDelete(b.id)}>
                    <Trash2 size={13} />
                  </button>
                </div>
              </div>
            </div>
          ))
        )}
      </div>

      {/* Modal */}
      {modalOpen && (
        <div className="modal-overlay" onClick={() => setModalOpen(false)}>
          <div className="modal-content" onClick={e => e.stopPropagation()}>
            <div className="modal-header">
              <div className="modal-title">
                {editingBanner ? 'Edit Promo Banner' : 'Create Hero Banner'}
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
                    <label className="form-label">Announcement Tag</label>
                    <input 
                      type="text" 
                      className="form-input" 
                      value={formData.tagText}
                      onChange={e => setFormData({ ...formData, tagText: e.target.value })}
                      placeholder="SPECIAL OFFER"
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">Banner Title *</label>
                    <input 
                      type="text" 
                      className="form-input" 
                      value={formData.title}
                      onChange={e => setFormData({ ...formData, title: e.target.value })}
                      placeholder="e.g. 40% OFF"
                      required
                    />
                  </div>
                </div>

                <div className="form-group">
                  <label className="form-label">Dishes Subtext / Description</label>
                  <input 
                    type="text" 
                    className="form-input" 
                    value={formData.dishesText}
                    onChange={e => setFormData({ ...formData, dishesText: e.target.value })}
                    placeholder="Shahi Qorma, Beef Kabab, Degi Biryani, Mutton Karahi..."
                  />
                </div>

                <div className="form-grid-2">
                  <div className="form-group">
                    <label className="form-label">Action Button Label</label>
                    <input 
                      type="text" 
                      className="form-input" 
                      value={formData.buttonText}
                      onChange={e => setFormData({ ...formData, buttonText: e.target.value })}
                      placeholder="Order Now"
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">Target Cuisine / Category Link</label>
                    <input 
                      type="text" 
                      className="form-input" 
                      value={formData.linkCategory}
                      onChange={e => setFormData({ ...formData, linkCategory: e.target.value })}
                      placeholder="Biryani"
                    />
                  </div>
                </div>

                <ImageUploadField 
                  label="Banner Promotional Image"
                  value={formData.imageUrl}
                  onChange={url => setFormData({ ...formData, imageUrl: url })}
                  placeholder="https://... or upload banner image directly from PC"
                  category="banners"
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
                    {formData.isVisible ? 'Visible to Users' : 'Hidden'}
                  </span>
                </div>
              </div>

              <div className="modal-footer">
                <button type="button" className="btn btn-secondary" onClick={() => setModalOpen(false)}>
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary" disabled={saving}>
                  {saving ? 'Saving...' : (editingBanner ? 'Update Banner' : 'Create Banner')}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
