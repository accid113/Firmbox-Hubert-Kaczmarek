import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../providers/auth_provider.dart';
import '../../providers/logo_provider.dart';
import '../../utils/app_theme.dart';

class LogoIntroScreen extends StatefulWidget {
  const LogoIntroScreen({super.key});

  @override
  State<LogoIntroScreen> createState() => _LogoIntroScreenState();
}

class _LogoIntroScreenState extends State<LogoIntroScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _startLogoCreation() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final logoProvider = Provider.of<LogoProvider>(context, listen: false);

    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Błąd: Brak zalogowanego użytkownika'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await logoProvider.createNewLogoDesign(authProvider.user!.uid);

      if (mounted) {
        Navigator.of(context).pushNamed('/logo-company-name');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd tworzenia projektu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                            'Kreator Logo',
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 48), // Balans dla przycisku wstecz
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // main
                  Expanded(
                    child: AnimationLimiter(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // icon
                            AnimationConfiguration.staggeredList(
                              position: 0,
                              child: SlideAnimation(
                                verticalOffset: 50,
                                child: FadeInAnimation(
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          AppTheme.logoColor,
                                          AppTheme.logoColor.withOpacity(0.7),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(25),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.logoColor.withOpacity(0.4),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.palette_outlined,
                                      size: 50,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // header
                            AnimationConfiguration.staggeredList(
                              position: 1,
                              child: SlideAnimation(
                                verticalOffset: 30,
                                child: FadeInAnimation(
                                  child: Text(
                                    'Kreator Logo',
                                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                      fontSize: 32,
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
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: AppTheme.cardColor.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: AppTheme.logoColor.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          'Stwórz unikalne logo dla swojej firmy',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: AppTheme.textPrimary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Przejdziemy przez proces projektowania razem.',
                                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            color: AppTheme.textSecondary,
                                            height: 1.5,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 16),

                                        Column(
                                          children: [
                                            _buildStep(
                                              context,
                                              '1',
                                              'Nazwa firmy',
                                              'Wprowadź nazwę Twojej firmy',
                                            ),
                                            const SizedBox(height: 8),
                                            _buildStep(
                                              context,
                                              '2',
                                              'Opis działalności',
                                              'Opisz czym się zajmujesz',
                                            ),
                                            const SizedBox(height: 8),
                                            _buildStep(
                                              context,
                                              '3',
                                              'Kolory marki',
                                              'Wybierz paletę kolorów logo',
                                            ),
                                            const SizedBox(height: 8),
                                            _buildStep(
                                              context,
                                              '4',
                                              'Styl i generacja',
                                              'Wybierz styl i wygeneruj logo',
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // button
                  AnimationConfiguration.staggeredList(
                    position: 3,
                    child: SlideAnimation(
                      verticalOffset: 50,
                      child: FadeInAnimation(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _startLogoCreation,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.logoColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 8,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Rozpocznij projektowanie!',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: AppTheme.textPrimary,
                                  ),
                                ],
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

  Widget _buildStep(BuildContext context, String number, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppTheme.logoColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              number,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 