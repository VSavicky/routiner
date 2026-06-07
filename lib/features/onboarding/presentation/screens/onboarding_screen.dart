import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';
import 'package:routiner/features/auth/domain/services/google_sign_in_service.dart';
import 'package:routiner/l10n/app_localizations.dart';
import 'package:routiner/main.dart' show changeAppLocale;

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;
  final GoogleSignInService _googleSignInService = GoogleSignInService();
  bool _isLoading = false;

  final List<Map<String, String>> _onboardingData = [
    {
      'image': 'assets/images/onboarding/onboarding1.png',
      'title': 'onboardingWelcomeTitle',
      'subtitle': 'onboardingWelcomeSubtitle',
      'description': 'onboardingWelcomeDescription',
    },
    {
      'image': 'assets/images/onboarding/onboarding2.png',
      'title': 'onboardingTrackTitle',
      'subtitle': 'onboardingTrackSubtitle',
      'description': 'onboardingTrackDescription',
    },
    {
      'image': 'assets/images/onboarding/onboarding3.png',
      'title': 'onboardingAchieveTitle',
      'subtitle': 'onboardingAchieveSubtitle',
      'description': 'onboardingAchieveDescription',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentPage < _onboardingData.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
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
        _showErrorDialog('Google sign in failed.');
      }
    } catch (e) {
      _showErrorDialog('Error: ${e.toString()}');
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
            child: const Text(
              'OK',
              style: TextStyle(color: AppColors.blue100),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.purple,
              AppColors.blue,
            ],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  const SizedBox(height: 56),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemCount: _onboardingData.length,
                      itemBuilder: (context, index) {
                        final data = _onboardingData[index];
                        return Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Spacer(),
                              Flexible(
                                flex: 2,
                                child: Center(
                                  child: Image.asset(
                                    data['image']!,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                context.l10n.translate(data['subtitle']!),
                                style: AppFonts.headlineH2,
                              ),
                              const SizedBox(height: 32),
                              Text(
                                context.l10n.translate(data['description']!),
                                style: AppFonts.body,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: List.generate(
                        _onboardingData.length,
                        (index) => Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.4),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          context.go('/auth');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                        ),
                        child: Text(
                          context.l10n.translate('continueWithEmail'),
                          style: AppFonts.body.copyWith(
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signInWithGoogle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.black),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.asset(
                                    'assets/icons/google.svg',
                                    width: 20,
                                    height: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    context.l10n.translate('continueWithGoogle'),
                                    style: AppFonts.body.copyWith(
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 84),
                ],
              ),
              Positioned(
                top: 0,
                right: 16,
                child: PopupMenuButton<String>(
                  offset: const Offset(0, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: Colors.white,
                  elevation: 8,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.language,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  onSelected: (language) {
                    final localeMap = {
                      'English': const Locale('en', 'US'),
                      'Русский': const Locale('ru', 'RU'),
                      'Қазақша': const Locale('kk', 'KZ'),
                    };
                    final locale = localeMap[language];
                    if (locale != null) {
                      changeAppLocale(locale);
                    }
                  },
                  itemBuilder: (context) => [
                    _buildLanguageItem('English', '🇺🇸'),
                    _buildLanguageItem('Русский', '🇷🇺'),
                    _buildLanguageItem('Қазақша', '🇰🇿'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildLanguageItem(String language, String flag) {
    return PopupMenuItem<String>(
      value: language,
      child: Row(
        children: [
          Text(
            flag,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 12),
          Text(
            language,
            style: const TextStyle(
              color: AppColors.black100,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }
}
