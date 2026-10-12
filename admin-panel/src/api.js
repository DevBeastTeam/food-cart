const API_BASE = 'http://localhost:5000/api';

export function getAuthToken() {
  return localStorage.getItem('fc_admin_token') || '';
}

export function setAuthToken(token) {
  if (token) {
    localStorage.setItem('fc_admin_token', token);
  } else {
    localStorage.removeItem('fc_admin_token');
  }
}

export function getCurrentAdminUser() {
  try {
    const raw = localStorage.getItem('fc_admin_user');
    return raw ? JSON.parse(raw) : null;
  } catch (e) {
    return null;
  }
}

export function setCurrentAdminUser(user) {
  if (user) {
    localStorage.setItem('fc_admin_user', JSON.stringify(user));
  } else {
    localStorage.removeItem('fc_admin_user');
  }
}

export async function apiRequest(endpoint, options = {}) {
  const token = getAuthToken();
  const headers = {
    ...options.headers
  };

  if (!(options.body instanceof FormData)) {
    headers['Content-Type'] = 'application/json';
  }

  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  try {
    const response = await fetch(`${API_BASE}${endpoint}`, {
      ...options,
      headers
    });

    const data = await response.json();
    if (!response.ok) {
      throw new Error(data.message || `API error ${response.status}`);
    }
    return data;
  } catch (error) {
    console.error(`API Call failed [${endpoint}]:`, error);
    throw error;
  }
}

