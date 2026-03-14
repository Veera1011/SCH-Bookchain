import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(booksProvider);
    final usersAsync = ref.watch(allUsersProvider);
    final pendingCountAsync = ref.watch(pendingUsersCountProvider);
    final borrowsAsync = ref.watch(recentBorrowsProvider);
    final locationsAsync = ref.watch(locationsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(booksProvider);
        ref.invalidate(allUsersProvider);
        ref.invalidate(pendingUsersCountProvider);
        ref.invalidate(recentBorrowsProvider);
        ref.invalidate(locationsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          _buildSectionHeader('DASHBOARD OVERVIEW'),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildKpiCard(
                context,
                title: 'Total Books',
                valueAsync: booksAsync.whenData((books) => books.length.toString()),
                icon: Icons.auto_stories_rounded,
                color: Colors.blue,
                onTap: () => context.go('/admin/books'),
              ),
              _buildKpiCard(
                context,
                title: 'Total Users',
                valueAsync: usersAsync.whenData((users) => users.length.toString()),
                icon: Icons.badge_rounded,
                color: Colors.green,
                onTap: () => context.go('/admin/users'),
              ),
              _buildKpiCard(
                context,
                title: 'Pending Approvals',
                valueAsync: pendingCountAsync.whenData((count) => count.toString()),
                icon: Icons.hourglass_empty_rounded,
                color: Colors.orange,
                onTap: () => context.go('/admin/users'),
              ),
              _buildKpiCard(
                context,
                title: 'Active Borrows',
                valueAsync: borrowsAsync.whenData((b) => b.where((r) => r.status == 'borrowed').length.toString()),
                icon: Icons.sync_alt_rounded,
                color: Colors.purple,
                onTap: () => context.go('/admin/borrows'),
              ),
              _buildKpiCard(
                context,
                title: 'Locations',
                valueAsync: locationsAsync.whenData((locs) => locs.length.toString()),
                icon: Icons.location_on_rounded,
                color: Colors.teal,
                onTap: () => context.go('/admin/locations'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w900,
        fontSize: 12,
        letterSpacing: 1.5,
        color: Colors.grey,
      ),
    );
  }


  Widget _buildKpiCard(
    BuildContext context, {
    required String title,
    required AsyncValue<String> valueAsync,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        color: color.withOpacity(0.1),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              valueAsync.when(
                data: (val) => Text(
                  val,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (_, _) => Text('Error', style: TextStyle(color: color)),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
