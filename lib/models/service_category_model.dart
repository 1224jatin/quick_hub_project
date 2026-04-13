class ServiceCategoryModel {
  final String id;
  final String name;
  final String iconUrl; // E.g., 'assets/icons/plumber.png' or remote URL
  final String description;

  ServiceCategoryModel({
    required this.id,
    required this.name,
    required this.iconUrl,
    required this.description,
  });

  factory ServiceCategoryModel.fromJson(Map<String, dynamic> json) {
    return ServiceCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      iconUrl: json['iconUrl'] as String,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconUrl': iconUrl,
      'description': description,
    };
  }
}
