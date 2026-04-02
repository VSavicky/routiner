import 'package:go_router/go_router.dart';
import 'package:routiner/features/auth/presentation/screens/auth_screen.dart';
import 'package:routiner/features/auth/presentation/screens/register_screen.dart';
import 'package:routiner/features/auth/presentation/screens/gender_selection_screen.dart';
import 'package:routiner/features/auth/presentation/screens/habit_selection_screen.dart';
import 'package:routiner/features/home/presentation/screens/home_screen.dart';
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
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/gender',
      builder: (context, state) => const GenderSelectionScreen(),
    ),
    GoRoute(
      path: '/habits',
      builder: (context, state) => const HabitSelectionScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomePage(),
    ),
  ],
);
