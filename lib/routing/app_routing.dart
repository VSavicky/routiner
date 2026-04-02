import 'package:go_router/go_router.dart';
import 'package:routiner/features/auth/presentation/screens/auth_screen.dart';
import 'package:routiner/features/onboarding/presentation/screens/onboarding_screen.dart';

final router = GoRouter(
  initialLocation: '/onboarding',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthScreen(),
    ),
  ],
);
