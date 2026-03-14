import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../../widgets/common/loading_shimmers.dart';

class AllBorrowsScreen extends ConsumerWidget {
  const AllBorrowsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final borrowsAsync = ref.watch(recentBorrowsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: borrowsAsync.when(
        data: (records) {
          if (records.isEmpty) {
            return const Center(child: Text('No borrow records found.'));
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(recentBorrowsProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
                final isReturned = record.status == 'returned';
                final isOverdue = record.isOverdue || (!isReturned && record.dueDate.isBefore(DateTime.now()));

                return Card(
                  child: ExpansionTile(
                    title: Text(record.bookTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Borrower: ${record.userName}'),
                    trailing: _buildStatusChip(record.status, isOverdue),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Borrowed At: ${DateFormat.yMMMd().format(record.borrowedAt.toLocal())}'),
                            Text('Due Date: ${DateFormat.yMMMd().format(record.dueDate.toLocal())}'),
                            if (isReturned) Text('Returned At: ${DateFormat.yMMMd().format(record.returnedAt!.toLocal())}'),
                            const SizedBox(height: 8),
                            const Text('Reason:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(record.reason),
                            if (isReturned && record.summary != null) ...[
                              const SizedBox(height: 8),
                              const Text('Summary:', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(record.summary!),
                              const SizedBox(height: 4),
                              if (record.rating != null)
                                Row(
                                  children: [
                                    const Text('Rating: '),
                                    ...List.generate(5, (starIndex) {
                                      return Icon(
                                        starIndex < record.rating! ? Icons.star : Icons.star_border,
                                        size: 16,
                                        color: Colors.amber,
                                      );
                                    }),
                                  ],
                                ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
        loading: () => const ListShimmer(),
        error: (e, stack) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildStatusChip(String status, bool isOverdue) {
    Color color;
    String label = status.toUpperCase();

    if (isOverdue && status != 'returned') {
      color = Colors.red;
      label = 'OVERDUE';
    } else if (status == 'returned') {
      color = Colors.green;
    } else if (status == 'borrowed') {
      color = Colors.blue;
    } else {
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
