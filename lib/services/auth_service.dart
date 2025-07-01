import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _firestoreService = FirestoreService();

  // current user
  User? get currentUser => _auth.currentUser;

  // status change
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // login with email and password
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (result.user != null) {
        await _updateUserLastLogin(result.user!);
      }
      
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // register with email and password
  Future<UserCredential?> registerWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (result.user != null) {
        await _createUserDocument(result.user!);
      }
      
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // login by google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      
      if (result.user != null) {
        await _createOrUpdateUserDocument(result.user!);
      }
      
      return result;
    } catch (e) {
      throw Exception('Błąd logowania przez Google: $e');
    }
  }

  // login by apple
  Future<UserCredential?> signInWithApple() async {
    if (kIsWeb || !Platform.isIOS) {
      throw Exception('Logowanie przez Apple ID jest dostępne tylko na platformie iOS.');
    }

    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      UserCredential result = await _auth.signInWithCredential(oauthCredential);
      
      if (result.user != null) {
        await _createOrUpdateUserDocument(result.user!);
      }
      
      return result;
    } catch (e) {
      throw Exception('Błąd logowania przez Apple ID: $e');
    }
  }

  // log out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> _updateUserLastLogin(User user) async {
    try {
      await _firestoreService.updateUserLastLogin(user.uid);
    } catch (e) {
      print('Błąd podczas aktualizacji czasu ostatniego logowania w Firestore: $e');

      if (e.toString().contains('permission-denied')) {
        print('UWAGA: Sprawdź reguły bezpieczeństwa Firestore - użytkownik nie ma uprawnień do zapisu');
      }

    }
  }

  Future<void> _createUserDocument(User user) async {
    final userModel = UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoURL: user.photoURL,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
    
    try {
      await _firestoreService.createUser(userModel);
    } catch (e) {
      print('Błąd podczas tworzenia dokumentu użytkownika w Firestore: $e');

      if (e.toString().contains('permission-denied')) {
        print('UWAGA: Sprawdź reguły bezpieczeństwa Firestore - użytkownik nie ma uprawnień do zapisu');
      }

    }
  }

  Future<void> _createOrUpdateUserDocument(User user) async {
    final existingUser = await _firestoreService.getUser(user.uid);
    
    if (existingUser == null) {
      await _createUserDocument(user);
    } else {
      await _updateUserLastLogin(user);
    }
  }

  // firebase auth
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Nie znaleziono użytkownika z tym adresem email';
      case 'wrong-password':
        return 'Nieprawidłowe hasło';
      case 'email-already-in-use':
        return 'Konto z tym adresem email już istnieje';
      case 'weak-password':
        return 'Hasło jest za słabe';
      case 'invalid-email':
        return 'Nieprawidłowy adres email';
      case 'network-request-failed':
        return 'Błąd połączenia z internetem';
      default:
        return 'Wystąpił błąd: ${e.message}';
    }
  }
} 