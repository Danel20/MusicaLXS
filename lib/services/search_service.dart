import 'package:diacritic/diacritic.dart';

class SearchService {

  static String normalize(
      String text,
      ) {

    return removeDiacritics(
      text.toLowerCase(),
    );
  }

  static bool contains(
      String source,
      String query,
      ) {

    return normalize(source)
        .contains(
      normalize(query),
    );
  }

  static List<String> autocomplete(
      String query,
      List<String> source,
      ) {

    if(query.length < 3) {
      return [];
    }

    return source.where(
          (e) => contains(
        e,
        query,
      ),
    ).toList();
  }
}