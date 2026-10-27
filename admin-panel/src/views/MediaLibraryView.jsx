import React, { useState } from 'react';
import { Image, Upload, Plus, Trash2, Copy, Check, ExternalLink } from 'lucide-react';
import { api } from '../api';
import CustomDropdown from '../components/CustomDropdown';

export default function MediaLibraryView({ media, onRefresh, showToast }) {
  const [selectedFile, setSelectedFile] = useState(null);
  const [mediaName, setMediaName] = useState('');
  const [mediaCategory, setMediaCategory] = useState('dishes');
  const [externalUrl, setExternalUrl] = useState('');
  const [uploading, setUploading] = useState(false);
  const [copiedId, setCopiedId] = useState(null);

  const handleFileUpload = async (e) => {
    e.preventDefault();
    if (!selectedFile) {
      showToast('Please select an image file to upload', 'error');
      return;
    }

    const formData = new FormData();
    formData.append('image', selectedFile);
    formData.append('name', mediaName || selectedFile.name);
    formData.append('category', mediaCategory);

    try {
      setUploading(true);
      await api.uploadMedia(formData);
      showToast('Image uploaded successfully to server!');
      setSelectedFile(null);
      setMediaName('');
      onRefresh();
    } catch (err) {
      showToast(err.message || 'Upload failed', 'error');
    } finally {
      setUploading(false);
    }
  };

  const handleAddUrl = async (e) => {
    e.preventDefault();
    if (!externalUrl.trim()) return;

    try {
      setUploading(true);
      await api.addMediaUrl(mediaName || 'External Image', externalUrl.trim(), mediaCategory);
      showToast('Media URL added to library');
      setExternalUrl('');
      setMediaName('');
      onRefresh();
    } catch (err) {
      showToast(err.message || 'Failed to add URL', 'error');
    } finally {
      setUploading(false);
    }
  };

  const handleCopyUrl = (item) => {
    navigator.clipboard.writeText(item.url);
    setCopiedId(item.id);
    showToast('Image URL copied to clipboard');
    setTimeout(() => setCopiedId(null), 2000);
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Delete this media asset?')) return;
    try {
      await api.deleteMedia(id);
      showToast('Media asset removed');
      onRefresh();
    } catch (err) {
      showToast(err.message || 'Failed to delete media', 'error');
    }
  };

  return (
    <div>
      <div style={{ marginBottom: 24 }}>
        <h2 style={{ fontSize: 22, fontWeight: 800 }}>Media & Image Library</h2>
        <p style={{ fontSize: 13, color: 'var(--text-muted)' }}>
          Upload new dish photos, banners, and app graphics or register external CDN URLs.
        </p>
      </div>

      {/* Upload panels grid */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))', gap: '20px', marginBottom: 24 }}>
        {/* Physical File Upload */}
        <div className="panel" style={{ marginBottom: 0 }}>
          <div className="panel-title" style={{ marginBottom: 16 }}>
            <Upload size={18} color="var(--primary-light)" /> Upload Image File to Server
          </div>
          <form onSubmit={handleFileUpload}>
            <div className="form-group">
              <label className="form-label">Select Image File (PNG, JPG, WEBP)</label>
              <input 
                type="file" 
                accept="image/*"
                className="form-input"
                onChange={e => {
                  if (e.target.files?.[0]) {
                    setSelectedFile(e.target.files[0]);
                    if (!mediaName) setMediaName(e.target.files[0].name.split('.')[0]);
                  }
                }}
              />
            </div>

            <div className="form-grid-2">
              <div className="form-group">
                <label className="form-label">Asset Title</label>
                <input 
                  type="text" 
                  className="form-input" 
                  value={mediaName}
                  onChange={e => setMediaName(e.target.value)}
                  placeholder="e.g. Special Beef Pulao"
                />
              </div>

              <div className="form-group">
                <label className="form-label">Category</label>
                <CustomDropdown
                  value={mediaCategory}
                  onChange={val => setMediaCategory(val)}
                  options={[
                    { value: 'dishes', label: 'Food Dishes' },
                    { value: 'banners', label: 'Banners & Promos' },
                    { value: 'facilities', label: 'Head Office & Central Kitchen' },
                    { value: 'general', label: 'General' },
                  ]}
                />
              </div>
            </div>

            <button type="submit" className="btn btn-primary" style={{ width: '100%' }} disabled={uploading}>
              <Upload size={16} /> {uploading ? 'Uploading...' : 'Upload Image'}
            </button>
          </form>
        </div>

        {/* Register External Image URL */}
        <div className="panel" style={{ marginBottom: 0 }}>
          <div className="panel-title" style={{ marginBottom: 16 }}>
            <ExternalLink size={18} color="#FBBF24" /> Register External Photo URL (CDN)
          </div>
          <form onSubmit={handleAddUrl}>
            <div className="form-group">
              <label className="form-label">Image URL</label>
              <input 
                type="url" 
                className="form-input" 
                value={externalUrl}
                onChange={e => setExternalUrl(e.target.value)}
                placeholder="https://images.unsplash.com/photo-..."
                required
              />
            </div>

            <div className="form-grid-2">
              <div className="form-group">
                <label className="form-label">Asset Title</label>
                <input 
                  type="text" 
                  className="form-input" 
                  value={mediaName}
                  onChange={e => setMediaName(e.target.value)}
                  placeholder="e.g. Royal Wedding Deg"
                />
              </div>

              <div className="form-group">
                <label className="form-label">Category</label>
                <CustomDropdown
                  value={mediaCategory}
                  onChange={val => setMediaCategory(val)}
                  options={[
                    { value: 'dishes', label: 'Food Dishes' },
                    { value: 'banners', label: 'Banners & Promos' },
                    { value: 'facilities', label: 'Head Office & Central Kitchen' },
                    { value: 'general', label: 'General' },
                  ]}
                />
              </div>
            </div>

            <button type="submit" className="btn btn-secondary" style={{ width: '100%' }} disabled={uploading}>
              <Plus size={16} /> Save URL to Library
            </button>
          </form>
        </div>
      </div>

      {/* Media Gallery Grid */}
      <div className="panel">
        <div className="panel-header">
          <div>
            <div className="panel-title">
              <Image size={18} color="var(--primary-light)" />
              Uploaded Assets Gallery ({media?.length || 0})
            </div>
            <div className="panel-desc">Click 'Copy URL' to paste into dish menus, promo banners, or Daig items</div>
          </div>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(200px, 1fr))', gap: '16px' }}>
          {(!media || media.length === 0) ? (
            <div style={{ textAlign: 'center', padding: '30px', color: 'var(--text-muted)', gridColumn: '1 / -1' }}>
              No media assets registered.
            </div>
          ) : (
            media.map(item => (
              <div 
                key={item.id}
                style={{
                  background: '#0E1424',
                  border: '1px solid #242E42',
                  borderRadius: '12px',
                  overflow: 'hidden',
                  display: 'flex',
                  flexDirection: 'column'
                }}
              >
                <div style={{ height: 130, position: 'relative', background: '#080C14' }}>
                  <img 
                    src={item.url} 
                    alt={item.name} 
                    style={{ width: '100%', height: '100%', objectFit: 'cover' }} 
                  />
                  <span style={{
                    position: 'absolute',
                    top: 8,
                    left: 8,
                    background: 'rgba(0,0,0,0.6)',
                    color: '#DDD6FE',
                    fontSize: '10px',
                    fontWeight: 700,
                    padding: '2px 6px',
                    borderRadius: 4
                  }}>
                    {item.category}
                  </span>
                </div>

                <div style={{ padding: '12px', flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
                  <div>
                    <div style={{ fontSize: '13px', fontWeight: 700, color: 'white', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                      {item.name}
                    </div>
                    <div style={{ fontSize: '11px', color: 'var(--text-dim)', marginTop: 2 }}>
                      {new Date(item.uploadedAt).toLocaleDateString()}
                    </div>
                  </div>

                  <div style={{ display: 'flex', gap: 6, marginTop: 12 }}>
                    <button 
                      className="btn btn-sm btn-secondary" 
                      style={{ flex: 1 }}
                      onClick={() => handleCopyUrl(item)}
                    >
                      {copiedId === item.id ? <Check size={12} color="#10B981" /> : <Copy size={12} />}
                      {copiedId === item.id ? 'Copied' : 'Copy URL'}
                    </button>
                    <button 
                      className="btn btn-sm btn-danger"
                      onClick={() => handleDelete(item.id)}
                    >
                      <Trash2 size={12} />
                    </button>
                  </div>
                </div>
              </div>
            ))
          )}
        </div>
      </div>
    </div>
  );
}
