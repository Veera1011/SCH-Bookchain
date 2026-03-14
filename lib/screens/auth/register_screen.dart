import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../core/utils/toast_utils.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _departmentController = TextEditingController();

  String? _selectedLocationId;
  bool _isLoading = false;
  bool _obscureText = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocationId == null) {
      ToastUtils.showError('Please select an office location');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).signUp(
            _emailController.text.trim(),
            _passwordController.text,
            _nameController.text.trim(),
            _selectedLocationId!,
            _departmentController.text.trim(),
          );

      if (mounted) {
        ToastUtils.showSuccess('Registration submitted! Awaiting admin approval.');
        context.go('/pending-approval');
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError('Registration failed: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final locationsAsync = ref.watch(locationsProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colorScheme.onSurface, size: 18),
          onPressed: () => context.go('/welcome'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/images/sch_logo.png',
                        height: 50,
                      ),
                    ),
                    const SizedBox(height: 48),
                    Text(
                      'CREATE ACCOUNT',
                      style: TextStyle(
                        fontSize: 28, 
                        fontWeight: FontWeight.w900, 
                        color: colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'JOIN THE SCH ORCHESTRATION NETWORK',
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.5), 
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTextField(
                            controller: _nameController,
                            label: 'FULL NAME *',
                            icon: Icons.badge_outlined,
                            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _emailController,
                            label: 'WORK EMAIL *',
                            icon: Icons.alternate_email,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Required';
                              if (!value!.contains('@')) return 'Invalid email format';
                              
                              final settings = ref.read(appSettingsProvider).value;
                              if (settings != null && settings.containsKey('allowed_domains')) {
                                final rawDomains = settings['allowed_domains'];
                                if (rawDomains is List) {
                                  final allowed = rawDomains.map((e) => e.toString().toLowerCase()).toList();
                                  if (allowed.isNotEmpty) {
                                    final domain = value.split('@').last.toLowerCase();
                                    if (!allowed.contains(domain)) {
                                      return 'Email domain must be one of: ${allowed.join(", ")}';
                                    }
                                  }
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildPasswordField(
                            controller: _passwordController,
                            label: 'PASSWORD *',
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Required';
                              if (value!.length < 8) return 'Minimum 8 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildPasswordField(
                            controller: _confirmPasswordController,
                            label: 'CONFIRM PASSWORD *',
                            validator: (value) {
                              if (value != _passwordController.text) return 'Passwords do not match';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _departmentController,
                            label: 'DEPARTMENT (OPTIONAL)',
                            icon: Icons.business_outlined,
                          ),
                          const SizedBox(height: 20),
                          locationsAsync.when(
                            data: (locations) => DropdownButtonFormField<String>(
                              decoration: _inputDecoration('OFFICE LOCATION *', Icons.location_on_outlined),
                              dropdownColor: colorScheme.surface,
                              style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w600),
                              items: locations
                                  .map((loc) => DropdownMenuItem(
                                        value: loc.id,
                                        child: Text(loc.name.toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
                                      ))
                                  .toList(),
                              onChanged: (val) => setState(() => _selectedLocationId = val),
                              validator: (value) => value == null ? 'Required' : null,
                            ),
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (_, __) => Text('FAILED TO LOAD LOCATIONS', style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.w900, fontSize: 11)),
                          ),
                          const SizedBox(height: 48),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.onSurface,
                              foregroundColor: colorScheme.surface,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('REGISTER ACCOUNT', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
                          ),
                          const SizedBox(height: 24),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            child: Text(
                              'ALREADY HAVE AN ACCOUNT? LOG IN',
                              style: TextStyle(
                                fontSize: 11, 
                                fontWeight: FontWeight.w900, 
                                color: colorScheme.primary,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontSize: 10, 
        fontWeight: FontWeight.w900, 
        letterSpacing: 1.5,
        color: colorScheme.onSurface.withOpacity(0.4),
      ),
      prefixIcon: Icon(icon, size: 20, color: colorScheme.primary),
      filled: true,
      fillColor: colorScheme.onSurface.withOpacity(0.02),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.onSurface.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.onSurface.withOpacity(0.05)),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(fontWeight: FontWeight.w600),
      decoration: _inputDecoration(label, icon),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: _obscureText,
      style: const TextStyle(fontWeight: FontWeight.w600),
      decoration: _inputDecoration(label, Icons.lock_outline).copyWith(
        suffixIcon: IconButton(
          icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility, size: 20),
          onPressed: () => setState(() => _obscureText = !_obscureText),
        ),
      ),
      validator: validator,
    );
  }
}
