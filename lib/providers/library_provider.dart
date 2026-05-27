import 'package:flutter/material.dart';

class LibraryProvider
    extends ChangeNotifier {

  List books = [];

  List authors = [];

  List editorials = [];

  List countries = [];

  List departments = [];

  List cities = [];

  List categories = [];

  bool loading = false;

  final repository =
  BookRepository();

  Future<void> load() async {

    loading = true;

    notifyListeners();

    final data =
    await repository
        .preloadLibrary();

    books =
    data['books'];

    authors =
    data['authors'];

    editorials =
    data['editorials'];

    countries =
    data['countries'];

    departments =
    data['departments'];

    cities =
    data['cities'];

    categories =
    data['categories'];

    loading = false;

    notifyListeners();
  }
}