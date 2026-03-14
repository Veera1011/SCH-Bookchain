import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../providers/providers.dart';
import '../../core/utils/toast_utils.dart';

class ReturnBookScreen extends ConsumerStatefulWidget {
  final String recordId;

  const ReturnBookScreen({super.key, required this.recordId});

  @override
  ConsumerState<ReturnBookScreen> createState() => _ReturnBookScreenState();
}

class _ReturnBookScreenState extends ConsumerState<ReturnBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _summaryController = TextEditingController();
  final _reviewController = TextEditingController();
  final _isbnController = TextEditingController();

  int _rating = 0;
  bool _isLoading = false;
  bool _isbnVerified = false;
  String? _isbnError;
  DateTime? _isbnReturnVerifiedAt;

  void _verifyIsbn(String bookIsbn) {
    final entered = _isbnController.text.trim().replaceAll('-', '').replaceAll(' ', '');
    final expected = bookIsbn.replaceAll('-', '').replaceAll(' ', '');

    if (entered.isEmpty) {
      setState(() {
        _isbnError = 'Please enter the ISBN printed on the book.';
        _isbnVerified = false;
        _isbnReturnVerifiedAt = null;
      });
      return;
    }

    if (entered == expected) {
      setState(() {
        _isbnVerified = true;
        _isbnReturnVerifiedAt = DateTime.now();
        _isbnError = null;
      });
    } else {
      setState(() {
        _isbnError = 'ISBN does not match. Please check and try again.';
        _isbnVerified = false;
        _isbnReturnVerifiedAt = null;
      });
    }
  }

  Future<void> _scanIsbn(String bookIsbn) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scanning not available on web. Enter ISBN manually.')),
      );
      return;
    }
    final scanned = await context.push<String>('/qr-scanner');
    if (scanned != null && scanned.isNotEmpty && mounted) {
      setState(() => _isbnController.text = scanned);
      _verifyIsbn(bookIsbn);
    }
  }

  Future<void> _submitReturn() async {
    if (!_isbnVerified) {
      ToastUtils.showError('Please verify the book ISBN first.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_rating == 0) {
      ToastUtils.showError('Please provide a star rating (1-5).');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(borrowServiceProvider).returnBook(
        recordId: widget.recordId,
        summary: _summaryController.text.trim(),
        rating: _rating,
        review: _reviewController.text.trim().isEmpty ? null : _reviewController.text.trim(),
        isbnReturnedVerifiedAt: _isbnReturnVerifiedAt,
      );

      ref.invalidate(myActiveBorrowsProvider);
      ref.invalidate(myHistoryProvider);
      ref.invalidate(currentProfileProvider);
      ref.invalidate(booksProvider);

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
                Text('Book Returned!'),
              ],
            ),
            content: const Text('Thank you for returning the book and sharing your summary.'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/my-books');
                },
                child: const Text('Awesome'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError('Failed to return: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _summaryController.dispose();
    _reviewController.dispose();
    _isbnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // We need the book's ISBN to verify against. Fetch via borrow record → book_id
    final myBorrows = ref.watch(myActiveBorrowsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Return Book')),
      body: myBorrows.when(
        data: (borrows) {
          // Find the relevant borrow record to get book ISBN
          final record = borrows.where((b) => b.id == widget.recordId).firstOrNull;
          final bookId = record?.bookId;

          // For ISBN, watch the book by id
          final bookAsync = bookId != null ? ref.watch(bookByIdProvider(bookId)) : null;

          final bookIsbn = bookAsync?.valueOrNull?.isbn ?? '';
          final hasIsbn = bookIsbn.isNotEmpty;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Return & Share',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Verify the book you are returning, then share your takeaways.',
                    style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 13),
                  ),
                  const SizedBox(height: 24),

                  // ── ISBN Verification ──────────────────────────────────
                  if (hasIsbn) ...[
                    Card(
                      elevation: 0,
                      color: _isbnVerified
                          ? Colors.green.withOpacity(0.05)
                          : colorScheme.surfaceVariant.withOpacity(0.4),
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
                                  _isbnVerified ? Icons.verified : Icons.qr_code_2,
                                  color: _isbnVerified ? Colors.green : colorScheme.primary,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _isbnVerified ? 'Book Verified ✓' : 'Verify the Book You Are Returning',
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
                              'Scan the barcode or enter the ISBN from the physical book to confirm you are returning the correct copy.',
                              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 13),
                            ),
                            if (_isbnVerified && _isbnReturnVerifiedAt != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Verified at: ${_isbnReturnVerifiedAt!.toLocal().toString().split('.')[0]}',
                                style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.w600),
                              ),
                            ],
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
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      suffixIcon: _isbnVerified
                                          ? const Icon(Icons.check_circle, color: Colors.green)
                                          : null,
                                    ),
                                    onChanged: (_) {
                                      if (_isbnVerified) setState(() => _isbnVerified = false);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  children: [
                                    IconButton.filled(
                                      onPressed: () => _scanIsbn(bookIsbn),
                                      icon: const Icon(Icons.qr_code_scanner),
                                      tooltip: 'Scan Barcode / QR',
                                      style: IconButton.styleFrom(
                                        backgroundColor: colorScheme.primary,
                                        foregroundColor: colorScheme.onPrimary,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    IconButton.filled(
                                      onPressed: () => _verifyIsbn(bookIsbn),
                                      icon: const Icon(Icons.check),
                                      tooltip: 'Verify ISBN',
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

                  // ── Rating ─────────────────────────────────────────────
                  const Text('Rate this book *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        iconSize: 40,
                        icon: Icon(index < _rating ? Icons.star : Icons.star_border, color: Colors.amber),
                        onPressed: () => setState(() => _rating = index + 1),
                      );
                    }),
                  ),
                  if (_rating > 0)
                    Center(
                      child: Text(
                        ['', '😕 Poor', '😐 Fair', '🙂 Good', '😊 Great', '🌟 Excellent'][_rating],
                        style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.primary),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // ── Summary ────────────────────────────────────────────
                  const Text('Reading Summary *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    'Returning requires a summary (min 100 chars) to build the team knowledge base.',
                    style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5), fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _summaryController,
                    decoration: InputDecoration(
                      hintText: 'Write your key takeaways...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    maxLines: 6,
                    maxLength: 2000,
                    validator: (value) {
                      if (value == null || value.trim().length < 100) {
                        return 'Summary must be at least 100 characters (${value?.trim().length ?? 0}/100)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── Review ─────────────────────────────────────────────
                  const Text('Public Review (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _reviewController,
                    decoration: InputDecoration(
                      hintText: 'Share your thoughts with colleagues...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    maxLines: 3,
                    maxLength: 500,
                  ),
                  const SizedBox(height: 12),

                  // ── Warning if ISBN not verified ───────────────────────
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
                              'Scan or enter the ISBN to verify you are returning the correct book first.',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── Submit ─────────────────────────────────────────────
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: (hasIsbn && !_isbnVerified) || _isLoading ? null : _submitReturn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        disabledBackgroundColor: colorScheme.onSurface.withOpacity(0.12),
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('SUBMIT RETURN', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
