import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../providers/providers.dart';

class BorrowBookScreen extends ConsumerStatefulWidget {
  final String bookId;

  const BorrowBookScreen({super.key, required this.bookId});

  @override
  ConsumerState<BorrowBookScreen> createState() => _BorrowBookScreenState();
}

class _BorrowBookScreenState extends ConsumerState<BorrowBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _isbnController = TextEditingController();
  bool _isLoading = false;
  bool _isbnVerified = false;
  String? _isbnError;
  DateTime? _isbnVerifiedAt; // timestamp when ISBN was verified

  final List<String> _quickSuggestions = [
    'For professional development and skill building',
    'Researching for current project implementation',
    'Recommended by manager for team upskilling',
    'Personal interest in the subject matter',
    'Preparing for an upcoming certification',
  ];
  void _verifyIsbn(String bookIsbn) {
    final entered = _isbnController.text.trim().replaceAll('-', '').replaceAll(' ', '');
    final expected = bookIsbn.replaceAll('-', '').replaceAll(' ', '');

    if (entered.isEmpty) {
      setState(() {
        _isbnError = 'Please enter the ISBN from the book.';
        _isbnVerified = false;
      });
      return;
    }

    if (entered == expected) {
      setState(() {
        _isbnVerified = true;
        _isbnVerifiedAt = DateTime.now(); // capture timestamp
        _isbnError = null;
      });
    } else {
      setState(() {
        _isbnError = 'ISBN does not match. Please check the book and try again.';
        _isbnVerified = false;
        _isbnVerifiedAt = null;
      });
    }
  }

  // Open scanner and populate ISBN field
  Future<void> _scanIsbn(String bookIsbn) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scanning is not available on web. Please enter the ISBN manually.')),
      );
      return;
    }
    final scanned = await context.push<String>('/qr-scanner');
    if (scanned != null && scanned.isNotEmpty && mounted) {
      setState(() => _isbnController.text = scanned);
      _verifyIsbn(bookIsbn);
    }
  }

  Future<void> _submitBorrow(String title, String locationId) async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isbnVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please verify the book ISBN before borrowing.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(borrowServiceProvider).borrowBook(
        bookId: widget.bookId,
        bookTitle: title,
        locationId: locationId,
        reason: _reasonController.text.trim(),
        isbnVerifiedAt: _isbnVerifiedAt,
      );

      ref.invalidate(booksProvider);
      ref.invalidate(myActiveBorrowsProvider);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 10),
                Text('Borrow Confirmed!'),
              ],
            ),
            content: const Text(
              'You have successfully borrowed this book.\nPlease return it within 14 days.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/my-books');
                },
                child: const Text('VIEW MY BOOKS'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to borrow: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _isbnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookAsync = ref.watch(bookByIdProvider(widget.bookId));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Borrow')),
      body: bookAsync.when(
        data: (book) {
          final bookIsbn = book.isbn ?? '';
          final hasIsbn = bookIsbn.isNotEmpty;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Book Details Card ──────────────────────────────
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.menu_book, color: colorScheme.primary, size: 22),
                              const SizedBox(width: 10),
                              Text(
                                'Book Details',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Text(book.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(height: 4),
                          Text(book.author, style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6))),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 15, color: colorScheme.primary),
                              const SizedBox(width: 6),
                              Text(
                                'Due: ${DateTime.now().add(const Duration(days: 14)).toString().split(' ')[0]}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── ISBN Verification ──────────────────────────────
                  if (hasIsbn) ...[
                    Card(
                      elevation: 0,
                      color: _isbnVerified
                          ? Colors.green.withOpacity(0.05)
                          : colorScheme.errorContainer.withOpacity(0.05),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: _isbnVerified ? Colors.green : colorScheme.outlineVariant,
                          width: _isbnVerified ? 2 : 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _isbnVerified ? Icons.verified : Icons.security,
                                  color: _isbnVerified ? Colors.green : colorScheme.primary,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _isbnVerified ? 'ISBN Verified ✓' : 'Verify Your Book',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: _isbnVerified ? Colors.green : colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Enter the ISBN printed on the physical book or scan its barcode to confirm you have the correct copy.',
                              style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.6),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _isbnController,
                                    decoration: InputDecoration(
                                      labelText: 'Enter ISBN',
                                      hintText: 'e.g. 978-3-16-148410-0',
                                      prefixIcon: const Icon(Icons.numbers),
                                      errorText: _isbnError,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      suffixIcon: _isbnVerified
                                          ? const Icon(Icons.check_circle, color: Colors.green)
                                          : null,
                                    ),
                                    onChanged: (_) {
                                      if (_isbnVerified) {
                                        setState(() => _isbnVerified = false);
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  children: [
                                    // Scan button
                                    IconButton.filled(
                                      onPressed: () => _scanIsbn(bookIsbn),
                                      icon: const Icon(Icons.qr_code_scanner),
                                      tooltip: 'Scan Barcode / QR',
                                      style: IconButton.styleFrom(
                                        backgroundColor: colorScheme.primary,
                                        foregroundColor: colorScheme.onPrimary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    // Verify button
                                    IconButton.filled(
                                      onPressed: () => _verifyIsbn(bookIsbn),
                                      icon: const Icon(Icons.check),
                                      tooltip: 'Verify ISBN',
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── Reason ────────────────────────────────────────
                  Text(
                    'Why are you borrowing this book? *',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'This helps SCH track learning goals',
                    style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5), fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _reasonController,
                    decoration: InputDecoration(
                      hintText: 'Enter your reason here (min 20 characters)...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    maxLines: 4,
                    maxLength: 300,
                    validator: (value) {
                      if (value == null || value.trim().length < 20) {
                        return 'Reason must be at least 20 characters.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text('Quick Suggestions:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _quickSuggestions.map((suggestion) {
                      return ActionChip(
                        label: Text(suggestion, style: const TextStyle(fontSize: 12)),
                        onPressed: () => setState(() => _reasonController.text = suggestion),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  // ── Submit ────────────────────────────────────────
                  if (hasIsbn && !_isbnVerified)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.withOpacity(0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You must verify the ISBN before borrowing.',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: (hasIsbn && !_isbnVerified) || _isLoading
                          ? null
                          : () => _submitBorrow(book.title, book.locationId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        disabledBackgroundColor: colorScheme.onSurface.withOpacity(0.12),
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('CONFIRM BORROW', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, stack) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
