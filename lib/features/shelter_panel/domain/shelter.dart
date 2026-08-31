class Shelter {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String? address;
  final String? city;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final String? email;
  final String? schedule;
  final String? avatarUrl;
  final String? coverUrl;
  final double rating;
  final bool isVerified;
  final DateTime createdAt;

  const Shelter({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.address,
    this.city,
    this.latitude,
    this.longitude,
    this.phone,
    this.email,
    this.schedule,
    this.avatarUrl,
    this.coverUrl,
    this.rating = 0,
    this.isVerified = false,
    required this.createdAt,
  });

  factory Shelter.fromMap(Map<String, dynamic> map) {
    return Shelter(
      id: map['id'],
      userId: map['user_id'],
      name: map['name'],
      description: map['description'],
      address: map['address'],
      city: map['city'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      phone: map['phone'],
      email: map['email'],
      schedule: map['schedule'],
      avatarUrl: map['avatar_url'],
      coverUrl: map['cover_url'],
      rating: (map['rating'] ?? 0).toDouble(),
      isVerified: map['is_verified'] ?? false,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'address': address,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'email': email,
      'schedule': schedule,
    };
  }

  Shelter copyWith({
    String? name,
    String? description,
    String? address,
    String? city,
    String? phone,
    String? email,
    String? schedule,
    String? avatarUrl,
    String? coverUrl,
  }) {
    return Shelter(
      id: id,
      userId: userId,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      city: city ?? this.city,
      latitude: latitude,
      longitude: longitude,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      schedule: schedule ?? this.schedule,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      rating: rating,
      isVerified: isVerified,
      createdAt: createdAt,
    );
  }
}