class BookRepository {

  final client =
      SupabaseService.client;

  Future<Map<String,dynamic>>
  preloadLibrary() async {

    final books =
    await client
        .from('books')
        .select();

    final authors =
    await client
        .from('authors')
        .select();

    final editorials =
    await client
        .from('editorials')
        .select();

    final countries =
    await client
        .from('countries')
        .select();

    final departments =
    await client
        .from('departments')
        .select();

    final cities =
    await client
        .from('cities')
        .select();

    final categories =
    await client
        .from('categories')
        .select();

    return {
      'books': books,
      'authors': authors,
      'editorials': editorials,
      'countries': countries,
      'departments': departments,
      'cities': cities,
      'categories': categories,
    };
  }
}