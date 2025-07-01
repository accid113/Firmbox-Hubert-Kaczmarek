import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../providers/logo_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/step_progress_indicator.dart';

class LogoCompanyNameScreen extends StatefulWidget {
  const LogoCompanyNameScreen({super.key});

  @override
  State<LogoCompanyNameScreen> createState() => _LogoCompanyNameScreenState();
}

class _LogoCompanyNameScreenState extends State<LogoCompanyNameScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();

    _nameController.addListener(() {
      setState(() {
      });
    });
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
    _nameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _proceedToNext() async {
    if (!_formKey.currentState!.validate()) return;

    final logoProvider = Provider.of<LogoProvider>(context, listen: false);
    final companyName = _nameController.text.trim();
    
    final success = await logoProvider.setCompanyName(companyName);
    
    if (success && mounted) {
      Navigator.of(context).pushNamed('/logo-business-description');
    } else if (mounted) {
      _showErrorSnackBar(logoProvider.errorMessage ?? 'Błąd zapisywania nazwy');
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
    if (value.trim().length > 50) {
      return 'Nazwa nie może być dłuższa niż 50 znaków';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final logoProvider = Provider.of<LogoProvider>(context);
    
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
                            'Nazwa firmy',
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
                    activeColor: AppTheme.logoColor,
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
                            const SizedBox(height: 40),

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
                                        color: AppTheme.logoColor.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: AppTheme.logoColor.withOpacity(0.5),
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.business,
                                        size: 40,
                                        color: AppTheme.logoColor,
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
                                verticalOffset: 30,
                                child: FadeInAnimation(
                                  child: Text(
                                    'Jak nazywa się Twoja firma?',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // description
                            AnimationConfiguration.staggeredList(
                              position: 2,
                              child: SlideAnimation(
                                verticalOffset: 30,
                                child: FadeInAnimation(
                                  child: Text(
                                    'Wprowadź nazwę swojej firmy. Ta nazwa zostanie użyta do stworzenia logo dopasowanego do Twojej marki.',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: AppTheme.textSecondary,
                                      height: 1.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 40),

                            // text box
                            AnimationConfiguration.staggeredList(
                              position: 3,
                              child: SlideAnimation(
                                verticalOffset: 30,
                                child: FadeInAnimation(
                                  child: CustomTextField(
                                    controller: _nameController,
                                    label: 'Nazwa firmy',
                                    hint: 'np. TechnoSoft, EkoMarket, Creative Studio',
                                    prefixIcon: Icons.business,
                                    validator: _validateCompanyName,
                                    keyboardType: TextInputType.text,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            AnimationConfiguration.staggeredList(
                              position: 4,
                              child: SlideAnimation(
                                verticalOffset: 30,
                                child: FadeInAnimation(
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppTheme.logoColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppTheme.logoColor.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.lightbulb_outline,
                                              color: AppTheme.logoColor,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Wskazówki',
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                color: AppTheme.logoColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          '• Używaj pełnej nazwy firmy\n'
                                          '• Unikaj skrótów i akronimów\n'
                                          '• Nazwa powinna być czytelna i zapamiętywalna',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: AppTheme.textSecondary,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 50),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // button
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: AnimationConfiguration.staggeredList(
                      position: 5,
                      child: SlideAnimation(
                        verticalOffset: 30,
                        child: FadeInAnimation(
                          child: Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: logoProvider.isLoading || _nameController.text.trim().isEmpty
                                      ? null
                                      : _proceedToNext,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.logoColor,
                                    foregroundColor: AppTheme.textPrimary,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                  ),
                                  child: logoProvider.isLoading
                                      ? LoadingAnimationWidget.threeArchedCircle(
                                          color: AppTheme.logoColor,
                                          size: 24,
                                        )
                                      : const Text(
                                          'Dalej',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Krok 1 z 4',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textHint,
                                ),
                              ),
                            ],
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