import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../providers/logo_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/step_progress_indicator.dart';

class LogoStyleScreen extends StatefulWidget {
  const LogoStyleScreen({super.key});

  @override
  State<LogoStyleScreen> createState() => _LogoStyleScreenState();
}

class _LogoStyleScreenState extends State<LogoStyleScreen>
    with TickerProviderStateMixin {
  String? _selectedStyle;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<StyleOption> _styleOptions = [
    StyleOption(
      name: 'Minimalistyczny',
      description: 'Proste, czyste linie i przestrzeń',
      icon: Icons.remove_circle_outline,
    ),
    StyleOption(
      name: 'Nowoczesny',
      description: 'Współczesny design z geometrycznymi kształtami',
      icon: Icons.auto_awesome,
    ),
    StyleOption(
      name: 'Klasyczny',
      description: 'Elegancki, ponadczasowy styl',
      icon: Icons.account_balance,
    ),
    StyleOption(
      name: 'Retro',
      description: 'Vintage design z charakterem',
      icon: Icons.history,
    ),
    StyleOption(
      name: 'Zabawny',
      description: 'Kolorowy i przyjazny styl',
      icon: Icons.emoji_emotions,
    ),
    StyleOption(
      name: 'Profesjonalny',
      description: 'Solidny, biznesowy charakter',
      icon: Icons.business_center,
    ),
    StyleOption(
      name: 'Kreatywny',
      description: 'Artystyczny i oryginalny',
      icon: Icons.brush,
    ),
    StyleOption(
      name: 'Technologiczny',
      description: 'Futurystyczny, hi-tech design',
      icon: Icons.computer,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
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
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _proceedToGeneration() async {
    if (_selectedStyle == null) return;

    final logoProvider = Provider.of<LogoProvider>(context, listen: false);
    
    final success = await logoProvider.setStyle(_selectedStyle!);
    
    if (success && mounted) {
      Navigator.of(context).pushNamed('/logo-final');
    } else if (mounted) {
      _showErrorSnackBar(logoProvider.errorMessage ?? 'Błąd zapisywania stylu');
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
                            'Styl logo',
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
                    currentStep: 4,
                    activeColor: AppTheme.logoColor,
                  ),

                  // main
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
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
                                      Icons.style,
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
                                  'Wybierz styl swojego logo',
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
                                  'Wybierz styl, który najlepiej reprezentuje charakter Twojej firmy. To pomoże stworzyć idealne logo.',
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

                          ...List.generate(_styleOptions.length, (index) {
                            final style = _styleOptions[index];
                            final isSelected = _selectedStyle == style.name;

                            return AnimationConfiguration.staggeredList(
                              position: index + 3,
                              child: SlideAnimation(
                                verticalOffset: 30,
                                child: FadeInAnimation(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildStyleOption(style, isSelected),
                                  ),
                                ),
                              ),
                            );
                          }),

                          const SizedBox(height: 50),
                        ],
                      ),
                    ),
                  ),

                  // button
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: AnimationConfiguration.staggeredList(
                      position: _styleOptions.length + 3,
                      child: SlideAnimation(
                        verticalOffset: 30,
                        child: FadeInAnimation(
                          child: Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: logoProvider.isLoading || _selectedStyle == null
                                      ? null
                                      : _proceedToGeneration,
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
                                          'Wygeneruj logo',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Krok 4 z 4',
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

  Widget _buildStyleOption(StyleOption style, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStyle = style.name;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
              ? [
                  AppTheme.logoColor.withOpacity(0.8),
                  AppTheme.logoColor.withOpacity(0.4),
                ]
              : [
                  AppTheme.cardColor.withOpacity(0.3),
                  AppTheme.cardColor.withOpacity(0.1),
                ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
              ? AppTheme.logoColor 
              : AppTheme.accentColor.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppTheme.logoColor.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : null,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected 
                  ? Colors.white.withOpacity(0.2)
                  : AppTheme.logoColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                style.icon,
                color: isSelected ? Colors.white : AppTheme.logoColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    style.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    style.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isSelected ? Colors.white.withOpacity(0.8) : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

class StyleOption {
  final String name;
  final String description;
  final IconData icon;

  StyleOption({
    required this.name,
    required this.description,
    required this.icon,
  });
} 