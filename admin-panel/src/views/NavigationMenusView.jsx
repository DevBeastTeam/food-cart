import React, { useState } from 'react';
import { Compass, Plus, Edit2, Trash2, Eye, EyeOff, MoveUp, MoveDown, Layers } from 'lucide-react';
import { api } from '../api';

export default function NavigationMenusView({ navigation, categories, onRefresh, showToast }) {
  const [navModalOpen, setNavModalOpen] = useState(false);
  const [catModalOpen, setCatModalOpen] = useState(false);
  const [editingNav, setEditingNav] = useState(null);
  const [editingCat, setEditingCat] = useState(null);
  const [saving, setSaving] = useState(false);

  const [navForm, setNavForm] = useState({ label: '', icon: 'home', screen: 'home', order: 1, isVisible: true });
  const [catForm, setCatForm] = useState({ name: '', icon: '🍲', image: '', order: 1 });

  const handleToggleNavVisibility = async (item) => {
    try {
      const res = await api.toggleNavVisibility(item.id, !item.isVisible);
      showToast(res.message);
      onRefresh();
    } catch (err) {
      showToast(err.message || 'Failed to update nav', 'error');
    }
  };

  const handleToggleCatVisibility = async (cat) => {
    try {
      const res = await api.toggleCategoryVisibility(cat.id, !cat.isVisible);
      showToast(res.message);
      onRefresh();
    } catch (err) {
      showToast(err.message || 'Failed to update category', 'error');
    }
  };

  const handleNavSubmit = async (e) => {
    e.preventDefault();
    try {
      setSaving(true);
      if (editingNav) {
        await api.updateNavItem(editingNav.id, navForm);
        showToast('Navigation tab updated');
      } else {
        await api.createNavItem(navForm);
        showToast('Navigation tab created');
      }
      setNavModalOpen(false);
      onRefresh();
    } catch (err) {
      showToast(err.message || 'Error saving nav', 'error');
    } finally {
      setSaving(false);
    }
  };

  const handleCatSubmit = async (e) => {
    e.preventDefault();
    try {
      setSaving(true);
      if (editingCat) {
        await api.updateCategory(editingCat.id, catForm);
        showToast('Category updated');
      } else {
        await api.createCategory(catForm);
        showToast('Category created');
      }
      setCatModalOpen(false);
      onRefresh();
    } catch (err) {
      showToast(err.message || 'Error saving category', 'error');
    } finally {
      setSaving(false);
    }
  };

  const handleDeleteCat = async (id) => {
    if (!window.confirm('Delete this category?')) return;
    try {
      await api.deleteCategory(id);
      showToast('Category deleted');
      onRefresh();
    } catch (err) {
      showToast(err.message || 'Failed to delete category', 'error');
    }
  };

  return (
    <div>
      <div style={{ marginBottom: 24 }}>
        <h2 style={{ fontSize: 22, fontWeight: 800 }}>Navigation Bars & Category Menus</h2>
        <p style={{ fontSize: 13, color: 'var(--text-muted)' }}>
          Manage mobile app bottom navigation tabs, category labels, ordering, and icon assignments.
        </p>
      </div>

      {/* 1. Mobile Bottom Navigation Items */}
      <div className="panel" style={{ marginBottom: 24 }}>
        <div className="panel-header">
          <div>
            <div className="panel-title">
              <Compass size={18} color="var(--primary-light)" />
              Bottom Navigation Bar Tabs
            </div>
            <div className="panel-desc">Labels, icons, ordering, and visibility of tabs in the mobile app</div>
          </div>
          <button 
            className="btn btn-sm btn-primary"
            onClick={() => {
              setEditingNav(null);
              setNavForm({ label: '', icon: 'star', screen: 'home', order: (navigation?.length || 0) + 1, isVisible: true });
              setNavModalOpen(true);
            }}
          >
            <Plus size={14} /> Add Navigation Tab
          </button>
        </div>

        <div className="table-responsive">
          <table className="data-table">
            <thead>
              <tr>
                <th>Order</th>
                <th>Tab Label</th>
                <th>Icon Code</th>
                <th>Screen Target</th>
                <th>Visibility</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {(navigation || []).map(nav => (
                <tr key={nav.id}>
                  <td style={{ fontWeight: 800, color: '#C4B5FD', width: 60 }}>
                    #{nav.order}
                  </td>
                  <td style={{ fontWeight: 700 }}>
                    {nav.label}
                  </td>
                  <td style={{ fontFamily: 'monospace', color: '#FBBF24', fontSize: '12px' }}>
                    {nav.icon}
                  </td>
                  <td style={{ fontSize: '12px', color: 'var(--text-dim)' }}>
                    {nav.screen}
                  </td>
                  <td>
                    <label className="switch">
                      <input 
                        type="checkbox" 
                        checked={nav.isVisible !== false}
                        onChange={() => handleToggleNavVisibility(nav)}
                      />
                      <span className="slider"></span>
                    </label>
                  </td>
                  <td>
                    <button 
                      className="btn btn-sm btn-secondary"
                      onClick={() => {
                        setEditingNav(nav);
                        setNavForm({
                          label: nav.label,
                          icon: nav.icon,
                          screen: nav.screen,
                          order: nav.order || 1,
                          isVisible: nav.isVisible !== false
                        });
                        setNavModalOpen(true);
                      }}
                    >
                      <Edit2 size={13} />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* 2. Cuisines & Categories Carousel Ordering */}
      <div className="panel">
        <div className="panel-header">
          <div>
            <div className="panel-title">
              <Layers size={18} color="var(--primary-light)" />
              Cuisine Categories & Chips
            </div>
            <div className="panel-desc">Manage horizontal category filters (Pulao, Biryani, Mutton, Karahi, Zarda...)</div>
          </div>
          <button 
            className="btn btn-sm btn-primary"
            onClick={() => {
              setEditingCat(null);
              setCatForm({ name: '', icon: '🍲', image: '', order: (categories?.length || 0) + 1 });
              setCatModalOpen(true);
            }}
          >
            <Plus size={14} /> Add Category
          </button>
        </div>

        <div className="table-responsive">
          <table className="data-table">
            <thead>
              <tr>
                <th>Order</th>
                <th>Category Name</th>
                <th>Icon / Emoji</th>
                <th>Photo Preview</th>
                <th>Visibility</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {(categories || []).map(cat => (
                <tr key={cat.id}>
                  <td style={{ fontWeight: 800, color: '#C4B5FD', width: 60 }}>
                    #{cat.order}
                  </td>
                  <td style={{ fontWeight: 700 }}>
                    {cat.name}
                  </td>
                  <td style={{ fontSize: '20px' }}>
                    {cat.icon}
                  </td>
                  <td>
                    {cat.image ? (
                      <img 
                        src={cat.image} 
                        alt="" 
                        style={{ width: 36, height: 36, borderRadius: 8, objectFit: 'cover' }} 
                      />
                    ) : (
                      <span style={{ fontSize: 11, color: 'var(--text-dim)' }}>None</span>
                    )}
                  </td>
                  <td>
                    <label className="switch">
                      <input 
                        type="checkbox" 
                        checked={cat.isVisible !== false}
                        onChange={() => handleToggleCatVisibility(cat)}
                      />
                      <span className="slider"></span>
                    </label>
                  </td>
                  <td>
                    <div style={{ display: 'flex', gap: 6 }}>
                      <button 
                        className="btn btn-sm btn-secondary"
                        onClick={() => {
                          setEditingCat(cat);
                          setCatForm({
                            name: cat.name,
                            icon: cat.icon || '🍲',
                            image: cat.image || '',
                            order: cat.order || 1
                          });
                          setCatModalOpen(true);
                        }}
                      >
                        <Edit2 size={13} />
                      </button>
                      {cat.name !== 'All' && (
                        <button 
                          className="btn btn-sm btn-danger"
                          onClick={() => handleDeleteCat(cat.id)}
                        >
                          <Trash2 size={13} />
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Nav Modal */}
      {navModalOpen && (
        <div className="modal-overlay" onClick={() => setNavModalOpen(false)}>
          <div className="modal-content" onClick={e => e.stopPropagation()}>
            <div className="modal-header">
              <div className="modal-title">
                {editingNav ? 'Edit Navigation Tab' : 'Add Navigation Tab'}
              </div>
              <button 
                style={{ background: 'transparent', border: 'none', color: 'var(--text-muted)', cursor: 'pointer', fontSize: 18 }}
                onClick={() => setNavModalOpen(false)}
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleNavSubmit}>
              <div className="modal-body">
                <div className="form-group">
                  <label className="form-label">Tab Label *</label>
                  <input 
                    type="text" 
                    className="form-input" 
                    value={navForm.label}
                    onChange={e => setNavForm({ ...navForm, label: e.target.value })}
                    placeholder="e.g. Home, Cart, Orders, Account"
                    required
                  />
                </div>

                <div className="form-grid-2">
                  <div className="form-group">
                    <label className="form-label">Icon Name</label>
                    <input 
                      type="text" 
                      className="form-input" 
                      value={navForm.icon}
                      onChange={e => setNavForm({ ...navForm, icon: e.target.value })}
                      placeholder="home, shopping_bag, receipt_long, person"
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">Display Order</label>
                    <input 
                      type="number" 
                      className="form-input" 
                      value={navForm.order}
                      onChange={e => setNavForm({ ...navForm, order: Number(e.target.value) })}
                    />
                  </div>
                </div>
              </div>

              <div className="modal-footer">
                <button type="button" className="btn btn-secondary" onClick={() => setNavModalOpen(false)}>
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary" disabled={saving}>
                  {saving ? 'Saving...' : 'Save Tab'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Category Modal */}
      {catModalOpen && (
        <div className="modal-overlay" onClick={() => setCatModalOpen(false)}>
          <div className="modal-content" onClick={e => e.stopPropagation()}>
            <div className="modal-header">
              <div className="modal-title">
                {editingCat ? 'Edit Category' : 'Add Category'}
              </div>
              <button 
                style={{ background: 'transparent', border: 'none', color: 'var(--text-muted)', cursor: 'pointer', fontSize: 18 }}
                onClick={() => setCatModalOpen(false)}
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleCatSubmit}>
              <div className="modal-body">
                <div className="form-group">
                  <label className="form-label">Category Name *</label>
                  <input 
                    type="text" 
                    className="form-input" 
                    value={catForm.name}
                    onChange={e => setCatForm({ ...catForm, name: e.target.value })}
                    placeholder="e.g. Mutton Karahi"
                    required
                  />
                </div>

                <div className="form-grid-2">
                  <div className="form-group">
                    <label className="form-label">Emoji / Icon *</label>
                    <input 
                      type="text" 
                      className="form-input" 
                      value={catForm.icon}
                      onChange={e => setCatForm({ ...catForm, icon: e.target.value })}
                      placeholder="🍲, 🥩, 🍚..."
                      required
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">Display Order</label>
                    <input 
                      type="number" 
                      className="form-input" 
                      value={catForm.order}
                      onChange={e => setCatForm({ ...catForm, order: Number(e.target.value) })}
                    />
                  </div>
                </div>

                <div className="form-group">
                  <label className="form-label">Image URL</label>
                  <input 
                    type="url" 
                    className="form-input" 
                    value={catForm.image}
                    onChange={e => setCatForm({ ...catForm, image: e.target.value })}
                    placeholder="https://images.unsplash.com/photo-..."
                  />
                </div>
              </div>

              <div className="modal-footer">
                <button type="button" className="btn btn-secondary" onClick={() => setCatModalOpen(false)}>
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary" disabled={saving}>
                  {saving ? 'Saving...' : 'Save Category'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
