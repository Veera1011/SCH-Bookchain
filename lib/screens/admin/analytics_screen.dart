import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../../providers/providers.dart';
import '../../models/book_model.dart';
import '../../models/borrow_record_model.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(booksProvider);
    final usersAsync = ref.watch(allUsersProvider);
    final pendingCountAsync = ref.watch(pendingUsersCountProvider);
    final borrowsAsync = ref.watch(recentBorrowsProvider);
    final locationsAsync = ref.watch(locationsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
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
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.9,
              children: [
                _buildKpiCard(
                  context,
                  title: 'Books',
                  valueAsync: booksAsync.whenData((books) => books.length.toString()),
                  icon: Icons.auto_stories_rounded,
                  color: Colors.blue,
                  onTap: () => context.go('/admin/books'),
                ),
                _buildKpiCard(
                  context,
                  title: 'Users',
                  valueAsync: usersAsync.whenData((users) => users.length.toString()),
                  icon: Icons.badge_rounded,
                  color: Colors.green,
                  onTap: () => context.go('/admin/users'),
                ),
                _buildKpiCard(
                  context,
                  title: 'Pending',
                  valueAsync: pendingCountAsync.whenData((count) => count.toString()),
                  icon: Icons.hourglass_empty_rounded,
                  color: Colors.orange,
                  onTap: () => context.go('/admin/users'),
                ),
                _buildKpiCard(
                  context,
                  title: 'Borrows',
                  valueAsync: borrowsAsync.whenData((b) => b.where((r) => r.status == 'borrowed').length.toString()),
                  icon: Icons.sync_alt_rounded,
                  color: Colors.purple,
                  onTap: () => context.go('/admin/borrows'),
                ),
                _buildKpiCard(
                  context,
                  title: 'Locs',
                  valueAsync: locationsAsync.whenData((locs) => locs.length.toString()),
                  icon: Icons.location_on_rounded,
                  color: Colors.teal,
                  onTap: () => context.go('/admin/locations'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('INVENTORY ANALYTICS'),
            const SizedBox(height: 16),
            booksAsync.when(
              data: (books) => Column(
                children: [
                   _buildChartCard(
                    context,
                    title: 'GENRE DISTRIBUTION',
                    chart: _buildGenreDonut(books),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildChartCard(
                          context,
                          title: 'STOCK STATUS',
                          chart: _buildStockPie(books),
                          compact: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: borrowsAsync.when(
                          data: (borrows) => _buildChartCard(
                            context,
                            title: 'BORROW TRENDS',
                            chart: _buildBorrowBar(borrows),
                            compact: true,
                          ),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(BuildContext context, {required String title, required Widget chart, bool compact = false}) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: compact ? 220 : 300,
      borderRadius: 16,
      blur: 10,
      alignment: Alignment.center,
      border: 1,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Theme.of(context).colorScheme.surface.withOpacity(0.1),
          Theme.of(context).colorScheme.surface.withOpacity(0.05),
        ],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Theme.of(context).colorScheme.primary.withOpacity(0.2),
          Theme.of(context).colorScheme.primary.withOpacity(0.05),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Expanded(child: chart),
          ],
        ),
      ),
    );
  }

  Widget _buildGenreDonut(List<BookModel> books) {
    Map<String, int> genres = {};
    for (var book in books) {
      for (var genre in book.genre) {
        genres[genre] = (genres[genre] ?? 0) + 1;
      }
    }

    final sortedGenres = genres.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topGenres = sortedGenres.take(5).toList();

    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 40,
        sections: topGenres.map((e) {
          final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.teal];
          final index = topGenres.indexOf(e);
          return PieChartSectionData(
            color: colors[index % colors.length],
            value: e.value.toDouble(),
            title: '${e.key}\n${e.value}',
            radius: 50,
            titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStockPie(List<BookModel> books) {
    int available = books.fold(0, (sum, b) => sum + b.availableCopies);
    int total = books.fold(0, (sum, b) => sum + b.totalCopies);
    int borrowed = total - available;

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 30,
        sections: [
          PieChartSectionData(
            color: Colors.green.withOpacity(0.8),
            value: available.toDouble(),
            title: 'AVBL',
            radius: 40,
            titleStyle: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
          ),
          PieChartSectionData(
            color: Colors.red.withOpacity(0.8),
            value: borrowed.toDouble(),
            title: 'BORR',
            radius: 40,
            titleStyle: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildBorrowBar(List<BorrowRecordModel> borrows) {
    final returned = borrows.where((b) => b.status == 'returned').length;
    final active = borrows.where((b) => b.status == 'borrowed').length;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (returned > active ? returned : active).toDouble() + 2,
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: active.toDouble(), color: Colors.purple, width: 20, borderRadius: BorderRadius.circular(4))]),
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: returned.toDouble(), color: Colors.blue, width: 20, borderRadius: BorderRadius.circular(4))]),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) => Text(value == 0 ? 'ACT' : 'RET', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
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
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (_, _) => Text('Error', style: TextStyle(color: color, fontSize: 10)),
              ),
              const SizedBox(height: 4),
              Text(
                title.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 8,
                  letterSpacing: 0.5,
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
