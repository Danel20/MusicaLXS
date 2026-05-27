import 'dart:convert';

class Author {
  String firstName;
  String lastName;

  Author({required this.firstName, required this.lastName});

  Map<String, String> toJson() => {
    'first_name': firstName,
    'last_name': lastName,
  };

  factory Author.fromJson(Map<String, dynamic> json) => Author(
    firstName: json['first_name'] ?? '',
    lastName: json['last_name'] ?? '',
  );

  String get fullName => '$firstName $lastName'.trim();
}

class Book {
  String? id;
  String isbn;
  List<Author> authors;
  String title;
  String category;
  String city;
  String department;
  String country;
  String editorial;
  String year;

  Book({
    this.id,
    required this.isbn,
    required this.authors,
    required this.title,
    required this.category,
    required this.city,
    required this.department,
    required this.country,
    required this.editorial,
    required this.year,
  });

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'isbn': isbn,
    'authors': jsonEncode(authors.map((a) => a.toJson()).toList()),
    'title': title,
    'category': category,
    'city': city,
    'department': department,
    'country': country,
    'editorial': editorial,
    'year': year,
  };

  factory Book.fromJson(Map<String, dynamic> json) {
    List<Author> parsedAuthors = [];
    if (json['authors'] != null) {
      try {
        final List decoded = jsonDecode(json['authors']);
        parsedAuthors = decoded.map((item) => Author.fromJson(item)).toList();
      } catch (_) {
        parsedAuthors = [Author(firstName: json['authors'].toString(), lastName: '')];
      }
    }
    return Book(
      id: json['id']?.toString(),
      isbn: json['isbn'] ?? '',
      authors: parsedAuthors,
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      city: json['city'] ?? '',
      department: json['department'] ?? '',
      country: json['country'] ?? '',
      editorial: json['editorial'] ?? '',
      year: json['year']?.toString() ?? '',
    );
  }

  bool contains(String query) {
    final q = _normalize(query);
    final matchAuthors = authors.any((a) => _normalize(a.fullName).contains(q));
    return _normalize(title).contains(q) ||
        matchAuthors ||
        _normalize(isbn).contains(q) ||
        _normalize(editorial).contains(q) ||
        _normalize(category).contains(q) ||
        _normalize(year).contains(q) ||
        _normalize(country).contains(q) ||
        _normalize(city).contains(q);
  }

  static String _normalize(String text) {
    var withDia = 'áéíóúüñÁÉÍÓÚÜÑ';
    var withoutDia = 'aeiounAEIOUN';
    String result = text.toLowerCase();
    for (int i = 0; i < withDia.length; i++) {
      result = result.replaceAll(withDia[i], withoutDia[i]);
    }
    return result;
  }
}