import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../../widgets/common/loading_shimmers.dart';

class PendingUsersScreen extends ConsumerWidget {
  const PendingUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingUsersAsync = ref.watch(pendingUsersProvider);

    return pendingUsersAsync.when(
      data: (users) {
        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade300),
                const SizedBox(height: 16),
                const Text(
                  'No pending registrations',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(pendingUsersProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.orange.shade100,
                            child: Text(user.name[0], style: TextStyle(color: Colors.orange.shade800)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(user.email, style: const TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('Department: ${user.department ?? 'N/A'}'),
                      Text('Registered: ${DateFormat.yMMMd().format(user.createdAt.toLocal())}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.push('/admin/users/${user.id}'),
                        style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
                        child: const Text('Review Registration'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const ListShimmer(),
      error: (e, stack) => Center(child: Text('Error: $e')),
    );
  }
}
