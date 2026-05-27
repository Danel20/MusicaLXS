class Author {
  final int id;

  final String fullName;

  Author({
    required this.id,
    required this.fullName,
  });

  factory Author.fromJson(
      Map<String, dynamic> json) {
    return Author(
      id: json['id'],
      fullName: json['full_name'],
    );
  }
}