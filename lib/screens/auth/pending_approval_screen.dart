import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';

class PendingApprovalScreen extends ConsumerWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.hourglass_empty, size: 80, color: Colors.orange),
                const SizedBox(height: 24),
                Text(
                  'Awaiting Approval',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your registration has been submitted.\nAn admin will review and approve your account.\nYou will be notified once approved.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 32),
                profileAsync.when(
                  data: (profile) {
                    if (profile == null) return const SizedBox.shrink();
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Name: ${profile.name}'),
                            const SizedBox(height: 8),
                            Text('Email: ${profile.email}'),
                            const SizedBox(height: 8),
                            Text('Department: ${profile.department ?? 'N/A'}'),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const Text('Error loading profile'),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(currentProfileProvider);
                  },
                  child: const Text('Check Status'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    ref.read(authServiceProvider).signOut();
                  },
                  child: const Text('Sign Out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
