import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/providers.dart';
import '../../widgets/navigation/responsive_navigation.dart';
import '../../widgets/navigation/app_drawer.dart';
import '../employee/ai_assistant_screen.dart';

class AdminHome extends ConsumerWidget {
  final Widget child;

  const AdminHome({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return ResponsiveNavigation(
      selectedIndex: _calculateSelectedIndex(context),
      onDestinationSelected: (int index) => _onItemTapped(index, context),
      drawer: const AppDrawer(isAdmin: true),
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics),
          label: 'Analytics',
        ),
        const NavigationDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2),
          label: 'Inventory',
        ),
        const NavigationDestination(
          icon: Icon(Icons.library_books_outlined),
          selectedIcon: Icon(Icons.library_books),
          label: 'Books',
        ),
        const NavigationDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: 'Users',
        ),
        const NavigationDestination(
          icon: Icon(Icons.compare_arrows_outlined),
          selectedIcon: Icon(Icons.compare_arrows),
          label: 'Borrows',
        ),
      ],
      child: child,
      floatingActionButton: ref.watch(booksProvider).maybeWhen(
        data: (books) => FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AIAssistantScreen(availableBooks: books),
                fullscreenDialog: true,
              ),
            );
          },
          backgroundColor: Theme.of(context).colorScheme.primary,
          icon: const Icon(Icons.auto_awesome, color: Colors.amber),
          label: Text(
            'ASK AI',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
        ),
        orElse: () => null,
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location == '/admin') return 0;
    if (location == '/admin/discovery') return 1;
    if (location.startsWith('/admin/books')) return 2;
    if (location.startsWith('/admin/users')) return 3;
    if (location.startsWith('/admin/borrows')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0: context.go('/admin'); break;
      case 1: context.go('/admin/discovery'); break;
      case 2: context.go('/admin/books'); break;
      case 3: context.go('/admin/users'); break;
      case 4: context.go('/admin/borrows'); break;
    }
  }

}
