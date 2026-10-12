import React, { useState, useEffect } from 'react';
import { 
  LayoutDashboard, Type, Compass, Store, Utensils, Soup, 
  Tag, Image, ShoppingBag, Users, FolderOpen, Settings as SettingsIcon,
  LogOut, Menu, X, Bell, RefreshCw, CheckCircle, AlertTriangle
} from 'lucide-react';

import { api, getAuthToken, setAuthToken, getCurrentAdminUser, setCurrentAdminUser } from './api';

import DashboardView from './views/DashboardView';
import ContentHeadingsView from './views/ContentHeadingsView';
import NavigationMenusView from './views/NavigationMenusView';
import RestaurantsView from './views/RestaurantsView';
import MenuItemsView from './views/MenuItemsView';
import DaigDishesView from './views/DaigDishesView';
import DealsOffersView from './views/DealsOffersView';
import BannersView from './views/BannersView';
import OrdersView from './views/OrdersView';
import UsersView from './views/UsersView';
import MediaLibraryView from './views/MediaLibraryView';
import SettingsView from './views/SettingsView';
import LoginModal from './views/LoginModal';

export default function App() {
  const [currentUser, setCurrentUser] = useState(getCurrentAdminUser());
  const [activeTab, setActiveTab] = useState('dashboard');
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [toast, setToast] = useState(null);

  // App State Data
  const [stats, setStats] = useState(null);
  const [orders, setOrders] = useState([]);
  const [restaurants, setRestaurants] = useState([]);
  const [foodItems, setFoodItems] = useState([]);
  const [daigDishes, setDaigDishes] = useState([]);
  const [deals, setDeals] = useState([]);
  const [banners, setBanners] = useState([]);
  const [content, setContent] = useState(null);
  const [navigation, setNavigation] = useState([]);
  const [categories, setCategories] = useState([]);
  const [users, setUsers] = useState([]);
  const [media, setMedia] = useState([]);
  const [settings, setSettings] = useState(null);
  const [loading, setLoading] = useState(false);

  const showToast = (message, type = 'success') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 3500);
  };

  const loadAllData = async () => {
    try {
      setLoading(true);
      const [
        statsRes,
        ordersRes,
        restaurantsRes,
        foodItemsRes,
        daigRes,
        dealsRes,
        bannersRes,
        contentRes,
        navRes,
        catRes,
        usersRes,
        mediaRes,
        settingsRes
      ] = await Promise.all([
        api.getStats().catch(() => ({ data: null })),
        api.getOrders().catch(() => ({ data: [] })),
        api.getRestaurants(true).catch(() => ({ data: [] })),
        api.getFoodItems(true).catch(() => ({ data: [] })),
        api.getDaigItems(true).catch(() => ({ data: [] })),
        api.getDeals(true).catch(() => ({ data: [] })),
        api.getBanners(true).catch(() => ({ data: [] })),
        api.getContent().catch(() => ({ data: null })),
        api.getNavigation(true).catch(() => ({ data: [] })),
        api.getCategories(true).catch(() => ({ data: [] })),
        api.getUsers().catch(() => ({ data: [] })),
        api.getMedia().catch(() => ({ data: [] })),
        api.getSettings().catch(() => ({ data: null }))
      ]);

      if (statsRes?.data) setStats(statsRes.data);
      if (ordersRes?.data) setOrders(ordersRes.data);
      if (restaurantsRes?.data) setRestaurants(restaurantsRes.data);
      if (foodItemsRes?.data) setFoodItems(foodItemsRes.data);
      if (daigRes?.data) setDaigDishes(daigRes.data);
      if (dealsRes?.data) setDeals(dealsRes.data);
      if (bannersRes?.data) setBanners(bannersRes.data);
      if (contentRes?.data) setContent(contentRes.data);
      if (navRes?.data) setNavigation(navRes.data);
      if (catRes?.data) setCategories(catRes.data);
      if (usersRes?.data) setUsers(usersRes.data);
      if (mediaRes?.data) setMedia(mediaRes.data);
      if (settingsRes?.data) setSettings(settingsRes.data);
    } catch (err) {
      console.error('Error fetching admin data:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (currentUser) {
      loadAllData();
      // Auto polling every 15s for live orders
      const interval = setInterval(loadAllData, 15000);
      return () => clearInterval(interval);
    }
  }, [currentUser]);

  const handleLogout = () => {
    setAuthToken(null);
    setCurrentAdminUser(null);
    setCurrentUser(null);
  };

  if (!currentUser) {
    return <LoginModal onLoginSuccess={(u) => setCurrentUser(u)} showToast={showToast} />;
  }

  const navMenuItems = [
    { id: 'dashboard', label: 'Dashboard', icon: LayoutDashboard, badge: orders.filter(o => o.status !== 'Delivered' && o.status !== 'Cancelled').length || null },
    { id: 'content', label: 'Headings & Content', icon: Type },
    { id: 'navigation', label: 'Navigation & Menus', icon: Compass },
    { id: 'restaurants', label: 'Restaurants & Hubs', icon: Store, count: restaurants.length },
    { id: 'menu', label: 'Food Items Menu', icon: Utensils, count: foodItems.length },
    { id: 'daig', label: 'Pakwan Center (Daig)', icon: Soup, count: daigDishes.length },
    { id: 'deals', label: 'Deals & Offers', icon: Tag, count: deals.length },
    { id: 'banners', label: 'Hero Banners', icon: Image, count: banners.length },
    { id: 'orders', label: 'Live Orders', icon: ShoppingBag, badge: orders.filter(o => o.status === 'Accepted' || o.status === 'Preparing').length || null },
    { id: 'users', label: 'User Management', icon: Users, count: users.length },
    { id: 'media', label: 'Media Library', icon: FolderOpen, count: media.length },
    { id: 'settings', label: 'App Settings', icon: SettingsIcon }
  ];

  return (
    <div className="app-layout">
      {/* Toast Alert */}
      {toast && (
        <div className="toast-notice" style={{ borderLeftColor: toast.type === 'error' ? '#EF4444' : '#10B981' }}>
          {toast.type === 'error' ? <AlertTriangle size={18} color="#EF4444" /> : <CheckCircle size={18} color="#10B981" />}
          <span>{toast.message}</span>
        </div>
      )}

      {/* Sidebar Navigation */}
      <aside className={`sidebar ${mobileMenuOpen ? 'open' : ''}`}>
        <div className="sidebar-header">
          <div className="brand-icon">
            <Utensils size={22} color="white" />
          </div>
          <div>
            <div className="brand-title">Food Court</div>
            <div className="brand-badge">ADMIN CONTROL HUB</div>
          </div>
        </div>

        <nav className="sidebar-nav">
          <div className="nav-section-title">Main Operations</div>
          {navMenuItems.slice(0, 3).map(item => {
            const Icon = item.icon;
            const isActive = activeTab === item.id;
            return (
              <div 
                key={item.id} 
                className={`nav-item ${isActive ? 'active' : ''}`}
                onClick={() => {
                  setActiveTab(item.id);
                  setMobileMenuOpen(false);
                }}
              >
                <Icon size={18} className="nav-icon" />
                <span>{item.label}</span>
                {item.badge && <span className="nav-badge">{item.badge}</span>}
              </div>
            );
          })}

          <div className="nav-section-title">Catalog & Menus</div>
          {navMenuItems.slice(3, 8).map(item => {
            const Icon = item.icon;
            const isActive = activeTab === item.id;
            return (
              <div 
                key={item.id} 
                className={`nav-item ${isActive ? 'active' : ''}`}
                onClick={() => {
                  setActiveTab(item.id);
                  setMobileMenuOpen(false);
                }}
              >
                <Icon size={18} className="nav-icon" />
                <span>{item.label}</span>
                {item.count !== undefined && (
                  <span style={{ marginLeft: 'auto', fontSize: '11px', color: 'var(--text-dim)' }}>
                    {item.count}
                  </span>
                )}
              </div>
            );
          })}

          <div className="nav-section-title">Operations & System</div>
          {navMenuItems.slice(8).map(item => {
            const Icon = item.icon;
            const isActive = activeTab === item.id;
            return (
              <div 
                key={item.id} 
                className={`nav-item ${isActive ? 'active' : ''}`}
                onClick={() => {
                  setActiveTab(item.id);
                  setMobileMenuOpen(false);
                }}
              >
                <Icon size={18} className="nav-icon" />
                <span>{item.label}</span>
                {item.badge && <span className="nav-badge">{item.badge}</span>}
              </div>
            );
          })}
        </nav>

        <div className="sidebar-footer">
          <div className="user-pill">
            <div className="user-avatar">
              {currentUser?.name?.[0] || 'A'}
            </div>
            <div>
              <div className="user-info-name">{currentUser?.name || 'Admin'}</div>
              <div className="user-info-role">Super Admin</div>
            </div>
          </div>
          <button 
            className="btn-icon" 
            title="Log out" 
            onClick={handleLogout}
          >
            <LogOut size={16} />
          </button>
        </div>
      </aside>

      {/* Main Content Viewport */}
      <div className="main-wrapper">
        <header className="topbar">
          <div className="topbar-left">
            <button 
              className="btn-icon" 
              style={{ display: 'none' }} // only shows on mobile via media query
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            >
              {mobileMenuOpen ? <X size={20} /> : <Menu size={20} />}
            </button>
            <h1 className="page-heading-title">
              {navMenuItems.find(i => i.id === activeTab)?.label || 'Dashboard'}
            </h1>
          </div>

          <div className="topbar-actions">
            {/* Store open status */}
            <div 
              className={`store-status-pill ${settings?.storeOpen !== false ? 'open' : 'closed'}`}
              onClick={() => setActiveTab('settings')}
              title="Click to toggle in settings"
            >
              <span className={`pulse-dot ${settings?.storeOpen !== false ? 'green' : 'red'}`}></span>
              <span>{settings?.storeOpen !== false ? 'Kitchen Open' : 'Kitchen Closed'}</span>
            </div>

            {/* Refresh button */}
            <button 
              className="btn-icon"
              title="Refresh data"
              onClick={() => {
                loadAllData();
                showToast('App data synchronized with backend');
              }}
            >
              <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
            </button>
          </div>
        </header>

        <main className="content-body">
          {activeTab === 'dashboard' && (
            <DashboardView 
              stats={stats} 
              orders={orders} 
              onRefresh={loadAllData} 
              onSelectTab={setActiveTab} 
              showToast={showToast} 
            />
          )}

          {activeTab === 'content' && content && (
            <ContentHeadingsView 
              content={content} 
              onUpdateContent={loadAllData} 
              showToast={showToast} 
            />
          )}

          {activeTab === 'navigation' && (
            <NavigationMenusView 
              navigation={navigation} 
              categories={categories} 
              onRefresh={loadAllData} 
              showToast={showToast} 
            />
          )}

          {activeTab === 'restaurants' && (
            <RestaurantsView 
              restaurants={restaurants} 
              onRefresh={loadAllData} 
              showToast={showToast} 
            />
          )}

          {activeTab === 'menu' && (
            <MenuItemsView 
              foodItems={foodItems} 
              restaurants={restaurants} 
              categories={categories} 
              onRefresh={loadAllData} 
              showToast={showToast} 
            />
          )}

          {activeTab === 'daig' && (
            <DaigDishesView 
              daigDishes={daigDishes} 
              onRefresh={loadAllData} 
              showToast={showToast} 
            />
          )}

          {activeTab === 'deals' && (
            <DealsOffersView 
              deals={deals} 
              onRefresh={loadAllData} 
              showToast={showToast} 
            />
          )}

          {activeTab === 'banners' && (
            <BannersView 
              banners={banners} 
              onRefresh={loadAllData} 
              showToast={showToast} 
            />
          )}

          {activeTab === 'orders' && (
            <OrdersView 
              orders={orders} 
              onRefresh={loadAllData} 
              showToast={showToast} 
            />
          )}

          {activeTab === 'users' && (
            <UsersView 
              users={users} 
              onRefresh={loadAllData} 
              showToast={showToast} 
            />
          )}

          {activeTab === 'media' && (
            <MediaLibraryView 
              media={media} 
              onRefresh={loadAllData} 
              showToast={showToast} 
            />
          )}

          {activeTab === 'settings' && settings && (
            <SettingsView 
              settings={settings} 
              onRefresh={loadAllData} 
              showToast={showToast} 
            />
          )}
        </main>
      </div>
    </div>
  );
}
