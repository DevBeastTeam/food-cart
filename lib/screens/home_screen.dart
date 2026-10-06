import 'package:flutter/material.dart';
import '../data/sample_data.dart';
import '../models/food_item.dart';
import '../state/cart_state.dart';
import '../state/user_state.dart';
import '../theme/app_theme.dart';
import '../widgets/category_chip.dart';
import '../widgets/daig_card.dart';
import '../widgets/shahi_dish_card.dart';
import 'admin_dashboard_screen.dart';
import 'auth_screen.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';
import 'rider_dashboard_screen.dart';
import 'user_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  final CartState cartState;
  final UserState userState;

  const HomeScreen({
    super.key,
    required this.cartState,
    required this.userState,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;
  String _selectedCategory = 'All';
  String _quickFilter = 'All'; // 'All', 'Top Rated', 'Fast Delivery', 'Free Delivery'
  final TextEditingController _homeSearchController = TextEditingController();
  String _homeSearchQuery = '';

  @override
  void dispose() {
    _homeSearchController.dispose();
    super.dispose();
  }

  void _showAddressSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Delivery Address',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, size: 20),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...SampleData.sampleAddresses.map((address) {
                final isSelected = widget.cartState.deliveryAddress == address;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryLight : AppTheme.surfaceMuted,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    address,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppTheme.primary, size: 22)
                      : null,
                  onTap: () {
                    widget.cartState.setAddress(address);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _openCart() {
    setState(() {
      _currentNavIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.cartState, widget.userState]),
      builder: (context, _) {
        if (widget.userState.isLoggedIn && widget.userState.currentRole == UserRole.admin) {
          return AdminDashboardScreen(
            userState: widget.userState,
            onSwitchToCustomer: () => widget.userState.setRole(UserRole.client),
          );
        }

        if (widget.userState.isLoggedIn && widget.userState.currentRole == UserRole.rider) {
          return RiderDashboardScreen(
            userState: widget.userState,
            onSwitchToCustomer: () => widget.userState.setRole(UserRole.client),
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            child: _buildBody(),
          ),
          bottomNavigationBar: _buildBottomNavigationBar(),
          floatingActionButton: widget.cartState.totalItemCount > 0 && _currentNavIndex != 1
              ? _buildFloatingCartButton()
              : null,
        );
      },
    );
  }

  Widget _buildFloatingCartButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: FloatingActionButton.extended(
        onPressed: _openCart,
        backgroundColor: AppTheme.primary,
        elevation: 4,
        icon: Badge(
          label: Text(
            '${widget.cartState.totalItemCount}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          ),
          backgroundColor: Colors.white,
          textColor: AppTheme.primary,
          child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
        ),
        label: Text(
          'View Cart • Rs. ${widget.cartState.subtotal.toInt()}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentNavIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return CartScreen(
          cartState: widget.cartState,
          userState: widget.userState,
          isEmbedded: true,
          onNavigateToOrders: () {
            setState(() {
              _currentNavIndex = 2;
            });
          },
          onStartShopping: () {
            setState(() {
              _currentNavIndex = 0;
            });
          },
        );
      case 2:
        return OrdersScreen(
          userState: widget.userState,
          cartState: widget.cartState,
          isEmbedded: true,
          onStartShopping: () {
            setState(() {
              _currentNavIndex = 0;
            });
          },
        );
      case 3:
        return UserDashboardScreen(
          userState: widget.userState,
          cartState: widget.cartState,
          isEmbedded: true,
        );
      default:
        return _buildHomeTab();
    }
  }

  // ===========================================================================
  // TAB 1: HOME TAB
  // ===========================================================================
  Widget _buildHomeTab() {
    final isLoggedIn = widget.userState.isLoggedIn;
    final user = widget.userState.user;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Bar: Brand & Profile Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Food Court',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      isLoggedIn
                          ? 'Welcome back, ${user?.name.split(' ').first ?? 'Foodie'}! 👋'
                          : 'Order food, groceries & Deg catering',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isLoggedIn && user != null)
                InkWell(
                  onTap: () => setState(() => _currentNavIndex = 3),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: AppTheme.primary,
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          user.name.split(' ').first,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AuthScreen(
                          userState: widget.userState,
                          initialIsSignUp: false,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.login, size: 14),
                  label: const Text('Login / Sign Up'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // Address Delivery Chip Bar
          InkWell(
            onTap: _showAddressSelector,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppTheme.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, size: 15, color: AppTheme.primary),
                  const SizedBox(width: 6),
                  const Text(
                    'Deliver to: ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      widget.cartState.deliveryAddress.split('•').first.trim(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down, size: 16, color: AppTheme.textSecondary),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 2. Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _homeSearchController,
              onChanged: (val) => setState(() => _homeSearchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search Pulao, Biryani, Mutton, Beef, Karahi, Daig...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.primary, size: 20),
                suffixIcon: _homeSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _homeSearchController.clear();
                          setState(() => _homeSearchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),

          const SizedBox(height: 14),

          const SizedBox(height: 14),

          // 4. Cuisines for you (Horizontal Carousel)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Cuisines for you',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (_selectedCategory != 'All')
                InkWell(
                  onTap: () => setState(() => _selectedCategory = 'All'),
                  child: const Text(
                    'Reset',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: SampleData.categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = SampleData.categories[index];
                final name = cat['name'] as String;
                final icon = cat['icon'] as String;
                return CategoryChip(
                  label: name,
                  icon: icon,
                  isSelected: _selectedCategory == name,
                  onTap: () {
                    setState(() {
                      _selectedCategory = name;
                    });
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // 5. Quick Filter Pills (Horizontal)
          SizedBox(
            height: 28,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildQuickFilterPill('All'),
                const SizedBox(width: 6),
                _buildQuickFilterPill('Top Rated', icon: Icons.star_rounded),
                const SizedBox(width: 6),
                _buildQuickFilterPill('Fast Delivery', icon: Icons.electric_bolt_rounded),
                const SizedBox(width: 6),
                _buildQuickFilterPill('Free Delivery', icon: Icons.delivery_dining_rounded),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 6. Category Menu Dishes (Shahi Daig Design)
          _buildCategoryDishesSection(),

          const SizedBox(height: 20),

          // 7. Shahi Daig Catering Spotlight
          _buildDaigSpotlightCard(),

          const SizedBox(height: 20),

        ],
      ),
    );
  }

  Widget _buildQuickFilterPill(String filterName, {IconData? icon}) {
    final isSelected = _quickFilter == filterName;
    return InkWell(
      onTap: () {
        setState(() {
          _quickFilter = filterName;
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: isSelected ? Colors.white : (filterName == 'Top Rated' ? const Color(0xFFF59E0B) : AppTheme.primary),
              ),
              const SizedBox(width: 3),
            ],
            Text(
              filterName,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDishesSection() {
    final List<FoodItem> dishes;
    final String title;
    final String subtitle;

    if (_selectedCategory == 'All') {
      title = '👑 Shahi Menu Dishes (Signature Selection)';
      subtitle = 'Popular dishes cooked in pure desi ghee & authentic secret spices';
      dishes = SampleData.allTrendingFoodItems.take(4).toList();
    } else {
      title = '👑 $_selectedCategory Specials (Signature Selection)';
      subtitle = '2-3 signature items prepared fresh at FoodCourt Central Kitchen';
      dishes = SampleData.getDishesForCategory(_selectedCategory).take(3).toList();
    }

    if (dishes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...dishes.map(
          (dish) => ShahiDishCard(
            item: dish,
            cartState: widget.cartState,
          ),
        ),
      ],
    );
  }

  Widget _buildDaigSpotlightCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E1065), Color(0xFF4C1D95), Color(0xFF6D28D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4C1D95).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.soup_kitchen_rounded, color: Color(0xFFFBBF24), size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shahi Daig Catering & Pakwan Center',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Sealed hot cauldrons for Dawats, Weddings & Niyaz',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Preview Daig Item Card
          DaigCard(
            daig: SampleData.daigDishes.first,
            cartState: widget.cartState,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // BOTTOM NAVIGATION BAR
  // ===========================================================================
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppTheme.primary,
      unselectedItemColor: AppTheme.textSecondary,
      currentIndex: _currentNavIndex,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
      onTap: (idx) {
        setState(() {
          _currentNavIndex = idx;
        });
      },
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home_filled, color: AppTheme.primary),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Badge(
            isLabelVisible: widget.cartState.totalItemCount > 0,
            label: Text(
              '${widget.cartState.totalItemCount}',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppTheme.primary,
            child: const Icon(Icons.shopping_bag_outlined),
          ),
          activeIcon: Badge(
            isLabelVisible: widget.cartState.totalItemCount > 0,
            label: Text(
              '${widget.cartState.totalItemCount}',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppTheme.primary,
            child: const Icon(Icons.shopping_bag, color: AppTheme.primary),
          ),
          label: 'Cart',
        ),
        BottomNavigationBarItem(
          icon: Badge(
            isLabelVisible: widget.userState.activeOrdersCount > 0,
            label: Text(
              '${widget.userState.activeOrdersCount}',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.orangeAccent,
            child: const Icon(Icons.receipt_long_outlined),
          ),
          activeIcon: Badge(
            isLabelVisible: widget.userState.activeOrdersCount > 0,
            label: Text(
              '${widget.userState.activeOrdersCount}',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.orangeAccent,
            child: const Icon(Icons.receipt_long, color: AppTheme.primary),
          ),
          label: 'Orders',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person, color: AppTheme.primary),
          label: 'Account',
        ),
      ],
    );
  }
}
