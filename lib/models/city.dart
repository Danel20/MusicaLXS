class City {
  final int id;

  final String name;

  final int departmentId;

  City({
    required this.id,
    required this.name,
    required this.departmentId,
  });

  factory City.fromJson(
      Map<String, dynamic> json) {
    return City(
      id: json['id'],
      name: json['name'],
      departmentId: json['department_id'],
    );
  }
}