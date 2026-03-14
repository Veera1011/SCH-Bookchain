import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/providers.dart';
import '../../widgets/navigation/responsive_navigation.dart';

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
                      'MEMBER ACCESS',
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
              icon: Icons.person_outline,
              label: 'MY PROFILE',
              onTap: () {
                Navigator.pop(context);
                context.go('/profile');
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
      destinations: const [
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
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/my-books')) return 1;
    if (location.startsWith('/profile')) return 2;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0: context.go('/home'); break;
      case 1: context.go('/my-books'); break;
      case 2: context.go('/profile'); break;
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
