class Pet {
  final String id;
  final String shelterId;
  final String name;
  final String species;
  final String? breed;
  final int? ageMonths;
  final String? size;
  final String? gender;
  final String? description;
  final String? story;
  final String? healthStatus;
  final bool vaccinated;
  final bool sterilized;
  final bool dewormed;
  final bool childFriendly;
  final String adoptionStatus;
  final String? mainPhotoUrl;
  final DateTime createdAt;

  const Pet({
    required this.id,
    required this.shelterId,
    required this.name,
    required this.species,
    this.breed,
    this.ageMonths,
    this.size,
    this.gender,
    this.description,
    this.story,
    this.healthStatus,
    this.vaccinated = false,
    this.sterilized = false,
    this.dewormed = false,
    this.childFriendly = false,
    this.adoptionStatus = 'disponible',
    this.mainPhotoUrl,
    required this.createdAt,
  });

  factory Pet.fromMap(Map<String, dynamic> map) {
    return Pet(
      id: map['id'],
      shelterId: map['shelter_id'],
      name: map['name'],
      species: map['species'],
      breed: map['breed'],
      ageMonths: map['age_months'],
      size: map['size'],
      gender: map['gender'],
      description: map['description'],
      story: map['story'],
      healthStatus: map['health_status'],
      vaccinated: map['vaccinated'] ?? false,
      sterilized: map['sterilized'] ?? false,
      dewormed: map['dewormed'] ?? false,
      childFriendly: map['child_friendly'] ?? false,
      adoptionStatus: map['adoption_status'] ?? 'disponible',
      mainPhotoUrl: map['main_photo_url'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap(String shelterId) {
    return {
      'shelter_id': shelterId,
      'name': name,
      'species': species,
      'breed': breed,
      'age_months': ageMonths,
      'size': size,
      'gender': gender,
      'description': description,
      'story': story,
      'health_status': healthStatus,
      'vaccinated': vaccinated,
      'sterilized': sterilized,
      'dewormed': dewormed,
      'child_friendly': childFriendly,
      'adoption_status': adoptionStatus,
    };
  }
}

String petAgeLabel(int? ageMonths) {
  if (ageMonths == null) return 'Edad desconocida';
  if (ageMonths < 12) return '$ageMonths meses';
  final years = ageMonths ~/ 12;
  final months = ageMonths % 12;
  if (months == 0) return '$years ${years == 1 ? 'año' : 'años'}';
  return '$years ${years == 1 ? 'año' : 'años'} y $months meses';
}