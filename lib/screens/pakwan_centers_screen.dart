import 'package:flutter/material.dart';
import '../data/sample_data.dart';
import '../models/catering_package.dart';
import '../models/daig_item.dart';
import '../state/cart_state.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_image.dart';
import '../widgets/daig_card.dart';
import 'cart_screen.dart';

class PakwanCentersScreen extends StatefulWidget {
  final CartState cartState;

  const PakwanCentersScreen({
    super.key,
    required this.cartState,
  });

  @override
  State<PakwanCentersScreen> createState() => _PakwanCentersScreenState();
}

class _PakwanCentersScreenState extends State<PakwanCentersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Biryani & Pulao',
    'Qorma & Karahi',
    'Haleem & Nihari',
    'Sweet & Desserts',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<DaigItem> get _filteredDaigs {
    return SampleData.daigDishes.where((daig) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchName = daig.name.toLowerCase().contains(query);
        final matchUrdu = daig.urduName.contains(query);
        final matchDesc = daig.description.toLowerCase().contains(query);
        final matchCat = daig.category.toLowerCase().contains(query);
        if (!matchName && !matchUrdu && !matchDesc && !matchCat) return false;
      }

      if (_selectedCategory != 'All') {
        final cat = _selectedCategory.toLowerCase();
        final matchesCat = daig.category.toLowerCase().contains(cat) ||
            cat.contains(daig.category.toLowerCase());
        if (!matchesCat) return false;
      }

      return true;
    }).toList();
  }

  void _openCart() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CartScreen(cartState: widget.cartState),
      ),
    );
  }

  // ===========================================================================
  // CATERING PACKAGE BOOKING MODAL
  // ===========================================================================
  void _openPackageBookingSheet(CateringPackage package) {
    int guestCount = package.minGuests;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 3));
    TimeOfDay selectedTime = const TimeOfDay(hour: 13, minute: 30);
    final locationController = TextEditingController(text: 'Banquet Hall / Residence, Lahore');
    final specialRequestsController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final double grandTotal = package.pricePerHead * guestCount;

            return Container(
              margin: EdgeInsets.only(top: MediaQuery.of(ctx).size.height * 0.08),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    MediaQuery.of(ctx).viewInsets.bottom + 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Title Header
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2E1065).withAlpha(20),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    package.badge.toUpperCase(),
                                    style: const TextStyle(
                                      color: Color(0xFF4C1D95),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 10,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  package.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  package.urduName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close_rounded, size: 22),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Package Menu Items Preview
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF5FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE9D5FF)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.restaurant_menu_rounded, size: 16, color: Color(0xFF7E22CE)),
                                SizedBox(width: 6),
                                Text(
                                  'Catering Menu Included in this Package:',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF581C87),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: package.menuItems.map((dish) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFD8B4FE)),
                                  ),
                                  child: Text(
                                    dish,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF3B0764)),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                      const Divider(color: AppTheme.border),
                      const SizedBox(height: 12),

                      // 1. GUEST COUNT ESTIMATOR
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '1. Estimated Guests (مہمان)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Rs. ${package.pricePerHead.toInt()} / head (Min: ${package.minGuests})',
                                  style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceMuted,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 18),
                                  onPressed: guestCount > package.minGuests
                                      ? () => setModalState(() => guestCount -= 10)
                                      : null,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Text(
                                    '$guestCount',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF4C1D95),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 18),
                                  onPressed: guestCount < 1000
                                      ? () => setModalState(() => guestCount += 10)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Quick guest presets
                      Wrap(
                        spacing: 8,
                        children: [50, 100, 150, 200, 300, 500].map((preset) {
                          if (preset < package.minGuests) return const SizedBox.shrink();
                          final isSel = guestCount == preset;
                          return ChoiceChip(
                            label: Text('$preset Guests'),
                            selected: isSel,
                            onSelected: (val) {
                              if (val) setModalState(() => guestCount = preset);
                            },
                            selectedColor: const Color(0xFF2E1065).withAlpha(20),
                            labelStyle: TextStyle(
                              color: isSel ? const Color(0xFF4C1D95) : AppTheme.textPrimary,
                              fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                              fontSize: 11,
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 18),

                      // 2. EVENT DATE & TIME
                      const Text(
                        '2. Event Date & Serving Time (تاریخ و وقت)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime.now().add(const Duration(days: 1)),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (picked != null) {
                                  setModalState(() => selectedDate = picked);
                                }
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppTheme.border),
                                  borderRadius: BorderRadius.circular(10),
                                  color: const Color(0xFFF9FAFB),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF4C1D95)),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: selectedTime,
                                );
                                if (picked != null) {
                                  setModalState(() => selectedTime = picked);
                                }
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppTheme.border),
                                  borderRadius: BorderRadius.circular(10),
                                  color: const Color(0xFFF9FAFB),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF4C1D95)),
                                    const SizedBox(width: 8),
                                    Text(
                                      selectedTime.format(context),
                                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // 3. EVENT LOCATION & SPECIAL REQUESTS
                      const Text(
                        '3. Event Location / Venue (تقریب کا مقام)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: locationController,
                        decoration: InputDecoration(
                          hintText: 'Marquee / Hall Name or Residential Address...',
                          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                          prefixIcon: const Icon(Icons.location_on_rounded, color: Color(0xFF4C1D95), size: 18),
                          contentPadding: const EdgeInsets.all(12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppTheme.border),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
                      TextField(
                        controller: specialRequestsController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Special Catering Requests (e.g. food warmers, spicy dum, extra aloo, crockery)...',
                          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                          contentPadding: const EdgeInsets.all(12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppTheme.border),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Booking Confirmation Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            final dateStr = '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}';
                            final timeStr = selectedTime.format(context);
                            final foodItem = package.toFoodItem(
                              guestCount: guestCount,
                              eventDate: dateStr,
                              eventTime: timeStr,
                              eventLocation: locationController.text.trim().isNotEmpty
                                  ? locationController.text.trim()
                                  : 'Venue, Lahore',
                              specialRequests: specialRequestsController.text.trim(),
                            );

                            widget.cartState.addItem(
                              foodItem,
                              package.centerId,
                              package.centerName,
                            );

                            Navigator.pop(ctx);
                            AppTheme.showAddToCartToast(
                              context,
                              itemName: 'Catering Package ($guestCount guests)',
                              subtitle: 'Catering Package Booked! 🎉',
                              onViewCart: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CartScreen(cartState: widget.cartState),
                                  ),
                                );
                              },
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4C1D95),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Book Catering ($guestCount Guests)',
                                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Colors.white),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Rs. ${grandTotal.toInt()}',
                                style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: Color(0xFFFBBF24)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E1065),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: Colors.white,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              '🍲 Pakwan Center & Catering',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Traditional Coal-Dum Degs • Dawat Catering',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFFFBBF24),
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _openCart,
            icon: Badge(
              isLabelVisible: widget.cartState.totalItemCount > 0,
              label: Text(
                '${widget.cartState.totalItemCount}',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
              backgroundColor: const Color(0xFFFBBF24),
              textColor: Colors.black,
              child: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
            ),
          ),
          const SizedBox(width: 6),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: const Color(0xFFFBBF24),
          indicatorWeight: 3,
          labelColor: const Color(0xFFFBBF24),
          unselectedLabelColor: Colors.white70,
          labelPadding: const EdgeInsets.symmetric(horizontal: 14),
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          tabs: const [
            Tab(text: 'Deg Orders (دیگ)', icon: Icon(Icons.soup_kitchen_rounded, size: 17)),
            Tab(text: 'Catering Packages', icon: Icon(Icons.celebration_rounded, size: 17)),
            Tab(text: 'Partner Centers', icon: Icon(Icons.storefront_rounded, size: 17)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDegOrdersTab(),
          _buildCateringPackagesTab(),
          _buildPartnerCentersTab(),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: DEG ORDERS (INDIVIDUAL BULK DEGS)
  // ===========================================================================
  Widget _buildDegOrdersTab() {
    final daigs = _filteredDaigs;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Spotlight Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E1065), Color(0xFF4C1D95), Color(0xFF6D28D9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4C1D95).withAlpha(60),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.soup_kitchen_rounded, color: Color(0xFFFBBF24), size: 26),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Small (6 KG) • Medium (10 KG) • Large (12-14 KG)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Clay-sealed hot cauldrons with free Zeera Raita & Fresh Salad included.',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Search
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search Chicken Deg, Beef Yakhni Pulao, Mutton Korma...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF4C1D95), size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: InputBorder.none,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Category Pills
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSel = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFF4C1D95) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSel ? const Color(0xFF4C1D95) : AppTheme.border,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                        color: isSel ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Text(
                  'Available Deg Varieties (${daigs.length})',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Choose size & book',
                style: TextStyle(fontSize: 11, color: Color(0xFF7E22CE), fontWeight: FontWeight.w700),
              ),
            ],
          ),

          const SizedBox(height: 12),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: daigs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final daig = daigs[index];
              return DaigCard(
                daig: daig,
                cartState: widget.cartState,
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: CATERING PACKAGES (WEDDINGS, DAWATS & EVENTS)
  // ===========================================================================
  Widget _buildCateringPackagesTab() {
    final packages = SampleData.cateringPackages;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF701A75), Color(0xFF4C1D95)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.celebration_rounded, color: Color(0xFFFBBF24), size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Full Event Catering & Dawat Packages',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Includes Deg rice, meat curries, BBQ, Naan, desserts, drinks & staff support.',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Curated Catering Packages (${packages.length})',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),

          ...packages.map((pkg) => _buildPackageCard(pkg)),
        ],
      ),
    );
  }

  Widget _buildPackageCard(CateringPackage package) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Image & Badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: CustomImage(
                  imageUrl: package.imageUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  fallbackIcon: Icons.celebration_rounded,
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E1065).withAlpha(220),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    package.badge,
                    style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 10.5, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(230),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    package.occasion,
                    style: const TextStyle(color: Color(0xFF4C1D95), fontSize: 10.5, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        package.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Rs. ${package.pricePerHead.toInt()}',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF4C1D95)),
                        ),
                        const Text('per person', style: TextStyle(fontSize: 10.5, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ],
                ),
                Text(
                  package.urduName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 8),
                Text(
                  package.description,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.3),
                ),
                const SizedBox(height: 12),

                // Menu items tags
                const Text(
                  'Included Menu Dishes:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: package.menuItems.map((item) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF5FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE9D5FF)),
                      ),
                      child: Text(item, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4C1D95))),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 14),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => _openPackageBookingSheet(package),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4C1D95),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_month_rounded, size: 16, color: Color(0xFFFBBF24)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Configure & Book (${package.minGuests}+ Guests)',
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 3: PARTNER PAKWAN CENTERS
  // ===========================================================================
  Widget _buildPartnerCentersTab() {
    final centers = SampleData.pakwanCenters;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: centers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final center = centers[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CustomImage(
                      imageUrl: center.imageUrl,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      fallbackIcon: Icons.storefront_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                center.name,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.amber.shade300),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star_rounded, size: 13, color: Colors.amber),
                                  const SizedBox(width: 2),
                                  Text(
                                    center.rating.toStringAsFixed(1),
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.amber),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          center.urduName,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 13, color: AppTheme.primary),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                center.address,
                                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.phone_rounded, size: 12, color: Color(0xFF10B981)),
                            const SizedBox(width: 4),
                            Text(
                              center.phone,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF10B981)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF5FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(center.experienceYears, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF4C1D95))),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(center.minAdvanceNotice, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF15803D))),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    // Switch to Deg Tab
                    _tabController.animateTo(0);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4C1D95),
                    side: const BorderSide(color: Color(0xFF4C1D95)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Browse Degs from this Center', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
