class Department {
  final int id;

  final String name;

  final int countryId;

  Department({
    required this.id,
    required this.name,
    required this.countryId,
  });

  factory Department.fromJson(
      Map<String, dynamic> json) {
    return Department(
      id: json['id'],
      name: json['name'],
      countryId: json['country_id'],
    );
  }
}