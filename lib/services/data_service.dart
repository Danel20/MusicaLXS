import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../models/book_model.dart';

class DataService {
  static final client = Supabase.instance.client;

  // Streams en tiempo real
  static Stream<List<Book>> get booksStream {
    return client
        .from('books')
        .stream(primaryKey: ['id'])
        .order('title')
        .map((maps) => maps.map((m) => Book.fromJson(m)).toList());
  }

  static Stream<List<String>> get categoriesStream {
    return client
        .from('categories')
        .stream(primaryKey: ['id'])
        .order('name')
        .map((maps) => maps.map((m) => m['name'] as String).toList());
  }

  static Future<void> saveLocalBackup(List<Book> books) async {
    if (kIsWeb) return;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/books_backup.json');
      await file.writeAsString(jsonEncode(books.map((b) => b.toJson()).toList()));
    } catch (e) { debugPrint("Error backup: $e"); }
  }

  static Future<List<Book>> getLocalBackup() async {
    if (kIsWeb) return [];
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/books_backup.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final List list = jsonDecode(content);
        return list.map((item) => Book.fromJson(item)).toList();
      }
    } catch (e) { debugPrint("Error backup: $e"); }
    return [];
  }

  static Future<void> upsertBook(Book book) async {
    await client.from('books').upsert(book.toJson());
  }

  static Future<void> deleteBook(String id) async {
    await client.from('books').delete().match({'id': id});
  }

  static Future<void> saveCategory(String categoryName) async {
    try {
      await client.from('categories').upsert({'name': categoryName}, onConflict: 'name');
    } catch (e) { debugPrint("Error guardando categoría: $e"); }
  }

  // Consulta Multi-API para Books
  static Future<Map<String, Map<String, String>>> fetchFromMultipleApis(String isbn) async {
    Map<String, Map<String, String>> results = {};
    const timeoutDuration1 = Duration(seconds: 5);

    // 1. Consulta Open Library
    try {
      final url = Uri.parse('https://openlibrary.org/api/books?bibkeys=ISBN:$isbn&format=json&jscmd=data');
      final res = await http.get(url).timeout(timeoutDuration1);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data.containsKey('ISBN:$isbn')) {
          final b = data['ISBN:$isbn'];
          results['Open Library'] = {
            'title': b['title'] ?? '',
            'author': (b['authors'] as List?)?.map((a) => a['name']).join(', ') ?? '',
            'editorial': (b['publishers'] as List?)?.map((p) => p['name']).join(', ') ?? '',
            'year': b['publish_date'] ?? '',
          };
        }
      }
    } catch (_) {}
    if (!results.containsKey('Open Library')) results['Open Library'] = {};

    // 2. Consulta Google Books API
    try {
      final url = Uri.parse('https://www.googleapis.com/books/v1/volumes?q=isbn:$isbn');
      final res = await http.get(url).timeout(timeoutDuration1);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['totalItems'] > 0) {
          final volumeInfo = data['items'][0]['volumeInfo'];
          results['Google Books'] = {
            'title': volumeInfo['title'] ?? '',
            'author': (volumeInfo['authors'] as List?)?.join(', ') ?? '',
            'editorial': volumeInfo['publisher'] ?? '',
            'year': volumeInfo['publishedDate'] ?? '',
          };
        }
      }
    } catch (_) {}
    if (!results.containsKey('Google Books')) results['Google Books'] = {};

    // 3. API: Open Library Volumes (Estructura de respaldo alternativa)
    try {
      final url = Uri.parse('https://openlibrary.org/api/volumes/brief/isbn/$isbn.json');
      final res = await http.get(url).timeout(timeoutDuration1);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data.containsKey('records') && data['records'].isNotEmpty) {
          final record = data['records'].values.first;
          final dataBook = record['data'];
          results['Open Library Volumes'] = {
            'title': dataBook['title'] ?? '',
            'author': (dataBook['authors'] as List?)?.map((a) => a['name']).join(', ') ?? '',
            'editorial': (dataBook['publishers'] as List?)?.map((p) => p['name']).join(', ') ?? '',
            'year': dataBook['publish_date'] ?? '',
          };
        }
      }
    } catch (_) {}
    if (!results.containsKey('Open Library Volumes')) results['Open Library Volumes'] = {};

    return results;
  }
}