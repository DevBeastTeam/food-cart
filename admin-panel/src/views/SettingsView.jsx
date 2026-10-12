import React, { useState } from 'react';
import { Settings, Save, AlertTriangle, Building, Phone, Mail, Clock, DollarSign } from 'lucide-react';
import { api } from '../api';

export default function SettingsView({ settings, onRefresh, showToast }) {
  const [formData, setFormData] = useState({
    ...settings,
    emergencyAlert: {
      enabled: settings?.emergencyAlert?.enabled || false,
      message: settings?.emergencyAlert?.message || '',
      type: settings?.emergencyAlert?.type || 'warning'
    }
  });
  const [saving, setSaving] = useState(false);

  const handleChange = (field, val) => {
    setFormData(prev => ({ ...prev, [field]: val }));
  };

  const handleAlertChange = (field, val) => {
    setFormData(prev => ({
      ...prev,
      emergencyAlert: {
        ...prev.emergencyAlert,
        [field]: val
      }
    }));
  };

  const handleToggleStoreStatus = async () => {
    const nextStatus = !formData.storeOpen;
    setFormData(prev => ({ ...prev, storeOpen: nextStatus }));
    try {
      const res = await api.toggleStoreStatus(nextStatus);
      showToast(res.message);
      onRefresh();
    } catch (err) {
      showToast(err.message || 'Failed to update store status', 'error');
    }
  };

  const handleSaveAll = async (e) => {
    e.preventDefault();
    try {
      setSaving(true);
      await api.updateSettings(formData);
      showToast('Settings saved successfully!');
      onRefresh();
    } catch (err) {
      showToast(err.message || 'Failed to save settings', 'error');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <div>
          <h2 style={{ fontSize: 22, fontWeight: 800 }}>Global App Settings & Configurations</h2>
          <p style={{ fontSize: 13, color: 'var(--text-muted)' }}>
            Configure delivery fees, operating hours, emergency alerts, and Head Office credentials.
          </p>
        </div>
        <button className="btn btn-primary" onClick={handleSaveAll} disabled={saving}>
          <Save size={16} /> {saving ? 'Saving...' : 'Save Settings'}
        </button>
      </div>

      <form onSubmit={handleSaveAll}>
        {/* 1. Store Open/Closed Master Switch & Emergency Alerts */}
        <div className="panel" style={{ borderLeft: `4px solid ${formData.storeOpen ? '#10B981' : '#EF4444'}` }}>
          <div className="panel-header">
            <div>
              <div className="panel-title">
                <Clock size={18} color="var(--primary-light)" />
                Kitchen & Store Operational State
              </div>
              <div className="panel-desc">Master switch to accept or pause incoming orders in the mobile app</div>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <span style={{ fontSize: 13, fontWeight: 800, color: formData.storeOpen ? '#34D399' : '#F87171' }}>
                {formData.storeOpen ? 'STORE IS OPEN & ACCEPTING ORDERS' : 'STORE IS CURRENTLY CLOSED'}
              </span>
              <label className="switch">
                <input 
                  type="checkbox" 
                  checked={formData.storeOpen !== false}
                  onChange={handleToggleStoreStatus}
                />
                <span className="slider"></span>
              </label>
            </div>
          </div>

          {/* Emergency Maintenance Alert Broadcast */}
          <div style={{
            background: 'rgba(245, 158, 11, 0.1)',
            border: '1px solid rgba(245, 158, 11, 0.3)',
            borderRadius: '10px',
            padding: '16px',
            marginTop: 12
          }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontWeight: 800, color: '#FBBF24', fontSize: 14 }}>
                <AlertTriangle size={16} /> Broadcast Emergency Notice Banner
              </div>
              <label className="switch">
                <input 
                  type="checkbox" 
                  checked={formData.emergencyAlert?.enabled || false}
                  onChange={e => handleAlertChange('enabled', e.target.checked)}
                />
                <span className="slider"></span>
              </label>
            </div>

            <div className="form-group" style={{ marginBottom: 0 }}>
              <label className="form-label">Alert Message (Shown to all users on top of app)</label>
              <input 
                type="text" 
                className="form-input" 
                value={formData.emergencyAlert?.message || ''}
                onChange={e => handleAlertChange('message', e.target.value)}
                placeholder="e.g. Heavy rain in Lahore. Orders might experience a 10-15 min slight delay."
              />
            </div>
          </div>
        </div>

        {/* 2. Pricing & Delivery Rules */}
        <div className="panel">
          <div className="panel-title" style={{ marginBottom: 16 }}>
            <DollarSign size={18} color="#34D399" /> Fee Structure & Ordering Thresholds
          </div>

          <div className="form-grid-2">
            <div className="form-group">
              <label className="form-label">Currency Symbol</label>
              <input 
                type="text" 
                className="form-input" 
                value={formData.currency || 'Rs.'}
                onChange={e => handleChange('currency', e.target.value)}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Default Delivery Fee (Rs.)</label>
              <input 
                type="number" 
                className="form-input" 
                value={formData.defaultDeliveryFee || 49}
                onChange={e => handleChange('defaultDeliveryFee', Number(e.target.value))}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Standard Service Fee (Rs.)</label>
              <input 
                type="number" 
                className="form-input" 
                value={formData.serviceFee || 29}
                onChange={e => handleChange('serviceFee', Number(e.target.value))}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Minimum Order Requirement (Rs.)</label>
              <input 
                type="number" 
                className="form-input" 
                value={formData.minOrderAmount || 250}
                onChange={e => handleChange('minOrderAmount', Number(e.target.value))}
              />
            </div>
          </div>

          <div className="form-group">
            <label className="form-label">Operating Hours Text</label>
            <input 
              type="text" 
              className="form-input" 
              value={formData.operatingHours || '09:00 AM - 02:00 AM'}
              onChange={e => handleChange('operatingHours', e.target.value)}
              placeholder="09:00 AM - 02:00 AM"
            />
          </div>
        </div>

        {/* 3. Head Office & Support Contact Information */}
        <div className="panel">
          <div className="panel-title" style={{ marginBottom: 16 }}>
            <Building size={18} color="var(--primary-light)" /> Head Office & Customer Support Hub
          </div>

          <div className="form-grid-2">
            <div className="form-group">
              <label className="form-label">Customer Support Phone</label>
              <input 
                type="text" 
                className="form-input" 
                value={formData.supportPhone || '+92 300 8472910'}
                onChange={e => handleChange('supportPhone', e.target.value)}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Support Email Address</label>
              <input 
                type="email" 
                className="form-input" 
                value={formData.supportEmail || 'support@foodcourt.pk'}
                onChange={e => handleChange('supportEmail', e.target.value)}
              />
            </div>
          </div>

          <div className="form-group">
            <label className="form-label">Head Office Registered Address (Head Office Screen)</label>
            <input 
              type="text" 
              className="form-input" 
              value={formData.headOfficeAddress || ''}
              onChange={e => handleChange('headOfficeAddress', e.target.value)}
            />
          </div>

          <div className="form-grid-2">
            <div className="form-group">
              <label className="form-label">Head Office Landline / Phone</label>
              <input 
                type="text" 
                className="form-input" 
                value={formData.headOfficePhone || ''}
                onChange={e => handleChange('headOfficePhone', e.target.value)}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Central Kitchen Address</label>
              <input 
                type="text" 
                className="form-input" 
                value={formData.centralKitchenAddress || ''}
                onChange={e => handleChange('centralKitchenAddress', e.target.value)}
              />
            </div>
          </div>
        </div>
      </form>
    </div>
  );
}
