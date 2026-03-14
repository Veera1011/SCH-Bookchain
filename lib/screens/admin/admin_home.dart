import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/providers.dart';
import '../../widgets/navigation/responsive_navigation.dart';
import '../employee/ai_assistant_screen.dart';

class AdminHome extends ConsumerWidget {
  final Widget child;

  const AdminHome({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return ResponsiveNavigation(
      selectedIndex: _calculateSelectedIndex(context),
      onDestinationSelected: (int index) => _onItemTapped(index, context),
      title: Text('ADMIN DASHBOARD', style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface, fontSize: 14, letterSpacing: 1.2)),
      drawer: Drawer(
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
                  ),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/images/sch_logo.svg',
                      height: 40,
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.primary,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ADMIN PORTAL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildDrawerItem(
              context,
              icon: Icons.settings_outlined,
              label: 'THEME SETTINGS',
              onTap: () {
                Navigator.pop(context);
                context.push('/admin/theme');
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.location_on_outlined,
              label: 'MANAGE LOCATIONS',
              onTap: () {
                Navigator.pop(context);
                context.push('/admin/locations');
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.help_outline,
              label: 'HELP & SUPPORT',
              onTap: () {
                Navigator.pop(context);
                launchUrl(Uri.parse('https://supplychainhub.com'));
              },
            ),
            const Spacer(),
            const Divider(indent: 20, endIndent: 20),
            _buildDrawerItem(
              context,
              icon: Icons.logout,
              label: 'SIGN OUT',
              color: Colors.red,
              onTap: () => ref.read(authServiceProvider).signOut(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics),
          label: 'Analytics',
        ),
        const NavigationDestination(
          icon: Icon(Icons.library_books_outlined),
          selectedIcon: Icon(Icons.library_books),
          label: 'Inventory',
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
    if (location.startsWith('/admin/books')) return 1;
    if (location.startsWith('/admin/users')) return 2;
    if (location.startsWith('/admin/borrows')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0: context.go('/admin'); break;
      case 1: context.go('/admin/books'); break;
      case 2: context.go('/admin/users'); break;
      case 3: context.go('/admin/borrows'); break;
    }
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: color ?? Theme.of(context).colorScheme.onSurface.withOpacity(0.7), size: 20),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 11,
            letterSpacing: 1,
            color: color ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        hoverColor: Theme.of(context).colorScheme.primary.withOpacity(0.05),
      ),
    );
  }
}
