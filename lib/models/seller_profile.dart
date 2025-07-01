class SellerProfile {
  final String userId;
  final String name;
  final String address;
  final String nip;
  final String? logoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  SellerProfile({
    required this.userId,
    required this.name,
    required this.address,
    required this.nip,
    this.logoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  SellerProfile copyWith({
    String? name,
    String? address,
    String? nip,
    String? logoUrl,
    DateTime? updatedAt,
    bool updateLogoUrl = false,
  }) {
    return SellerProfile(
      userId: userId,
      name: name ?? this.name,
      address: address ?? this.address,
      nip: nip ?? this.nip,
      logoUrl: updateLogoUrl ? logoUrl : (logoUrl ?? this.logoUrl),
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'address': address,
      'nip': nip,
      'logoUrl': logoUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SellerProfile.fromMap(Map<String, dynamic> map) {
    return SellerProfile(
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      nip: map['nip'] ?? '',
      logoUrl: map['logoUrl'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
} 