import 'package:flutter/material.dart';

class LogoDesign {
  final String id;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // user data
  final String? companyName;
  final String? businessDescription;
  final Color? textColor;
  final Color? backgroundColor;
  final List<Color>? additionalColors;
  final String? style;
  
  // logo
  final String? logoUrl;
  final String? logoPrompt;

  const LogoDesign({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.companyName,
    this.businessDescription,
    this.textColor,
    this.backgroundColor,
    this.additionalColors,
    this.style,
    this.logoUrl,
    this.logoPrompt,
  });

  LogoDesign copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? companyName,
    String? businessDescription,
    Color? textColor,
    Color? backgroundColor,
    List<Color>? additionalColors,
    String? style,
    String? logoUrl,
    String? logoPrompt,
  }) {
    return LogoDesign(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      companyName: companyName ?? this.companyName,
      businessDescription: businessDescription ?? this.businessDescription,
      textColor: textColor ?? this.textColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      additionalColors: additionalColors ?? this.additionalColors,
      style: style ?? this.style,
      logoUrl: logoUrl ?? this.logoUrl,
      logoPrompt: logoPrompt ?? this.logoPrompt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'companyName': companyName,
      'businessDescription': businessDescription,
      'textColor': textColor?.toARGB32(),
      'backgroundColor': backgroundColor?.toARGB32(),
      'additionalColors': additionalColors?.map((c) => c.toARGB32()).toList(),
      'style': style,
      'logoUrl': logoUrl,
      'logoPrompt': logoPrompt,
    };
  }

  factory LogoDesign.fromMap(Map<String, dynamic> map) {
    return LogoDesign(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      companyName: map['companyName'],
      businessDescription: map['businessDescription'],
      textColor: map['textColor'] != null ? Color(map['textColor']) : null,
      backgroundColor: map['backgroundColor'] != null ? Color(map['backgroundColor']) : null,
      additionalColors: map['additionalColors'] != null 
          ? (map['additionalColors'] as List).map((c) => Color(c)).toList()
          : null,
      style: map['style'],
      logoUrl: map['logoUrl'],
      logoPrompt: map['logoPrompt'],
    );
  }
} 