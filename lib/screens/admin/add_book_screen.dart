import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/providers.dart';
import '../../models/book_model.dart';

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

  String? _selectedLocationId;
  bool _isLoading = false;
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.book?.title);
    _authorController = TextEditingController(text: widget.book?.author);
    _isbnController = TextEditingController(text: widget.book?.isbn);
    _descriptionController = TextEditingController(text: widget.book?.description);
    _copiesController = TextEditingController(text: widget.book?.totalCopies.toString() ?? '1');
    _genreController = TextEditingController(
      text: widget.book?.genre.isNotEmpty == true ? widget.book!.genre.join(', ') : 'Technology',
    );
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
    super.dispose();
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
        setState(() => _selectedImage = image);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location for the book.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final genres = _genreController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      
      String? coverUrl = widget.book?.coverUrl;
      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        coverUrl = await ref.read(bookServiceProvider).uploadBookCover(bytes, _selectedImage!.name);
      }

      if (widget.book != null) {
        // Edit Mode
        await ref.read(bookServiceProvider).updateBook(
          widget.book!.id,
          {
            'title': _titleController.text.trim(),
            'author': _authorController.text.trim(),
            'location_id': _selectedLocationId!,
            'isbn': _isbnController.text.trim(),
            'description': _descriptionController.text.trim(),
            'total_copies': int.tryParse(_copiesController.text) ?? 1,
            'genre': genres,
            'cover_url': coverUrl,
          }
        );
      } else {
        // Add Mode
        await ref
            .read(bookServiceProvider)
            .createBook(
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
          SnackBar(content: Text(widget.book != null ? 'Book updated successfully' : 'Book added successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationsAsync = ref.watch(locationsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(widget.book != null ? 'Edit Book' : 'Add New Book')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Picker Section
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 150,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).dividerColor),
                        image: _selectedImage != null
                            ? DecorationImage(
                                image: FileImage(File(_selectedImage!.path)),
                                fit: BoxFit.cover,
                              )
                            : widget.book?.coverUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(widget.book!.coverUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                      ),
                      child: _selectedImage == null && widget.book?.coverUrl == null
                          ? const Icon(Icons.book_rounded, size: 64, color: Colors.grey)
                          : null,
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
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Book Title *'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _authorController,
                decoration: const InputDecoration(labelText: 'Author Name *'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _isbnController,
                decoration: const InputDecoration(labelText: 'ISBN'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _copiesController,
                decoration: const InputDecoration(labelText: 'Total Copies'),
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
                    labelText: 'Assigned Location *',
                  ),
                  value: _selectedLocationId,
                  items: locations
                      .map(
                        (loc) => DropdownMenuItem(
                          value: loc.id,
                          child: Text(loc.name),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _selectedLocationId = val),
                  validator: (val) => val == null ? 'Required' : null,
                ),
                loading: () => const CircularProgressIndicator(),
                error: (e, stack) => Text('Error loading locations $e'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _genreController,
                decoration: const InputDecoration(
                  labelText: 'Genres (comma separated)',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Book Description',
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(widget.book != null ? 'Update Book' : 'Add Book'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
