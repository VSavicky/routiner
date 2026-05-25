import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';
import 'package:routiner/features/auth/presentation/widgets/auth_header.dart';
import 'package:routiner/features/auth/presentation/widgets/auth_input_field.dart';
import 'package:routiner/features/auth/presentation/widgets/password_input_field.dart';
import 'package:routiner/features/auth/presentation/widgets/primary_button.dart';
import 'package:routiner/features/auth/domain/services/auth_service.dart';
import 'package:routiner/features/auth/domain/services/google_sign_in_service.dart';
import 'package:routiner/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final GoogleSignInService _googleSignInService = GoogleSignInService();
  
  bool _isEmailValid = true;
  bool _isPasswordValid = true;
  bool _isLoading = false;

  bool _validateEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  bool _validatePassword(String password) {
    return password.length >= 8;
  }

  bool get _isFormValid {
    return _isEmailValid && _isPasswordValid && 
           _emailController.text.isNotEmpty && _passwordController.text.isNotEmpty;
  }

  void _validateInputs() {
    setState(() {
      _isEmailValid = _validateEmail(_emailController.text);
      _isPasswordValid = _validatePassword(_passwordController.text);
    });
  }

  Future<void> _signInWithEmail() async {
    if (!_isFormValid) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('[AUTH] Signing in with email: ${_emailController.text}');
      
      final userEntity = await _authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      print('[AUTH] Sign in result: ${userEntity != null ? "success" : "failed"}');

      if (userEntity != null && mounted) {
        print('[AUTH] Navigation to /home');
        context.go('/home');
      } else {
        print('[AUTH] User entity is null');
        _showErrorDialog(context.l10n.translate('signInFailed'));
      }
    } on FirebaseAuthException catch (e) {
      print('[AUTH] FirebaseAuthException: ${e.code} - ${e.message}');
      String errorMessage = _getLocalizedAuthErrorMessage(e.code);
      _showErrorDialog(errorMessage);
    } catch (e, stackTrace) {
      print('[AUTH] Error: $e');
      print('[AUTH] Stack trace: $stackTrace');
      _showErrorDialog('${context.l10n.translate('signInFailed')}: $e');
    } finally {
      if (mounted) {
        print('[AUTH] Setting isLoading to false');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getLocalizedAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'wrong-password':
        return context.l10n.translate('wrongPassword');
      case 'user-not-found':
        return context.l10n.translate('userNotFound');
      case 'invalid-email':
        return context.l10n.translate('invalidEmail');
      case 'user-disabled':
        return context.l10n.translate('userDisabled');
      case 'too-many-requests':
        return context.l10n.translate('tooManyRequests');
      default:
        return context.l10n.translate('signInFailed');
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userEntity = await _googleSignInService.signInWithGoogle();

      if (userEntity != null) {
        if (mounted) {
          context.go('/home');
        }
      } else {
        _showErrorDialog(context.l10n.translate('googleSignInFailed'));
      }
    } catch (e) {
      _showErrorDialog(context.l10n.translateWithArgs('googleSignInError', {'error': e.toString()}));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: AppColors.black100,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: const TextStyle(
          color: AppColors.black100,
          fontSize: 16,
          height: 1.35,
        ),
        title: Text(context.l10n.translate('error')),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              context.l10n.translate('ok'),
              style: const TextStyle(color: AppColors.blue100),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateInputs);
    _passwordController.addListener(_validateInputs);
  }

  @override
  void dispose() {
    _emailController.removeListener(_validateInputs);
    _passwordController.removeListener(_validateInputs);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AuthHeader(
            title: context.l10n.translate('authTitle'),
            onBackPressed: () {
              context.go('/onboarding');
            },
          ),
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        AuthInputField(
                          title: context.l10n.translate('authEmailTitle'),
                          hintText: context.l10n.translate('authEmailHint'),
                          controller: _emailController,
                          isValid: _isEmailValid,
                          onClear: () {
                            setState(() {
                              _emailController.clear();
                              _isEmailValid = true;
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        PasswordInputField(
                          title: context.l10n.translate('authPasswordTitle'),
                          hintText: context.l10n.translate('authPasswordHint'),
                          controller: _passwordController,
                          isValid: _isPasswordValid,
                          onClear: () {
                            setState(() {
                              _passwordController.clear();
                              _isPasswordValid = true;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () {
                              
                            },
                            child: Text(
                              context.l10n.translate('authForgotPassword'),
                              style: AppFonts.body.copyWith(
                                color: AppColors.black60,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 82,
                  child: Align(
                    alignment: Alignment.center,
                    child: GestureDetector(
                      onTap: () {
                        context.go('/register');
                      },
                      child: Text.rich(
                        TextSpan(
                          text: context.l10n.translate('authNoAccount'),
                          style: AppFonts.body.copyWith(
                            color: AppColors.black100,
                          ),
                          children: [
                            TextSpan(
                              text: context.l10n.translate('authCreateAccount'),
                              style: AppFonts.body.copyWith(
                                color: AppColors.blue100,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 20,
                  child: PrimaryButton(
                    text: _isLoading ? context.l10n.translate('authSigningIn') : context.l10n.translate('authNext'),
                    onPressed: _isFormValid && !_isLoading ? _signInWithEmail : null,
                    isActive: _isFormValid && !_isLoading,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
