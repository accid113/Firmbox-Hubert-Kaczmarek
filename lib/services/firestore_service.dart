import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'dart:convert';
import '../models/user_model.dart';
import '../models/business_idea.dart';
import '../models/logo_design.dart';
import '../models/website_design.dart';
import '../models/invoice.dart';
import '../models/seller_profile.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kolekcje
  static const String usersCollection = 'users';
  static const String businessIdeasCollection = 'business_ideas';
  static const String logoDesignsCollection = 'logo_designs';
  static const String websiteDesignsCollection = 'website_designs';
  static const String invoicesCollection = 'invoices';
  static const String sellerProfilesCollection = 'seller_profiles';

  // === OPERACJE NA UŻYTKOWNIKACH ===

  // Tworzenie nowego użytkownika
  Future<void> createUser(UserModel user) async {
    await _firestore
        .collection(usersCollection)
        .doc(user.uid)
        .set(user.toMap())
        .timeout(const Duration(seconds: 10));
  }

  // Pobieranie użytkownika
  Future<UserModel?> getUser(String uid) async {
    DocumentSnapshot doc = await _firestore.collection(usersCollection).doc(uid).get();
    
    if (doc.exists) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  // Aktualizacja czasu ostatniego logowania
  Future<void> updateUserLastLogin(String uid) async {
    await _firestore
        .collection(usersCollection)
        .doc(uid)
        .update({
          'lastLoginAt': DateTime.now().toIso8601String(),
        })
        .timeout(const Duration(seconds: 10));
  }

  // === OPERACJE NA POMYSŁACH BIZNESOWYCH ===

  // Tworzenie nowego pomysłu biznesowego
  Future<void> createBusinessIdea(BusinessIdea businessIdea) async {
    await _firestore
        .collection(businessIdeasCollection)
        .doc(businessIdea.id)
        .set(businessIdea.toMap());
  }

  // Pobieranie pomysłu biznesowego
  Future<BusinessIdea?> getBusinessIdea(String id) async {
    DocumentSnapshot doc = await _firestore
        .collection(businessIdeasCollection)
        .doc(id)
        .get();
    
    if (doc.exists) {
      return BusinessIdea.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  // Aktualizacja pomysłu biznesowego
  Future<void> updateBusinessIdea(BusinessIdea businessIdea) async {
    await _firestore
        .collection(businessIdeasCollection)
        .doc(businessIdea.id)
        .update(businessIdea.copyWith(updatedAt: DateTime.now()).toMap());
  }

  // Częściowa aktualizacja pomysłu biznesowego
  Future<void> updateBusinessIdeaField(String id, String field, String value) async {
    await _firestore
        .collection(businessIdeasCollection)
        .doc(id)
        .update({
      field: value,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // Pobieranie wszystkich pomysłów biznesowych użytkownika
  Future<List<BusinessIdea>> getUserBusinessIdeas(String userId) async {
    QuerySnapshot query = await _firestore
        .collection(businessIdeasCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs
        .map((doc) => BusinessIdea.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Usuwanie pomysłu biznesowego
  Future<void> deleteBusinessIdea(String id) async {
    await _firestore.collection(businessIdeasCollection).doc(id).delete();
  }

  // Stream pomysłów biznesowych użytkownika (realtime)
  Stream<List<BusinessIdea>> getUserBusinessIdeasStream(String userId) {
    return _firestore
        .collection(businessIdeasCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BusinessIdea.fromMap(doc.data()))
            .toList());
  }

  // === OPERACJE NA PROJEKTACH LOGO ===

  // Tworzenie nowego projektu logo
  Future<void> createLogoDesign(LogoDesign logoDesign) async {
    await _firestore
        .collection(logoDesignsCollection)
        .doc(logoDesign.id)
        .set(logoDesign.toMap());
  }

  // Pobieranie projektu logo
  Future<LogoDesign?> getLogoDesign(String id) async {
    DocumentSnapshot doc = await _firestore
        .collection(logoDesignsCollection)
        .doc(id)
        .get();
    
    if (doc.exists) {
      return LogoDesign.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  // Aktualizacja projektu logo
  Future<void> updateLogoDesign(LogoDesign logoDesign) async {
    await _firestore
        .collection(logoDesignsCollection)
        .doc(logoDesign.id)
        .update(logoDesign.copyWith(updatedAt: DateTime.now()).toMap());
  }

  // Częściowa aktualizacja projektu logo (pojedyncze pole)
  Future<void> updateLogoDesignField(String id, String field, dynamic value) async {
    await _firestore
        .collection(logoDesignsCollection)
        .doc(id)
        .update({
      field: value,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // Częściowa aktualizacja projektu logo (wiele pól)
  Future<void> updateLogoDesignFields(String id, Map<String, dynamic> fields) async {
    final updateData = Map<String, dynamic>.from(fields);
    updateData['updatedAt'] = DateTime.now().toIso8601String();
    
    await _firestore
        .collection(logoDesignsCollection)
        .doc(id)
        .update(updateData);
  }

  // Pobieranie wszystkich projektów logo użytkownika
  Future<List<LogoDesign>> getUserLogoDesigns(String userId) async {
    QuerySnapshot query = await _firestore
        .collection(logoDesignsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs
        .map((doc) => LogoDesign.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Usuwanie projektu logo
  Future<void> deleteLogoDesign(String id) async {
    await _firestore.collection(logoDesignsCollection).doc(id).delete();
  }

  // Stream projektów logo użytkownika (realtime)
  Stream<List<LogoDesign>> getUserLogoDesignsStream(String userId) {
    return _firestore
        .collection(logoDesignsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LogoDesign.fromMap(doc.data()))
            .toList());
  }

  // === OPERACJE NA PROJEKTACH STRON WWW ===

  // Tworzenie nowego projektu strony WWW
  Future<void> createWebsiteDesign(WebsiteDesign websiteDesign) async {
    await _firestore
        .collection(websiteDesignsCollection)
        .doc(websiteDesign.id)
        .set(websiteDesign.toMap());
  }

  // Pobieranie projektu strony WWW
  Future<WebsiteDesign?> getWebsiteDesign(String id) async {
    DocumentSnapshot doc = await _firestore
        .collection(websiteDesignsCollection)
        .doc(id)
        .get();
    
    if (doc.exists) {
      return WebsiteDesign.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  // Aktualizacja projektu strony WWW
  Future<void> updateWebsiteDesign(WebsiteDesign websiteDesign) async {
    await _firestore
        .collection(websiteDesignsCollection)
        .doc(websiteDesign.id)
        .update(websiteDesign.copyWith(updatedAt: DateTime.now()).toMap());
  }

  // Częściowa aktualizacja projektu strony WWW (pojedyncze pole)
  Future<void> updateWebsiteDesignField(String id, String field, dynamic value) async {
    await _firestore
        .collection(websiteDesignsCollection)
        .doc(id)
        .update({
      field: value,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // Częściowa aktualizacja projektu strony WWW (wiele pól)
  Future<void> updateWebsiteDesignFields(String id, Map<String, dynamic> fields) async {
    final updateData = Map<String, dynamic>.from(fields);
    updateData['updatedAt'] = DateTime.now().toIso8601String();
    
    await _firestore
        .collection(websiteDesignsCollection)
        .doc(id)
        .update(updateData);
  }

  // Pobieranie wszystkich projektów stron WWW użytkownika
  Future<List<WebsiteDesign>> getUserWebsiteDesigns(String userId) async {
    QuerySnapshot query = await _firestore
        .collection(websiteDesignsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs
        .map((doc) => WebsiteDesign.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Usuwanie projektu strony WWW
  Future<void> deleteWebsiteDesign(String id) async {
    await _firestore.collection(websiteDesignsCollection).doc(id).delete();
  }

  // Stream projektów stron WWW użytkownika (realtime)
  Stream<List<WebsiteDesign>> getUserWebsiteDesignsStream(String userId) {
    return _firestore
        .collection(websiteDesignsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WebsiteDesign.fromMap(doc.data()))
            .toList());
  }

  // === OPERACJE NA FAKTURACH ===

  // Tworzenie nowej faktury
  Future<void> createInvoice(Invoice invoice) async {
    await _firestore
        .collection(invoicesCollection)
        .doc(invoice.id)
        .set(invoice.toMap());
  }

  // Pobieranie faktury
  Future<Invoice?> getInvoice(String id) async {
    DocumentSnapshot doc = await _firestore
        .collection(invoicesCollection)
        .doc(id)
        .get();
    
    if (doc.exists) {
      return Invoice.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  // Aktualizacja faktury
  Future<void> updateInvoice(Invoice invoice) async {
    await _firestore
        .collection(invoicesCollection)
        .doc(invoice.id)
        .update(invoice.copyWith(updatedAt: DateTime.now()).toMap());
  }

  // Częściowa aktualizacja faktury
  Future<void> updateInvoiceField(String id, String field, dynamic value) async {
    await _firestore
        .collection(invoicesCollection)
        .doc(id)
        .update({
      field: value,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // Pobieranie wszystkich faktur użytkownika
  Future<List<Invoice>> getUserInvoices(String userId) async {
    QuerySnapshot query = await _firestore
        .collection(invoicesCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs
        .map((doc) => Invoice.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Usuwanie faktury
  Future<void> deleteInvoice(String id) async {
    await _firestore.collection(invoicesCollection).doc(id).delete();
  }

  // Stream faktur użytkownika (realtime)
  Stream<List<Invoice>> getUserInvoicesStream(String userId) {
    return _firestore
        .collection(invoicesCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Invoice.fromMap(doc.data()))
            .toList());
  }

  // === OPERACJE NA PROFILACH SPRZEDAWCY ===

  // Tworzenie/aktualizacja profilu sprzedawcy
  Future<void> saveSellerProfile(SellerProfile profile) async {
    await _firestore
        .collection(sellerProfilesCollection)
        .doc(profile.userId)
        .set(profile.toMap());
  }

  // Pobieranie profilu sprzedawcy
  Future<SellerProfile?> getSellerProfile(String userId) async {
    DocumentSnapshot doc = await _firestore
        .collection(sellerProfilesCollection)
        .doc(userId)
        .get();
    
    if (doc.exists) {
      return SellerProfile.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  // Aktualizacja profilu sprzedawcy
  Future<void> updateSellerProfile(SellerProfile profile) async {
    await _firestore
        .collection(sellerProfilesCollection)
        .doc(profile.userId)
        .update(profile.copyWith(updatedAt: DateTime.now()).toMap());
  }

  // === OPERACJE NA PLIKACH (FIREBASE STORAGE) ===

  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Upload pliku HTML do podglądu strony internetowej
  Future<String?> uploadWebsitePreview(String htmlContent, String userId) async {
    try {
      // Generuj unikalną nazwę pliku
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'website_preview_${userId}_$timestamp.html';
      final path = 'website_previews/$fileName';
      
      // Konwertuj HTML na bytes
      final bytes = Uint8List.fromList(utf8.encode(htmlContent));
      
      // Upload do Firebase Storage
      final ref = _storage.ref().child(path);
      final uploadTask = await ref.putData(
        bytes,
        SettableMetadata(
          contentType: 'text/html',
          customMetadata: {
            'userId': userId,
            'createdAt': DateTime.now().toIso8601String(),
            'expiresAt': DateTime.now().add(const Duration(minutes: 15)).toIso8601String(),
          },
        ),
      );
      
      // Pobierz publiczny URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      // Zaplanuj automatyczne usunięcie po 15 minutach
      _scheduleFileDeletion(path, const Duration(minutes: 15));
      
      return downloadUrl;
    } catch (e) {
      print('Błąd podczas uploadowania pliku HTML: $e');
      return null;
    }
  }
  
  // Zaplanuj automatyczne usunięcie pliku
  void _scheduleFileDeletion(String path, Duration delay) {
    Future.delayed(delay, () async {
      try {
        await _storage.ref().child(path).delete();
        print('Plik usunięty automatycznie: $path');
      } catch (e) {
        print('Błąd podczas automatycznego usuwania pliku: $e');
      }
    });
  }
  
  // Ręczne usunięcie pliku podglądu
  Future<bool> deleteWebsitePreview(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
      return true;
    } catch (e) {
      print('Błąd podczas usuwania pliku podglądu: $e');
      return false;
    }
  }
  
  // Czyszczenie starych plików podglądu (opcjonalne - można wywołać w tle)
  Future<void> cleanupExpiredPreviews() async {
    try {
      final now = DateTime.now();
      final previewsRef = _storage.ref().child('website_previews');
      final listResult = await previewsRef.listAll();
      
      for (final item in listResult.items) {
        try {
          final metadata = await item.getMetadata();
          final expiresAtStr = metadata.customMetadata?['expiresAt'];
          
          if (expiresAtStr != null) {
            final expiresAt = DateTime.parse(expiresAtStr);
            if (now.isAfter(expiresAt)) {
              await item.delete();
              print('Usunięto wygasły plik: ${item.name}');
            }
          }
        } catch (e) {
          print('Błąd podczas sprawdzania pliku ${item.name}: $e');
        }
      }
    } catch (e) {
      print('Błąd podczas czyszczenia wygasłych plików: $e');
    }
  }
} 