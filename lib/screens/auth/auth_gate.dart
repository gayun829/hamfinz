import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.onAuthenticated});

  final VoidCallback onAuthenticated;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final user = await AuthService.instance.getCurrentUser();
    if (!mounted) return;
    if (user != null) {
      widget.onAuthenticated();
      return;
    }
    setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Text('🐹', textAlign: TextAlign.center, style: TextStyle(fontSize: 72)),
              const SizedBox(height: 16),
              const Text(
                '핀퀴즈',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '매일 5분, 재미있는 금융 퀴즈',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () async {
                  final success = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => const SignupScreen()),
                  );
                  if (success == true) widget.onAuthenticated();
                },
                child: const Text('이메일로 회원가입'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () async {
                  final success = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                  if (success == true) widget.onAuthenticated();
                },
                child: const Text('로그인'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
