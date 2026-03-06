import 'package:board_app/features/auth/view/login_screen.dart';
import 'package:board_app/features/auth/view/register_screen.dart';
import 'package:board_app/features/splash/view/splash_screen.dart';
import 'package:board_app/features/onboarding/view/onboarding_screen.dart';
import 'package:board_app/features/boards/view/boards_screen.dart';
import 'package:board_app/features/workspace/view/board_detail_screen.dart';
import 'package:board_app/features/profile/view/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:board_app/core/theme/app_theme.dart';
import 'package:board_app/core/theme/theme_provider.dart';
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) {
        return MainAppShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/boards',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: BoardsScreen()),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ProfileScreen()),
        ),
      ],
    ),
    GoRoute(
      path: '/board/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return BoardDetailScreen(boardId: id);
      },
    ),
  ],
);

class MainAppShell extends ConsumerWidget {
  final Widget child;

  const MainAppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _getIndex(location);
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: isDarkMode ? Colors.grey[400] : Colors.grey,
        currentIndex: currentIndex,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/boards');
              break;
            case 1:
              context.go('/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: "Boards",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  int _getIndex(String location) {
    if (location.startsWith('/boards')) return 0;
    if (location.startsWith('/profile')) return 1;
    return 0;
  }
}
