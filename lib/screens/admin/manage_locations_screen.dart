import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/providers.dart';
import '../../models/location_model.dart';
import '../../widgets/common/loading_shimmers.dart';
import '../../core/utils/toast_utils.dart';

class ManageLocationsScreen extends ConsumerStatefulWidget {
  const ManageLocationsScreen({super.key});

  @override
  ConsumerState<ManageLocationsScreen> createState() => _ManageLocationsScreenState();
}

class _ManageLocationsScreenState extends ConsumerState<ManageLocationsScreen> {
  Future<void> _showLocationDialog({LocationModel? location}) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: location?.name);
    final cityCtrl = TextEditingController(text: location?.city);
    final addressCtrl = TextEditingController(text: location?.address);

    final isNew = location == null;
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isNew ? 'Add Location' : 'Edit Location'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Office Name *'),
                        validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: cityCtrl,
                        decoration: const InputDecoration(labelText: 'City *'),
                        validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: addressCtrl,
                        decoration: const InputDecoration(labelText: 'Address (Optional)'),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setState(() => isLoading = true);
                          try {
                            final adminService = ref.read(adminServiceProvider);
                            if (isNew) {
                              await adminService.addLocation(
                                nameCtrl.text.trim(),
                                cityCtrl.text.trim(),
                                addressCtrl.text.trim(),
                              );
                            } else {
                              await adminService.updateLocation(
                                location.id,
                                nameCtrl.text.trim(),
                                cityCtrl.text.trim(),
                                addressCtrl.text.trim(),
                              );
                            }
                            ref.invalidate(locationsProvider);
                            if (mounted) Navigator.pop(context);
                          } catch (e) {
                            ToastUtils.showError('Error: $e');
                            setState(() => isLoading = false);
                          }
                        },
                  child: isLoading
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(isNew ? 'Create' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteLocation(LocationModel location) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Location'),
        content: Text('Are you sure you want to delete ${location.name}? Users and books assigned to this location will still exist but lack an office association.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(adminServiceProvider).deleteLocation(location.id);
        ref.invalidate(locationsProvider);
        if (mounted) {
          ToastUtils.showSuccess('Location deleted');
        }
      } catch (e) {
        if (mounted) {
          ToastUtils.showError('Failed to delete: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationsAsync = ref.watch(locationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Locations'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showLocationDialog(),
        child: const Icon(Icons.add),
      ),
      body: locationsAsync.when(
        data: (locations) {
          if (locations.isEmpty) {
            return const Center(
              child: Text('No locations found. Add one to get started.', style: TextStyle(fontSize: 16, color: Colors.grey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: locations.length,
            itemBuilder: (context, index) {
              final location = locations[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.location_city),
                  ),
                  title: Text(location.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${location.city}${location.address != null ? '\n${location.address}' : ''}'),
                  isThreeLine: location.address != null && location.address!.isNotEmpty,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showLocationDialog(location: location),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteLocation(location),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const ListShimmer(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
