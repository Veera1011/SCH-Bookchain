import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';
import '../../providers/providers.dart';

class AppDrawer extends ConsumerWidget {
  final bool isAdmin;

  const AppDrawer({super.key, required this.isAdmin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final profileAsync = ref.watch(currentProfileProvider);

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Stack(
        children: [
          // Glassmorphic background
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.8),
                  border: Border(
                    right: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header with Profile
                _buildHeader(context, profileAsync),
                const SizedBox(height: 20),
                
                // Navigation Items
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        if (isAdmin) ..._buildAdminItems(context)
                        else ..._buildEmployeeItems(context),
                        
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Divider(),
                        ),
                        
                        _buildDrawerItem(
                          context,
                          icon: Icons.help_outline_rounded,
                          label: 'HELP & SUPPORT',
                          onTap: () => launchUrl(Uri.parse('https://supplychainhub.com')),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Section
                _buildBottomSection(context, ref),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AsyncValue profileAsync) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Image.asset(
            'assets/images/sch_logo.png',
            height: 48,
          ),
          const SizedBox(height: 24),
          profileAsync.when(
            data: (profile) => Column(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                  child: Text(
                    profile?.name.substring(0, 1).toUpperCase() ?? '?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  profile?.name.toUpperCase() ?? 'GUEST USER',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  (profile?.role ?? 'UNKNOWN').toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            loading: () => const CircularProgressIndicator(),
            error: (error, stack) => const Icon(Icons.error_outline),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAdminItems(BuildContext context) {
    return [
      _buildDrawerItem(
        context,
        icon: Icons.settings_suggest_outlined,
        label: 'SETTINGS',
        onTap: () {
          Navigator.pop(context);
          context.push('/admin/theme');
        },
      ),
      _buildDrawerItem(
        context,
        icon: Icons.hub_outlined,
        label: 'MANAGE LOCATIONS',
        onTap: () {
          Navigator.pop(context);
          context.push('/admin/locations');
        },
      ),
    ];
  }

  List<Widget> _buildEmployeeItems(BuildContext context) {
    return [
      _buildDrawerItem(
        context,
        icon: Icons.person_outline_rounded,
        label: 'MY PROFILE',
        onTap: () {
          Navigator.pop(context);
          context.go('/profile');
        },
      ),
      _buildDrawerItem(
        context,
        icon: Icons.history_rounded,
        label: 'BORROW HISTORY',
        onTap: () {
          Navigator.pop(context);
          context.go('/my-books'); // Assuming this leads to history/my books
        },
      ),
    ];
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          leading: Icon(
            icon, 
            color: color ?? colorScheme.onSurface.withValues(alpha: 0.7), 
            size: 22
          ),
          title: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 1,
              color: color ?? colorScheme.onSurface,
            ),
          ),
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          hoverColor: colorScheme.primary.withValues(alpha: 0.1),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 12),
          _buildDrawerItem(
            context,
            icon: Icons.logout_rounded,
            label: 'SIGN OUT',
            color: Colors.redAccent,
            onTap: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
    );
  }
}
