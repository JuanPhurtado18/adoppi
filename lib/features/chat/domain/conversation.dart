class Conversation {
  final String id;
  final String adoptantId;
  final String shelterId;
  final String? petId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final Map<String, dynamic>? shelterInfo;
  final Map<String, dynamic>? adoptantInfo;
  final Map<String, dynamic>? petInfo;

  const Conversation({
    required this.id,
    required this.adoptantId,
    required this.shelterId,
    this.petId,
    this.lastMessage,
    this.lastMessageAt,
    required this.createdAt,
    this.shelterInfo,
    this.adoptantInfo,
    this.petInfo,
  });

  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      id: map['id'],
      adoptantId: map['adoptant_id'],
      shelterId: map['shelter_id'],
      petId: map['pet_id'],
      lastMessage: map['last_message'],
      lastMessageAt: map['last_message_at'] != null
          ? DateTime.parse(map['last_message_at'])
          : null,
      createdAt: DateTime.parse(map['created_at']),
      shelterInfo: map['shelters'] as Map<String, dynamic>?,
      adoptantInfo: map['profiles'] as Map<String, dynamic>?,
      petInfo: map['pets'] as Map<String, dynamic>?,
    );
  }

  String get otherPartyName {
    return shelterInfo?['name'] ?? adoptantInfo?['full_name'] ?? 'Usuario';
  }

  String? get otherPartyAvatar {
    return shelterInfo?['avatar_url'] ?? adoptantInfo?['avatar_url'];
  }
}
