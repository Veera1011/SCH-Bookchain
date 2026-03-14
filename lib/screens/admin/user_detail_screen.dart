import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/location_model.dart';
import '../../providers/providers.dart';

class UserDetailScreen extends ConsumerStatefulWidget {
  final String userId;

  const UserDetailScreen({super.key, required this.userId});

  @override
  ConsumerState<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends ConsumerState<UserDetailScreen> {
  bool _isLoading = false;

  void _invalidateAll(WidgetRef ref) {
    ref.invalidate(userByIdProvider(widget.userId));
    ref.invalidate(pendingUsersProvider);
    ref.invalidate(activeUsersProvider);
    ref.invalidate(allUsersProvider);
    ref.invalidate(currentProfileProvider); // Profile might have changed
  }

  Future<void> _approveUser() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(adminServiceProvider).approveUser(widget.userId);
      _invalidateAll(ref);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User approved successfully')));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showRejectDialog() async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 24),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Reject Registration', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: reasonController,
                decoration: const InputDecoration(labelText: 'Reason for rejection (required)'),
                validator: (val) => val == null || val.isEmpty ? 'Reason required' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  Navigator.pop(context);
                  
                  setState(() => _isLoading = true);
                  try {
                    await ref.read(adminServiceProvider).rejectUser(widget.userId, reasonController.text);
                    _invalidateAll(ref);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User rejected')));
                      context.pop();
                    }
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
                child: const Text('Confirm Rejection'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showChangeRoleDialog(String currentRole) async {
    String selectedRole = currentRole;
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change Role'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['employee', 'manager', 'location_admin'].map((role) {
              return RadioListTile<String>(
                title: Text(role.toUpperCase()),
                value: role,
                groupValue: selectedRole,
                onChanged: (val) {
                  setDialogState(() => selectedRole = val!);
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                if (selectedRole == currentRole) return;
                
                setState(() => _isLoading = true);
                try {
                  await ref.read(adminServiceProvider).updateUserRole(widget.userId, selectedRole);
                  _invalidateAll(ref);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Role updated')));
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showChangeLocationDialog(String? currentLocationId) async {
    final locationsAsync = ref.read(locationsProvider);
    if (locationsAsync.value == null) return;

    String? selectedLocationId = currentLocationId;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change Location'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: locationsAsync.value!.map((loc) {
                return RadioListTile<String>(
                  title: Text(loc.name.toUpperCase()),
                  subtitle: Text(loc.city),
                  value: loc.id,
                  groupValue: selectedLocationId,
                  onChanged: (val) {
                    setDialogState(() => selectedLocationId = val);
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                if (selectedLocationId == currentLocationId) return;
                
                setState(() => _isLoading = true);
                try {
                  await ref.read(adminServiceProvider).updateUserLocation(widget.userId, selectedLocationId!);
                  _invalidateAll(ref);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location updated')));
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text('Permanently delete this user profile?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(adminServiceProvider).deleteUser(widget.userId);
      _invalidateAll(ref);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User deleted')));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userByIdProvider(widget.userId));

    return Scaffold(
      appBar: AppBar(title: const Text('User Details')),
      body: userAsync.when(
        data: (user) {
          Color statusColor;
          switch (user.status) {
            case 'active': statusColor = Colors.green; break;
            case 'pending': statusColor = Colors.orange; break;
            case 'rejected': statusColor = Colors.red; break;
            default: statusColor = Colors.grey;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: statusColor.withOpacity(0.2),
                        backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                        child: user.avatarUrl == null ? Text(user.name[0], style: TextStyle(fontSize: 40, color: statusColor)) : null,
                      ),
                      const SizedBox(height: 16),
                      Text(user.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      Text(user.email, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Chip(
                        label: Text(user.status.toUpperCase()),
                        backgroundColor: statusColor.withOpacity(0.1),
                        labelStyle: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                        side: BorderSide(color: statusColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Registration Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const Divider(),
                        ListTile(title: const Text('Submitted on'), trailing: Text(DateFormat.yMMMd().format(user.createdAt.toLocal()))),
                        ListTile(title: const Text('Department'), trailing: Text(user.department ?? 'N/A')),
                        ListTile(
                          title: const Text('Location'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(ref.watch(locationsProvider).maybeWhen(
                                data: (locs) => locs.firstWhere((l) => l.id == user.locationId, orElse: () => LocationModel(id: '', name: 'N/A', city: '', isActive: true)).name,
                                orElse: () => 'Loading...',
                              )),
                              if (user.status == 'active')
                                IconButton(
                                  icon: const Icon(Icons.edit_location_alt_outlined, size: 20),
                                  onPressed: () => _showChangeLocationDialog(user.locationId),
                                ),
                            ],
                          ),
                        ),
                        ListTile(title: const Text('Role'), trailing: Text(user.role.toUpperCase())),
                        if (user.rejectionReason != null)
                          ListTile(
                            title: const Text('Reason', style: TextStyle(color: Colors.red)),
                            subtitle: Text(user.rejectionReason!, style: const TextStyle(color: Colors.red)),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  if (user.status == 'pending') ...[
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      icon: const Icon(Icons.check),
                      label: const Text('Approve User'),
                      onPressed: _approveUser,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                      icon: const Icon(Icons.close),
                      label: const Text('Reject Registration'),
                      onPressed: _showRejectDialog,
                    ),
                  ] else if (user.status == 'active') ...[
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.blue, side: const BorderSide(color: Colors.blue)),
                      onPressed: () => _showChangeRoleDialog(user.role),
                      child: const Text('Change Role'),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                      onPressed: _deleteUser,
                      child: const Text('Delete User'),
                    ),
                  ] else if (user.status == 'rejected') ...[
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'This registration was rejected. Please contact the administrator for further clarification.',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ]
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, stack) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
