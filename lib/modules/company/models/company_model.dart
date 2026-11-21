class CompanyModel {
  const CompanyModel({
    required this.id,
    required this.name,
    required this.position,
    required this.logoKey,
    required this.salary,
    required this.period,
    required this.currency,
    required this.location,
    required this.tags,
    required this.employmentType,
    required this.level,
    required this.isFeatured,
    required this.isSaved,
  });

  final String id;
  final String name;
  final String position;
  final String logoKey;
  final num salary;
  final String period;
  final String currency;
  final String location;
  final List<String> tags;
  final String employmentType;
  final String level;
  final bool isFeatured;
  final bool isSaved;

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    final tags = json['tags'];
    if (json['id'] is! String ||
        json['name'] is! String ||
        json['position'] is! String ||
        json['logoKey'] is! String ||
        json['salary'] is! num ||
        json['period'] is! String ||
        json['currency'] is! String ||
        json['location'] is! String ||
        tags is! List ||
        tags.any((tag) => tag is! String) ||
        json['employmentType'] is! String ||
        json['level'] is! String ||
        json['isFeatured'] is! bool ||
        json['isSaved'] is! bool) {
      throw const FormatException('Los datos de la empresa no son válidos.');
    }

    return CompanyModel(
      id: json['id'] as String,
      name: json['name'] as String,
      position: json['position'] as String,
      logoKey: json['logoKey'] as String,
      salary: json['salary'] as num,
      period: json['period'] as String,
      currency: json['currency'] as String,
      location: json['location'] as String,
      tags: List<String>.from(tags),
      employmentType: json['employmentType'] as String,
      level: json['level'] as String,
      isFeatured: json['isFeatured'] as bool,
      isSaved: json['isSaved'] as bool,
    );
  }

  CompanyModel copyWith({bool? isSaved}) => CompanyModel(
    id: id,
    name: name,
    position: position,
    logoKey: logoKey,
    salary: salary,
    period: period,
    currency: currency,
    location: location,
    tags: tags,
    employmentType: employmentType,
    level: level,
    isFeatured: isFeatured,
    isSaved: isSaved ?? this.isSaved,
  );
}
