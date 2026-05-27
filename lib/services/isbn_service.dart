import 'dart:convert';

import 'package:http/http.dart'
as http;

class IsbnSourceResult {

  final String source;

  final bool found;

  final String title;

  final String authors;

  final String editorial;

  final String year;

  IsbnSourceResult({
    required this.source,
    required this.found,
    required this.title,
    required this.authors,
    required this.editorial,
    required this.year,
  });
}

class IsbnService {

  static Future<List<IsbnSourceResult>>
  search(String isbn) async {

    final results =
    <IsbnSourceResult>[];

    results.add(
      await _openLibrary(isbn),
    );

    results.add(
      await _googleBooks(isbn),
    );

    return results;
  }

  static Future<IsbnSourceResult>
  _openLibrary(
      String isbn,
      ) async {

    try {

      final response =
      await http.get(
        Uri.parse(
          'https://openlibrary.org/api/books?bibkeys=ISBN:$isbn&format=json&jscmd=data',
        ),
      );

      final json =
      jsonDecode(response.body);

      final key =
          'ISBN:$isbn';

      if(!json.containsKey(key)) {

        return IsbnSourceResult(
          source: 'OpenLibrary',
          found: false,
          title: '',
          authors: '',
          editorial: '',
          year: '',
        );
      }

      final data =
      json[key];

      return IsbnSourceResult(
        source: 'OpenLibrary',
        found: true,
        title: data['title'] ?? '',
        authors:
        (data['authors'] as List?)
            ?.map(
              (e) => e['name'],
        )
            .join(', ')
            ?? '',
        editorial:
        (data['publishers'] as List?)
            ?.map(
              (e) => e['name'],
        )
            .join(', ')
            ?? '',
        year:
        data['publish_date']
            ?? '',
      );

    } catch (_) {

      return IsbnSourceResult(
        source: 'OpenLibrary',
        found: false,
        title: '',
        authors: '',
        editorial: '',
        year: '',
      );
    }
  }

  static Future<IsbnSourceResult>
  _googleBooks(
      String isbn,
      ) async {

    try {

      final response =
      await http.get(
        Uri.parse(
          'https://www.googleapis.com/books/v1/volumes?q=isbn:$isbn',
        ),
      );

      final json =
      jsonDecode(response.body);

      if(json['totalItems'] == 0) {

        return IsbnSourceResult(
          source: 'Google Books',
          found: false,
          title: '',
          authors: '',
          editorial: '',
          year: '',
        );
      }

      final info =
      json['items'][0]
      ['volumeInfo'];

      return IsbnSourceResult(
        source: 'Google Books',
        found: true,
        title:
        info['title'] ?? '',
        authors:
        (info['authors']
        as List?)
            ?.join(', ')
            ?? '',
        editorial:
        info['publisher']
            ?? '',
        year:
        info['publishedDate']
            ?? '',
      );

    } catch (_) {

      return IsbnSourceResult(
        source: 'Google Books',
        found: false,
        title: '',
        authors: '',
        editorial: '',
        year: '',
      );
    }
  }
}