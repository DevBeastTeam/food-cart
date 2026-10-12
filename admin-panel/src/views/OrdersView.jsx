import React, { useState } from 'react';
import { 
  ShoppingBag, Search, Bike, Clock, CheckCircle2, 
  MapPin, Phone, User, MessageSquare, Trash2 
} from 'lucide-react';
import { api } from '../api';

export default function OrdersView({ orders, onRefresh, showToast }) {
  const [filter, setFilter] = useState('All');
  const [search, setSearch] = useState('');
  const [assignModalOrder, setAssignModalOrder] = useState(null);
  const [riderName, setRiderName] = useState('Captain Ali Raza');
  const [riderPhone, setRiderPhone] = useState('+92 302 9988776');
  const [savingRider, setSavingRider] = useState(false);

  const filteredOrders = (orders || []).filter(o => {
    const matchFilter = filter === 'All' || o.status.toLowerCase() === filter.toLowerCase();
    const query = search.trim().toLowerCase();
    const matchSearch = !query || 
      o.id.toLowerCase().includes(query) || 
      o.customerName?.toLowerCase().includes(query) || 
      o.customerPhone?.includes(query) ||
      o.restaurantName?.toLowerCase().includes(query);
    return matchFilter && matchSearch;
  });

  const handleStatusChange = async (orderId, newStatus) => {
    try {
      await api.updateOrderStatus(orderId, newStatus);
      showToast(`Order ${orderId} status changed to ${newStatus}`);
      onRefresh();
    } catch (err) {
      showToast(err.message || 'Failed to update order status', 'error');
    }
  };

  const handleAssignRiderSubmit = async (e) => {
    e.preventDefault();
    if (!assignModalOrder) return;
    try {
      setSavingRider(true);
      await api.assignRider(assignModalOrder.id, riderName, riderPhone);
      showToast(`Rider ${riderName} assigned to order ${assignModalOrder.id}`);
      setAssignModalOrder(null);
      onRefresh();
    } catch (err) {
      showToast(err.message || 'Failed to assign rider', 'error');
    } finally {
      setSavingRider(false);
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm(`Delete order ${id}?`)) return;
    try {
      await api.deleteOrder(id);
      showToast('Order removed');
      onRefresh();
    } catch (err) {
      showToast(err.message || 'Failed to delete order', 'error');
    }
  };

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <div>
          <h2 style={{ fontSize: 22, fontWeight: 800 }}>Live Orders & Kitchen Management</h2>
          <p style={{ fontSize: 13, color: 'var(--text-muted)' }}>
            Track active customer orders, dispatch delivery riders, update preparation times, and view customer notes.
          </p>
        </div>
      </div>

      {/* Tabs & Search */}
      <div className="panel" style={{ padding: '16px 20px', marginBottom: 20 }}>
        <div style={{ display: 'flex', gap: 16, alignItems: 'center', flexWrap: 'wrap', justifyContent: 'space-between' }}>
          {/* Status Tabs */}
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
            {['All', 'Accepted', 'Preparing', 'On the Way', 'Delivered', 'Cancelled'].map(st => {
              const count = st === 'All' ? orders.length : orders.filter(o => o.status === st).length;
              const isActive = filter === st;
              return (
                <button
                  key={st}
                  className={`btn btn-sm ${isActive ? 'btn-primary' : 'btn-secondary'}`}
                  onClick={() => setFilter(st)}
                  style={{ borderRadius: 20 }}
                >
                  {st} ({count})
                </button>
              );
            })}
          </div>

          {/* Search box */}
          <div style={{ position: 'relative', width: 280 }}>
            <Search size={15} style={{ position: 'absolute', left: 12, top: 12, color: 'var(--text-dim)' }} />
            <input 
              type="text" 
              className="form-input" 
              placeholder="Search by ID, customer, phone..."
              style={{ paddingLeft: 36, paddingRight: 12 }}
              value={search}
              onChange={e => setSearch(e.target.value)}
            />
          </div>
        </div>
      </div>

      {/* Orders List / Cards */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
        {filteredOrders.length === 0 ? (
          <div className="panel" style={{ textAlign: 'center', padding: '40px', color: 'var(--text-muted)' }}>
            No orders found under {filter} status.
          </div>
        ) : (
          filteredOrders.map(order => (
            <div 
              key={order.id}
              className="panel"
              style={{
                marginBottom: 0,
                borderLeft: `4px solid ${
                  order.status === 'Delivered' ? '#10B981' :
                  order.status === 'On the Way' ? '#A855F7' :
                  order.status === 'Preparing' ? '#F59E0B' :
                  order.status === 'Accepted' ? '#3B82F6' : '#EF4444'
                }`
              }}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: 12, marginBottom: 14 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                  <div style={{
                    width: 44,
                    height: 44,
                    borderRadius: 10,
                    background: 'rgba(124, 58, 237, 0.15)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    color: '#A78BFA'
                  }}>
                    <ShoppingBag size={22} />
                  </div>
                  <div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                      <span style={{ fontSize: 16, fontWeight: 800, color: '#FFFFFF' }}>{order.id}</span>
                      <span className={`badge badge-${order.status?.toLowerCase().replace(/\s+/g, '')}`}>
                        {order.status}
                      </span>
                      {order.isDaigBooking && (
                        <span style={{ 
                          fontSize: '11px', 
                          background: 'rgba(245, 158, 11, 0.2)', 
                          color: '#FBBF24', 
                          padding: '2px 8px', 
                          borderRadius: 4, 
                          fontWeight: 700 
                        }}>
                          👑 Daig Catering ({order.occasion || 'Event'})
                        </span>
                      )}
                    </div>
                    <div style={{ fontSize: '11.5px', color: 'var(--text-dim)', marginTop: 2 }}>
                      Placed {new Date(order.orderDate).toLocaleString()} • {order.restaurantName}
                    </div>
                  </div>
                </div>

                <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                  <div style={{ textAlign: 'right' }}>
                    <div style={{ fontSize: 18, fontWeight: 900, color: '#34D399' }}>
                      Rs. {order.totalAmount?.toLocaleString()}
                    </div>
                    <div style={{ fontSize: '11px', color: 'var(--text-dim)' }}>
                      Prep time: {order.prepTime || '25-35 min'}
                    </div>
                  </div>
                  <button 
                    className="btn btn-sm btn-danger"
                    onClick={() => handleDelete(order.id)}
                    title="Delete order"
                  >
                    <Trash2 size={13} />
                  </button>
                </div>
              </div>

              {/* Order Items */}
              <div style={{ 
                background: '#0E1424', 
                padding: '12px 16px', 
                borderRadius: '8px', 
                marginBottom: 14,
                border: '1px solid #1E283D' 
              }}>
                <div style={{ fontSize: 12, fontWeight: 700, color: 'var(--text-muted)', marginBottom: 6 }}>
                  ORDER ITEMS:
                </div>
                <div style={{ fontSize: 13, color: '#E2E8F0', display: 'flex', flexWrap: 'wrap', gap: 8 }}>
                  {order.items.map((it, idx) => (
                    <span 
                      key={idx}
                      style={{ 
                        background: 'rgba(255, 255, 255, 0.05)', 
                        padding: '3px 8px', 
                        borderRadius: 4, 
                        border: '1px solid rgba(255, 255, 255, 0.1)' 
                      }}
                    >
                      {it}
                    </span>
                  ))}
                </div>
                {order.notes && (
                  <div style={{ marginTop: 8, fontSize: '12px', color: '#FDE68A', display: 'flex', alignItems: 'center', gap: 6 }}>
                    <MessageSquare size={13} /> Note: {order.notes}
                  </div>
                )}
              </div>

              {/* Details & Action footer */}
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 14 }}>
                <div style={{ display: 'flex', gap: 20, flexWrap: 'wrap', fontSize: 12, color: 'var(--text-muted)' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                    <User size={14} color="var(--primary)" />
                    <strong>{order.customerName}</strong> ({order.customerPhone})
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                    <MapPin size={14} color="var(--primary)" />
                    <span>{order.deliveryAddress}</span>
                  </div>
                  {order.riderName && (
                    <div style={{ display: 'flex', alignItems: 'center', gap: 6, color: '#C084FC' }}>
                      <Bike size={14} />
                      <span>Rider: <strong>{order.riderName}</strong> ({order.riderPhone})</span>
                    </div>
                  )}
                </div>

                {/* Pipeline Controls */}
                <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
                  <select 
                    className="form-select"
                    style={{ width: 'auto', padding: '6px 12px', fontSize: 12 }}
                    value={order.status}
                    onChange={e => handleStatusChange(order.id, e.target.value)}
                  >
                    <option value="Accepted">Accepted</option>
                    <option value="Preparing">Preparing (Kitchen)</option>
                    <option value="On the Way">On the Way</option>
                    <option value="Delivered">Delivered</option>
                    <option value="Cancelled">Cancelled</option>
                  </select>

                  {order.status !== 'Delivered' && order.status !== 'Cancelled' && (
                    <button 
                      className="btn btn-sm btn-secondary"
                      onClick={() => setAssignModalOrder(order)}
                    >
                      <Bike size={14} /> Assign Rider
                    </button>
                  )}
                </div>
              </div>
            </div>
          ))
        )}
      </div>

      {/* Assign Rider Modal */}
      {assignModalOrder && (
        <div className="modal-overlay" onClick={() => setAssignModalOrder(null)}>
          <div className="modal-content" onClick={e => e.stopPropagation()}>
            <div className="modal-header">
              <div className="modal-title">
                Assign Rider to Order {assignModalOrder.id}
              </div>
              <button 
                style={{ background: 'transparent', border: 'none', color: 'var(--text-muted)', cursor: 'pointer', fontSize: 18 }}
                onClick={() => setAssignModalOrder(null)}
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleAssignRiderSubmit}>
              <div className="modal-body">
                <div className="form-group">
                  <label className="form-label">Rider Name</label>
                  <input 
                    type="text" 
                    className="form-input" 
                    value={riderName}
                    onChange={e => setRiderName(e.target.value)}
                    required
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Rider Phone</label>
                  <input 
                    type="text" 
                    className="form-input" 
                    value={riderPhone}
                    onChange={e => setRiderPhone(e.target.value)}
                    required
                  />
                </div>
              </div>

              <div className="modal-footer">
                <button type="button" className="btn btn-secondary" onClick={() => setAssignModalOrder(null)}>
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary" disabled={savingRider}>
                  {savingRider ? 'Assigning...' : 'Confirm Rider Assignment'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
