import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _user;
  UserModel? _userModel;
  bool _isLoading = true;
  String? _errorMessage;

  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;

  AuthProvider() {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (user != null) {
      _user = user;
    } else {
      _user = null;
      _userModel = null;
    }
    _setLoading(false);
  }

  // login by email
  Future<bool> signInWithEmail(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.signInWithEmail(email, password);
      if (result != null) {
        _user = result.user;
        _setLoading(false);
        return true;
      }
    } catch (e) {
      print('AuthProvider złapał błąd (signInWithEmail): $e');
      print('Typ błędu (signInWithEmail): ${e.runtimeType}');
      _setError(_formatAuthError(e.toString()));
    }

    _setLoading(false);
    return false;
  }

  // Register by email
  Future<bool> registerWithEmail(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.registerWithEmail(email, password);
      if (result != null) {
        _user = result.user;
        _setLoading(false);
        return true;
      }
    } catch (e) {
      print('AuthProvider złapał błąd (registerWithEmail): $e');
      print('Typ błędu (registerWithEmail): ${e.runtimeType}');
      _setError(_formatAuthError(e.toString()));
    }

    _setLoading(false);
    return false;
  }

  // login by google
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.signInWithGoogle();
      if (result != null) {
        _user = result.user;
        _setLoading(false);
        return true;
      } else {
        _setError('Logowanie przez Google zostało anulowane');
      }
    } catch (e) {
      print('AuthProvider złapał błąd (signInWithGoogle): $e');
      print('Typ błędu (signInWithGoogle): ${e.runtimeType}');
      
      String errorMessage = e.toString();
      if (errorMessage.contains('network_error') || errorMessage.contains('network')) {
        _setError('Brak połączenia z internetem. Sprawdź swoje połączenie i spróbuj ponownie.');
      } else if (errorMessage.contains('sign_in_canceled') || errorMessage.contains('canceled')) {
        _setError('Logowanie przez Google zostało anulowane');
      } else {
        _setError('Nie udało się zalogować przez Google. Spróbuj ponownie.');
      }
    }

    _setLoading(false);
    return false;
  }

  // login by apple
  Future<bool> signInWithApple() async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.signInWithApple();
      if (result != null) {
        _user = result.user;
        _setLoading(false);
        return true;
      } else {
        _setError('Logowanie przez Apple ID zostało anulowane');
      }
    } catch (e) {
      print('AuthProvider złapał błąd (signInWithApple): $e');
      print('Typ błędu (signInWithApple): ${e.runtimeType}');
      
      String errorMessage = e.toString();
      if (errorMessage.contains('nie jest dostępne') || errorMessage.contains('nie dostępne')) {
        _setError('Logowanie przez Apple ID jest dostępne tylko na urządzeniach iOS');
      } else if (errorMessage.contains('canceled') || errorMessage.contains('anulowane')) {
        _setError('Logowanie przez Apple ID zostało anulowane');
      } else {
        _setError('Nie udało się zalogować przez Apple ID. Spróbuj ponownie.');
      }
    }

    _setLoading(false);
    return false;
  }

  // log out
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _user = null;
      _userModel = null;
    } catch (e) {
      _setError('Nie udało się wylogować. Spróbuj ponownie.');
    }
    _setLoading(false);
  }

  // password reset
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.resetPassword(email);
      _setLoading(false);
      return true;
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('user-not-found') || errorMessage.contains('nie znaleziono')) {
        _setError('Nie znaleziono konta z tym adresem email');
      } else if (errorMessage.contains('invalid-email') || errorMessage.contains('nieprawidłowy')) {
        _setError('Wprowadź prawidłowy adres email');
      } else {
        _setError('Nie udało się wysłać emaila z resetem hasła. Spróbuj ponownie.');
      }
      _setLoading(false);
      return false;
    }
  }


  String _formatAuthError(String rawError) {
    String cleanError = rawError;

    if (cleanError.startsWith('Exception: ')) {
      cleanError = cleanError.substring(11);
    }
    
    if (cleanError.startsWith('Błąd logowania: ')) {
      cleanError = cleanError.substring(16);
    }
    
    if (cleanError.startsWith('Błąd rejestracji: ')) {
      cleanError = cleanError.substring(18);
    }
    
    if (cleanError.startsWith('Błąd ')) {
      cleanError = cleanError.substring(5);
    }

    if (_isUserFriendlyMessage(cleanError)) {
      return cleanError;
    }

    return 'Wystąpił problem z logowaniem. Sprawdź swoje dane i spróbuj ponownie.';
  }

  bool _isUserFriendlyMessage(String message) {
    final friendlyMessages = [
      'Nie znaleziono użytkownika z tym adresem email',
      'Nieprawidłowe hasło',
      'Konto z tym adresem email już istnieje',
      'Hasło jest za słabe',
      'Nieprawidłowy adres email',
      'Błąd połączenia z internetem',
    ];
    
    return friendlyMessages.any((friendly) => message.contains(friendly));
  }

  void _setLoading(bool loading) {
    if (_isLoading == loading) return;
    
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
} 