import 'package:flutter/material.dart';

class WebsiteDesign {
  final String id;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // (screen 1)
  final String? companyName;
  final String? nipNumber;
  final String? address;
  final String? phoneNumber;
  final String? businessDescription;
  final String? additionalInfo;
  
  // (screen 2)
  final List<String>? selectedSections;
  final String? customSection;
  
  // (screen 3)
  final String? websiteStyle;
  
  // (screen 4)
  final Color? textColor;
  final Color? backgroundColor;
  final List<Color>? additionalColors;
  
  // site
  final String? htmlCode;
  final String? cssCode;
  final String? websitePrompt;
  final String? previewUrl;

  const WebsiteDesign({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.companyName,
    this.nipNumber,
    this.address,
    this.phoneNumber,
    this.businessDescription,
    this.additionalInfo,
    this.selectedSections,
    this.customSection,
    this.websiteStyle,
    this.textColor,
    this.backgroundColor,
    this.additionalColors,
    this.htmlCode,
    this.cssCode,
    this.websitePrompt,
    this.previewUrl,
  });

  WebsiteDesign copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? companyName,
    String? nipNumber,
    String? address,
    String? phoneNumber,
    String? businessDescription,
    String? additionalInfo,
    List<String>? selectedSections,
    String? customSection,
    String? websiteStyle,
    Color? textColor,
    Color? backgroundColor,
    List<Color>? additionalColors,
    String? htmlCode,
    String? cssCode,
    String? websitePrompt,
    String? previewUrl,
  }) {
    return WebsiteDesign(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      companyName: companyName ?? this.companyName,
      nipNumber: nipNumber ?? this.nipNumber,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      businessDescription: businessDescription ?? this.businessDescription,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      selectedSections: selectedSections ?? this.selectedSections,
      customSection: customSection ?? this.customSection,
      websiteStyle: websiteStyle ?? this.websiteStyle,
      textColor: textColor ?? this.textColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      additionalColors: additionalColors ?? this.additionalColors,
      htmlCode: htmlCode ?? this.htmlCode,
      cssCode: cssCode ?? this.cssCode,
      websitePrompt: websitePrompt ?? this.websitePrompt,
      previewUrl: previewUrl ?? this.previewUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'companyName': companyName,
      'nipNumber': nipNumber,
      'address': address,
      'phoneNumber': phoneNumber,
      'businessDescription': businessDescription,
      'additionalInfo': additionalInfo,
      'selectedSections': selectedSections,
      'customSection': customSection,
      'websiteStyle': websiteStyle,
      'textColor': textColor?.toARGB32(),
      'backgroundColor': backgroundColor?.toARGB32(),
      'additionalColors': additionalColors?.map((c) => c.toARGB32()).toList(),
      'htmlCode': htmlCode,
      'cssCode': cssCode,
      'websitePrompt': websitePrompt,
      'previewUrl': previewUrl,
    };
  }

  factory WebsiteDesign.fromMap(Map<String, dynamic> map) {
    return WebsiteDesign(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      companyName: map['companyName'],
      nipNumber: map['nipNumber'],
      address: map['address'],
      phoneNumber: map['phoneNumber'],
      businessDescription: map['businessDescription'],
      additionalInfo: map['additionalInfo'],
      selectedSections: map['selectedSections'] != null 
          ? List<String>.from(map['selectedSections'])
          : null,
      customSection: map['customSection'],
      websiteStyle: map['websiteStyle'],
      textColor: map['textColor'] != null ? Color(map['textColor']) : null,
      backgroundColor: map['backgroundColor'] != null ? Color(map['backgroundColor']) : null,
      additionalColors: map['additionalColors'] != null 
          ? (map['additionalColors'] as List).map((c) => Color(c)).toList()
          : null,
      htmlCode: map['htmlCode'],
      cssCode: map['cssCode'],
      websitePrompt: map['websitePrompt'],
      previewUrl: map['previewUrl'],
    );
  }
} 