import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/router.dart';
import '../config/theme.dart';

/// Cookie consent banner — web only.
/// Stored in localStorage via FlutterSecureStorage.
/// Shown once; hidden permanently after "Понятно".
class CookieBanner extends StatefulWidget {
  const CookieBanner({super.key});

  @override
  State<CookieBanner> createState() => _CookieBannerState();
}

class _CookieBannerState extends State<CookieBanner>
    with SingleTickerProviderStateMixin {
  static const _storageKey = 'cookie_consent_v1';
  static const _storage = FlutterSecureStorage();

  bool _visible = false;
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    if (kIsWeb) _checkConsent();
  }

  Future<void> _checkConsent() async {
    final stored = await _storage.read(key: _storageKey);
    if (stored == null && mounted) {
      setState(() => _visible = true);
      _ctrl.forward();
    }
  }

  Future<void> _accept() async {
    await _storage.write(key: _storageKey, value: '1');
    await _ctrl.reverse();
    if (mounted) setState(() => _visible = false);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || !_visible) return const SizedBox.shrink();

    return SlideTransition(
      position: _slide,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1830),
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.10),
              width: 0.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.cookie_outlined,
                        color: AppTheme.accentColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Text
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Мы используем cookies для работы сервиса. '
                            'Продолжая использовать сайт, вы соглашаетесь с ',
                            style: GoogleFonts.nunitoSans(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.75),
                              height: 1.4,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.go(AppRoutes.privacy),
                            child: Text(
                              'Политикой конфиденциальности',
                              style: GoogleFonts.nunitoSans(
                                fontSize: 13,
                                color: AppTheme.primaryLight,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                decorationColor: AppTheme.primaryLight,
                                height: 1.4,
                              ),
                            ),
                          ),
                          Text(
                            '.',
                            style: GoogleFonts.nunitoSans(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Accept button
                    GestureDetector(
                      onTap: _accept,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 9),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Понятно',
                          style: GoogleFonts.nunitoSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
