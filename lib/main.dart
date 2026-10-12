import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'services/api_service.dart';
import 'state/cart_state.dart';
import 'state/user_state.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase not initialized: $e');
  }

  runApp(const CraveeFoodApp());
}

class CraveeFoodApp extends StatefulWidget {
  const CraveeFoodApp({super.key});

  @override
  State<CraveeFoodApp> createState() => _CraveeFoodAppState();
}

class _CraveeFoodAppState extends State<CraveeFoodApp> {
  late final CartState _cartState;
  late final UserState _userState;

  @override
  void initState() {
    super.initState();
    _cartState = CartState();
    _userState = UserState();
    ApiService.instance.syncWithBackend(userState: _userState);
  }

  @override
  void dispose() {
    _cartState.dispose();
    _userState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Court — Food & Grocery Delivery',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: HomeScreen(cartState: _cartState, userState: _userState),
    );
  }
}
