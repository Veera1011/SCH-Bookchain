import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/navigation/responsive_navigation.dart';
import '../../widgets/navigation/app_drawer.dart';

class EmployeeHome extends ConsumerWidget {
  final Widget child;

  const EmployeeHome({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return ResponsiveNavigation(
      selectedIndex: _calculateSelectedIndex(context),
      onDestinationSelected: (int index) => _onItemTapped(index, context),
      actions: [
        IconButton(
          icon: const Icon(Icons.qr_code_scanner),
          onPressed: () => context.push('/qr-scanner'),
        ),
      ],
      drawer: const AppDrawer(isAdmin: false),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.auto_awesome_outlined),
          selectedIcon: Icon(Icons.auto_awesome),
          label: 'Discover',
        ),
        NavigationDestination(
          icon: Icon(Icons.search_outlined),
          selectedIcon: Icon(Icons.search),
          label: 'Browse',
        ),
        NavigationDestination(
          icon: Icon(Icons.book_outlined),
          selectedIcon: Icon(Icons.book),
          label: 'My Books',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
      child: child,
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location == '/home') return 0;
    if (location.startsWith('/browse')) return 1;
    if (location.startsWith('/my-books')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0: context.go('/home'); break;
      case 1: context.go('/browse'); break;
      case 2: context.go('/my-books'); break;
      case 3: context.go('/profile'); break;
    }
  }
}
