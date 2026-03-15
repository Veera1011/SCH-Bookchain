import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/providers.dart';

class ThemeSettingsScreen extends ConsumerStatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  ConsumerState<ThemeSettingsScreen> createState() =>
      _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends ConsumerState<ThemeSettingsScreen> {
  final _aiKeyController = TextEditingController();
  // Common theme color presets
  final List<String> _colorPresets = [
    '#1A3557', // Original Navy
    '#2E7D32', // Green
    '#C62828', // Red
    '#F57C00', // Orange
    '#6200EA', // Deep Purple
    '#00838F', // Cyan
    '#4E342E', // Brown
    '#37474F', // Blue Grey
  ];

  bool _isLoading = false;

  Future<void> _updateSettings(String key, dynamic value) async {
    setState(() => _isLoading = true);

    try {
      final supabase = ref.read(supabaseProvider);

      // Update the single global settings row
      await supabase
          .from('app_settings')
          .update({
            key: value,
            'updated_at': DateTime.now().toIso8601String(),
            'updated_by': supabase.auth.currentUser!.id,
          })
          .eq('id', '00000000-0000-0000-0000-000000000001');

      // Also invalidate AI provider just in case the key changed
      ref.invalidate(aiServiceProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings updated successfully!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update settings: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _aiKeyController.dispose();
    super.dispose();
  }

  // Helper to parse hex for display
  Color _colorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  Future<void> _showAddDomainDialog(List<String> currentDomains) async {
    final controller = TextEditingController();
    final newDomain = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Allowed Domain'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'e.g., supplychainhub.com',
            prefixText: '@ ',
          ),
          autofocus: true,
          onSubmitted: (val) {
            val = val.trim().toLowerCase();
            if (val.isNotEmpty) Navigator.pop(context, val);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = controller.text.trim().toLowerCase();
              if (val.isNotEmpty) Navigator.pop(context, val);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (newDomain != null &&
        newDomain.isNotEmpty &&
        !currentDomains.contains(newDomain)) {
      final newDomains = List<String>.from(currentDomains)..add(newDomain);
      await _updateSettings('allowed_domains', newDomains);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
      ),
      body: settingsAsync.when(
        data: (settings) {
          final currentColor =
              settings['primary_color'] as String? ?? '#1A3557';
          final isDark = settings['is_dark_mode'] as bool? ?? false;
          final rawDomains = settings['allowed_domains'];
          List<String> allowedDomains = [];
          if (rawDomains is List) {
            allowedDomains = rawDomains.map((e) => e.toString()).toList();
          }
          final aiKey = settings['gemini_api_key'] as String?;
          if (_aiKeyController.text.isEmpty && aiKey != null) {
            _aiKeyController.text = aiKey;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // _buildSectionHeader('APPEARANCE', Icons.palette_outlined),
                // const SizedBox(height: 16),
                // Card(
                //   elevation: 0,
                //   shape: RoundedRectangleBorder(
                //     borderRadius: BorderRadius.circular(20),
                //     side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                //   ),
                //   child: Padding(
                //     padding: const EdgeInsets.all(20),
                //     child: Column(
                //       crossAxisAlignment: CrossAxisAlignment.start,
                //       children: [
                //         SwitchListTile(
                //           title: const Text('Global Dark Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                //           subtitle: const Text('Forces dark mode for all users'),
                //           value: isDark,
                //           onChanged: _isLoading ? null : (val) => _updateSettings('is_dark_mode', val),
                //           secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: Theme.of(context).colorScheme.primary),
                //           contentPadding: EdgeInsets.zero,
                //         ),
                //         const Divider(height: 32),
                //         const Text(
                //           'Primary Brand Color',
                //           style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                //         ),
                //         const SizedBox(height: 16),
                //         Wrap(
                //           spacing: 12,
                //           runSpacing: 12,
                //           children: _colorPresets.map((hex) {
                //             final color = _colorFromHex(hex);
                //             final isSelected = currentColor.toUpperCase() == hex.toUpperCase();

                //             return GestureDetector(
                //               onTap: _isLoading ? null : () => _updateSettings('primary_color', hex),
                //               child: AnimatedContainer(
                //                 duration: const Duration(milliseconds: 200),
                //                 width: 48,
                //                 height: 48,
                //                 decoration: BoxDecoration(
                //                   color: color,
                //                   shape: BoxShape.circle,
                //                   border: isSelected ? Border.all(color: Theme.of(context).colorScheme.primary, width: 3) : null,
                //                   boxShadow: [
                //                     if (isSelected)
                //                       BoxShadow(
                //                         color: color.withOpacity(0.4),
                //                         blurRadius: 12,
                //                         spreadRadius: 2,
                //                       )
                //                   ],
                //                 ),
                //                 child: isSelected
                //                     ? Icon(Icons.check, color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: 20)
                //                     : null,
                //               ),
                //             );
                //           }).toList(),
                //         ),
                //       ],
                //     ),
                //   ),
                // ),
                const SizedBox(height: 40),
                _buildSectionHeader(
                  'SECURITY & ACCESS',
                  Icons.security_outlined,
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Allowed Email Domains',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Only users with these email domains will be allowed to create an account.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ...allowedDomains.map(
                              (domain) => Chip(
                                label: Text(domain),
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.surfaceVariant.withOpacity(0.5),
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted: _isLoading
                                    ? null
                                    : () async {
                                        final newDomains = List<String>.from(
                                          allowedDomains,
                                        )..remove(domain);
                                        await _updateSettings(
                                          'allowed_domains',
                                          newDomains,
                                        );
                                      },
                              ),
                            ),
                            ActionChip(
                              label: const Text('Add Domain'),
                              avatar: const Icon(Icons.add, size: 16),
                              onPressed: _isLoading
                                  ? null
                                  : () => _showAddDomainDialog(allowedDomains),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),
                _buildSectionHeader(
                  'AI ASSISTANT',
                  Icons.auto_awesome_outlined,
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Configure Assistant',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Enter your AI API Key (Groq/Llama 3) to enable recommendations.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _aiKeyController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'API Key',
                            prefixIcon: const Icon(Icons.key_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () => _updateSettings(
                                    'gemini_api_key',
                                    _aiKeyController.text.trim(),
                                  ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'SAVE AI CONFIGURATION',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading settings: $e')),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
