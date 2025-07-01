import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:file_picker/file_picker.dart';
import 'package:universal_io/io.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../../providers/invoice_provider.dart';
import '../../providers/seller_profile_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../services/firestore_service.dart';

class InvoiceSellerDataScreen extends StatefulWidget {
  const InvoiceSellerDataScreen({super.key});

  @override
  State<InvoiceSellerDataScreen> createState() => _InvoiceSellerDataScreenState();
}

class _InvoiceSellerDataScreenState extends State<InvoiceSellerDataScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _nipController = TextEditingController();
  final _invoiceNumberController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  File? _selectedLogo;
  String? _currentLogoUrl;
  bool _isUploadingLogo = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingData();
    });
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
  }

  void _startAnimations() {
    _animationController.forward();
  }

  void _loadExistingData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final sellerProfileProvider = Provider.of<SellerProfileProvider>(context, listen: false);
    final invoiceProvider = Provider.of<InvoiceProvider>(context, listen: false);
    
    if (invoiceProvider.currentInvoice?.invoiceNumber.isEmpty ?? true) {
      final predictedNumber = await _generatePredictedInvoiceNumber();
      _invoiceNumberController.text = predictedNumber;
    } else {
      _invoiceNumberController.text = invoiceProvider.currentInvoice?.invoiceNumber ?? '';
    }

    final invoice = invoiceProvider.currentInvoice;
    if (invoice != null && invoice.sellerLogoUrl != null && invoice.sellerLogoUrl!.isNotEmpty) {
      _currentLogoUrl = invoice.sellerLogoUrl;
      setState(() {});
    }

    if (authProvider.user?.uid != null) {
      await sellerProfileProvider.loadSellerProfile(authProvider.user!.uid);
      
      final profile = sellerProfileProvider.sellerProfile;
      if (profile != null) {
        _nameController.text = profile.name;
        _addressController.text = profile.address;
        _nipController.text = profile.nip;
        
        if (_currentLogoUrl == null || _currentLogoUrl!.isEmpty) {
          _currentLogoUrl = profile.logoUrl;
        }
        setState(() {});
      }
    }

    if (invoice != null && _nameController.text.isEmpty) {
      _nameController.text = invoice.sellerName;
      _addressController.text = invoice.sellerAddress;
      _nipController.text = invoice.sellerNip;
    }
  }

  Future<String> _generatePredictedInvoiceNumber() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (authProvider.user?.uid != null) {
        final firestoreService = FirestoreService();
        final invoices = await firestoreService.getUserInvoices(authProvider.user!.uid);
        final now = DateTime.now();
        final currentMonth = now.month.toString().padLeft(2, '0');
        final currentYear = now.year;
        
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
        return '$nextNumber/$currentMonth/$currentYear';
      }
    } catch (e) {
      print('Błąd generowania przewidywanego numeru: $e');
    }
    
    final now = DateTime.now();
    final currentMonth = now.month.toString().padLeft(2, '0');
    return '1/$currentMonth/${now.year}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _nipController.dispose();
    _invoiceNumberController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectLogo() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedLogo = File(result.files.single.path!);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Błąd wybierania pliku: $e');
    }
  }

  Future<String?> _uploadLogo() async {
    if (_selectedLogo == null) return _currentLogoUrl;

    setState(() {
      _isUploadingLogo = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final sellerProfileProvider = Provider.of<SellerProfileProvider>(context, listen: false);
      
      final logoUrl = await sellerProfileProvider.uploadLogo(
        authProvider.user!.uid, 
        _selectedLogo!
      );

      setState(() {
        _isUploadingLogo = false;
        if (logoUrl != null) {
          _currentLogoUrl = logoUrl;
        }
      });

      return logoUrl;
    } catch (e) {
      setState(() {
        _isUploadingLogo = false;
      });
      _showErrorSnackBar('Błąd uploadu logo: $e');
      return _currentLogoUrl;
    }
  }

  Future<void> _proceedToNext() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final invoiceProvider = Provider.of<InvoiceProvider>(context, listen: false);
    final sellerProfileProvider = Provider.of<SellerProfileProvider>(context, listen: false);

    try {
      print('_proceedToNext - START');
      
      String? finalLogoUrl = _currentLogoUrl;
      if (_selectedLogo != null) {
        print('Uploading new logo...');
        finalLogoUrl = await _uploadLogo();
        print('Upload result: $finalLogoUrl');
      }

      print('Final logo URL to save: $finalLogoUrl');

      final profileSaved = await sellerProfileProvider.saveSellerProfile(
        userId: authProvider.user!.uid,
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        nip: _nipController.text.trim(),
        logoUrl: finalLogoUrl,
      );

      print('Profile saved: $profileSaved');

      if (!profileSaved) {
        _showErrorSnackBar('Błąd zapisywania profilu sprzedawcy');
        return;
      }

      await Future.delayed(const Duration(milliseconds: 500));

      final success = await invoiceProvider.setSellerData(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        nip: _nipController.text.trim(),
        invoiceNumber: _invoiceNumberController.text.trim(),
      );

      if (success && mounted) {
        print('Navigation to buyer data screen');
        Navigator.of(context).pushNamed('/invoice-buyer-data');
      } else if (mounted) {
        _showErrorSnackBar(invoiceProvider.errorMessage ?? 'Błąd zapisywania danych faktury');
      }
    } catch (e) {
      print('_proceedToNext - ERROR: $e');
      _showErrorSnackBar('Błąd zapisywania danych: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildLogoImage(String logoUrl) {
    if (kIsWeb) {
      final proxyUrl = 'https://corsproxy.io/?${Uri.encodeComponent(logoUrl)}';
      
      return FutureBuilder<http.Response>(
        future: http.get(Uri.parse(proxyUrl)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: LoadingAnimationWidget.threeArchedCircle(
                color: AppTheme.invoiceColor,
                size: 24,
              ),
            );
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.statusCode != 200) {
            return Image.network(
              logoUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.broken_image,
                  size: 50,
                  color: Colors.grey,
                );
              },
               loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: LoadingAnimationWidget.threeArchedCircle(
                      color: AppTheme.invoiceColor,
                      size: 24,
                    ),
                  );
                },
            );
          }

          final imageBytes = snapshot.data!.bodyBytes;
          return Image.memory(
            imageBytes,
            fit: BoxFit.contain,
          );
        },
      );
    } else {
      return Image.network(
        logoUrl,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: LoadingAnimationWidget.threeArchedCircle(
              color: AppTheme.invoiceColor,
              size: 24,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.broken_image,
            size: 50,
            color: Colors.grey,
          );
        },
      );
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Wprowadź nazwę sprzedawcy';
    }
    if (value.trim().length < 2) {
      return 'Nazwa musi mieć co najmniej 2 znaki';
    }
    return null;
  }

  String? _validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Wprowadź adres sprzedawcy';
    }
    if (value.trim().length < 5) {
      return 'Adres musi mieć co najmniej 5 znaków';
    }
    return null;
  }

  String? _validateNip(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Wprowadź NIP sprzedawcy';
    }
    
    final nipNumbers = value.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (nipNumbers.length != 10) {
      return 'NIP musi mieć 10 cyfr';
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Dane sprzedawcy',
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),

                  // Progress indicator
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppTheme.invoiceColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // main
                  Expanded(
                    child: AnimationLimiter(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              const SizedBox(height: 20),

                              // icon
                              AnimationConfiguration.staggeredList(
                                position: 0,
                                child: SlideAnimation(
                                  verticalOffset: 30,
                                  child: FadeInAnimation(
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: AppTheme.cardColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: AppTheme.invoiceColor.withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.image_outlined,
                                                color: AppTheme.invoiceColor,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Logo firmy',
                                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  color: AppTheme.textPrimary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          
                                          // logo
                                          Container(
                                            height: 120,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.grey.withOpacity(0.3),
                                                style: BorderStyle.solid,
                                              ),
                                            ),
                                            child: _selectedLogo != null
                                              ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(12),
                                                  child: Image.file(
                                                    _selectedLogo!,
                                                    fit: BoxFit.contain,
                                                  ),
                                                )
                                              : _currentLogoUrl != null
                                                ? ClipRRect(
                                                    borderRadius: BorderRadius.circular(12),
                                                    child: _buildLogoImage(_currentLogoUrl!),
                                                  )
                                                : Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(
                                                        Icons.add_photo_alternate_outlined,
                                                        size: 40,
                                                        color: Colors.grey,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        'Dodaj logo firmy',
                                                        style: TextStyle(
                                                          color: Colors.grey,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                          ),
                                          
                                          const SizedBox(height: 16),
                                          
                                          ElevatedButton.icon(
                                            onPressed: _isUploadingLogo ? null : _selectLogo,
                                            icon: _isUploadingLogo
                                              ? LoadingAnimationWidget.threeArchedCircle(
                                                  color: AppTheme.textPrimary,
                                                  size: 16,
                                                )
                                              : Icon(Icons.upload),
                                            label: Text(_isUploadingLogo ? 'Uploading...' : 'Wybierz logo'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.invoiceColor,
                                              foregroundColor: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // icon
                              AnimationConfiguration.staggeredList(
                                position: 1,
                                child: SlideAnimation(
                                  verticalOffset: 30,
                                  child: FadeInAnimation(
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: AppTheme.invoiceColor.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Icon(
                                        Icons.business,
                                        size: 40,
                                        color: AppTheme.invoiceColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 32),

                              // title
                              AnimationConfiguration.staggeredList(
                                position: 2,
                                child: SlideAnimation(
                                  verticalOffset: 30,
                                  child: FadeInAnimation(
                                    child: Column(
                                      children: [
                                        Text(
                                          'Dane sprzedawcy',
                                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                            color: AppTheme.textPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        
                                        const SizedBox(height: 12),
                                        
                                        Text(
                                          'Wprowadź dane Twojej firmy które pojawią się na fakturze',
                                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            color: AppTheme.textSecondary,
                                            height: 1.4,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 40),

                              // form
                              AnimationConfiguration.staggeredList(
                                position: 3,
                                child: SlideAnimation(
                                  verticalOffset: 30,
                                  child: FadeInAnimation(
                                    child: Column(
                                      children: [
                                        CustomTextField(
                                          controller: _nameController,
                                          label: 'Nazwa firmy',
                                          hint: 'np. Moja Firma Sp. z o.o.',
                                          validator: _validateName,
                                          prefixIcon: Icons.business,
                                        ),
                                        
                                        const SizedBox(height: 20),

                                        // Pole numeru faktury - zawsze edytowalne
                                        CustomTextField(
                                          controller: _invoiceNumberController,
                                          label: 'Numer faktury',
                                          hint: 'np. 1/06/2025',
                                          validator: (value) {
                                            if (value == null || value.trim().isEmpty) {
                                              return 'Wprowadź numer faktury';
                                            }
                                            return null;
                                          },
                                          prefixIcon: Icons.tag,
                                        ),

                                        const SizedBox(height: 20),
                                        
                                        CustomTextField(
                                          controller: _addressController,
                                          label: 'Adres firmy',
                                          hint: 'ul. Firmowa 123, 00-001 Warszawa',
                                          validator: _validateAddress,
                                          prefixIcon: Icons.location_on,
                                          maxLines: 3,
                                        ),
                                        
                                        const SizedBox(height: 20),
                                        
                                        CustomTextField(
                                          controller: _nipController,
                                          label: 'NIP',
                                          hint: '1234567890',
                                          validator: _validateNip,
                                          prefixIcon: Icons.receipt_long,
                                          keyboardType: TextInputType.number,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 40),

                              AnimationConfiguration.staggeredList(
                                position: 4,
                                child: SlideAnimation(
                                  verticalOffset: 30,
                                  child: FadeInAnimation(
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppTheme.invoiceColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppTheme.invoiceColor.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            color: AppTheme.invoiceColor,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'Wprowadź poprawny 10-cyfrowy NIP zgodny z danymi Twojej firmy.',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 60),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: AnimationConfiguration.staggeredList(
                      position: 5,
                      child: SlideAnimation(
                        verticalOffset: 50,
                        child: FadeInAnimation(
                          child: Consumer<InvoiceProvider>(
                            builder: (context, invoiceProvider, child) {
                              return SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton.icon(
                                  onPressed: (invoiceProvider.isLoading || _isUploadingLogo) ? null : _proceedToNext,
                                  icon: (invoiceProvider.isLoading || _isUploadingLogo)
                                    ? LoadingAnimationWidget.threeArchedCircle(
                                        color: AppTheme.textPrimary,
                                        size: 20,
                                      )
                                    : const Icon(
                                        Icons.arrow_forward_rounded,
                                        color: AppTheme.textPrimary,
                                      ),
                                  label: Text(
                                    (invoiceProvider.isLoading || _isUploadingLogo) ? 'Zapisywanie...' : 'Dalej',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.invoiceColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 