import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:routiner/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:routiner/features/auth/presentation/screens/auth_screen.dart';
import 'package:routiner/features/auth/presentation/screens/register_screen.dart';
import 'package:routiner/features/auth/presentation/screens/gender_selection_screen.dart';
import 'package:routiner/features/auth/presentation/screens/habit_selection_screen.dart';
import 'package:routiner/features/explore/presentation/screens/explore_screen.dart';
import 'package:routiner/features/home/presentation/screens/home_screen.dart';
import 'package:routiner/features/root/presentation/screens/root_screen.dart';
import 'package:routiner/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:routiner/features/profile/presentation/screens/profile_screen.dart';
import 'package:routiner/features/splash/presentation/screens/splash_screen.dart';

final router = GoRouter(
  initialLocation: '/splash',
  routes: [
    // Splash screen
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    // Авторизационные роуты
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
    
    // Основной экран с нижней навигацией
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => RootScreen(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/analytics',
              builder: (context, state) => const AnalyticsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/add',
              builder: (context, state) => const Center(
                child: Text('Добавить привычку'),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/explore',
              builder: (context, state) => const ExploreScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
