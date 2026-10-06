import 'package:flutter/material.dart';
import '../state/cart_state.dart';
import '../state/user_state.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';

class UserDashboardScreen extends StatefulWidget {
  final UserState userState;
  final CartState? cartState;
  final bool isEmbedded;

  const UserDashboardScreen({
    super.key,
    required this.userState,
    this.cartState,
    this.isEmbedded = false,
  });

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  bool _isEditingProfile = false;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _populateFields();
  }

  void _populateFields() {
    final user = widget.userState.user;
    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
      _phoneController.text = user.phone;
      _passwordController.clear();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _saveProfileChanges() {
    final newName = _nameController.text.trim();
    final newPhone = _phoneController.text.trim();
    final newEmail = _emailController.text.trim();

    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty!')),
      );
      return;
    }

    widget.userState.updateProfile(
      name: newName,
      phone: newPhone,
    );

    if (newEmail.isNotEmpty && widget.userState.user != null) {
      widget.userState.user!.email = newEmail;
    }

    setState(() {
      _isEditingProfile = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Profile updated successfully!'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF2E7D32),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.userState,
      builder: (context, _) {
        final isLoggedIn = widget.userState.isLoggedIn;
        final user = widget.userState.user;

        if (!isLoggedIn || user == null) {
          return _buildLoggedOutView();
        }

        final content = SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Profile Card at Top (Clickable to toggle edit form below)
              _buildProfileCard(user),

              const SizedBox(height: 12),

              // 2. Inline Edit Form (Shown directly below profile card, NO popup!)
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: _buildInlineEditForm(),
                crossFadeState: _isEditingProfile
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250),
              ),

              const SizedBox(height: 16),

              // 3. Quick Action List Tiles Section
              Material(
                color: Colors.white,
                clipBehavior: Clip.antiAlias,
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    // Contact Support List Tile
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.headset_mic_rounded, color: Color(0xFF2E7D32), size: 20),
                      ),
                      title: const Text(
                        'Contact Support',
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                      ),
                      subtitle: const Text(
                        '24/7 Helpline, WhatsApp & Kitchen Support',
                        style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textSecondary),
                      onTap: _showContactSupportSheet,
                    ),

                    const Divider(height: 1, indent: 56, color: AppTheme.border),

                    // Update My Location List Tile
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE7F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.location_on_rounded, color: AppTheme.primary, size: 20),
                      ),
                      title: const Text(
                        'Update My Location',
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        widget.cartState?.deliveryAddress ?? 'Gulberg III, Main Blvd, Lahore',
                        style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textSecondary),
                      onTap: _showUpdateLocationSheet,
                    ),

                    const Divider(height: 1, indent: 56, color: AppTheme.border),

                    // Switch Role / Portal Mode Tile
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.swap_horiz_rounded, color: Color(0xFFE65100), size: 20),
                      ),
                      title: Row(
                        children: [
                          const Flexible(
                            child: Text(
                              'Switch Role / Portal',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: widget.userState.currentRole == UserRole.admin
                                  ? const Color(0xFF6B21A8)
                                  : (widget.userState.currentRole == UserRole.rider
                                      ? const Color(0xFF1B2A4A)
                                      : AppTheme.primary),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.userState.currentRole.name.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                      subtitle: const Text(
                        'Switch between Customer, Rider Console & Admin Dashboard',
                        style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textSecondary),
                      onTap: _showRoleSwitchSheet,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // 4. Logout Button at the bottom
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Text('Log Out?'),
                        content: const Text('Are you sure you want to log out of your account?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              widget.userState.logout();
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                            child: const Text('Log Out'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
                  label: const Text(
                    'Log Out',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFFCDD2)),
                    backgroundColor: const Color(0xFFFFF5F5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        );

        if (widget.isEmbedded) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            body: SafeArea(child: content),
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            title: const Text('My Account'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: content,
        );
      },
    );
  }

  // Profile Card (Clickable to expand inline edit form below)
  Widget _buildProfileCard(UserProfile user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _isEditingProfile = !_isEditingProfile;
              if (_isEditingProfile) {
                _populateFields();
              }
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.primaryLight,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // User Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.name,
                              style: const TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Pro ⭐',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFE65100),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user.email,
                        style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.phone,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                // Toggle Edit Indicator
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: _isEditingProfile ? AppTheme.primary : AppTheme.surfaceMuted,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isEditingProfile ? Icons.close_rounded : Icons.edit_rounded,
                    size: 16,
                    color: _isEditingProfile ? Colors.white : AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Inline Profile Edit Form (shown directly below the profile card, NOT in a popup)
  Widget _buildInlineEditForm() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withAlpha(80), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.edit_note_rounded, color: AppTheme.primary, size: 20),
                  SizedBox(width: 6),
                  Text(
                    'Edit Profile Information',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => setState(() => _isEditingProfile = false),
                child: const Icon(Icons.close, size: 18, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Name Field
          const Text('Full Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.person_outline, size: 18),
              hintText: 'Enter your name',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 12),

          // Email Field
          const Text('Email Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.email_outlined, size: 18),
              hintText: 'Enter your email',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 12),

          // Phone Field
          const Text('Phone Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.phone_outlined, size: 18),
              hintText: '+92 300 1234567',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 12),

          // Password Field
          const Text('Update Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline, size: 18),
              hintText: 'Enter new password (optional)',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 16),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveProfileChanges,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Save Profile Updates'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Contact Support Bottom Sheet
  void _showContactSupportSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.headset_mic_rounded, color: AppTheme.primary, size: 24),
                SizedBox(width: 10),
                Text(
                  'Customer Support & Kitchen Help',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Our team is available 24/7 for order inquiries, Daig reservations, and rider updates.',
              style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 18),
            ListTile(
              tileColor: AppTheme.background,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.phone, color: Color(0xFF28A745)),
              title: const Text('Helpline Call', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('+92 42 111-CRAVEE (272-833)'),
              trailing: const Icon(Icons.call_made, size: 16),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dialing helpline: +92 42 111-272-833')),
                );
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              tileColor: AppTheme.background,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.chat_bubble_outline, color: Color(0xFF25D366)),
              title: const Text('WhatsApp Live Support', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('+92 300 8472910'),
              trailing: const Icon(Icons.call_made, size: 16),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening WhatsApp Support (+92 300 8472910)...')),
                );
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              tileColor: AppTheme.background,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.email_outlined, color: AppTheme.primary),
              title: const Text('Email Support', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('support@foodcourt.pk'),
              trailing: const Icon(Icons.call_made, size: 16),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Email support: support@foodcourt.pk')),
                );
              },
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  // Update My Location Bottom Sheet
  void _showUpdateLocationSheet() {
    final currentAddress = widget.cartState?.deliveryAddress ?? 'Gulberg III, Main Blvd, Lahore';
    final controller = TextEditingController(text: currentAddress);
    String selectedCity = 'Lahore';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.location_on_rounded, color: AppTheme.primary, size: 24),
                SizedBox(width: 8),
                Text(
                  'Update Delivery Location',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Specify your street address, town, and city for accurate hot deliveries.',
              style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 14),
            const Text('Full Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 5),
            TextField(
              controller: controller,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'e.g. House 42, Block H, Phase 5, DHA, Lahore',
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            const Text('City', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 5),
            DropdownButtonFormField<String>(
              initialValue: selectedCity,
              decoration: InputDecoration(
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: const [
                DropdownMenuItem(value: 'Lahore', child: Text('Lahore')),
                DropdownMenuItem(value: 'Islamabad', child: Text('Islamabad')),
                DropdownMenuItem(value: 'Rawalpindi', child: Text('Rawalpindi')),
                DropdownMenuItem(value: 'Karachi', child: Text('Karachi')),
                DropdownMenuItem(value: 'Faisalabad', child: Text('Faisalabad')),
              ],
              onChanged: (val) {
                if (val != null) selectedCity = val;
              },
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final text = controller.text.trim();
                  if (text.isNotEmpty) {
                    widget.cartState?.setAddress(text);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Delivery location updated to "$text"!'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppTheme.primary,
                      ),
                    );
                  }
                },
                child: const Text('Update Location'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoggedOutView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: Color(0xFFF3E8FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline, color: AppTheme.primary, size: 48),
            ),
            const SizedBox(height: 20),
            const Text(
              'Log In to Your Account',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sign in to manage your profile, tracked Pakistani orders, and locations.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AuthScreen(userState: widget.userState),
                  ),
                );
              },
              icon: const Icon(Icons.login_rounded),
              label: const Text('Log In / Register'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRoleSwitchSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Switch Active Role Portal',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Choose which interface you want to work with:',
              style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.restaurant_rounded, color: AppTheme.primary),
              title: const Text('Customer / Client App', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Browse Pakistani food, orders & checkout'),
              selected: widget.userState.currentRole == UserRole.client,
              trailing: widget.userState.currentRole == UserRole.client
                  ? const Icon(Icons.check, color: AppTheme.primary)
                  : null,
              onTap: () {
                widget.userState.setRole(UserRole.client);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.two_wheeler_rounded, color: Color(0xFF1B2A4A)),
              title: const Text('Rider Delivery Console', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Pickups, dropoff navigation & order statuses'),
              selected: widget.userState.currentRole == UserRole.rider,
              trailing: widget.userState.currentRole == UserRole.rider
                  ? const Icon(Icons.check, color: Color(0xFF1B2A4A))
                  : null,
              onTap: () {
                widget.userState.setRole(UserRole.rider);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF6B21A8)),
              title: const Text('Admin & Kitchen Dashboard', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Process orders, set prep time, assign riders'),
              selected: widget.userState.currentRole == UserRole.admin,
              trailing: widget.userState.currentRole == UserRole.admin
                  ? const Icon(Icons.check, color: Color(0xFF6B21A8))
                  : null,
              onTap: () {
                widget.userState.setRole(UserRole.admin);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}
