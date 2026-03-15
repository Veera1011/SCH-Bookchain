import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AIService {
  final SupabaseClient _supabase;
  String? _apiKey;
  bool _isInitializing = false;
  String? _initError;
  
  // Model provided by user
  static const String _modelId = 'openai/gpt-oss-120b';

  AIService(this._supabase);

  Future<void> _ensureInitialized() async {
    if (_apiKey != null || _isInitializing) return;
    
    _isInitializing = true;
    try {
      final data = await _supabase
          .from('app_settings')
          .select('gemini_api_key')
          .eq('id', '00000000-0000-0000-0000-000000000001')
          .single();
          
      _apiKey = data['gemini_api_key'] as String?;
      
      if (_apiKey == null || _apiKey!.isEmpty) {
        throw Exception('AI API Key is not configured in settings.');
      }
      _initError = null;
    } catch (e) {
      _initError = 'Failed to initialize AI: $e';
      print(_initError);
    } finally {
      _isInitializing = false;
    }
  }

  Future<String> getBookRecommendations(String userPrompt, List<BookModel> availableBooks) async {
    await _ensureInitialized();
    
    if (_initError != null) {
      return "⚠️ **AI Assistant Error**: $_initError\n\nPlease check the AI Assistant API Key in Settings.";
    }

    if (availableBooks.isEmpty) {
      return "I can't recommend books right now because the currently selected location has no available books in the catalog.";
    }

    final StringBuffer catalogContext = StringBuffer();
    catalogContext.writeln("Available Book Catalog:");
    for (final book in availableBooks) {
      final availability = book.availableCopies > 0 ? "Available (${book.availableCopies} copies)" : "Out of Stock";
      catalogContext.writeln("- \"${book.title}\" by ${book.author}");
      catalogContext.writeln("  * Genres: ${book.genre.join(', ')}");
      catalogContext.writeln("  * Rating: ${book.avgRating.toStringAsFixed(1)} (${book.ratingCount} reviews)");
      catalogContext.writeln("  * Status: $availability");
      catalogContext.writeln("  * Description: ${book.description}");
    }

    final systemPrompt = '''
You are a helpful, professional AI Book Assistant for an enterprise library called SCH BookChain.
Your goal is to suggest books to the user based EXCLUSIVELY on the catalog provided below.

When recommending books:
1. Mention the **Rating** if it's high (4.0+).
2. Inform the user about **Availability** (number of copies).
3. Suggest popular books based on the number of reviews and average rating.
4. If a book is "Out of Stock", let the user know but suggest a similar available alternative.

CRITICAL FORMATTING RULE:
- DO NOT use markdown tables. Tables are not responsive on mobile.
- Use bullet points, bold text, and numbered lists for organization.
- Keep descriptions concise.

DO NOT suggest books that are not in the provided catalog. If the user asks for something completely unrelated to the available catalog, casually inform them that the specific topic isn't available, but recommend the closest alternative from the catalog instead.

$catalogContext
''';

    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _modelId,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ?? "No response generated.";
      } else {
        final error = jsonDecode(response.body);
        return "⚠️ **AI Assistant Error**: Provider returned ${response.statusCode}. ${error['error']?['message'] ?? response.reasonPhrase}";
      }
    } catch (e) {
      return "⚠️ **AI Assistant Error**: Failed to connect to AI service. Details: $e";
    }
  }

  /// Performs a semantic search on the catalog and returns a list of book IDs.
  Future<List<String>> semanticSearch(String query, List<BookModel> catalog) async {
    await _ensureInitialized();
    if (_initError != null || _apiKey == null || catalog.isEmpty) return [];

    final StringBuffer catalogBuffer = StringBuffer();
    for (final book in catalog) {
      catalogBuffer.writeln("ID: ${book.id} | Title: ${book.title} | Author: ${book.author} | Description: ${book.description} | Genres: ${book.genre.join(', ')}");
    }

    final systemPrompt = '''
You are a library search engine. Your task is to find the IDs of books that best match the user's intent or "mood".
User intent might be: "I want to be inspired", "Books like Deep Work", "I'm feeling burnt out", "Leadership skills".

Instructions:
1. Review the catalog provided.
2. Identify up to 10 books that match the intent.
3. Return ONLY a valid JSON array of strings containing the book IDs.
4. If NO books match at all, return an empty array [].
5. DO NOT provide any explanation or markdown formatting outside the JSON array.

Catalog:
$catalogBuffer
''';

    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _modelId,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': query},
          ],
          'temperature': 0.2, // Lower temperature for more consistent JSON
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        
        // Clean possible markdown wrappers
        final jsonStr = content.replaceAll('```json', '').replaceAll('```', '').trim();
        final List<dynamic> ids = jsonDecode(jsonStr);
        return ids.cast<String>();
      }
    } catch (e) {
      print('Semantic search error: $e');
    }
    return [];
  }
}
