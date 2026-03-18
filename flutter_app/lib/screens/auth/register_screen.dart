import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/router.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/gradient_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Необходимо принять пользовательское соглашение'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(authStateProvider.notifier).register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            displayName: _nameController.text.trim().isNotEmpty
                ? _nameController.text.trim()
                : null,
          );

      if (mounted) {
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo area
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: AppTheme.secondaryGradient,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.secondaryColor
                                  .withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.person_add,
                            size: 36, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Создать аккаунт',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.comfortaa(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Присоединяйтесь к TaleKID',
                      textAlign: TextAlign.center,
                      style: AppTheme.body(
                        size: 15,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Form card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.glassLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppTheme.glassBorder, width: 0.5),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Column(
                        children: [
                          // Name field
                          TextFormField(
                            controller: _nameController,
                            autofillHints: const [AutofillHints.name],
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Имя (необязательно)',
                              hintText: 'Как вас зовут?',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Email field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              hintText: 'example@mail.com',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Введите email';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(value.trim())) {
                                return 'Некорректный email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Password field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            autofillHints: const [AutofillHints.newPassword],
                            decoration: InputDecoration(
                              labelText: 'Пароль',
                              hintText: 'Минимум 6 символов',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppTheme.textLight,
                                ),
                                onPressed: () {
                                  setState(() =>
                                      _obscurePassword = !_obscurePassword);
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Введите пароль';
                              }
                              if (value.length < 6) {
                                return 'Пароль должен быть не менее 6 символов';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Confirm password field
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirm,
                            decoration: InputDecoration(
                              labelText: 'Подтвердите пароль',
                              hintText: 'Повторите пароль',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppTheme.textLight,
                                ),
                                onPressed: () {
                                  setState(() =>
                                      _obscureConfirm = !_obscureConfirm);
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value != _passwordController.text) {
                                return 'Пароли не совпадают';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Terms agreement — styled
                          GestureDetector(
                            onTap: () => setState(
                                () => _agreedToTerms = !_agreedToTerms),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: _agreedToTerms
                                    ? AppTheme.primaryColor
                                        .withValues(alpha: 0.06)
                                    : AppTheme.fillColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _agreedToTerms
                                      ? AppTheme.primaryColor
                                      : AppTheme.borderColor,
                                  width: _agreedToTerms ? 1.5 : 0.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: _agreedToTerms
                                          ? AppTheme.primaryColor
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: _agreedToTerms
                                            ? AppTheme.primaryColor
                                            : AppTheme.textLight,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: _agreedToTerms
                                        ? const Icon(Icons.check,
                                            size: 14, color: Colors.white)
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Wrap(
                                      children: [
                                        Text(
                                          'Я принимаю ',
                                          style: GoogleFonts.nunitoSans(
                                              fontSize: 12,
                                              color: AppTheme.textSecondary),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            context.push(AppRoutes.terms);
                                          },
                                          child: Text(
                                            'соглашение',
                                            style: GoogleFonts.nunitoSans(
                                              fontSize: 12,
                                              color: AppTheme.primaryColor,
                                              fontWeight: FontWeight.w600,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          ' и ',
                                          style: GoogleFonts.nunitoSans(
                                              fontSize: 12,
                                              color: AppTheme.textSecondary),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            context.push(AppRoutes.privacy);
                                          },
                                          child: Text(
                                            'политику',
                                            style: GoogleFonts.nunitoSans(
                                              fontSize: 12,
                                              color: AppTheme.primaryColor,
                                              fontWeight: FontWeight.w600,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          ' и ',
                                          style: GoogleFonts.nunitoSans(
                                              fontSize: 12,
                                              color: AppTheme.textSecondary),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            context.push(AppRoutes.consent);
                                          },
                                          child: Text(
                                            'согласие на обработку ПД',
                                            style: GoogleFonts.nunitoSans(
                                              fontSize: 12,
                                              color: AppTheme.primaryColor,
                                              fontWeight: FontWeight.w600,
                                              decoration:
                                                  TextDecoration.underline,
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
                          const SizedBox(height: 20),

                          // Register button
                          GradientButton(
                            text: 'Создать аккаунт',
                            icon: Icons.person_add,
                            isLoading: _isLoading,
                            onPressed: _isLoading ? null : _handleRegister,
                            gradient: AppTheme.secondaryGradient,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Login link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Уже есть аккаунт? ',
                          style: AppTheme.body(
                            size: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go(AppRoutes.login),
                          child: Text(
                            'Войти',
                            style: GoogleFonts.nunitoSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
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
