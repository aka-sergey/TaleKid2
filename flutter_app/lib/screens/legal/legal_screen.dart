import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_config.dart';
import '../../config/theme.dart';

/// Generic legal document screen.
/// Opens the external URL and shows a placeholder while loading.
class LegalScreen extends StatelessWidget {
  final String title;
  final String url;

  const LegalScreen({
    super.key,
    required this.title,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.description,
                size: 64,
                color: AppTheme.primaryLight,
              ),
              const SizedBox(height: AppTheme.spacingLg),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                'Документ доступен на сайте TaleKID',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingXl),
              ElevatedButton.icon(
                onPressed: () => _openUrl(url),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Открыть в браузере'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Convenience constructors for each legal page.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalScreen(
      title: 'Пользовательское соглашение',
      url: AppConfig.termsUrl,
    );
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalScreen(
      title: 'Политика конфиденциальности',
      url: AppConfig.privacyUrl,
    );
  }
}

class ConsentScreen extends StatelessWidget {
  const ConsentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalScreen(
      title: 'Согласие на обработку данных',
      url: AppConfig.consentUrl,
    );
  }
}
