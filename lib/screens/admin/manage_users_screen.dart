import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../../widgets/common/loading_shimmers.dart';
import 'pending_users_screen.dart';

class ManageUsersScreen extends ConsumerWidget {
  const ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCountAsync = ref.watch(pendingUsersCountProvider);

    return DefaultTabController(
      length: 3,
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
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('PENDING'),
                        pendingCountAsync.when(
                          data: (count) {
                            if (count == 0) return const SizedBox.shrink();
                            return Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.error,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$count',
                                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                  const Tab(text: 'ACTIVE'),
                  const Tab(text: 'ALL USERS'),
                ],
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [PendingUsersScreen(), _ActiveUsersList(), _AllUsersList()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveUsersList extends ConsumerWidget {
  const _ActiveUsersList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeUsersAsync = ref.watch(activeUsersProvider);

    return activeUsersAsync.when(
      data: (users) {
        if (users.isEmpty) {
          return const Center(child: Text('No active users.'));
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(activeUsersProvider.future),
          child: ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: user.avatarUrl != null
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: user.avatarUrl == null ? Text(user.name[0]) : null,
                ),
                title: Text(
                  user.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('${user.email}\nRole: ${user.role}'),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'view') {
                          context.push('/admin/users/${user.id}');
                        } else if (value == 'suspend') {
                          _showSuspendDialog(context, ref, user.id);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'view',
                          child: Text('Manage Role/View'),
                        ),
                        const PopupMenuItem(
                          value: 'suspend',
                          child: Text(
                            'Suspend',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                onTap: () => context.push('/admin/users/${user.id}'),
              );
            },
          ),
        );
      },
      loading: () => const ListShimmer(),
      error: (e, stack) => Center(child: Text('Error: $e')),
    );
  }

  void _showSuspendDialog(BuildContext context, WidgetRef ref, String userId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspend User'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: 'Reason for suspension'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (reasonController.text.isEmpty) return;
              await ref
                  .read(adminServiceProvider)
                  .suspendUser(userId, reasonController.text);
              ref.invalidate(activeUsersProvider);
              ref.invalidate(allUsersProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Suspend', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _AllUsersList extends ConsumerWidget {
  const _AllUsersList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allUsersAsync = ref.watch(allUsersProvider);

    return allUsersAsync.when(
      data: (users) {
        if (users.isEmpty) {
          return const Center(child: Text('No users found.'));
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(allUsersProvider.future),
          child: ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              Color statusColor;
              switch (user.status) {
                case 'active':
                  statusColor = Colors.green;
                  break;
                case 'pending':
                  statusColor = Colors.orange;
                  break;
                case 'rejected':
                  statusColor = Colors.red;
                  break;
                case 'suspended':
                  statusColor = Colors.grey;
                  break;
                default:
                  statusColor = Colors.black;
              }

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.2),
                  child: Text(
                    user.name[0],
                    style: TextStyle(color: statusColor),
                  ),
                ),
                title: Text(user.name),
                subtitle: Text(user.email),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    user.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                onTap: () => context.push('/admin/users/${user.id}'),
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
