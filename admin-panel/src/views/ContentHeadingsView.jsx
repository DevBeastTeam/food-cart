import React, { useState } from 'react';
import { Type, Eye, EyeOff, Plus, Trash2, Save, MapPin, Layers } from 'lucide-react';
import { api } from '../api';

export default function ContentHeadingsView({ content, onUpdateContent, showToast }) {
  const [formData, setFormData] = useState({ ...content });
  const [newAddress, setNewAddress] = useState('');
  const [saving, setSaving] = useState(false);

  const handleChange = (field, val) => {
    setFormData(prev => ({ ...prev, [field]: val }));
  };

  const handleToggleSection = async (sectionKey) => {
    const newVal = !formData[sectionKey];
    setFormData(prev => ({ ...prev, [sectionKey]: newVal }));
    try {
      await api.toggleSectionVisibility(sectionKey, newVal);
      showToast(`Section ${sectionKey} is now ${newVal ? 'Visible' : 'Hidden'}`);
      onUpdateContent();
    } catch (err) {
      showToast(err.message || 'Failed to toggle section', 'error');
    }
  };

  const handleSaveAll = async (e) => {
    e.preventDefault();
    try {
      setSaving(true);
      await api.updateContent(formData);
      showToast('Headings & Content updated successfully!');
      onUpdateContent();
    } catch (err) {
      showToast(err.message || 'Failed to save content', 'error');
    } finally {
      setSaving(false);
    }
  };

  const handleAddAddress = async () => {
    if (!newAddress.trim()) return;
    try {
      await api.addAddress(newAddress.trim());
      showToast('Delivery address added!');
      setNewAddress('');
      onUpdateContent();
    } catch (err) {
      showToast(err.message || 'Failed to add address', 'error');
    }
  };

  const handleDeleteAddress = async (index) => {
    try {
      await api.deleteAddress(index);
      showToast('Address removed');
      onUpdateContent();
    } catch (err) {
      showToast(err.message || 'Failed to delete address', 'error');
    }
  };

  return (
    <div>
      {/* Top action bar */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <div>
          <h2 style={{ fontSize: 22, fontWeight: 800 }}>App Headings & Section Visibility</h2>
          <p style={{ fontSize: 13, color: 'var(--text-muted)' }}>
            Customize headings, titles, promo texts, and control visibility of every section in the Flutter app.
          </p>
        </div>
        <button 
          className="btn btn-primary"
          onClick={handleSaveAll}
          disabled={saving}
        >
          <Save size={16} /> {saving ? 'Saving...' : 'Save All Changes'}
        </button>
      </div>

      {/* 1. Master Section Visibility Controls */}
      <div className="panel">
        <div className="panel-header">
          <div>
            <div className="panel-title">
              <Layers size={18} color="var(--primary-light)" />
              App Sections Visibility Controls (Hide / Unhide)
            </div>
            <div className="panel-desc">Turn sections on or off in the mobile application without touching code</div>
          </div>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '16px' }}>
          {[
            { key: 'showPromoBanner', label: 'Promo Discount Banner', desc: '40% OFF gradient hero banner on Home screen' },
            { key: 'showCuisines', label: 'Cuisines Carousel', desc: 'Horizontal category chips (Biryani, Pulao, Mutton, etc.)' },
            { key: 'showQuickFilters', label: 'Quick Filter Pills', desc: 'Top Rated, Fast Delivery, Free Delivery pills' },
            { key: 'showShahiDishes', label: 'Shahi Menu Dishes', desc: 'Signature Selection popular food cards' },
            { key: 'showDaigSpotlight', label: 'Shahi Daig Catering Spotlight', desc: 'Pakwan Center cauldrons & wedding deg spotlight' },
            { key: 'showMartSection', label: 'FoodCourt Mart Grocery', desc: 'Mart products & grocery delivery section' },
          ].map(sec => {
            const isVisible = formData[sec.key] !== false;
            return (
              <div 
                key={sec.key}
                style={{
                  background: '#0F1524',
                  border: `1px solid ${isVisible ? 'rgba(124, 58, 237, 0.3)' : 'rgba(239, 68, 68, 0.3)'}`,
                  borderRadius: '12px',
                  padding: '16px',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  gap: '12px'
                }}
              >
                <div>
                  <div style={{ fontWeight: 700, fontSize: '14px', color: isVisible ? '#FFFFFF' : 'var(--text-muted)' }}>
                    {sec.label}
                  </div>
                  <div style={{ fontSize: '11.5px', color: 'var(--text-dim)', marginTop: '2px' }}>
                    {sec.desc}
                  </div>
                  <span className={`badge ${isVisible ? 'badge-active' : 'badge-hidden'}`} style={{ marginTop: 8 }}>
                    {isVisible ? <Eye size={10} style={{ marginRight: 3 }} /> : <EyeOff size={10} style={{ marginRight: 3 }} />}
                    {isVisible ? 'Visible in App' : 'Hidden from Users'}
                  </span>
                </div>
                <label className="switch">
                  <input 
                    type="checkbox" 
                    checked={isVisible}
                    onChange={() => handleToggleSection(sec.key)}
                  />
                  <span className="slider"></span>
                </label>
              </div>
            );
          })}
        </div>
      </div>

      {/* 2. Headings & Text Inputs */}
      <form onSubmit={handleSaveAll}>
        <div className="panel">
          <div className="panel-header">
            <div>
              <div className="panel-title">
                <Type size={18} color="var(--primary-light)" />
                Main App Headings & Subtitles
              </div>
              <div className="panel-desc">All visible labels, greetings, and section headers</div>
            </div>
          </div>

          <div className="form-grid-2">
            <div className="form-group">
              <label className="form-label">Top App Title (Header)</label>
              <input 
                type="text" 
                className="form-input" 
                value={formData.heroTitle || ''} 
                onChange={e => handleChange('heroTitle', e.target.value)}
                placeholder="Food Court"
              />
            </div>

            <div className="form-group">
              <label className="form-label">Guest Subtitle / Tagline</label>
              <input 
                type="text" 
                className="form-input" 
                value={formData.heroSubtitle || ''} 
                onChange={e => handleChange('heroSubtitle', e.target.value)}
                placeholder="Order food, groceries & Deg catering"
              />
            </div>

            <div className="form-group">
              <label className="form-label">Cuisines Section Title</label>
              <input 
                type="text" 
                className="form-input" 
                value={formData.cuisinesSectionTitle || ''} 
                onChange={e => handleChange('cuisinesSectionTitle', e.target.value)}
                placeholder="Cuisines for you"
              />
            </div>

            <div className="form-group">
              <label className="form-label">Shahi Menu Dishes Title</label>
              <input 
                type="text" 
                className="form-input" 
                value={formData.shahiMenuTitle || ''} 
                onChange={e => handleChange('shahiMenuTitle', e.target.value)}
                placeholder="👑 Shahi Menu Dishes (Signature Selection)"
              />
            </div>

            <div className="form-group">
              <label className="form-label">Shahi Menu Subtitle</label>
              <input 
                type="text" 
                className="form-input" 
                value={formData.shahiMenuSubtitle || ''} 
                onChange={e => handleChange('shahiMenuSubtitle', e.target.value)}
                placeholder="Popular dishes cooked in pure desi ghee..."
              />
            </div>

            <div className="form-group">
              <label className="form-label">Shahi Daig Catering Title</label>
              <input 
                type="text" 
                className="form-input" 
                value={formData.daigSpotlightTitle || ''} 
                onChange={e => handleChange('daigSpotlightTitle', e.target.value)}
                placeholder="Shahi Daig Catering & Pakwan Center"
              />
            </div>

            <div className="form-group">
              <label className="form-label">Shahi Daig Catering Subtitle</label>
              <input 
                type="text" 
                className="form-input" 
                value={formData.daigSpotlightSubtitle || ''} 
                onChange={e => handleChange('daigSpotlightSubtitle', e.target.value)}
                placeholder="Sealed hot cauldrons for Dawats..."
              />
            </div>

            <div className="form-group">
              <label className="form-label">Daig Booking Advance Notice Text</label>
              <input 
                type="text" 
                className="form-input" 
                value={formData.daigNoticeText || ''} 
                onChange={e => handleChange('daigNoticeText', e.target.value)}
                placeholder="Order 3-4 hours in advance for fresh dum cooking"
              />
            </div>
          </div>
        </div>

        {/* 3. Delivery Addresses Selector Management */}
        <div className="panel">
          <div className="panel-header">
            <div>
              <div className="panel-title">
                <MapPin size={18} color="var(--primary-light)" />
                Pre-configured Delivery Addresses (Address Selector BottomSheet)
              </div>
              <div className="panel-desc">Manage the address options shown in the Flutter address selector modal</div>
            </div>
          </div>

          <div style={{ display: 'flex', gap: '10px', marginBottom: '16px' }}>
            <input 
              type="text" 
              className="form-input" 
              placeholder="e.g. Home • Phase 6 DHA, Lahore or Office • Blue Area, Islamabad"
              value={newAddress}
              onChange={e => setNewAddress(e.target.value)}
            />
            <button 
              type="button" 
              className="btn btn-secondary" 
              onClick={handleAddAddress}
              style={{ whiteSpace: 'nowrap' }}
            >
              <Plus size={16} /> Add Address
            </button>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
            {(content?.addresses || []).map((addr, idx) => (
              <div 
                key={idx}
                style={{
                  background: '#0F1524',
                  border: '1px solid #242E42',
                  padding: '12px 16px',
                  borderRadius: '10px',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between'
                }}
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                  <MapPin size={16} color="var(--primary)" />
                  <span style={{ fontSize: '13px', fontWeight: 600 }}>{addr}</span>
                </div>
                <button 
                  type="button"
                  className="btn btn-sm btn-danger"
                  onClick={() => handleDeleteAddress(idx)}
                >
                  <Trash2 size={13} />
                </button>
              </div>
            ))}
          </div>
        </div>
      </form>
    </div>
  );
}
