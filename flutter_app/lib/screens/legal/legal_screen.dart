import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_config.dart';
import '../../config/theme.dart';
import 'legal_content.dart';

/// Generic legal document screen.
/// - Web: renders Markdown text inline.
/// - APK/mobile: opens the external URL in browser.
class LegalScreen extends StatelessWidget {
  final String title;
  final String url;
  final String markdownContent;

  const LegalScreen({
    super.key,
    required this.title,
    required this.url,
    required this.markdownContent,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _buildWebView(context);
    } else {
      return _buildMobileView(context);
    }
  }

  Widget _buildWebView(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: 'Открыть в браузере',
            onPressed: () => _openUrl(url),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Markdown(
            data: markdownContent,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingXl,
              vertical: AppTheme.spacingLg,
            ),
            onTapLink: (text, href, title) {
              if (href != null) _openUrl(href);
            },
            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
              h1: Theme.of(context).textTheme.headlineMedium,
              h2: Theme.of(context).textTheme.titleLarge,
              p: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileView(BuildContext context) {
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
                'Документ опубликован на сайте TaleKID',
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

/// Convenience wrappers for each legal document.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalScreen(
      title: 'Пользовательское соглашение',
      url: AppConfig.termsUrl,
      markdownContent: kTermsMarkdown,
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
      markdownContent: kPrivacyMarkdown,
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
      markdownContent: kConsentMarkdown,
    );
  }
}
