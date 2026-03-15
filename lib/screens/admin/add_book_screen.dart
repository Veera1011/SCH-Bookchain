import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import '../../providers/providers.dart';
import '../../models/book_model.dart';
import '../../services/google_books_service.dart';

class AddBookScreen extends ConsumerStatefulWidget {
  final BookModel? book;
  const AddBookScreen({super.key, this.book});

  @override
  ConsumerState<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends ConsumerState<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _authorController;
  late final TextEditingController _isbnController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _copiesController;
  late final TextEditingController _genreController;
  late final TextEditingController _publisherController;

  String? _selectedLocationId;
  bool _isLoading = false;
  bool _isLookingUp = false; // NEW: for ISBN lookup spinner
  XFile? _selectedImage;
  String? _networkCoverUrl; // NEW: cover from Google Books
  final ImagePicker _picker = ImagePicker();
  final GoogleBooksService _googleBooks = GoogleBooksService();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.book?.title);
    _authorController = TextEditingController(text: widget.book?.author);
    _isbnController = TextEditingController(text: widget.book?.isbn);
    _descriptionController =
        TextEditingController(text: widget.book?.description);
    _copiesController = TextEditingController(
        text: widget.book?.totalCopies.toString() ?? '1');
    _genreController = TextEditingController(
      text: widget.book?.genre.isNotEmpty == true
          ? widget.book!.genre.join(', ')
          : '',
    );
    _publisherController = TextEditingController();
    _networkCoverUrl = widget.book?.coverUrl;
    _selectedLocationId = widget.book?.locationId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _isbnController.dispose();
    _descriptionController.dispose();
    _copiesController.dispose();
    _genreController.dispose();
    _publisherController.dispose();
    super.dispose();
  }

  // ── NEW: Scan ISBN from camera ─────────────────────────────────────────
  Future<void> _scanAndLookup() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Scanning not available on web. Enter ISBN manually.')),
      );
      return;
    }

    // Reuse your existing QR scanner screen
    final scanned = await context.push<String>('/qr-scanner');
    if (scanned != null && scanned.isNotEmpty && mounted) {
      _isbnController.text = scanned;
      await _lookupByIsbn(scanned);
    }
  }

  // ── NEW: Lookup by manually typed ISBN ────────────────────────────────
  Future<void> _lookupByIsbn(String isbn) async {
    if (isbn.trim().isEmpty) return;

    setState(() => _isLookingUp = true);

    final info = await _googleBooks.lookupByIsbn(isbn.trim());

    if (!mounted) return;
    setState(() => _isLookingUp = false);

    if (info == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              '⚠️ Book not found in Google Books. Please fill details manually.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // ── Auto-fill all fields ───────────────────────────────────────────
    setState(() {
      _titleController.text = info.title;
      _authorController.text = info.author;
      if (info.description != null) {
        _descriptionController.text = info.description!;
      }
      if (info.genres.isNotEmpty) {
        _genreController.text = info.genres.join(', ');
      }
      if (info.publisher != null) {
        _publisherController.text = info.publisher!;
      }
      if (info.coverUrl != null) {
        _networkCoverUrl = info.coverUrl;
        _selectedImage = null; // clear local image if we got one from API
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Found: "${info.title}" — fields auto-filled!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 800,
        imageQuality: 50,
      );
      if (image != null) {
        setState(() {
          _selectedImage = image;
          _networkCoverUrl = null; // override Google Books cover
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a location for the book.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final genres = _genreController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // Determine cover URL priority:
      // 1. Newly picked local image (upload it)
      // 2. Google Books cover (use directly)
      // 3. Existing cover from edit mode
      String? coverUrl = _networkCoverUrl ?? widget.book?.coverUrl;

      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        coverUrl = await ref
            .read(bookServiceProvider)
            .uploadBookCover(bytes, _selectedImage!.name);
      }

      if (widget.book != null) {
        await ref.read(bookServiceProvider).updateBook(widget.book!.id, {
          'title': _titleController.text.trim(),
          'author': _authorController.text.trim(),
          'location_id': _selectedLocationId!,
          'isbn': _isbnController.text.trim(),
          'description': _descriptionController.text.trim(),
          'total_copies': int.tryParse(_copiesController.text) ?? 1,
          'genre': genres,
          'cover_url': coverUrl,
        });
      } else {
        await ref.read(bookServiceProvider).createBook(
              title: _titleController.text.trim(),
              author: _authorController.text.trim(),
              locationId: _selectedLocationId!,
              isbn: _isbnController.text.trim(),
              description: _descriptionController.text.trim(),
              totalCopies: int.tryParse(_copiesController.text) ?? 1,
              genre: genres,
              coverUrl: coverUrl,
            );
      }

      ref.invalidate(booksProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.book != null
                  ? 'Book updated successfully'
                  : 'Book added successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationsAsync = ref.watch(locationsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Determine which cover image to display
    Widget coverWidget;
    if (_selectedImage != null) {
      coverWidget = Image.file(File(_selectedImage!.path), fit: BoxFit.cover);
    } else if (_networkCoverUrl != null) {
      coverWidget = Image.network(_networkCoverUrl!, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.book_rounded, size: 64, color: Colors.grey));
    } else {
      coverWidget =
          const Icon(Icons.book_rounded, size: 64, color: Colors.grey);
    }

    return Scaffold(
      appBar: AppBar(
          title:
              Text(widget.book != null ? 'Edit Book' : 'Add New Book')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── ISBN Scan Banner (only in Add mode) ─────────────────
              if (widget.book == null)
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withOpacity(0.1),
                        colorScheme.primary.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: colorScheme.primary.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome,
                              color: colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Quick Add via ISBN',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Scan the barcode or type the ISBN to auto-fill all book details from Google Books.',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withOpacity(0.6),
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
                                hintText: '978-...',
                                prefixIcon: const Icon(Icons.numbers),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                suffixIcon: _isLookingUp
                                    ? const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        ),
                                      )
                                    : null,
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Scan button
                          IconButton.filled(
                            onPressed:
                                _isLookingUp ? null : _scanAndLookup,
                            icon: const Icon(Icons.qr_code_scanner),
                            tooltip: 'Scan Barcode',
                            style: IconButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              minimumSize: const Size(48, 56),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Lookup button
                          IconButton.filled(
                            onPressed: _isLookingUp
                                ? null
                                : () =>
                                    _lookupByIsbn(_isbnController.text),
                            icon: const Icon(Icons.search),
                            tooltip: 'Lookup ISBN',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(48, 56),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // ── Cover Image ──────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 150,
                      height: 200,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: coverWidget,
                    ),
                    if (_networkCoverUrl != null && _selectedImage == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Cover from Google Books',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_rounded),
                          label: const Text('Take Photo'),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.image_rounded),
                          label: const Text('Gallery'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Form Fields ──────────────────────────────────────────
              TextFormField(
                controller: _titleController,
                decoration:
                    const InputDecoration(labelText: 'Book Title *'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _authorController,
                decoration:
                    const InputDecoration(labelText: 'Author Name *'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _publisherController,
                decoration:
                    const InputDecoration(labelText: 'Publisher'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _copiesController,
                decoration:
                    const InputDecoration(labelText: 'Total Copies'),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  if (int.tryParse(val) == null) return 'Must be a number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              locationsAsync.when(
                data: (locations) => DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                      labelText: 'Assigned Location *'),
                  value: _selectedLocationId,
                  items: locations
                      .map((loc) => DropdownMenuItem(
                            value: loc.id,
                            child: Text(loc.name),
                          ))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _selectedLocationId = val),
                  validator: (val) => val == null ? 'Required' : null,
                ),
                loading: () => const CircularProgressIndicator(),
                error: (e, stack) => Text('Error loading locations $e'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _genreController,
                decoration: const InputDecoration(
                    labelText: 'Genres (comma separated)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration:
                    const InputDecoration(labelText: 'Book Description'),
                maxLines: 4,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(widget.book != null
                        ? 'Update Book'
                        : 'Add Book'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
