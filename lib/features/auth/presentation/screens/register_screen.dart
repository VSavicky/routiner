import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';
import 'package:routiner/features/auth/presentation/widgets/auth_header.dart';
import 'package:routiner/features/auth/presentation/widgets/auth_input_field.dart';
import 'package:routiner/features/auth/presentation/widgets/password_input_field.dart';
import 'package:routiner/features/auth/presentation/widgets/primary_button.dart';

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
  
  bool _isEmailValid = true;
  bool _isPasswordValid = true;
  bool _isConfirmPasswordValid = true;
  bool _isFirstNameValid = true;
  bool _isLastNameValid = true;
  bool _isBirthDateValid = true;
  
  int _currentStep = 1; 
  
  bool _validateEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  bool _validatePassword(String password) {
    return password.length >= 8;
  }

  bool _validateConfirmPassword(String password, String confirmPassword) {
    return password == confirmPassword && password.isNotEmpty;
  }

  bool _validateName(String name) {
    return name.isNotEmpty;
  }

  bool _validateBirthDate(String date) {
    if (date.isEmpty) return false;
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
    return _isEmailValid && _isPasswordValid && _isConfirmPasswordValid &&
           _emailController.text.isNotEmpty && _passwordController.text.isNotEmpty && _confirmPasswordController.text.isNotEmpty;
  }

  bool get _isStep2Valid {
    return _isFirstNameValid && _isLastNameValid && _isBirthDateValid &&
           _firstNameController.text.isNotEmpty && _lastNameController.text.isNotEmpty && _birthDateController.text.isNotEmpty;
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

  void _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        _birthDateController.text = '${picked.day.toString().padLeft(2, '0')}.${picked.month.toString().padLeft(2, '0')}.${picked.year}';
        _isBirthDateValid = true;
      });
    }
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
            title: _currentStep == 1 ? 'Create Account' : 'Personal Information',
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
                            title: 'E-mail',
                            hintText: 'Enter your e-mail',
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
                            title: 'Password',
                            hintText: 'Enter your password',
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
                            title: 'Confirm Password',
                            hintText: 'Confirm your password',
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
                            title: 'First Name',
                            hintText: 'Enter your first name',
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
                            title: 'Last Name',
                            hintText: 'Enter your last name',
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
                                title: 'Birth Date',
                                hintText: 'DD.MM.YYYY',
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
                          text: "Already have account? ",
                          style: AppFonts.body.copyWith(
                            color: AppColors.black100,
                          ),
                          children: [
                            TextSpan(
                              text: "Sign In!",
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
                    text: _currentStep == 1 ? 'Next' : 'Create Account',
                    onPressed: _currentStep == 1 ? _nextStep : () {
                      context.go('/gender');
                    },
                    isActive: _isFormValid,
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
