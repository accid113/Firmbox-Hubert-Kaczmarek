import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/logo_design.dart';
import '../services/firestore_service.dart';
import '../services/openai_service.dart';

class LogoProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final OpenAIService _openAIService = OpenAIService();
  final Uuid _uuid = const Uuid();

  LogoDesign? _currentLogoDesign;
  List<LogoDesign> _userLogoDesigns = [];
  bool _isLoading = false;
  String? _errorMessage;

  LogoDesign? get currentLogoDesign => _currentLogoDesign;
  List<LogoDesign> get userLogoDesigns => _userLogoDesigns;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // new logo
  Future<String> createNewLogoDesign(String userId) async {
    final id = _uuid.v4();
    _currentLogoDesign = LogoDesign(
      id: id,
      userId: userId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestoreService.createLogoDesign(_currentLogoDesign!);
    notifyListeners();
    return id;
  }

  // load logo
  Future<void> loadLogoDesign(String id) async {
    _setLoading(true);
    try {
      _currentLogoDesign = await _firestoreService.getLogoDesign(id);
      notifyListeners();
    } catch (e) {
      _setError('Błąd wczytywania projektu: $e');
    }
    _setLoading(false);
  }

  // company name
  Future<bool> setCompanyName(String companyName) async {
    if (_currentLogoDesign == null) return false;

    _setLoading(true);
    try {
      _currentLogoDesign = _currentLogoDesign!.copyWith(
        companyName: companyName,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.updateLogoDesignField(
        _currentLogoDesign!.id,
        'companyName',
        companyName,
      );

      notifyListeners();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Błąd zapisywania nazwy firmy: $e');
      _setLoading(false);
      return false;
    }
  }

  // description
  Future<bool> setBusinessDescription(String description) async {
    if (_currentLogoDesign == null) return false;

    _setLoading(true);
    try {
      _currentLogoDesign = _currentLogoDesign!.copyWith(
        businessDescription: description,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.updateLogoDesignField(
        _currentLogoDesign!.id,
        'businessDescription',
        description,
      );

      notifyListeners();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Błąd zapisywania opisu: $e');
      _setLoading(false);
      return false;
    }
  }

  // color settings
  Future<bool> setColors({
    Color? textColor,
    Color? backgroundColor,
    List<Color>? additionalColors,
  }) async {
    if (_currentLogoDesign == null) return false;

    _setLoading(true);
    try {
      _currentLogoDesign = _currentLogoDesign!.copyWith(
        textColor: textColor ?? _currentLogoDesign!.textColor,
        backgroundColor: backgroundColor ?? _currentLogoDesign!.backgroundColor,
        additionalColors: additionalColors ?? _currentLogoDesign!.additionalColors,
        updatedAt: DateTime.now(),
      );

      // color save
      final Map<String, dynamic> colorData = {};
      if (textColor != null) colorData['textColor'] = textColor.toARGB32();
      if (backgroundColor != null) colorData['backgroundColor'] = backgroundColor.toARGB32();
      if (additionalColors != null) {
        colorData['additionalColors'] = additionalColors.map((c) => c.toARGB32()).toList();
      }

      await _firestoreService.updateLogoDesignFields(_currentLogoDesign!.id, colorData);

      notifyListeners();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Błąd zapisywania kolorów: $e');
      _setLoading(false);
      return false;
    }
  }

  // style settings
  Future<bool> setStyle(String style) async {
    if (_currentLogoDesign == null) return false;

    _setLoading(true);
    try {
      _currentLogoDesign = _currentLogoDesign!.copyWith(
        style: style,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.updateLogoDesignField(
        _currentLogoDesign!.id,
        'style',
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

  // logo generator
  Future<bool> generateLogo() async {
    if (_currentLogoDesign?.companyName == null || 
        _currentLogoDesign?.businessDescription == null ||
        _currentLogoDesign?.style == null) {
      _setError('Brakuje wymaganych danych do generowania logo');
      return false;
    }

    _setLoading(true);
    try {
      final logoUrl = await _openAIService.generateLogo(
        companyName: _currentLogoDesign!.companyName!,
        businessDescription: _currentLogoDesign!.businessDescription!,
        textColor: _currentLogoDesign!.textColor,
        backgroundColor: _currentLogoDesign!.backgroundColor,
        additionalColors: _currentLogoDesign!.additionalColors,
        style: _currentLogoDesign!.style!,
      );

      final prompt = _createLogoPrompt();

      _currentLogoDesign = _currentLogoDesign!.copyWith(
        logoUrl: logoUrl,
        logoPrompt: prompt,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.updateLogoDesignFields(
        _currentLogoDesign!.id,
        {
          'logoUrl': logoUrl,
          'logoPrompt': prompt,
        },
      );

      notifyListeners();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Błąd generowania logo: $e');
      _setLoading(false);
      return false;
    }
  }

  // regenerate
  Future<bool> regenerateLogo() async {
    return await generateLogo();
  }

  // all projects
  Future<void> loadUserLogoDesigns(String userId) async {
    _setLoading(true);
    try {
      _userLogoDesigns = await _firestoreService.getUserLogoDesigns(userId);
      notifyListeners();
    } catch (e) {
      _setError('Błąd wczytywania projektów: $e');
    }
    _setLoading(false);
  }

  Future<bool> deleteLogoDesign(String id) async {
    try {
      await _firestoreService.deleteLogoDesign(id);
      _userLogoDesigns.removeWhere((design) => design.id == id);
      
      if (_currentLogoDesign?.id == id) {
        _currentLogoDesign = null;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Błąd usuwania projektu: $e');
      return false;
    }
  }

  void clearCurrentLogoDesign() {
    _currentLogoDesign = null;
    _errorMessage = null;
    notifyListeners();
  }

  // prompt
  String _createLogoPrompt() {
    if (_currentLogoDesign == null) return '';

    final companyName = _currentLogoDesign!.companyName!;
    final description = _currentLogoDesign!.businessDescription!;
    final style = _currentLogoDesign!.style!;
    
    String prompt = 'Wygeneruj profesjonalne logo dla firmy "$companyName", która zajmuje się $description. ';
    prompt += 'Styl: $style. ';

    if (_currentLogoDesign!.textColor != null) {
      prompt += 'Kolor tekstu: ${_colorToName(_currentLogoDesign!.textColor!)}. ';
    }

    if (_currentLogoDesign!.backgroundColor != null) {
      prompt += 'Kolor tła: ${_colorToName(_currentLogoDesign!.backgroundColor!)}. ';
    }

    if (_currentLogoDesign!.additionalColors != null && _currentLogoDesign!.additionalColors!.isNotEmpty) {
      final additionalColorNames = _currentLogoDesign!.additionalColors!
          .map((color) => _colorToName(color))
          .join(', ');
      prompt += 'Kolory dodatkowe: $additionalColorNames. ';
    }

    prompt += 'Logo powinno być czytelne, profesjonalne i łatwe do zapamiętania.';

    return prompt;
  }


  String _colorToName(Color color) {
    if (color.red > 200 && color.green < 100 && color.blue < 100) return 'czerwony';
    if (color.green > 200 && color.red < 100 && color.blue < 100) return 'zielony';
    if (color.blue > 200 && color.red < 100 && color.green < 100) return 'niebieski';
    if (color.red > 200 && color.green > 200 && color.blue < 100) return 'żółty';
    if (color.red > 150 && color.green < 100 && color.blue > 150) return 'fioletowy';
    if (color.red > 200 && color.green > 100 && color.blue < 100) return 'pomarańczowy';
    if (color.red < 50 && color.green < 50 && color.blue < 50) return 'czarny';
    if (color.red > 200 && color.green > 200 && color.blue > 200) return 'biały';
    return 'kolorowy';
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) _errorMessage = null;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }
} 