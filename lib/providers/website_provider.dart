import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/website_design.dart';
import '../services/firestore_service.dart';
import '../services/openai_service.dart';

class WebsiteProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final OpenAIService _openAIService = OpenAIService();
  final Uuid _uuid = const Uuid();

  WebsiteDesign? _currentWebsiteDesign;
  List<WebsiteDesign> _userWebsiteDesigns = [];
  bool _isLoading = false;
  String? _errorMessage;

  WebsiteDesign? get currentWebsiteDesign => _currentWebsiteDesign;
  List<WebsiteDesign> get userWebsiteDesigns => _userWebsiteDesigns;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // sections available
  static const List<String> availableSections = [
    'O nas',
    'Oferta/Usługi',
    'Galeria',
    'Kontakt',
    'Social media',
    'Opinie klientów',
    'Cennik',
    'Formularz kontaktowy',
  ];

  // syles
  static const List<String> availableStyles = [
    'Nowoczesny',
    'Minimalistyczny',
    'Klasyczny',
    'Firmowy',
    'Kreatywny',
    'Elegancki',
    'Technologiczny',
    'Artystyczny',
  ];

  // new project
  Future<String> createNewWebsiteDesign(String userId) async {
    final id = _uuid.v4();
    _currentWebsiteDesign = WebsiteDesign(
      id: id,
      userId: userId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestoreService.createWebsiteDesign(_currentWebsiteDesign!);
    notifyListeners();
    return id;
  }

  Future<void> loadWebsiteDesign(String id) async {
    _setLoading(true);
    try {
      _currentWebsiteDesign = await _firestoreService.getWebsiteDesign(id);
      notifyListeners();
    } catch (e) {
      _setError('Błąd wczytywania projektu: $e');
    }
    _setLoading(false);
  }

  // (screen 1)
  Future<bool> setCompanyData({
    required String companyName,
    String? nipNumber,
    String? address,
    String? phoneNumber,
    required String businessDescription,
    String? additionalInfo,
  }) async {
    if (_currentWebsiteDesign == null) return false;

    _setLoading(true);
    try {
      _currentWebsiteDesign = _currentWebsiteDesign!.copyWith(
        companyName: companyName,
        nipNumber: nipNumber,
        address: address,
        phoneNumber: phoneNumber,
        businessDescription: businessDescription,
        additionalInfo: additionalInfo,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.updateWebsiteDesignFields(
        _currentWebsiteDesign!.id,
        {
          'companyName': companyName,
          'nipNumber': nipNumber,
          'address': address,
          'phoneNumber': phoneNumber,
          'businessDescription': businessDescription,
          'additionalInfo': additionalInfo,
        },
      );

      notifyListeners();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Błąd zapisywania danych firmy: $e');
      _setLoading(false);
      return false;
    }
  }

  // (screen 2)
  Future<bool> setSelectedSections(List<String> sections, String? customSection) async {
    if (_currentWebsiteDesign == null) return false;

    _setLoading(true);
    try {
      _currentWebsiteDesign = _currentWebsiteDesign!.copyWith(
        selectedSections: sections,
        customSection: customSection,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.updateWebsiteDesignFields(
        _currentWebsiteDesign!.id,
        {
          'selectedSections': sections,
          'customSection': customSection,
        },
      );

      notifyListeners();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Błąd zapisywania sekcji: $e');
      _setLoading(false);
      return false;
    }
  }

  // (screen 3)
  Future<bool> setWebsiteStyle(String style) async {
    if (_currentWebsiteDesign == null) return false;

    _setLoading(true);
    try {
      _currentWebsiteDesign = _currentWebsiteDesign!.copyWith(
        websiteStyle: style,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.updateWebsiteDesignField(
        _currentWebsiteDesign!.id,
        'websiteStyle',
        style,
      );

      notifyListeners();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Błąd zapisywania stylu: $e');
      _setLoading(false);
      return false;
    }
  }

  // (screen 4)
  Future<bool> setColors({
    Color? textColor,
    Color? backgroundColor,
    List<Color>? additionalColors,
  }) async {
    if (_currentWebsiteDesign == null) return false;

    _setLoading(true);
    try {
      _currentWebsiteDesign = _currentWebsiteDesign!.copyWith(
        textColor: textColor ?? _currentWebsiteDesign!.textColor,
        backgroundColor: backgroundColor ?? _currentWebsiteDesign!.backgroundColor,
        additionalColors: additionalColors ?? _currentWebsiteDesign!.additionalColors,
        updatedAt: DateTime.now(),
      );

      final Map<String, dynamic> colorData = {};
      if (textColor != null) colorData['textColor'] = textColor.toARGB32();
      if (backgroundColor != null) colorData['backgroundColor'] = backgroundColor.toARGB32();
      if (additionalColors != null) {
        colorData['additionalColors'] = additionalColors.map((c) => c.toARGB32()).toList();
      }

      await _firestoreService.updateWebsiteDesignFields(_currentWebsiteDesign!.id, colorData);

      notifyListeners();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Błąd zapisywania kolorów: $e');
      _setLoading(false);
      return false;
    }
  }

  // website generator
  Future<bool> generateWebsite() async {
    if (!_isDataComplete()) {
      _setError('Brakuje wymaganych danych do generowania strony');
      return false;
    }

    _setLoading(true);
    try {
      final websiteCode = await _openAIService.generateWebsite(
        companyName: _currentWebsiteDesign!.companyName!,
        nipNumber: _currentWebsiteDesign!.nipNumber,
        address: _currentWebsiteDesign!.address,
        phoneNumber: _currentWebsiteDesign!.phoneNumber,
        businessDescription: _currentWebsiteDesign!.businessDescription!,
        additionalInfo: _currentWebsiteDesign!.additionalInfo,
        selectedSections: _currentWebsiteDesign!.selectedSections!,
        customSection: _currentWebsiteDesign!.customSection,
        websiteStyle: _currentWebsiteDesign!.websiteStyle!,
        textColor: _currentWebsiteDesign!.textColor,
        backgroundColor: _currentWebsiteDesign!.backgroundColor,
        additionalColors: _currentWebsiteDesign!.additionalColors,
      );

      final prompt = _createWebsitePrompt();

      _currentWebsiteDesign = _currentWebsiteDesign!.copyWith(
        htmlCode: websiteCode['html'],
        cssCode: websiteCode['css'],
        websitePrompt: prompt,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.updateWebsiteDesignFields(
        _currentWebsiteDesign!.id,
        {
          'htmlCode': websiteCode['html'],
          'cssCode': websiteCode['css'],
          'websitePrompt': prompt,
        },
      );

      notifyListeners();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Błąd generowania strony: $e');
      _setLoading(false);
      return false;
    }
  }

  bool _isDataComplete() {
    return _currentWebsiteDesign != null &&
        _currentWebsiteDesign!.companyName != null &&
        _currentWebsiteDesign!.businessDescription != null &&
        _currentWebsiteDesign!.selectedSections != null &&
        _currentWebsiteDesign!.selectedSections!.isNotEmpty &&
        _currentWebsiteDesign!.websiteStyle != null &&
        _currentWebsiteDesign!.textColor != null &&
        _currentWebsiteDesign!.backgroundColor != null;
  }

  // prompt
  String _createWebsitePrompt() {
    final sections = _currentWebsiteDesign!.selectedSections!.join(', ');
    final customSection = _currentWebsiteDesign!.customSection;
    final allSections = customSection != null && customSection.isNotEmpty
        ? '$sections, $customSection'
        : sections;

    return '''
Firma: ${_currentWebsiteDesign!.companyName}
${_currentWebsiteDesign!.nipNumber != null ? 'NIP: ${_currentWebsiteDesign!.nipNumber}' : ''}
${_currentWebsiteDesign!.address != null ? 'Adres: ${_currentWebsiteDesign!.address}' : ''}
${_currentWebsiteDesign!.phoneNumber != null ? 'Telefon: ${_currentWebsiteDesign!.phoneNumber}' : ''}
Opis działalności: ${_currentWebsiteDesign!.businessDescription}
${_currentWebsiteDesign!.additionalInfo != null ? 'Dodatkowe informacje: ${_currentWebsiteDesign!.additionalInfo}' : ''}
Sekcje: $allSections
Styl: ${_currentWebsiteDesign!.websiteStyle}
Kolory: tekst #${_currentWebsiteDesign!.textColor!.toARGB32().toRadixString(16)}, tło #${_currentWebsiteDesign!.backgroundColor!.toARGB32().toRadixString(16)}
${_currentWebsiteDesign!.additionalColors != null && _currentWebsiteDesign!.additionalColors!.isNotEmpty ? 'Dodatkowe kolory: ${_currentWebsiteDesign!.additionalColors!.map((c) => '#${c.toARGB32().toRadixString(16)}').join(', ')}' : ''}
    ''';
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
} 