class LocationModel {
  final String id;
  final String name;
  final String city;
  final String? address;
  final bool isActive;

  LocationModel({
    required this.id,
    required this.name,
    required this.city,
    this.address,
    required this.isActive,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'],
      name: json['name'],
      city: json['city'],
      address: json['address'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'address': address,
      'is_active': isActive,
    };
  }
}
