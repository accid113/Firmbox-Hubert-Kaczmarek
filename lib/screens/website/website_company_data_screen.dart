import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../providers/website_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/step_progress_indicator.dart';

class WebsiteCompanyDataScreen extends StatefulWidget {
  const WebsiteCompanyDataScreen({super.key});

  @override
  State<WebsiteCompanyDataScreen> createState() => _WebsiteCompanyDataScreenState();
}

class _WebsiteCompanyDataScreenState extends State<WebsiteCompanyDataScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _nipController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _additionalInfoController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();

    _companyNameController.addListener(() => setState(() {}));
    _descriptionController.addListener(() => setState(() {}));
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
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

  @override
  void dispose() {
    _companyNameController.dispose();
    _nipController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _additionalInfoController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _proceedToNext() async {
    if (!_formKey.currentState!.validate()) return;

    final websiteProvider = Provider.of<WebsiteProvider>(context, listen: false);
    
    final success = await websiteProvider.setCompanyData(
      companyName: _companyNameController.text.trim(),
      nipNumber: _nipController.text.trim().isNotEmpty ? _nipController.text.trim() : null,
      address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
      phoneNumber: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      businessDescription: _descriptionController.text.trim(),
      additionalInfo: _additionalInfoController.text.trim().isNotEmpty ? _additionalInfoController.text.trim() : null,
    );
    
    if (success && mounted) {
      Navigator.of(context).pushNamed('/website-sections');
    } else if (mounted) {
      _showErrorSnackBar(websiteProvider.errorMessage ?? 'Błąd zapisywania danych');
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

  String? _validateCompanyName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Wprowadź nazwę firmy';
    }
    if (value.trim().length < 2) {
      return 'Nazwa musi mieć co najmniej 2 znaki';
    }
    if (value.trim().length > 100) {
      return 'Nazwa nie może być dłuższa niż 100 znaków';
    }
    return null;
  }

  String? _validateNip(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    
    final nip = value.trim().replaceAll('-', '').replaceAll(' ', '');
    if (nip.length != 10) {
      return 'NIP musi mieć 10 cyfr';
    }
    if (!RegExp(r'^\d+$').hasMatch(nip)) {
      return 'NIP może zawierać tylko cyfry';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    
    final phone = value.trim().replaceAll(' ', '').replaceAll('-', '');
    if (phone.length < 9) {
      return 'Numer telefonu jest za krótki';
    }
    return null;
  }

  String? _validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Wprowadź opis działalności firmy';
    }
    if (value.trim().length < 10) {
      return 'Opis musi mieć co najmniej 10 znaków';
    }
    if (value.trim().length > 500) {
      return 'Opis nie może być dłuższy niż 500 znaków';
    }
    return null;
  }

  bool get _canProceed {
    return _companyNameController.text.trim().isNotEmpty &&
           _descriptionController.text.trim().isNotEmpty &&
           _formKey.currentState?.validate() == true;
  }

  @override
  Widget build(BuildContext context) {
    final websiteProvider = Provider.of<WebsiteProvider>(context);
    
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
                            'Dane firmy',
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),

                  // progress bar
                  StepProgressIndicator(
                    totalSteps: 4,
                    currentStep: 1,
                    activeColor: AppTheme.websiteColor,
                  ),

                  // main
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),

                            // icon
                            AnimationConfiguration.staggeredList(
                              position: 0,
                              child: SlideAnimation(
                                verticalOffset: 30,
                                child: FadeInAnimation(
                                  child: Center(
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: AppTheme.websiteColor.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: AppTheme.websiteColor.withOpacity(0.5),
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.business,
                                        size: 40,
                                        color: AppTheme.websiteColor,
                                      ),
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
                                verticalOffset: 20,
                                child: FadeInAnimation(
                                  child: Text(
                                    'Wprowadź podstawowe informacje o swojej firmie',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),

                            // form
                            AnimationConfiguration.staggeredList(
                              position: 2,
                              child: SlideAnimation(
                                verticalOffset: 20,
                                child: FadeInAnimation(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildFieldLabel('Nazwa firmy', true),
                                      CustomTextField(
                                        controller: _companyNameController,
                                        label: 'Nazwa firmy',
                                        hint: 'np. FirmBox Sp. z o.o.',
                                        validator: _validateCompanyName,
                                        prefixIcon: Icons.business_outlined,
                                      ),
                                      
                                      const SizedBox(height: 20),

                                      _buildFieldLabel('Numer NIP', false),
                                      CustomTextField(
                                        controller: _nipController,
                                        label: 'Numer NIP',
                                        hint: 'np. 123-456-78-90',
                                        validator: _validateNip,
                                        prefixIcon: Icons.numbers_outlined,
                                        keyboardType: TextInputType.number,
                                      ),
                                      
                                      const SizedBox(height: 20),

                                      _buildFieldLabel('Adres firmy', false),
                                      CustomTextField(
                                        controller: _addressController,
                                        label: 'Adres firmy',
                                        hint: 'np. ul. Przykładowa 123, 00-000 Warszawa',
                                        prefixIcon: Icons.location_on_outlined,
                                        maxLines: 2,
                                      ),
                                      
                                      const SizedBox(height: 20),

                                      _buildFieldLabel('Numer telefonu', false),
                                      CustomTextField(
                                        controller: _phoneController,
                                        label: 'Numer telefonu',
                                        hint: 'np. +48 123 456 789',
                                        validator: _validatePhone,
                                        prefixIcon: Icons.phone_outlined,
                                        keyboardType: TextInputType.phone,
                                      ),
                                      
                                      const SizedBox(height: 20),

                                      _buildFieldLabel('Krótki opis działalności firmy', true),
                                      CustomTextField(
                                        controller: _descriptionController,
                                        label: 'Opis działalności',
                                        hint: 'Opisz czym zajmuje się Twoja firma...',
                                        validator: _validateDescription,
                                        prefixIcon: Icons.description_outlined,
                                        maxLines: 4,
                                      ),
                                      
                                      const SizedBox(height: 20),

                                      _buildFieldLabel('Dodatkowe informacje o firmie', false),
                                      CustomTextField(
                                        controller: _additionalInfoController,
                                        label: 'Dodatkowe informacje',
                                        hint: 'Dodatkowe informacje, które chcesz umieścić na stronie...',
                                        prefixIcon: Icons.info_outlined,
                                        maxLines: 3,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // button
                  AnimationConfiguration.staggeredList(
                    position: 3,
                    child: SlideAnimation(
                      verticalOffset: 30,
                      child: FadeInAnimation(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: websiteProvider.isLoading || !_canProceed ? null : _proceedToNext,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.websiteColor,
                                disabledBackgroundColor: AppTheme.accentColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 8,
                              ),
                              child: websiteProvider.isLoading
                                  ? LoadingAnimationWidget.threeArchedCircle(
                                      color: AppTheme.websiteColor,
                                      size: 24,
                                    )
                                  : const Text(
                                      'Dalej',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
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

  Widget _buildFieldLabel(String label, bool isRequired) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (isRequired) ...[
            const SizedBox(width: 4),
            const Text(
              '*',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
} 