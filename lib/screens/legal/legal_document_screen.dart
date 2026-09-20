import 'package:flutter/material.dart';

import '../../data/legal_documents.dart';
import '../../theme/app_theme.dart';
/// 이용약관 / 개인정보 처리방침 본문 화면.
class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  static Future<void> openTerms(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const LegalDocumentScreen(
          title: LegalDocuments.termsTitle,
          body: LegalDocuments.termsBody,
        ),
      ),
    );
  }

  static Future<void> openPrivacy(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const LegalDocumentScreen(
          title: LegalDocuments.privacyTitle,
          body: LegalDocuments.privacyBody,
        ),
      ),
    );
  }

  static Future<void> openMarketing(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const LegalDocumentScreen(
          title: LegalDocuments.marketingTitle,
          body: LegalDocuments.marketingBody,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Text(
            body,
            style: const TextStyle(
              fontSize: 15,
              height: 1.55,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
