import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../providers/invoice_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_text_field.dart';

class InvoiceBuyerDataScreen extends StatefulWidget {
  const InvoiceBuyerDataScreen({super.key});

  @override
  State<InvoiceBuyerDataScreen> createState() => _InvoiceBuyerDataScreenState();
}

class _InvoiceBuyerDataScreenState extends State<InvoiceBuyerDataScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _nipController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
    _loadExistingData();
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

  void _loadExistingData() {
    final invoiceProvider = Provider.of<InvoiceProvider>(context, listen: false);
    final invoice = invoiceProvider.currentInvoice;
    
    if (invoice != null) {
      _nameController.text = invoice.buyerName;
      _addressController.text = invoice.buyerAddress;
      _nipController.text = invoice.buyerNip;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _nipController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _proceedToNext() async {
    if (!_formKey.currentState!.validate()) return;

    final invoiceProvider = Provider.of<InvoiceProvider>(context, listen: false);
    
    final success = await invoiceProvider.setBuyerData(
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      nip: _nipController.text.trim(),
    );
    
    if (success && mounted) {
      Navigator.of(context).pushNamed('/invoice-items');
    } else if (mounted) {
      _showErrorSnackBar(invoiceProvider.errorMessage ?? 'Błąd zapisywania danych');
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

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Wprowadź nazwę nabywcy';
    }
    if (value.trim().length < 2) {
      return 'Nazwa musi mieć co najmniej 2 znaki';
    }
    return null;
  }

  String? _validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Wprowadź adres nabywcy';
    }
    if (value.trim().length < 5) {
      return 'Adres musi mieć co najmniej 5 znaków';
    }
    return null;
  }

  String? _validateNip(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Wprowadź NIP nabywcy';
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
                  // header
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
                            'Dane nabywcy',
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),

                  // progress indicator
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
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: AppTheme.invoiceColor.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Icon(
                                        Icons.person_outline,
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
                                position: 1,
                                child: SlideAnimation(
                                  verticalOffset: 30,
                                  child: FadeInAnimation(
                                    child: Column(
                                      children: [
                                        Text(
                                          'Dane nabywcy',
                                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                            color: AppTheme.textPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        
                                        const SizedBox(height: 12),
                                        
                                        Text(
                                          'Wprowadź dane klienta który otrzyma fakturę',
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
                                position: 2,
                                child: SlideAnimation(
                                  verticalOffset: 30,
                                  child: FadeInAnimation(
                                    child: Column(
                                      children: [
                                        CustomTextField(
                                          controller: _nameController,
                                          label: 'Nazwa/Imię i nazwisko',
                                          hint: 'np. Jan Kowalski lub Firma ABC Sp. z o.o.',
                                          validator: _validateName,
                                          prefixIcon: Icons.person,
                                        ),
                                        
                                        const SizedBox(height: 20),
                                        
                                        CustomTextField(
                                          controller: _addressController,
                                          label: 'Adres',
                                          hint: 'ul. Klienta 456, 01-234 Kraków',
                                          validator: _validateAddress,
                                          prefixIcon: Icons.location_on,
                                          maxLines: 3,
                                        ),
                                        
                                        const SizedBox(height: 20),
                                        
                                        CustomTextField(
                                          controller: _nipController,
                                          label: 'NIP',
                                          hint: '9876543210',
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
                                position: 3,
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
                                              'Wprowadź poprawny 10-cyfrowy NIP nabywcy zgodny z danymi firmy.',
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
                      position: 4,
                      child: SlideAnimation(
                        verticalOffset: 50,
                        child: FadeInAnimation(
                          child: Consumer<InvoiceProvider>(
                            builder: (context, invoiceProvider, child) {
                              return SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton.icon(
                                  onPressed: invoiceProvider.isLoading ? null : _proceedToNext,
                                  icon: invoiceProvider.isLoading
                                    ? LoadingAnimationWidget.threeArchedCircle(
                                        color: AppTheme.textPrimary,
                                        size: 20,
                                      )
                                    : const Icon(
                                        Icons.arrow_forward_rounded,
                                        color: AppTheme.textPrimary,
                                      ),
                                  label: Text(
                                    invoiceProvider.isLoading ? 'Zapisywanie...' : 'Dalej',
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