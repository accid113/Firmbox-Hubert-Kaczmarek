import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:universal_io/io.dart';
import '../models/seller_profile.dart';
import '../services/firestore_service.dart';

class SellerProfileProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  SellerProfile? _sellerProfile;
  bool _isLoading = false;
  String? _errorMessage;


  SellerProfile? get sellerProfile => _sellerProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // load seller profile
  Future<void> loadSellerProfile(String userId) async {
    _setLoading(true);
    try {
      _sellerProfile = await _firestoreService.getSellerProfile(userId);
      notifyListeners();
    } catch (e) {
      _setError('Błąd wczytywania profilu: $e');
    }
    _setLoading(false);
  }

  // saving seller profile
  Future<bool> saveSellerProfile({
    required String userId,
    required String name,
    required String address,
    required String nip,
    String? logoUrl,
  }) async {
    _setLoading(true);
    try {
      final now = DateTime.now();
      
      if (_sellerProfile == null) {
        // create new profile
        _sellerProfile = SellerProfile(
          userId: userId,
          name: name,
          address: address,
          nip: nip,
          logoUrl: logoUrl,
          createdAt: now,
          updatedAt: now,
        );
        await _firestoreService.saveSellerProfile(_sellerProfile!);
      } else {
        // upadte profile
        _sellerProfile = _sellerProfile!.copyWith(
          name: name,
          address: address,
          nip: nip,
          logoUrl: logoUrl,
          updatedAt: now,
        );
        await _firestoreService.updateSellerProfile(_sellerProfile!);
      }
      
      notifyListeners();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Błąd zapisywania profilu: $e');
      _setLoading(false);
      return false;
    }
  }

  // firestore logo upload
  Future<String?> uploadLogo(String userId, File logoFile) async {
    try {
      _setLoading(true);
      
      print('Upload logo - START');
      print('- User ID: $userId');
      print('- Plik: ${logoFile.path}');
      print('- Rozmiar: ${await logoFile.length()} bajtów');

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('seller_logos')
          .child(userId)
          .child('logo.jpg');
      
      print('- Ścieżka w Storage: ${storageRef.fullPath}');
      
      final uploadTask = storageRef.putFile(logoFile);

      // progress bar
      uploadTask.snapshotEvents.listen((event) {
        final progress = event.bytesTransferred / event.totalBytes;
        print('Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
      });
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('Upload logo - SUCCESS');
      print('- Download URL: $downloadUrl');
      
      _setLoading(false);
      return downloadUrl;
    } catch (e) {
      print('Upload logo - ERROR: $e');
      _setError('Błąd uploadu logo: $e');
      _setLoading(false);
      return null;
    }
  }

  // profile logo update
  Future<bool> updateLogo(String logoUrl) async {
    if (_sellerProfile == null) return false;
    
    try {
      _sellerProfile = _sellerProfile!.copyWith(
        logoUrl: logoUrl,
        updatedAt: DateTime.now(),
      );
      
      await _firestoreService.updateSellerProfile(_sellerProfile!);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Błąd aktualizacji logo: $e');
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
} 