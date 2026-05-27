class Editorial {
  final int id;

  final String name;

  Editorial({
    required this.id,
    required this.name,
  });

  factory Editorial.fromJson(
      Map<String, dynamic> json) {
    return Editorial(
      id: json['id'],
      name: json['name'],
    );
  }
}