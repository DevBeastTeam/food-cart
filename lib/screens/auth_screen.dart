import 'package:flutter/material.dart';
import '../state/user_state.dart';
import '../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  final UserState userState;
  final bool initialIsSignUp;
  final UserRole initialRole;

  const AuthScreen({
    super.key,
    required this.userState,
    this.initialIsSignUp = false,
    this.initialRole = UserRole.client,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late bool _isSignUp;
  late UserRole _selectedRole;
  bool _obscurePassword = true;

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialIsSignUp;
    _selectedRole = widget.initialRole;
    _applyRoleDefaults(_selectedRole);
  }

  void _applyRoleDefaults(UserRole role) {
    if (role == UserRole.client) {
      _emailController.text = 'hassan.raza@foodcourt.pk';
      _passwordController.text = '123456';
      _nameController.text = 'Hassan Raza';
      _phoneController.text = '+92 300 8472910';
    } else if (role == UserRole.rider) {
      _emailController.text = 'rider.ali@foodcourt.pk';
      _passwordController.text = '123456';
      _nameController.text = 'Captain Ali Raza';
      _phoneController.text = '+92 302 9988776';
    } else {
      _emailController.clear();
      _passwordController.clear();
      _nameController.clear();
      _phoneController.clear();
      _isSignUp = false; // Admin cannot sign up
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (_isSignUp) {
      if (_selectedRole == UserRole.rider) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Riders cannot register via mobile app. Please contact your store vendor for an account.'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
        return;
      }
      await widget.userState.signup(
        name: name.isNotEmpty ? name : 'Food Lover',
        email: email,
        phone: phone.isNotEmpty ? phone : '+92 300 0000000',
        password: password,
      );
      widget.userState.setRole(_selectedRole);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account created! Welcome as ${_selectedRole.name.toUpperCase()}.'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      await widget.userState.login(
        email: email,
        password: password,
        name: name.isNotEmpty ? name : null,
        phone: phone.isNotEmpty ? phone : null,
        role: _selectedRole,
      );

      if (!mounted) return;
      String roleTitle = 'Customer';
      if (_selectedRole == UserRole.admin || widget.userState.currentRole == UserRole.admin) {
        roleTitle = 'Kitchen Admin';
      } else if (_selectedRole == UserRole.rider || widget.userState.currentRole == UserRole.rider) {
        roleTitle = 'Delivery Rider';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Logged in successfully as $roleTitle (${widget.userState.userName})!'),
              ),
            ],
          ),
          backgroundColor: _selectedRole == UserRole.admin
              ? const Color(0xFF6B21A8)
              : (_selectedRole == UserRole.rider ? const Color(0xFF1B2A4A) : AppTheme.primary),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 750;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isSignUp ? 'Create Food Court Account' : 'Log In to Food Court',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32 : 18,
            vertical: 14,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Brand Header Banner
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _selectedRole == UserRole.admin
                            ? [const Color(0xFF3B0764), const Color(0xFF581C87), const Color(0xFF7E22CE)]
                            : (_selectedRole == UserRole.rider
                                ? [const Color(0xFF0F172A), const Color(0xFF1E293B), const Color(0xFF334155)]
                                : [const Color(0xFF2E1065), const Color(0xFF4C1D95), const Color(0xFF6D28D9)]),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(30),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _selectedRole == UserRole.admin
                                ? Icons.admin_panel_settings_rounded
                                : (_selectedRole == UserRole.rider
                                    ? Icons.two_wheeler_rounded
                                    : Icons.restaurant_rounded),
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedRole == UserRole.admin
                                    ? 'Kitchen Admin Portal'
                                    : (_selectedRole == UserRole.rider
                                        ? 'Rider Delivery Fleet'
                                        : 'Food Court Customer'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _selectedRole == UserRole.admin
                                    ? 'Kitchen order processing, dispatch & prep management.'
                                    : (_selectedRole == UserRole.rider
                                        ? 'Pickups from Central Kitchen & dropoff navigation.'
                                        : 'Order Pakistani cuisine, biryani & deg bookings.'),
                                style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2-Role Selector Tabs: Customer on Left (Default), Rider on Right
                  const Text(
                    'SELECT ROLE / رول منتخب کریں',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceMuted,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        _buildRoleTab(
                          role: UserRole.client,
                          label: 'Customer (کسٹمر)',
                          icon: Icons.person_rounded,
                        ),
                        _buildRoleTab(
                          role: UserRole.rider,
                          label: 'Rider (رائیڈر)',
                          icon: Icons.two_wheeler_rounded,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Quick 1-Tap Demo Shortcuts for Customer & Rider
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.person, size: 15, color: AppTheme.primary),
                        label: const Text('Customer Demo', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        backgroundColor: _selectedRole == UserRole.client ? AppTheme.primaryLight : Colors.white,
                        side: BorderSide(color: _selectedRole == UserRole.client ? AppTheme.primary : AppTheme.border),
                        onPressed: () {
                          setState(() {
                            _selectedRole = UserRole.client;
                            _isSignUp = false;
                            _applyRoleDefaults(UserRole.client);
                          });
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.two_wheeler, size: 15, color: Color(0xFF1B2A4A)),
                        label: const Text('Rider Demo', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        backgroundColor: _selectedRole == UserRole.rider ? const Color(0xFFE2E8F0) : Colors.white,
                        side: BorderSide(color: _selectedRole == UserRole.rider ? const Color(0xFF1B2A4A) : AppTheme.border),
                        onPressed: () {
                          setState(() {
                            _selectedRole = UserRole.rider;
                            _isSignUp = false;
                            _applyRoleDefaults(UserRole.rider);
                          });
                        },
                      ),
                    ],
                  ),

                  if (_selectedRole == UserRole.admin) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFD8B4FE)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: Color(0xFF6B21A8), size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Web Portals: Super Admin is at /admin, and Sub-Admin Vendors manage stores at /vendor.',
                              style: TextStyle(fontSize: 11, color: Color(0xFF581C87), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Mode Switcher (Log in / Sign up) - Only for Customer!
                  if (_selectedRole == UserRole.client) ...[
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _isSignUp = false),
                              borderRadius: BorderRadius.circular(9),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(
                                  color: !_isSignUp ? AppTheme.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Text(
                                  'Log In',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: !_isSignUp ? Colors.white : AppTheme.textSecondary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _isSignUp = true),
                              borderRadius: BorderRadius.circular(9),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(
                                  color: _isSignUp ? AppTheme.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Text(
                                  'Sign Up',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _isSignUp ? Colors.white : AppTheme.textSecondary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ] else if (_selectedRole == UserRole.rider) ...[
                    // Rider Official Notice: Accounts created ONLY by Vendors
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF93C5FD)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.shield_outlined, color: Color(0xFF1D4ED8), size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Rider Accounts Issued by Store Vendor',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E40AF),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Riders cannot create accounts from the mobile app. Your store manager/vendor creates your account in their portal. Please log in with the credentials provided to you.',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF1E3A8A), height: 1.3),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'رائیڈر اکاؤنٹ وینڈر اپنے پورٹل سے بنا کر دیتا ہے۔ وینڈر کی دی گئی تفصیلات سے لاگ ان کریں۔',
                                  style: TextStyle(fontSize: 10.5, color: Color(0xFF1E3A8A), fontWeight: FontWeight.w600),
                                  textDirection: TextDirection.rtl,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ] else ...[
                    const SizedBox(height: 4),
                  ],

                  // Form Container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isSignUp) ...[
                          const Text(
                            'Full Name',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText: _selectedRole == UserRole.rider ? 'Captain Name' : 'Your Full Name',
                              prefixIcon: const Icon(Icons.person_outline, size: 20),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (v) {
                              if (_isSignUp && (v == null || v.trim().isEmpty)) return 'Please enter name';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Phone Number',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              hintText: '+92 300 1234567',
                              prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        const Text(
                          'Email Address',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: _selectedRole == UserRole.admin ? 'admin@foodcourt.pk' : 'email@foodcourt.pk',
                            prefixIcon: const Icon(Icons.email_outlined, size: 20),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Please enter email';
                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        const Text(
                          'Password',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: 'Enter password',
                            prefixIcon: const Icon(Icons.lock_outline, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Please enter password';
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _selectedRole == UserRole.admin
                                  ? const Color(0xFF6B21A8)
                                  : (_selectedRole == UserRole.rider ? const Color(0xFF1B2A4A) : AppTheme.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                            ),
                            child: Text(
                              _isSignUp
                                  ? 'Register as ${_selectedRole.name.toUpperCase()}'
                                  : 'Log In as ${_selectedRole.name.toUpperCase()}',
                              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Bottom Switcher to toggle Login & Sign Up
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isSignUp ? "Already have an account? " : "Don't have an account? ",
                              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isSignUp = !_isSignUp;
                                });
                              },
                              child: Text(
                                _isSignUp ? "Log In" : "Sign Up",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _selectedRole == UserRole.rider ? const Color(0xFF1B2A4A) : AppTheme.primary,
                                  fontWeight: FontWeight.w800,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Kitchen Admin Switch Option
                        Center(
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedRole = _selectedRole == UserRole.admin ? UserRole.client : UserRole.admin;
                                _isSignUp = false;
                                _applyRoleDefaults(_selectedRole);
                              });
                            },
                            icon: Icon(
                              _selectedRole == UserRole.admin ? Icons.arrow_back : Icons.shield_outlined,
                              size: 14,
                              color: AppTheme.textSecondary,
                            ),
                            label: Text(
                              _selectedRole == UserRole.admin ? "Back to Customer / Rider Login" : "Kitchen Admin Sign In",
                              style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTab({
    required UserRole role,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == role;
    Color activeColor;
    if (role == UserRole.admin) {
      activeColor = const Color(0xFF6B21A8);
    } else if (role == UserRole.rider) {
      activeColor = const Color(0xFF1B2A4A);
    } else {
      activeColor = AppTheme.primary;
    }

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedRole = role;
            if (role == UserRole.admin || role == UserRole.rider) {
              _isSignUp = false;
            }
            _applyRoleDefaults(role);
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withAlpha(50),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