export const api = {
  // Auth
  login: (email, password) => apiRequest('/auth/login', { method: 'POST', body: JSON.stringify({ email, password }) }),
  getMe: () => apiRequest('/auth/me'),

  // Dashboard
  getStats: () => apiRequest('/dashboard/stats'),

  // Restaurants
  getRestaurants: (all = true) => apiRequest(`/restaurants?all=${all}`),
  createRestaurant: (data) => apiRequest('/restaurants', { method: 'POST', body: JSON.stringify(data) }),
  updateRestaurant: (id, data) => apiRequest(`/restaurants/${id}`, { method: 'PUT', body: JSON.stringify(data) }),
  toggleRestaurantVisibility: (id, isVisible) => apiRequest(`/restaurants/${id}/visibility`, { method: 'PATCH', body: JSON.stringify({ isVisible }) }),
  deleteRestaurant: (id) => apiRequest(`/restaurants/${id}`, { method: 'DELETE' }),

  // Food Items
  getFoodItems: (all = true, category = 'All') => apiRequest(`/food-items?all=${all}&category=${category}`),
  createFoodItem: (data) => apiRequest('/food-items', { method: 'POST', body: JSON.stringify(data) }),
  updateFoodItem: (id, data) => apiRequest(`/food-items/${id}`, { method: 'PUT', body: JSON.stringify(data) }),
  toggleFoodItemVisibility: (id, isVisible) => apiRequest(`/food-items/${id}/visibility`, { method: 'PATCH', body: JSON.stringify({ isVisible }) }),
  toggleFoodItemPopular: (id, isPopular) => apiRequest(`/food-items/${id}/popular`, { method: 'PATCH', body: JSON.stringify({ isPopular }) }),
  deleteFoodItem: (id) => apiRequest(`/food-items/${id}`, { method: 'DELETE' }),

  // Daig Dishes
  getDaigItems: (all = true) => apiRequest(`/daig-items?all=${all}`),
  createDaigItem: (data) => apiRequest('/daig-items', { method: 'POST', body: JSON.stringify(data) }),
  updateDaigItem: (id, data) => apiRequest(`/daig-items/${id}`, { method: 'PUT', body: JSON.stringify(data) }),
  toggleDaigVisibility: (id, isVisible) => apiRequest(`/daig-items/${id}/visibility`, { method: 'PATCH', body: JSON.stringify({ isVisible }) }),
  deleteDaigItem: (id) => apiRequest(`/daig-items/${id}`, { method: 'DELETE' }),

  // Mart Products
  getMartProducts: (all = true) => apiRequest(`/mart-products?all=${all}`),
  createMartProduct: (data) => apiRequest('/mart-products', { method: 'POST', body: JSON.stringify(data) }),
  updateMartProduct: (id, data) => apiRequest(`/mart-products/${id}`, { method: 'PUT', body: JSON.stringify(data) }),
  toggleMartVisibility: (id, isVisible) => apiRequest(`/mart-products/${id}/visibility`, { method: 'PATCH', body: JSON.stringify({ isVisible }) }),
  toggleMartStock: (id, inStock) => apiRequest(`/mart-products/${id}/stock`, { method: 'PATCH', body: JSON.stringify({ inStock }) }),
  deleteMartProduct: (id) => apiRequest(`/mart-products/${id}`, { method: 'DELETE' }),

  // Deals
  getDeals: (all = true) => apiRequest(`/deals?all=${all}`),
  createDeal: (data) => apiRequest('/deals', { method: 'POST', body: JSON.stringify(data) }),
  updateDeal: (id, data) => apiRequest(`/deals/${id}`, { method: 'PUT', body: JSON.stringify(data) }),
  toggleDealVisibility: (id, isVisible) => apiRequest(`/deals/${id}/visibility`, { method: 'PATCH', body: JSON.stringify({ isVisible }) }),
  deleteDeal: (id) => apiRequest(`/deals/${id}`, { method: 'DELETE' }),

  // Banners
  getBanners: (all = true) => apiRequest(`/banners?all=${all}`),
  createBanner: (data) => apiRequest('/banners', { method: 'POST', body: JSON.stringify(data) }),
  updateBanner: (id, data) => apiRequest(`/banners/${id}`, { method: 'PUT', body: JSON.stringify(data) }),
  toggleBannerVisibility: (id, isVisible) => apiRequest(`/banners/${id}/visibility`, { method: 'PATCH', body: JSON.stringify({ isVisible }) }),
  deleteBanner: (id) => apiRequest(`/banners/${id}`, { method: 'DELETE' }),

  // Categories
  getCategories: (all = true) => apiRequest(`/categories?all=${all}`),
  createCategory: (data) => apiRequest('/categories', { method: 'POST', body: JSON.stringify(data) }),
  updateCategory: (id, data) => apiRequest(`/categories/${id}`, { method: 'PUT', body: JSON.stringify(data) }),
  toggleCategoryVisibility: (id, isVisible) => apiRequest(`/categories/${id}/visibility`, { method: 'PATCH', body: JSON.stringify({ isVisible }) }),
  deleteCategory: (id) => apiRequest(`/categories/${id}`, { method: 'DELETE' }),

  // Content & Headings
  getContent: () => apiRequest('/content'),
  updateContent: (data) => apiRequest('/content', { method: 'PUT', body: JSON.stringify(data) }),
  addAddress: (address) => apiRequest('/content/addresses', { method: 'POST', body: JSON.stringify({ address }) }),
  deleteAddress: (index) => apiRequest(`/content/addresses/${index}`, { method: 'DELETE' }),
  toggleSectionVisibility: (sectionKey, isVisible) => apiRequest('/content/toggle-section', { method: 'PATCH', body: JSON.stringify({ sectionKey, isVisible }) }),

  // Navigation
  getNavigation: (all = true) => apiRequest(`/navigation?all=${all}`),
  createNavItem: (data) => apiRequest('/navigation', { method: 'POST', body: JSON.stringify(data) }),
  updateNavItem: (id, data) => apiRequest(`/navigation/${id}`, { method: 'PUT', body: JSON.stringify(data) }),
  toggleNavVisibility: (id, isVisible) => apiRequest(`/navigation/${id}/visibility`, { method: 'PATCH', body: JSON.stringify({ isVisible }) }),
  deleteNavItem: (id) => apiRequest(`/navigation/${id}`, { method: 'DELETE' }),

  // Orders
  getOrders: (status = 'All') => apiRequest(`/orders?status=${status}`),
  updateOrderStatus: (id, status, prepTime, notes) => apiRequest(`/orders/${id}/status`, { method: 'PATCH', body: JSON.stringify({ status, prepTime, notes }) }),
  assignRider: (id, riderName, riderPhone) => apiRequest(`/orders/${id}/assign-rider`, { method: 'PATCH', body: JSON.stringify({ riderName, riderPhone }) }),
  deleteOrder: (id) => apiRequest(`/orders/${id}`, { method: 'DELETE' }),

  // Users
  getUsers: (role = 'All') => apiRequest(`/users?role=${role}`),
  createUser: (data) => apiRequest('/users', { method: 'POST', body: JSON.stringify(data) }),
  updateUser: (id, data) => apiRequest(`/users/${id}`, { method: 'PUT', body: JSON.stringify(data) }),
  toggleUserStatus: (id) => apiRequest(`/users/${id}/status`, { method: 'PATCH' }),
  adjustUserWallet: (id, amount) => apiRequest(`/users/${id}/wallet`, { method: 'PATCH', body: JSON.stringify({ amount }) }),
  deleteUser: (id) => apiRequest(`/users/${id}`, { method: 'DELETE' }),

  // Settings
  getSettings: () => apiRequest('/settings'),
  updateSettings: (data) => apiRequest('/settings', { method: 'PUT', body: JSON.stringify(data) }),
  toggleStoreStatus: (storeOpen) => apiRequest('/settings/store-status', { method: 'PATCH', body: JSON.stringify({ storeOpen }) }),
  updateEmergencyAlert: (alertData) => apiRequest('/settings/emergency-alert', { method: 'PATCH', body: JSON.stringify(alertData) }),

  // Media
  getMedia: () => apiRequest('/media'),
  uploadMedia: (formData) => apiRequest('/media/upload', { method: 'POST', body: formData }),
  addMediaUrl: (name, url, category) => apiRequest('/media/url', { method: 'POST', body: JSON.stringify({ name, url, category }) }),
  deleteMedia: (id) => apiRequest(`/media/${id}`, { method: 'DELETE' })
};
