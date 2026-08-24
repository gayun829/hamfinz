import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/auth/auth_gate.dart';
import 'screens/home/main_shell.dart';
import 'theme/app_theme.dart';
import 'widgets/mobile_viewport.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const HamfinzApp());
}

class HamfinzApp extends StatelessWidget {
  const HamfinzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '햄핀즈',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      builder: (context, child) => MobileViewport(child: child),
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
      return MainShell(onLogout: _onLogout);
    }

    return AuthGate(onAuthenticated: _onAuthenticated);
  }
}
