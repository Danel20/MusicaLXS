class AppCache {

  static List<Book> books = [];

  static List<String> authors = [];

  static List<String> editorials = [];

  static List<String> countries = [];

  static List<String> departments = [];

  static List<String> cities = [];

  static List<String> categories = [];

}

await loadAllData();

Future<void> loadAllData() async {

  await Future.wait([

    loadBooks(),

    loadAuthors(),

    loadEditorials(),

    loadCountries(),

    loadDepartments(),

    loadCities(),

    loadCategories(),

  ]);

}