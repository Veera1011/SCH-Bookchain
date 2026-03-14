import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';

class MyBooksScreen extends ConsumerWidget {
  const MyBooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            Material(
              color: Theme.of(context).colorScheme.surface,
              child: TabBar(
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                indicatorColor: Theme.of(context).colorScheme.primary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 1),
                tabs: const [
                  Tab(text: 'CURRENTLY BORROWED'),
                  Tab(text: 'HISTORY'),
                ],
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [
                   _ActiveBorrowsList(),
                   _HistoryList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveBorrowsList extends ConsumerWidget {
  const _ActiveBorrowsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeBorrowsAsync = ref.watch(myActiveBorrowsProvider);

    return activeBorrowsAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return const Center(child: Text('No active borrowed books.'));
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(myActiveBorrowsProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              final daysLeft = record.daysUntilDue;
              final isOverdue = record.isOverdue || daysLeft < 0;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              record.bookTitle,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isOverdue ? Colors.red.shade100 : Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isOverdue ? 'Overdue' : 'Borrowed',
                              style: TextStyle(
                                color: isOverdue ? Colors.red.shade800 : Colors.blue.shade800,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('Borrowed: ${DateFormat.yMMMd().format(record.borrowedAt.toLocal())}'),
                      Text('Due: ${DateFormat.yMMMd().format(record.dueDate.toLocal())}'),
                      const SizedBox(height: 8),
                      Text(
                        isOverdue ? 'Overdue by ${daysLeft.abs()} days' : '$daysLeft days left',
                        style: TextStyle(
                          color: isOverdue ? Colors.red : (daysLeft <= 3 ? Colors.orange : Colors.green),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.push('/return/${record.id}'),
                        style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.secondary),
                        child: const Text('Return & Write Summary'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, stack) => Center(child: Text('Error: $e')),
    );
  }
}

class _HistoryList extends ConsumerWidget {
  const _HistoryList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(myHistoryProvider);

    return historyAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return const Center(child: Text('No history found.'));
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(myHistoryProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              record.bookTitle,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '+${record.pointsAwarded} pts',
                              style: TextStyle(
                                color: Colors.green.shade800,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Returned: ${DateFormat.yMMMd().format(record.returnedAt!.toLocal())}'),
                      if (record.rating != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: List.generate(5, (starIndex) {
                            return Icon(
                              starIndex < record.rating! ? Icons.star : Icons.star_border,
                              size: 16,
                              color: Colors.amber,
                            );
                          }),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, stack) => Center(child: Text('Error: $e')),
    );
  }
}
