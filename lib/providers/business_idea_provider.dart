import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/business_idea.dart';
import '../services/firestore_service.dart';
import '../services/openai_service.dart';

class BusinessIdeaProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final OpenAIService _openAIService = OpenAIService();
  final Uuid _uuid = const Uuid();

  BusinessIdea? _currentBusinessIdea;
  List<BusinessIdea> _userBusinessIdeas = [];
  bool _isLoading = false;
  String? _errorMessage;

  BusinessIdea? get currentBusinessIdea => _currentBusinessIdea;
  List<BusinessIdea> get userBusinessIdeas => _userBusinessIdeas;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // create new idea
  Future<String> createNewBusinessIdea(String userId) async {
    final id = _uuid.v4();
    _currentBusinessIdea = BusinessIdea(
      id: id,
      userId: userId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestoreService.createBusinessIdea(_currentBusinessIdea!);
    notifyListeners();
    return id;
  }

  // load idea
  Future<void> loadBusinessIdea(String id) async {
    _setLoading(true);
    try {
      _currentBusinessIdea = await _firestoreService.getBusinessIdea(id);
      notifyListeners();
    } catch (e) {
      _setError('Błąd wczytywania pomysłu: $e');
    }
    _setLoading(false);
  }

  // Ggenerate idea
  Future<bool> generateBusinessIdea() async {
    if (_currentBusinessIdea == null) return false;

    _setLoading(true);
    try {
      final idea = await _openAIService.generateBusinessIdea();
      
      _currentBusinessIdea = _currentBusinessIdea!.copyWith(
        idea: idea,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.updateBusinessIdeaField(
        _currentBusinessIdea!.id,
        'idea',
        idea,
      );

      notifyListeners();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Błąd generowania pomysłu: $e');
      _setLoading(false);
      return false;
    }
  }

  // cutom idea
  Future<bool> setCustomBusinessIdea(String idea) async {
    if (_currentBusinessIdea == null) return false;

    _setLoading(true);
    try {
      _currentBusinessIdea = _currentBusinessIdea!.copyWith(
        idea: idea,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.updateBusinessIdeaField(
        _currentBusinessIdea!.id,
        'idea',
        idea,
      );

      notifyListeners();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Błąd zapisywania pomysłu: $e');
      _setLoading(false);
      return false;
    }
  }

  // company name
  Future<bool> generateCompanyName() async {
    if (_currentBusinessIdea?.idea == null) return false;

    _setLoading(true);
    try {
      final companyName = await _openAIService.generateCompanyName(
        _currentBusinessIdea!.idea!,
      );

      _currentBusinessIdea = _currentBusinessIdea!.copyWith(
        companyName: companyName,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.updateBusinessIdeaField(
        _currentBusinessIdea!.id,
        'companyName',
        companyName,
      );

      notifyListeners();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Błąd generowania nazwy firmy: $e');
      _setLoading(false);
      return false;
    }
  }

  // customp company name
  Future<bool> setCustomCompanyName(String companyName) async {
    if (_currentBusinessIdea == null) return false;

    _setLoading(true);
    try {
      _currentBusinessIdea = _currentBusinessIdea!.copyWith(
        companyName: companyName,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.updateBusinessIdeaField(
        _currentBusinessIdea!.id,
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

  // competition analysis
  Future<bool> generateCompetitorAnalysis() async {
    if (_currentBusinessIdea?.idea == null || 
        _currentBusinessIdea?.companyName == null) {
      return false;
    }

    _setLoading(true);
    try {
      final analysis = await _openAIService.generateCompetitorAnalysis(
        businessIdea: _currentBusinessIdea!.idea!,
        companyName: _currentBusinessIdea!.companyName!,
      );

      _currentBusinessIdea = _currentBusinessIdea!.copyWith(
        competitorAnalysis: analysis,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.updateBusinessIdeaField(
        _currentBusinessIdea!.id,
        'competitorAnalysis',
        analysis,
      );

      notifyListeners();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Błąd generowania analizy konkurencji: $e');
      _setLoading(false);
      return false;
    }
  }

  // biznesplan genarator
  Future<bool> generateBusinessPlan() async {
    if (_currentBusinessIdea?.idea == null ||
        _currentBusinessIdea?.companyName == null ||
        _currentBusinessIdea?.competitorAnalysis == null) {
      return false;
    }

    _setLoading(true);
    try {
      final businessPlan = await _openAIService.generateBusinessPlan(
        businessIdea: _currentBusinessIdea!.idea!,
        companyName: _currentBusinessIdea!.companyName!,
        competitorAnalysis: _currentBusinessIdea!.competitorAnalysis!,
      );

      _currentBusinessIdea = _currentBusinessIdea!.copyWith(
        businessPlan: businessPlan,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.updateBusinessIdeaField(
        _currentBusinessIdea!.id,
        'businessPlan',
        businessPlan,
      );

      notifyListeners();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Błąd generowania biznesplanu: $e');
      _setLoading(false);
      return false;
    }
  }

  // marketing plan
  Future<bool> generateMarketingPlan() async {
    if (_currentBusinessIdea?.idea == null ||
        _currentBusinessIdea?.companyName == null ||
        _currentBusinessIdea?.competitorAnalysis == null ||
        _currentBusinessIdea?.businessPlan == null) {
      return false;
    }

    _setLoading(true);
    try {
      final marketingPlan = await _openAIService.generateMarketingPlan(
        businessIdea: _currentBusinessIdea!.idea!,
        companyName: _currentBusinessIdea!.companyName!,
        competitorAnalysis: _currentBusinessIdea!.competitorAnalysis!,
        businessPlan: _currentBusinessIdea!.businessPlan!,
      );

      _currentBusinessIdea = _currentBusinessIdea!.copyWith(
        marketingPlan: marketingPlan,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.updateBusinessIdeaField(
        _currentBusinessIdea!.id,
        'marketingPlan',
        marketingPlan,
      );

      notifyListeners();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Błąd generowania planu marketingowego: $e');
      _setLoading(false);
      return false;
    }
  }

  // pdf generator
  Future<bool> generatePDF() async {
    if (!_isBusinessIdeaComplete()) {
      return false;
    }

    _setLoading(true);
    try {
      final pdfUrl = await _openAIService.generatePDF(
        businessIdeaId: _currentBusinessIdea!.id,
        businessIdea: _currentBusinessIdea!.idea!,
        companyName: _currentBusinessIdea!.companyName!,
        competitorAnalysis: _currentBusinessIdea!.competitorAnalysis!,
        businessPlan: _currentBusinessIdea!.businessPlan!,
        marketingPlan: _currentBusinessIdea!.marketingPlan!,
      );

      _currentBusinessIdea = _currentBusinessIdea!.copyWith(
        pdfUrl: pdfUrl,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.updateBusinessIdeaField(
        _currentBusinessIdea!.id,
        'pdfUrl',
        pdfUrl,
      );

      notifyListeners();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Błąd generowania PDF: $e');
      _setLoading(false);
      return false;
    }
  }

  // get idea
  Future<void> loadUserBusinessIdeas(String userId) async {
    _setLoading(true);
    try {
      _userBusinessIdeas = await _firestoreService.getUserBusinessIdeas(userId);
      notifyListeners();
    } catch (e) {
      _setError('Błąd pobierania pomysłów: $e');
    }
    _setLoading(false);
  }

  bool _isBusinessIdeaComplete() {
    return _currentBusinessIdea?.idea != null &&
           _currentBusinessIdea?.companyName != null &&
           _currentBusinessIdea?.competitorAnalysis != null &&
           _currentBusinessIdea?.businessPlan != null &&
           _currentBusinessIdea?.marketingPlan != null;
  }


  bool get isBusinessIdeaComplete => _isBusinessIdeaComplete();

  Future<String> downloadPDF() async {
    if (!_isBusinessIdeaComplete()) {
      throw Exception('Brakuje wymaganych danych do generowania PDF');
    }

    _setLoading(true);
    try {
      final pdfResult = await _openAIService.generatePDF(
        businessIdeaId: _currentBusinessIdea!.id,
        businessIdea: _currentBusinessIdea!.idea!,
        companyName: _currentBusinessIdea!.companyName!,
        competitorAnalysis: _currentBusinessIdea!.competitorAnalysis!,
        businessPlan: _currentBusinessIdea!.businessPlan!,
        marketingPlan: _currentBusinessIdea!.marketingPlan!,
      );

      // update pdf url
      _currentBusinessIdea = _currentBusinessIdea!.copyWith(
        pdfUrl: pdfResult,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.updateBusinessIdeaField(
        _currentBusinessIdea!.id,
        'pdfUrl',
        pdfResult,
      );

      notifyListeners();
      _setLoading(false);
      return pdfResult;
    } catch (e) {
      _setError('Błąd generowania PDF: $e');
      _setLoading(false);
      rethrow;
    }
  }

  // current idea
  void clearCurrentBusinessIdea() {
    _currentBusinessIdea = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
} 