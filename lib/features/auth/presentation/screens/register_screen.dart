import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';
import 'package:routiner/features/auth/presentation/widgets/auth_header.dart';
import 'package:routiner/features/auth/presentation/widgets/auth_input_field.dart';
import 'package:routiner/features/auth/presentation/widgets/password_input_field.dart';
import 'package:routiner/features/auth/presentation/widgets/primary_button.dart';
import 'package:routiner/features/auth/domain/services/auth_service.dart';
import 'package:routiner/features/auth/domain/entities/user_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:routiner/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  
  final AuthService _authService = AuthService();
  
  bool _isEmailValid = true;
  bool _isPasswordValid = true;
  bool _isConfirmPasswordValid = true;
  bool _isFirstNameValid = true;
  bool _isLastNameValid = true;
  bool _isBirthDateValid = true;
  
  int _currentStep = 1;
  bool _isLoading = false; 
  
  Future<void> _saveRegistrationData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('registration_email', _emailController.text.trim());
    await prefs.setString('registration_password', _passwordController.text);
    await prefs.setString('registration_first_name', _firstNameController.text.trim());
    await prefs.setString('registration_last_name', _lastNameController.text.trim());
    await prefs.setString('registration_birth_date', _birthDateController.text.trim());
  }

  bool _validateEmail(String email) {
    if (email.isEmpty) return true;
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  bool _validatePassword(String password) {
    if (password.isEmpty) return true;
    return password.length >= 8;
  }

  bool _validateConfirmPassword(String password, String confirmPassword) {
    if (password.isEmpty || confirmPassword.isEmpty) return true;
    return password == confirmPassword;
  }

  bool _validateName(String name) {
    if (name.isEmpty) return true;
    return name.isNotEmpty;
  }

  bool _validateBirthDate(String date) {
    if (date.isEmpty) return true;
    try {
      final parts = date.split('.');
      if (parts.length != 3) return false;
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      
      if (day < 1 || day > 31) return false;
      if (month < 1 || month > 12) return false;
      if (year < 1900 || year > DateTime.now().year) return false;
      
      return true;
    } catch (e) {
      return false;
    }
  }

  bool get _isStep1Valid {
    final email = _emailController.text;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      return false;
    }
    
    return _validateEmail(email) && 
           _validatePassword(password) && 
           _validateConfirmPassword(password, confirmPassword);
  }

  bool get _isStep2Valid {
    final firstName = _firstNameController.text;
    final lastName = _lastNameController.text;
    final birthDate = _birthDateController.text;
    
    if (firstName.isEmpty || lastName.isEmpty || birthDate.isEmpty) {
      return false;
    }
    
    return _validateName(firstName) && 
           _validateName(lastName) && 
           _validateBirthDate(birthDate);
  }

  bool get _isFormValid {
    return _currentStep == 1 ? _isStep1Valid : _isStep2Valid;
  }

  void _validateInputs() {
    setState(() {
      if (_currentStep == 1) {
        _isEmailValid = _validateEmail(_emailController.text);
        _isPasswordValid = _validatePassword(_passwordController.text);
        _isConfirmPasswordValid = _validateConfirmPassword(_passwordController.text, _confirmPasswordController.text);
      } else {
        _isFirstNameValid = _validateName(_firstNameController.text);
        _isLastNameValid = _validateName(_lastNameController.text);
        _isBirthDateValid = _validateBirthDate(_birthDateController.text);
      }
    });
  }

  void _nextStep() {
    if (_currentStep == 1) {
      _validateInputs();
      if (_isStep1Valid) {
        setState(() {
          _currentStep = 2;
        });
      }
    }
  }

  void _previousStep() {
    setState(() {
      _currentStep = 1;
    });
  }

  void _handleNextStep() {
    _saveRegistrationData();
    _nextStep();
  }

  void _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(), // Нельзя выбрать будущую дату
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.blue100, // Цвет акцента
              onPrimary: Colors.white, // Цвет текста на кнопках
              surface: Colors.white, // Цвет фона календаря
              onSurface: AppColors.black100, // Цвет текста
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            // Уменьшаем текст кнопок
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                textStyle: const TextStyle(fontSize: 12),
                minimumSize: const Size(64, 32),
              ),
            ),
            // Уменьшаем текст в календаре
            textTheme: const TextTheme(
              bodyMedium: TextStyle(fontSize: 14),
              bodySmall: TextStyle(fontSize: 12),
              labelMedium: TextStyle(fontSize: 12),
            ),
            // Уменьшаем заголовок
            appBarTheme: const AppBarTheme(
              titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _birthDateController.text = '${picked.day.toString().padLeft(2, '0')}.${picked.month.toString().padLeft(2, '0')}.${picked.year}';
        _isBirthDateValid = true;
      });
    }
  }

  Future<void> _registerUser() async {
    if (!_isFormValid) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('[REGISTER] Starting registration for email: ${_emailController.text}');
      
      final userEntity = await _authService.registerWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        birthDate: _birthDateController.text.trim(),
        gender: '', // Заполнится на следующем экране
        habits: [], // Заполнится на следующих экранах
      );

      print('[REGISTER] Registration result: ${userEntity != null ? "success" : "failed"}');

      if (userEntity != null && mounted) {
        print('[REGISTER] Navigation to /gender');
        context.go('/gender');
      } else {
        print('[REGISTER] User entity is null');
        _showErrorDialog(context.l10n.translate('registrationFailed'));
      }
    } on FirebaseAuthException catch (e) {
      print('[REGISTER] FirebaseAuthException: ${e.code} - ${e.message}');
      String errorMessage = _getLocalizedAuthErrorMessage(e.code);
      _showErrorDialog(errorMessage);
    } catch (e, stackTrace) {
      print('[REGISTER] Error: $e');
      print('[REGISTER] Stack trace: $stackTrace');
      _showErrorDialog('${context.l10n.translate('registrationFailed')}: $e');
    } finally {
      if (mounted) {
        print('[REGISTER] Setting isLoading to false');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getLocalizedAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'weak-password':
        return context.l10n.translate('weakPassword');
      case 'email-already-in-use':
        return context.l10n.translate('emailAlreadyInUse');
      case 'invalid-email':
        return context.l10n.translate('invalidEmail');
      case 'operation-not-allowed':
        return context.l10n.translate('operationNotAllowed');
      default:
        return context.l10n.translate('registrationFailed');
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
    _confirmPasswordController.addListener(_validateInputs);
    _firstNameController.addListener(_validateInputs);
    _lastNameController.addListener(_validateInputs);
    _birthDateController.addListener(_validateInputs);
  }

  @override
  void dispose() {
    _emailController.removeListener(_validateInputs);
    _passwordController.removeListener(_validateInputs);
    _confirmPasswordController.removeListener(_validateInputs);
    _firstNameController.removeListener(_validateInputs);
    _lastNameController.removeListener(_validateInputs);
    _birthDateController.removeListener(_validateInputs);
    
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthDateController.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AuthHeader(
            title: _currentStep == 1 
                ? context.l10n.translate('registerTitle')
                : context.l10n.translate('registerPersonalInfoTitle'),
            onBackPressed: () {
              if (_currentStep == 1) {
                context.go('/auth');
              } else {
                _previousStep();
              }
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
                        if (_currentStep == 1) ...[
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
                          const SizedBox(height: 24),
                          PasswordInputField(
                            title: context.l10n.translate('registerConfirmPassword'),
                            hintText: context.l10n.translate('registerConfirmPasswordHint'),
                            controller: _confirmPasswordController,
                            isValid: _isConfirmPasswordValid,
                            onClear: () {
                              setState(() {
                                _confirmPasswordController.clear();
                                _isConfirmPasswordValid = true;
                              });
                            },
                          ),
                        ] else ...[
                          AuthInputField(
                            title: context.l10n.translate('registerFirstName'),
                            hintText: context.l10n.translate('registerFirstNameHint'),
                            controller: _firstNameController,
                            isValid: _isFirstNameValid,
                            onClear: () {
                              setState(() {
                                _firstNameController.clear();
                                _isFirstNameValid = true;
                              });
                            },
                          ),
                          const SizedBox(height: 24),
                          AuthInputField(
                            title: context.l10n.translate('registerLastName'),
                            hintText: context.l10n.translate('registerLastNameHint'),
                            controller: _lastNameController,
                            isValid: _isLastNameValid,
                            onClear: () {
                              setState(() {
                                _lastNameController.clear();
                                _isLastNameValid = true;
                              });
                            },
                          ),
                          const SizedBox(height: 24),
                          GestureDetector(
                            onTap: _selectBirthDate,
                            child: AbsorbPointer(
                              child: AuthInputField(
                                title: context.l10n.translate('registerBirthDate'),
                                hintText: context.l10n.translate('registerBirthDateHint'),
                                controller: _birthDateController,
                                isValid: _isBirthDateValid,
                                onClear: () {
                                  setState(() {
                                    _birthDateController.clear();
                                    _isBirthDateValid = true;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
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
                        context.go('/auth');
                      },
                      child: Text.rich(
                        TextSpan(
                          text: context.l10n.translate('alreadyHaveAccount'),
                          style: AppFonts.body.copyWith(
                            color: AppColors.black100,
                          ),
                          children: [
                            TextSpan(
                              text: context.l10n.translate('signIn'),
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
                    text: _currentStep == 1 
                        ? context.l10n.translate('authNext')
                        : context.l10n.translate('registerCreateAccount'),
                    onPressed: _currentStep == 1 ? _handleNextStep : _registerUser,
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
