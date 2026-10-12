import React, { useState } from 'react';
import { 
  DollarSign, ShoppingBag, Clock, CheckCircle2, 
  Users, Soup, ArrowUpRight, TrendingUp, AlertTriangle, RefreshCw
} from 'lucide-react';
import { api } from '../api';

export default function DashboardView({ stats, orders, onRefresh, onSelectTab, showToast }) {
  const [updatingId, setUpdatingId] = useState(null);

  if (!stats) {
    return (
      <div style={{ textAlign: 'center', padding: '60px 0', color: 'var(--text-muted)' }}>
        <RefreshCw className="animate-spin" size={32} style={{ margin: '0 auto 12px' }} />
        <p>Loading real-time dashboard analytics...</p>
      </div>
    );
  }

  const { metrics, ordersByStatus } = stats;

  const handleQuickStatusChange = async (orderId, newStatus) => {
    try {
      setUpdatingId(orderId);
      await api.updateOrderStatus(orderId, newStatus);
      showToast(`Order ${orderId} updated to ${newStatus}`);
      onRefresh();
    } catch (err) {
      showToast(err.message || 'Failed to update order', 'error');
    } finally {
      setUpdatingId(null);
    }
  };

  return (
    <div>
      {/* Emergency alert banner if enabled */}
      {stats.systemAlert?.enabled && (
        <div style={{
          background: 'rgba(245, 158, 11, 0.15)',
          border: '1px solid rgba(245, 158, 11, 0.4)',
          borderRadius: 'var(--radius-md)',
          padding: '14px 20px',
          marginBottom: '24px',
          display: 'flex',
          alignItems: 'center',
          gap: '12px',
          color: '#FDE68A'
        }}>
          <AlertTriangle color="#F59E0B" size={20} />
          <div style={{ flex: 1, fontSize: '13.5px' }}>
            <strong>Active App Alert:</strong> {stats.systemAlert.message}
          </div>
          <button 
            className="btn btn-sm btn-secondary"
            onClick={() => onSelectTab('settings')}
          >
            Manage Alert
          </button>
        </div>
      )}

      {/* Main KPI Stats Grid */}
      <div className="stats-grid">
        <div className="stat-card">
          <div>
            <div className="stat-label">Total Revenue</div>
            <div className="stat-value">Rs. {(metrics?.totalRevenue || 0).toLocaleString()}</div>
            <div className="stat-subtext" style={{ color: '#34D399' }}>
              <TrendingUp size={12} style={{ display: 'inline', marginRight: 4 }} />
              Live Order Volume
            </div>
          </div>
          <div className="stat-icon-wrap stat-icon-emerald">
            <DollarSign size={22} />
          </div>
        </div>

        <div className="stat-card">
          <div>
            <div className="stat-label">Total Orders</div>
            <div className="stat-value">{metrics?.totalOrders || 0}</div>
            <div className="stat-subtext">
              {metrics?.activeOrders || 0} currently processing
            </div>
          </div>
          <div className="stat-icon-wrap stat-icon-purple">
            <ShoppingBag size={22} />
          </div>
        </div>

        <div className="stat-card">
          <div>
            <div className="stat-label">Live Active Orders</div>
            <div className="stat-value" style={{ color: '#FBBF24' }}>
              {metrics?.activeOrders || 0}
            </div>
            <div className="stat-subtext">In kitchen & on route</div>
          </div>
          <div className="stat-icon-wrap stat-icon-gold">
            <Clock size={22} />
          </div>
        </div>

        <div className="stat-card">
          <div>
            <div className="stat-label">Daig Bookings</div>
            <div className="stat-value" style={{ color: '#C084FC' }}>
              {metrics?.daigBookings || 0}
            </div>
            <div className="stat-subtext">Pakwan Center Dawats</div>
          </div>
          <div className="stat-icon-wrap stat-icon-purple">
            <Soup size={22} />
          </div>
        </div>

        <div className="stat-card">
          <div>
            <div className="stat-label">Registered Users</div>
            <div className="stat-value">{metrics?.totalUsers || 0}</div>
            <div className="stat-subtext">{metrics?.totalRiders || 0} Active delivery riders</div>
          </div>
          <div className="stat-icon-wrap stat-icon-blue">
            <Users size={22} />
          </div>
        </div>
      </div>

      {/* Live Kitchen & Pipeline Distribution */}
      <div className="panel" style={{ marginBottom: 28 }}>
        <div className="panel-header">
          <div>
            <div className="panel-title">
              <Clock size={18} color="var(--primary-light)" />
              Live Kitchen Pipeline & Order Status
            </div>
            <div className="panel-desc">Real-time status breakdown across all active FoodCourt orders</div>
          </div>
          <button className="btn btn-sm btn-secondary" onClick={onRefresh}>
            <RefreshCw size={14} /> Refresh
          </button>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(160px, 1fr))', gap: '16px' }}>
          <div style={{ background: '#0F1524', padding: '16px', borderRadius: '12px', border: '1px solid #242E42' }}>
            <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>Accepted (New)</div>
            <div style={{ fontSize: '24px', fontWeight: 800, color: '#60A5FA', marginTop: '4px' }}>
              {ordersByStatus?.Accepted || 0}
            </div>
            <div style={{ fontSize: '11px', color: 'var(--text-dim)' }}>Ready for prep</div>
          </div>

          <div style={{ background: '#0F1524', padding: '16px', borderRadius: '12px', border: '1px solid #242E42' }}>
            <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>In Kitchen (Cooking)</div>
            <div style={{ fontSize: '24px', fontWeight: 800, color: '#FBBF24', marginTop: '4px' }}>
              {ordersByStatus?.Preparing || 0}
            </div>
            <div style={{ fontSize: '11px', color: 'var(--text-dim)' }}>Dum & packaging</div>
          </div>

          <div style={{ background: '#0F1524', padding: '16px', borderRadius: '12px', border: '1px solid #242E42' }}>
            <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>On the Way (Rider)</div>
            <div style={{ fontSize: '24px', fontWeight: 800, color: '#C084FC', marginTop: '4px' }}>
              {ordersByStatus?.['On the Way'] || 0}
            </div>
            <div style={{ fontSize: '11px', color: 'var(--text-dim)' }}>Dispatched</div>
          </div>

          <div style={{ background: '#0F1524', padding: '16px', borderRadius: '12px', border: '1px solid #242E42' }}>
            <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>Delivered Today</div>
            <div style={{ fontSize: '24px', fontWeight: 800, color: '#34D399', marginTop: '4px' }}>
              {ordersByStatus?.Delivered || 0}
            </div>
            <div style={{ fontSize: '11px', color: 'var(--text-dim)' }}>Completed</div>
          </div>
        </div>
      </div>

      {/* Recent Orders Action Table */}
      <div className="panel">
        <div className="panel-header">
          <div>
            <div className="panel-title">
              <ShoppingBag size={18} color="var(--primary-light)" />
              Live Orders Feed (Quick Actions)
            </div>
            <div className="panel-desc">Advance orders through the preparation & delivery pipeline with 1 click</div>
          </div>
          <button className="btn btn-sm btn-primary" onClick={() => onSelectTab('orders')}>
            View All Orders <ArrowUpRight size={14} />
          </button>
        </div>

        <div className="table-responsive">
          <table className="data-table">
            <thead>
              <tr>
                <th>Order ID</th>
                <th>Customer & Location</th>
                <th>Items & Type</th>
                <th>Amount</th>
                <th>Status</th>
                <th>Quick Pipeline Action</th>
              </tr>
            </thead>
            <tbody>
              {(!orders || orders.length === 0) ? (
                <tr>
                  <td colSpan="6" style={{ textAlign: 'center', padding: '30px', color: 'var(--text-muted)' }}>
                    No orders currently in system.
                  </td>
                </tr>
              ) : (
                orders.slice(0, 6).map(order => (
                  <tr key={order.id}>
                    <td>
                      <span style={{ fontWeight: 800, color: '#C4B5FD' }}>{order.id}</span>
                      {order.isDaigBooking && (
                        <span style={{ 
                          display: 'block', 
                          fontSize: '10px', 
                          color: '#FBBF24', 
                          fontWeight: 700 
                        }}>
                          👑 DAIG BOOKING
                        </span>
                      )}
                    </td>
                    <td>
                      <div style={{ fontWeight: 700 }}>{order.customerName}</div>
                      <div style={{ fontSize: '11.5px', color: 'var(--text-dim)' }}>
                        {order.deliveryAddress ? order.deliveryAddress.split('•').pop().trim() : 'Lahore'}
                      </div>
                    </td>
                    <td>
                      <div style={{ fontSize: '12px', maxWidth: 220, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                        {order.items.join(', ')}
                      </div>
                      <div style={{ fontSize: '11px', color: 'var(--text-dim)' }}>
                        {order.restaurantName}
                      </div>
                    </td>
                    <td style={{ fontWeight: 800, color: '#FFFFFF' }}>
                      Rs. {order.totalAmount?.toLocaleString()}
                    </td>
                    <td>
                      <span className={`badge badge-${order.status?.toLowerCase().replace(/\s+/g, '')}`}>
                        {order.status}
                      </span>
                    </td>
                    <td>
                      <div style={{ display: 'flex', gap: '6px' }}>
                        {order.status === 'Accepted' && (
                          <button 
                            className="btn btn-sm btn-secondary"
                            disabled={updatingId === order.id}
                            onClick={() => handleQuickStatusChange(order.id, 'Preparing')}
                          >
                            Start Cooking
                          </button>
                        )}
                        {order.status === 'Preparing' && (
                          <button 
                            className="btn btn-sm btn-primary"
                            disabled={updatingId === order.id}
                            onClick={() => handleQuickStatusChange(order.id, 'On the Way')}
                          >
                            Dispatch Rider
                          </button>
                        )}
                        {order.status === 'On the Way' && (
                          <button 
                            className="btn btn-sm"
                            style={{ background: 'rgba(16, 185, 129, 0.2)', color: '#34D399', border: '1px solid rgba(16, 185, 129, 0.3)' }}
                            disabled={updatingId === order.id}
                            onClick={() => handleQuickStatusChange(order.id, 'Delivered')}
                          >
                            Mark Delivered
                          </button>
                        )}
                        {order.status === 'Delivered' && (
                          <span style={{ fontSize: '12px', color: '#10B981', display: 'flex', alignItems: 'center', gap: 4 }}>
                            <CheckCircle2 size={14} /> Completed
                          </span>
                        )}
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
