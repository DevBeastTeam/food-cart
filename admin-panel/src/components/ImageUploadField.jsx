import React, { useState, useRef } from 'react';
import { Upload, Image as ImageIcon, X, Check, Loader2 } from 'lucide-react';
import { api } from '../api';

export default function ImageUploadField({ 
  label = 'Image', 
  value = '', 
  onChange, 
  placeholder = 'https://... or upload from computer',
  category = 'dishes'
}) {
  const [uploading, setUploading] = useState(false);
  const [uploadSuccess, setUploadSuccess] = useState(false);
  const [error, setError] = useState(null);
  const fileInputRef = useRef(null);

  const handleFileChange = async (e) => {
    const file = e.target.files?.[0];
    if (!file) return;

    // Validate size (max 10MB)
    if (file.size > 10 * 1024 * 1024) {
      setError('File size exceeds 10MB limit');
      return;
    }

    try {
      setUploading(true);
      setError(null);
      setUploadSuccess(false);

      const formData = new FormData();
      formData.append('image', file);
      formData.append('name', file.name);
      formData.append('category', category);

      const res = await api.uploadMedia(formData);
      if (res && res.data && res.data.url) {
        onChange(res.data.url);
        setUploadSuccess(true);
        setTimeout(() => setUploadSuccess(false), 3000);
      } else {
        throw new Error('Upload succeeded but no URL was returned');
      }
    } catch (err) {
      console.error('File upload failed:', err);
      setError(err.message || 'Image upload failed. Please try again.');
    } finally {
      setUploading(false);
      // Reset input value so same file can be selected again if needed
      if (fileInputRef.current) fileInputRef.current.value = '';
    }
  };

  return (
    <div className="form-group" style={{ marginBottom: 16 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 6 }}>
        <label className="form-label" style={{ marginBottom: 0 }}>{label}</label>
        {value && (
          <button
            type="button"
            onClick={() => onChange('')}
            style={{ 
              background: 'transparent', 
              border: 'none', 
              color: '#EF4444', 
              fontSize: '11px', 
              cursor: 'pointer', 
              display: 'flex', 
              alignItems: 'center', 
              gap: 3 
            }}
          >
            <X size={12} /> Remove Image
          </button>
        )}
      </div>

      {/* Image Preview & Controls */}
      <div style={{ display: 'flex', gap: 12, alignItems: 'flex-start' }}>
        {/* Preview Thumbnail */}
        <div style={{
          width: 64,
          height: 64,
          borderRadius: 8,
          background: '#0B0F19',
          border: '1px solid var(--border-color)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          overflow: 'hidden',
          flexShrink: 0
        }}>
          {value ? (
            <img 
              src={value} 
              alt="Preview" 
              style={{ width: '100%', height: '100%', objectFit: 'cover' }}
              onError={(e) => {
                e.target.style.display = 'none';
              }}
            />
          ) : (
            <ImageIcon size={24} color="var(--text-dim)" />
          )}
        </div>

        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 8 }}>
          {/* Direct URL input */}
          <input 
            type="text" 
            className="form-input" 
            value={value}
            onChange={e => onChange(e.target.value)}
            placeholder={placeholder}
          />

          {/* Action Row: Upload file button */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, flexWrap: 'wrap' }}>
            <input 
              type="file" 
              ref={fileInputRef}
              onChange={handleFileChange}
              accept="image/jpeg,image/png,image/webp,image/gif,image/svg+xml"
              style={{ display: 'none' }}
            />
            <button
              type="button"
              className="btn btn-secondary btn-sm"
              onClick={() => fileInputRef.current?.click()}
              disabled={uploading}
              style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: '12px', padding: '6px 12px' }}
            >
              {uploading ? (
                <>
                  <Loader2 size={13} className="animate-spin" />
                  <span>Uploading image...</span>
                </>
              ) : (
                <>
                  <Upload size={13} />
                  <span>📁 Upload from Device / PC</span>
                </>
              )}
            </button>

            {uploadSuccess && (
              <span style={{ fontSize: '11.5px', color: '#10B981', display: 'flex', alignItems: 'center', gap: 4, fontWeight: 700 }}>
                <Check size={13} /> Uploaded & Attached!
              </span>
            )}

            {error && (
              <span style={{ fontSize: '11.5px', color: '#EF4444', fontWeight: 600 }}>
                {error}
              </span>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
