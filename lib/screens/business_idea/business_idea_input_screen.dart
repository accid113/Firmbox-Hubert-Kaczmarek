import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../providers/business_idea_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/step_progress_indicator.dart';

class BusinessIdeaInputScreen extends StatefulWidget {
  const BusinessIdeaInputScreen({super.key});

  @override
  State<BusinessIdeaInputScreen> createState() => _BusinessIdeaInputScreenState();
}

class _BusinessIdeaInputScreenState extends State<BusinessIdeaInputScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _ideaController = TextEditingController();
  
  bool _hasIdea = false;
  String? _generatedIdea;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
    
    _ideaController.addListener(() {
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
    _ideaController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _setHasIdea(bool value) {
    setState(() {
      _hasIdea = value;
      _generatedIdea = null;
    });
  }

  Future<void> _generateIdea() async {
    final provider = Provider.of<BusinessIdeaProvider>(context, listen: false);
    
    final success = await provider.generateBusinessIdea();
    
    if (success && mounted) {
      setState(() {
        _generatedIdea = provider.currentBusinessIdea?.idea;
      });
    } else if (mounted) {
      _showErrorSnackBar(provider.errorMessage ?? 'Błąd generowania pomysłu');
    }
  }

  Future<void> _proceedToNext() async {
    final provider = Provider.of<BusinessIdeaProvider>(context, listen: false);
    
    String ideaToSave;
    
    if (_hasIdea) {
      if (!_formKey.currentState!.validate()) return;
      ideaToSave = _ideaController.text.trim();
      
      final success = await provider.setCustomBusinessIdea(ideaToSave);
      if (!success && mounted) {
        _showErrorSnackBar(provider.errorMessage ?? 'Błąd zapisywania pomysłu');
        return;
      }
    } else {
      if (_generatedIdea == null) {
        _showErrorSnackBar('Najpierw wygeneruj pomysł na biznes');
        return;
      }
      ideaToSave = _generatedIdea!;
    }
    
    if (mounted) {
      Navigator.of(context).pushNamed('/company-name');
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

  String? _validateIdea(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Wprowadź opis swojego pomysłu na biznes';
    }
    if (value.trim().length < 10) {
      return 'Opis musi mieć co najmniej 10 znaków';
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
                            'Pomysł na biznes',
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),

                  // Progress bar
                  StepProgressIndicator(
                    totalSteps: 5,
                    currentStep: 1,
                    activeColor: AppTheme.businessIdeaColor,
                  ),

                  // main
                  Expanded(
                    child: AnimationLimiter(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),

                            AnimationConfiguration.staggeredList(
                              position: 0,
                              child: SlideAnimation(
                                verticalOffset: 30,
                                child: FadeInAnimation(
                                  child: Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: AppTheme.cardColor.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: AppTheme.businessIdeaColor.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.help_outline,
                                          size: 48,
                                          color: AppTheme.businessIdeaColor,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Czy masz już pomysł na biznes?',
                                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                            color: AppTheme.textPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Wybierz jedną z opcji poniżej',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: AppTheme.textSecondary,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),

                            AnimationConfiguration.staggeredList(
                              position: 1,
                              child: SlideAnimation(
                                verticalOffset: 30,
                                child: FadeInAnimation(
                                  child: Column(
                                    children: [
                                      _buildOptionCard(
                                        title: 'Tak, mam już pomysł',
                                        description: 'Opowiem o swoim pomyśle na biznes',
                                        icon: Icons.psychology,
                                        color: AppTheme.businessIdeaColor,
                                        isSelected: _hasIdea,
                                        onTap: () => _setHasIdea(true),
                                      ),

                                      const SizedBox(height: 16),

                                      _buildOptionCard(
                                        title: 'Nie, potrzebuję inspiracji',
                                        description: 'Wygeneruj dla mnie pomysł na biznes',
                                        icon: Icons.auto_awesome,
                                        color: AppTheme.logoColor,
                                        isSelected: !_hasIdea,
                                        onTap: () => _setHasIdea(false),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),

                            AnimationConfiguration.staggeredList(
                              position: 2,
                              child: SlideAnimation(
                                verticalOffset: 30,
                                child: FadeInAnimation(
                                  child: _hasIdea ? _buildIdeaInput() : _buildIdeaGeneration(),
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),
                            
                            AnimationConfiguration.staggeredList(
                              position: 3,
                              child: SlideAnimation(
                                verticalOffset: 50,
                                child: FadeInAnimation(
                                  child: Consumer<BusinessIdeaProvider>(
                                    builder: (context, provider, child) {
                                      bool canProceed = _hasIdea 
                                        ? _ideaController.text.trim().isNotEmpty
                                        : _generatedIdea != null;

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        child: SizedBox(
                                          width: double.infinity,
                                          height: 56,
                                          child: ElevatedButton(
                                            onPressed: (canProceed && !provider.isLoading) 
                                              ? _proceedToNext 
                                              : null,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.businessIdeaColor,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                            ),
                                            child: provider.isLoading
                                              ? LoadingAnimationWidget.threeArchedCircle(
                                                  color: AppTheme.textPrimary,
                                                  size: 24,
                                                )
                                              : Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      'Dalej',
                                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                        color: AppTheme.textPrimary,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Icon(
                                                      Icons.arrow_forward_rounded,
                                                      color: AppTheme.textPrimary,
                                                    ),
                                                  ],
                                                ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 24), // Bottom padding
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
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
              ? [
                  color.withOpacity(0.8),
                  color.withOpacity(0.4),
                ]
              : [
                  AppTheme.cardColor.withOpacity(0.3),
                  AppTheme.cardColor.withOpacity(0.1),
                ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
              ? color 
              : AppTheme.accentColor.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
            ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : null,
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isSelected 
                  ? Colors.white.withOpacity(0.2)
                  : color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                icon,
                size: 30,
                color: isSelected ? Colors.white : color,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isSelected 
                        ? Colors.white.withOpacity(0.8)
                        : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdeaInput() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.businessIdeaColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.edit_outlined,
                  color: AppTheme.businessIdeaColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Opisz swój pomysł',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _ideaController,
              label: 'Pomysł na biznes',
              hint: 'Opisz swój pomysł na biznes...',
              maxLines: 4,
              validator: _validateIdea,
            ),
            const SizedBox(height: 12),
            Text(
              'Opisz czym chciałbyś się zajmować, jakie problemy rozwiązywać lub jaką usługę oferować.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textHint,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdeaGeneration() {
    return Container(
      padding: const EdgeInsets.all(24),
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
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: AppTheme.logoColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Generowanie pomysłu',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_generatedIdea == null) ...[
            Text(
              'Naciśnij przycisk poniżej, a AI wygeneruje dla Ciebie innowacyjny pomysł na biznes dostosowany do obecnych trendów rynkowych.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Consumer<BusinessIdeaProvider>(
              builder: (context, provider, child) {
                return SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: provider.isLoading ? null : _generateIdea,
                    icon: provider.isLoading
                      ? LoadingAnimationWidget.threeArchedCircle(
                          color: AppTheme.logoColor,
                          size: 20,
                        )
                      : Icon(Icons.auto_awesome, color: AppTheme.logoColor),
                    label: Text(
                      provider.isLoading ? 'Generuję pomysł...' : 'Wygeneruj pomysł',
                      style: TextStyle(color: AppTheme.logoColor),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.logoColor),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                );
              },
            ),
          ] else ...[
            Container(
              width: double.infinity,
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
                        Icons.lightbulb,
                        color: AppTheme.logoColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Wygenerowany pomysł:',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.logoColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _generatedIdea!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _generateIdea,
              icon: const Icon(Icons.refresh),
              label: const Text('Wygeneruj inny pomysł'),
            ),
          ],
        ],
      ),
    );
  }
} 