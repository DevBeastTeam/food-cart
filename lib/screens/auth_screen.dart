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
      // Admin: Explicit instruction from user - DO NOT display admin credentials on screen!
      _emailController.clear();
      _passwordController.clear();
      _nameController.text = 'Kitchen Super Admin';
      _phoneController.text = '+92 42 111-CRAVEE';
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (_isSignUp) {
      widget.userState.signup(
        name: name.isNotEmpty ? name : (_selectedRole == UserRole.rider ? 'Rider Partner' : 'Food Lover'),
        email: email,
        phone: phone.isNotEmpty ? phone : '+92 300 0000000',
        password: password,
      );
      widget.userState.setRole(_selectedRole);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account created! Welcome as ${_selectedRole.name.toUpperCase()}.'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      widget.userState.login(
        email: email,
        password: password,
        name: name.isNotEmpty ? name : null,
        phone: phone.isNotEmpty ? phone : null,
        role: _selectedRole,
      );

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

    Navigator.of(context).pop();
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

                  // 3-Role Selector Tabs (Customer, Rider, Admin)
                  const Text(
                    'SELECT ROLE / PORTAL',
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
                          label: 'Customer',
                          icon: Icons.person_rounded,
                        ),
                        _buildRoleTab(
                          role: UserRole.rider,
                          label: 'Rider',
                          icon: Icons.two_wheeler_rounded,
                        ),
                        _buildRoleTab(
                          role: UserRole.admin,
                          label: 'Admin',
                          icon: Icons.shield_rounded,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Mode Switcher (Log in / Sign up)
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

                  // Credential Notice Card
                  if (_selectedRole == UserRole.client)
                    _buildDemoInfoCard(
                      title: 'Customer Demo Account',
                      subtitle: 'Email: hassan.raza@foodcourt.pk | Pass: 123456',
                      icon: Icons.account_circle_outlined,
                      color: Colors.blue.shade700,
                      bgColor: Colors.blue.shade50,
                      borderColor: Colors.blue.shade200,
                      onTapFill: () => _applyRoleDefaults(UserRole.client),
                    )
                  else if (_selectedRole == UserRole.rider)
                    _buildDemoInfoCard(
                      title: 'Rider Demo Account',
                      subtitle: 'Email: rider.ali@foodcourt.pk | Pass: 123456',
                      icon: Icons.two_wheeler_rounded,
                      color: Colors.teal.shade800,
                      bgColor: Colors.teal.shade50,
                      borderColor: Colors.teal.shade200,
                      onTapFill: () => _applyRoleDefaults(UserRole.rider),
                    )
                  else
                    // Admin: User constraint - DO NOT display admin credentials on screen!
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lock_person_rounded, size: 20, color: Colors.purple.shade800),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Confidential Admin Access',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.purple.shade900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Admin credentials are confidential. Enter your assigned master login credentials.',
                                  style: TextStyle(fontSize: 11, color: Colors.purple.shade700),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

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
                      ],
                    ),
                  ),

                  // Quick Demo Autofills for Client and Rider
                  if (_selectedRole != UserRole.admin) ...[
                    const SizedBox(height: 18),
                    const Row(
                      children: [
                        Expanded(child: Divider(color: AppTheme.border)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'QUICK DEMO ONE-TAP',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
                          ),
                        ),
                        Expanded(child: Divider(color: AppTheme.border)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedRole = UserRole.client;
                                _applyRoleDefaults(UserRole.client);
                              });
                            },
                            icon: const Icon(Icons.person, size: 15, color: AppTheme.primary),
                            label: const Text('Fill Customer', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              side: const BorderSide(color: AppTheme.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedRole = UserRole.rider;
                                _applyRoleDefaults(UserRole.rider);
                              });
                            },
                            icon: const Icon(Icons.two_wheeler, size: 15, color: Color(0xFF1B2A4A)),
                            label: const Text('Fill Rider', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF1B2A4A))),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              side: const BorderSide(color: Color(0xFF1B2A4A)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
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

  Widget _buildDemoInfoCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    required VoidCallback onTapFill,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: color),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: color.withAlpha(200)),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onTapFill,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Auto Fill',
                style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
