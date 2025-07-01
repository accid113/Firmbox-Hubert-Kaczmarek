class BusinessIdea {
  final String id;
  final String userId;
  final String? idea;
  final String? companyName;
  final String? competitorAnalysis;
  final String? businessPlan;
  final String? marketingPlan;
  final String? pdfUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  BusinessIdea({
    required this.id,
    required this.userId,
    this.idea,
    this.companyName,
    this.competitorAnalysis,
    this.businessPlan,
    this.marketingPlan,
    this.pdfUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'idea': idea,
      'companyName': companyName,
      'competitorAnalysis': competitorAnalysis,
      'businessPlan': businessPlan,
      'marketingPlan': marketingPlan,
      'pdfUrl': pdfUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory BusinessIdea.fromMap(Map<String, dynamic> map) {
    return BusinessIdea(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      idea: map['idea'],
      companyName: map['companyName'],
      competitorAnalysis: map['competitorAnalysis'],
      businessPlan: map['businessPlan'],
      marketingPlan: map['marketingPlan'],
      pdfUrl: map['pdfUrl'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  BusinessIdea copyWith({
    String? id,
    String? userId,
    String? idea,
    String? companyName,
    String? competitorAnalysis,
    String? businessPlan,
    String? marketingPlan,
    String? pdfUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusinessIdea(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      idea: idea ?? this.idea,
      companyName: companyName ?? this.companyName,
      competitorAnalysis: competitorAnalysis ?? this.competitorAnalysis,
      businessPlan: businessPlan ?? this.businessPlan,
      marketingPlan: marketingPlan ?? this.marketingPlan,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 