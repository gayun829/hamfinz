import 'package:flutter/material.dart';

import 'screens/auth/auth_gate.dart';
import 'screens/home/home_screen.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.instance.init();
  runApp(const FinQuizApp());
}

class FinQuizApp extends StatelessWidget {
  const FinQuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '핀퀴즈',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const AppRoot(),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool _authenticated = false;

  void _onAuthenticated() {
    setState(() => _authenticated = true);
  }

  void _onLogout() {
    setState(() => _authenticated = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_authenticated) {
      return HomeScreen(onLogout: _onLogout);
    }

    return AuthGate(onAuthenticated: _onAuthenticated);
  }
}
