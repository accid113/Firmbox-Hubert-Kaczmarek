import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/invoice.dart';
import '../services/firestore_service.dart';
import '../services/openai_service.dart';

class InvoiceProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final OpenAIService _openAIService = OpenAIService();
  final Uuid _uuid = const Uuid();

  Invoice? _currentInvoice;
  List<Invoice> _userInvoices = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDraftInvoice = false;


  Invoice? get currentInvoice => _currentInvoice;
  List<Invoice> get userInvoices => _userInvoices;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // invoice draft
  void startDraftInvoice(String userId) {
    try {
      print('Rozpoczynanie draft faktury dla użytkownika: $userId');
      
      final id = _uuid.v4();
      final now = DateTime.now();
      

      _currentInvoice = Invoice(
        id: id,
        userId: userId,
        invoiceNumber: '',
        issueDate: now,
        saleDate: now,
        sellerName: '',
        sellerAddress: '',
        sellerNip: '',
        buyerName: '',
        buyerAddress: '',
        buyerNip: '',
        items: [],
        createdAt: now,
        updatedAt: now,
      );


      _isDraftInvoice = true;

      print('Draft faktura utworzona z ID: $id (nie zapisana w bazie)');
      notifyListeners();
    } catch (e) {
      print('Błąd tworzenia draft faktury: $e');
      _setError('Błąd tworzenia faktury: $e');
    }
  }

  // final save
  Future<String> finalizeInvoice() async {
    try {
      if (_currentInvoice == null) {
        throw Exception('Brak draft faktury do finalizacji');
      }

      // checking if user is logged in
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Użytkownik nie jest zalogowany');
      }
      
      if (currentUser.uid != _currentInvoice!.userId) {
        throw Exception('Niezgodność userId');
      }
      
      print('Finalizacja faktury dla użytkownika: ${_currentInvoice!.userId}');
      
      // invoice generator (only if draft)
      String finalInvoiceNumber = _currentInvoice!.invoiceNumber;
      if (finalInvoiceNumber.isEmpty) {
        finalInvoiceNumber = await _generateInvoiceNumber(_currentInvoice!.userId);
        print('Wygenerowany numer faktury: $finalInvoiceNumber');
      } else {
        print('Używam numeru ustawionego przez użytkownika: $finalInvoiceNumber');
      }
      
      // update draft number
      _currentInvoice = _currentInvoice!.copyWith(
        invoiceNumber: finalInvoiceNumber,
        updatedAt: DateTime.now(),
      );

      print('Zapisywanie finalizowanej faktury do Firestore z ID: ${_currentInvoice!.id}');
      await _firestoreService.createInvoice(_currentInvoice!);
      print('Faktura zapisana pomyślnie do Firestore');
      
      // invoice is finalized
      _isDraftInvoice = false;
      
      notifyListeners();
      return _currentInvoice!.id;
    } catch (e) {
      print('Błąd finalizacji faktury: $e');
      _setError('Błąd finalizacji faktury: $e');
      rethrow;
    }
  }

  // new invoice
  Future<String> createNewInvoice(String userId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Użytkownik nie jest zalogowany');
      }
      
      if (currentUser.uid != userId) {
        throw Exception('Niezgodność userId: przekazany $userId, aktualny ${currentUser.uid}');
      }
      
      print('Tworzenie faktury dla użytkownika: $userId (${currentUser.email})');
      
      final id = _uuid.v4();
      final now = DateTime.now();
      
      // invoice number generator
      final invoiceNumber = await _generateInvoiceNumber(userId);
      print('Wygenerowany numer faktury: $invoiceNumber');
      
      _currentInvoice = Invoice(
        id: id,
        userId: userId,
        invoiceNumber: invoiceNumber,
        issueDate: now,
        saleDate: now,
        sellerName: '',
        sellerAddress: '',
        sellerNip: '',
        buyerName: '',
        buyerAddress: '',
        buyerNip: '',
        items: [],
        createdAt: now,
        updatedAt: now,
      );

      print('Zapisywanie faktury do Firestore z ID: $id');
      await _firestoreService.createInvoice(_currentInvoice!);
      print('Faktura zapisana pomyślnie do Firestore');
      
      // invoice is finalized
      _isDraftInvoice = false;
      
      notifyListeners();
      return id;
    } catch (e) {
      print('Błąd tworzenia faktury: $e');
      _setError('Błąd tworzenia faktury: $e');
      rethrow;
    }
  }


  Future<String> _generateInvoiceNumber(String userId) async {
    try {
      final invoices = await _firestoreService.getUserInvoices(userId);
      final now = DateTime.now();
      final currentMonth = now.month.toString().padLeft(2, '0'); // 06 dla czerwca
      final currentYear = now.year;
      
      // year and mont filter
      final currentMonthInvoices = invoices.where((invoice) => 
        invoice.issueDate.year == currentYear && 
        invoice.issueDate.month == now.month
      ).toList();

      int highestNumber = 0;
      for (final invoice in currentMonthInvoices) {
        try {
          final parts = invoice.invoiceNumber.split('/');
          if (parts.length >= 1) {
            final number = int.tryParse(parts[0]) ?? 0;
            if (number > highestNumber) {
              highestNumber = number;
            }
          }
        } catch (e) {
          print('Błąd parsowania numeru faktury ${invoice.invoiceNumber}: $e');
        }
      }
      
      final nextNumber = highestNumber + 1;
      final invoiceNumber = '$nextNumber/$currentMonth/$currentYear';
      
      print('Wygenerowany numer faktury: $invoiceNumber (najwyższy numer w miesiącu: $highestNumber)');
      return invoiceNumber;
    } catch (e) {
      print('Błąd generowania numeru faktury: $e');
      final now = DateTime.now();
      final currentMonth = now.month.toString().padLeft(2, '0');
      return '1/$currentMonth/${now.year}';
    }
  }


  Future<void> loadInvoice(String id) async {
    _setLoading(true);
    try {
      _currentInvoice = await _firestoreService.getInvoice(id);
      _isDraftInvoice = false;
      notifyListeners();
    } catch (e) {
      _setError('Błąd wczytywania faktury: $e');
    }
    _setLoading(false);
  }

  // seller data
  Future<bool> setSellerData({
    required String name,
    required String address,
    required String nip,
    required String invoiceNumber,
  }) async {
    if (_currentInvoice == null) return false;

    _setLoading(true);
    try {
      print('setSellerData - START');
      print('- Invoice ID: ${_currentInvoice!.id}');
      print('- User ID: ${_currentInvoice!.userId}');
      print('- Current invoice number: "${_currentInvoice!.invoiceNumber}"');
      print('- Przekazany numer: "$invoiceNumber"');
      print('- Is draft: $_isDraftInvoice');
      
      // profile logo
      final sellerProfile = await _firestoreService.getSellerProfile(_currentInvoice!.userId);
      final logoUrl = sellerProfile?.logoUrl;
      
      print('Pobieranie logo dla faktury:');
      print('- Profil sprzedawcy znaleziony: ${sellerProfile != null}');
      print('- Logo URL z profilu: $logoUrl');
      print('- Aktualne logo w fakturze: ${_currentInvoice!.sellerLogoUrl}');

      final finalLogoUrl = logoUrl ?? _currentInvoice!.sellerLogoUrl;
      print('- Finalne logo URL: $finalLogoUrl');


      _currentInvoice = _currentInvoice!.copyWith(
        sellerName: name,
        sellerAddress: address,
        sellerNip: nip,
        sellerLogoUrl: finalLogoUrl,
        invoiceNumber: invoiceNumber.isNotEmpty ? invoiceNumber : _currentInvoice!.invoiceNumber,
        updatedAt: DateTime.now(),
      );

      // firestore save
      if (!_isDraftInvoice) {
        await _firestoreService.updateInvoice(_currentInvoice!);
        print('setSellerData - Zapisano do Firestore (istniejąca faktura)');
      } else {
        print('setSellerData - Pominięto zapis do Firestore (draft z numerem)');
      }
      
      print('setSellerData - SUCCESS');
      print('- Zapisane logo: ${_currentInvoice!.sellerLogoUrl}');
      print('- Zapisany numer: ${_currentInvoice!.invoiceNumber}');
      
      notifyListeners();
      _setLoading(false);
      return true;
    } catch (e) {
      print('setSellerData - ERROR: $e');
      _setError('Błąd: $e');
      _setLoading(false);
      return false;
    }
  }

  // buyer data
  Future<bool> setBuyerData({
    required String name,
    required String address,
    required String nip,
  }) async {
    if (_currentInvoice == null) return false;

    _setLoading(true);
    try {
      print('setBuyerData - isDraft: $_isDraftInvoice');
      
      _currentInvoice = _currentInvoice!.copyWith(
        buyerName: name,
        buyerAddress: address,
        buyerNip: nip,
        updatedAt: DateTime.now(),
      );

      // firebase save
      if (!_isDraftInvoice) {
        await _firestoreService.updateInvoice(_currentInvoice!);
        print('setBuyerData - Zapisano do Firestore');
      } else {
        print('setBuyerData - Pominięto zapis do Firestore (draft)');
      }
      
      notifyListeners();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Błąd zapisywania danych nabywcy: $e');
      _setLoading(false);
      return false;
    }
  }

  // invoice date
  Future<bool> setDates({
    required DateTime issueDate,
    required DateTime saleDate,
    DateTime? paymentDate,
  }) async {
    if (_currentInvoice == null) return false;

    _setLoading(true);
    try {
      print('setDates - isDraft: $_isDraftInvoice');
      
      _currentInvoice = _currentInvoice!.copyWith(
        issueDate: issueDate,
        saleDate: saleDate,
        paymentDate: paymentDate,
        updatedAt: DateTime.now(),
      );

      // saving to firestore
      if (!_isDraftInvoice) {
        await _firestoreService.updateInvoice(_currentInvoice!);
        print('setDates - Zapisano do Firestore');
      } else {
        print('setDates - Pominięto zapis do Firestore (draft)');
      }
      
      notifyListeners();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Błąd zapisywania dat: $e');
      _setLoading(false);
      return false;
    }
  }

  // items
  Future<bool> addItem(InvoiceItem item) async {
    if (_currentInvoice == null) return false;

    _setLoading(true);
    try {
      print('addItem - isDraft: $_isDraftInvoice');
      
      final updatedItems = List<InvoiceItem>.from(_currentInvoice!.items);
      updatedItems.add(item);

      _currentInvoice = _currentInvoice!.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );

      if (!_isDraftInvoice) {
        await _firestoreService.updateInvoice(_currentInvoice!);
        print('addItem - Zapisano do Firestore');
      } else {
        print('addItem - Pominięto zapis do Firestore (draft)');
      }
      
      notifyListeners();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Błąd dodawania pozycji: $e');
      _setLoading(false);
      return false;
    }
  }

  // index
  Future<bool> removeItem(int index) async {
    if (_currentInvoice == null || index >= _currentInvoice!.items.length) return false;

    _setLoading(true);
    try {
      print('removeItem - isDraft: $_isDraftInvoice');
      
      final updatedItems = List<InvoiceItem>.from(_currentInvoice!.items);
      updatedItems.removeAt(index);

      _currentInvoice = _currentInvoice!.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );

      if (!_isDraftInvoice) {
        await _firestoreService.updateInvoice(_currentInvoice!);
        print('removeItem - Zapisano do Firestore');
      } else {
        print('removeItem - Pominięto zapis do Firestore (draft)');
      }
      
      notifyListeners();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Błąd usuwania pozycji: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateItem(int index, InvoiceItem item) async {
    if (_currentInvoice == null || index >= _currentInvoice!.items.length) return false;

    _setLoading(true);
    try {
      print('updateItem - isDraft: $_isDraftInvoice');
      
      final updatedItems = List<InvoiceItem>.from(_currentInvoice!.items);
      updatedItems[index] = item;

      _currentInvoice = _currentInvoice!.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );

      if (!_isDraftInvoice) {
        await _firestoreService.updateInvoice(_currentInvoice!);
        print('updateItem - Zapisano do Firestore');
      } else {
        print('updateItem - Pominięto zapis do Firestore (draft)');
      }
      
      notifyListeners();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Błąd aktualizacji pozycji: $e');
      _setLoading(false);
      return false;
    }
  }

  // payments
  Future<bool> setNotesAndPayment({
    String? notes,
    String? paymentMethod,
  }) async {
    if (_currentInvoice == null) return false;

    _setLoading(true);
    try {
      print('setNotesAndPayment - isDraft: $_isDraftInvoice');
      
      _currentInvoice = _currentInvoice!.copyWith(
        notes: notes,
        paymentMethod: paymentMethod,
        updatedAt: DateTime.now(),
      );

      if (!_isDraftInvoice) {
        await _firestoreService.updateInvoice(_currentInvoice!);
        print('setNotesAndPayment - Zapisano do Firestore');
      } else {
        print('setNotesAndPayment - Pominięto zapis do Firestore (draft)');
      }
      
      notifyListeners();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Błąd zapisywania uwag: $e');
      _setLoading(false);
      return false;
    }
  }

  // invoice pdf
  Future<bool> generateInvoicePDF() async {
    if (!_isInvoiceComplete()) {
      _setError('Faktura nie jest kompletna');
      return false;
    }

    _setLoading(true);
    try {
      final pdfUrl = await _openAIService.generateInvoicePDF(_currentInvoice!);

      _currentInvoice = _currentInvoice!.copyWith(
        pdfUrl: pdfUrl,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.updateInvoice(_currentInvoice!);
      notifyListeners();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Błąd generowania PDF: $e');
      _setLoading(false);
      return false;
    }
  }


  Future<void> loadUserInvoices(String userId) async {
    _setLoading(true);
    try {
      print('Ładowanie faktur dla użytkownika: $userId');
      _userInvoices = await _firestoreService.getUserInvoices(userId);
      print('Znaleziono ${_userInvoices.length} faktur');
      _userInvoices.forEach((invoice) {
        print('Faktura: ${invoice.invoiceNumber}, data: ${invoice.issueDate}');
      });
      notifyListeners();
    } catch (e) {
      print('Błąd pobierania faktur: $e');
      _setError('Błąd pobierania faktur: $e');
    }
    _setLoading(false);
  }


  bool _isInvoiceComplete() {
    return _currentInvoice != null &&
           _currentInvoice!.sellerName.isNotEmpty &&
           _currentInvoice!.sellerAddress.isNotEmpty &&
           _currentInvoice!.sellerNip.isNotEmpty &&
           _currentInvoice!.buyerName.isNotEmpty &&
           _currentInvoice!.buyerAddress.isNotEmpty &&
           _currentInvoice!.buyerNip.isNotEmpty &&
           _currentInvoice!.items.isNotEmpty;
  }

  void clearCurrentInvoice() {
    _currentInvoice = null;
    _isDraftInvoice = false;
    notifyListeners();
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