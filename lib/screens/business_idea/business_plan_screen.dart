import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../providers/business_idea_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/step_progress_indicator.dart';

class BusinessPlanScreen extends StatefulWidget {
  const BusinessPlanScreen({super.key});

  @override
  State<BusinessPlanScreen> createState() => _BusinessPlanScreenState();
}

class _BusinessPlanScreenState extends State<BusinessPlanScreen>
    with TickerProviderStateMixin {
  bool _isPlanGenerated = false;
  
  late AnimationController _animationController;
  late AnimationController _progressController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
    _checkExistingPlan();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 4000),
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

  void _checkExistingPlan() {
    final provider = Provider.of<BusinessIdeaProvider>(context, listen: false);
    if (provider.currentBusinessIdea?.businessPlan != null) {
      setState(() {
        _isPlanGenerated = true;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _generateBusinessPlan() async {
    final provider = Provider.of<BusinessIdeaProvider>(context, listen: false);
    
    _progressController.forward();
    
    final success = await provider.generateBusinessPlan();
    
    _progressController.stop();
    
    if (success && mounted) {
      setState(() {
        _isPlanGenerated = true;
      });
    } else if (mounted) {
      _showErrorSnackBar(provider.errorMessage ?? 'Błąd generowania biznesplanu');
    }
  }

  Future<void> _proceedToNext() async {
    if (mounted) {
      Navigator.of(context).pushNamed('/marketing-plan');
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
    final provider = Provider.of<BusinessIdeaProvider>(context);
    final businessIdea = provider.currentBusinessIdea?.idea ?? '';
    final companyName = provider.currentBusinessIdea?.companyName ?? '';
    final businessPlan = provider.currentBusinessIdea?.businessPlan ?? '';

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
                            'Biznesplan',
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
                    currentStep: 4,
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

                            // summarize
                            AnimationConfiguration.staggeredList(
                              position: 0,
                              child: SlideAnimation(
                                verticalOffset: 30,
                                child: FadeInAnimation(
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: AppTheme.cardColor.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: AppTheme.businessIdeaColor.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.business_outlined,
                                              color: AppTheme.businessCardColor,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              companyName,
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                color: AppTheme.businessCardColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.lightbulb_outlined,
                                              color: AppTheme.businessIdeaColor,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                businessIdea,
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: AppTheme.textSecondary,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
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
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.description_outlined,
                                              color: AppTheme.businessIdeaColor,
                                              size: 32,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Biznesplan',
                                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                      color: AppTheme.textPrimary,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Profesjonalny plan rozwoju Twojej firmy',
                                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                      color: AppTheme.textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        
                                        const SizedBox(height: 24),
                                        
                                        if (!_isPlanGenerated) ...[
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(20),
                                            decoration: BoxDecoration(
                                              color: AppTheme.businessIdeaColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: AppTheme.businessIdeaColor.withOpacity(0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                Icon(
                                                  Icons.article_outlined,
                                                  color: AppTheme.businessIdeaColor,
                                                  size: 48,
                                                ),
                                                const SizedBox(height: 16),
                                                Text(
                                                  'Plan biznesowy',
                                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                    color: AppTheme.textPrimary,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'AI stworzy kompletny biznesplan uwzględniający model biznesowy, analizę rynku, projekcje finansowe i strategię rozwoju.',
                                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                    color: AppTheme.textSecondary,
                                                    height: 1.4,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                const SizedBox(height: 20),
                                                
                                                Column(
                                                  children: [
                                                    _buildPlanElement(
                                                      Icons.account_balance,
                                                      'Model biznesowy',
                                                      'Sposób generowania przychodów',
                                                    ),
                                                    const SizedBox(height: 12),
                                                    _buildPlanElement(
                                                      Icons.timeline,
                                                      'Analiza rynku',
                                                      'Wielkość rynku i potencjał wzrostu',
                                                    ),
                                                    const SizedBox(height: 12),
                                                    _buildPlanElement(
                                                      Icons.trending_up,
                                                      'Projekcje finansowe',
                                                      'Przewidywane koszty i przychody',
                                                    ),
                                                    const SizedBox(height: 12),
                                                    _buildPlanElement(
                                                      Icons.rocket_launch,
                                                      'Strategia rozwoju',
                                                      'Plan działań na przyszłość',
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          
                                          const SizedBox(height: 24),
                                          
                                          Consumer<BusinessIdeaProvider>(
                                            builder: (context, provider, child) {
                                              return SizedBox(
                                                width: double.infinity,
                                                child: ElevatedButton.icon(
                                                  onPressed: provider.isLoading ? null : _generateBusinessPlan,
                                                  icon: provider.isLoading
                                                    ? LoadingAnimationWidget.threeArchedCircle(
                                                        color: AppTheme.textPrimary,
                                                        size: 20,
                                                      )
                                                    : Icon(
                                                        Icons.auto_awesome,
                                                        color: AppTheme.textPrimary,
                                                      ),
                                                  label: Text(
                                                    provider.isLoading ? 'Tworzenie biznesplanu...' : 'Stwórz biznesplan',
                                                    style: TextStyle(color: AppTheme.textPrimary),
                                                  ),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppTheme.businessIdeaColor,
                                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          
                                          Consumer<BusinessIdeaProvider>(
                                            builder: (context, provider, child) {
                                              if (!provider.isLoading) return const SizedBox.shrink();
                                              
                                              return Column(
                                                children: [
                                                  const SizedBox(height: 24),
                                                  Container(
                                                    padding: const EdgeInsets.all(20),
                                                    decoration: BoxDecoration(
                                                      color: AppTheme.cardColor.withOpacity(0.5),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Column(
                                                      children: [
                                                        Text(
                                                          'Tworzę szczegółowy biznesplan...',
                                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                            color: AppTheme.textPrimary,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 8),
                                                        Text(
                                                          'Analizowanie modelu biznesowego',
                                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                            color: AppTheme.textSecondary,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 16),
                                                        AnimatedBuilder(
                                                          animation: _progressController,
                                                          builder: (context, child) {
                                                            return LinearProgressIndicator(
                                                              value: _progressController.value,
                                                              backgroundColor: AppTheme.textHint,
                                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                                AppTheme.businessIdeaColor,
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                        const SizedBox(height: 8),
                                                        Text(
                                                          'To może potrwać dłuższą chwilę...',
                                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                            color: AppTheme.textHint,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ] else ...[
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(20),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  AppTheme.businessIdeaColor.withOpacity(0.2),
                                                  AppTheme.businessIdeaColor.withOpacity(0.1),
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: AppTheme.businessIdeaColor.withOpacity(0.5),
                                                width: 2,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.check_circle,
                                                      color: AppTheme.businessIdeaColor,
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Biznesplan:',
                                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                        color: AppTheme.businessIdeaColor,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 16),
                                                Text(
                                                  businessPlan,
                                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                    color: AppTheme.textPrimary,
                                                    height: 1.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          
                                          const SizedBox(height: 16),
                                          
                                          TextButton.icon(
                                            onPressed: provider.isLoading ? null : () => _generateBusinessPlan(),
                                            icon: provider.isLoading 
                                              ? LoadingAnimationWidget.threeArchedCircle(
                                                  color: AppTheme.businessIdeaColor,
                                                  size: 16,
                                                )
                                              : const Icon(Icons.refresh),
                                            label: Text(provider.isLoading ? 'Tworzę biznesplan...' : 'Wygeneruj ponownie'),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),
                            
                            if (_isPlanGenerated)
                              AnimationConfiguration.staggeredList(
                                position: 2,
                                child: SlideAnimation(
                                  verticalOffset: 50,
                                  child: FadeInAnimation(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      child: SizedBox(
                                        width: double.infinity,
                                        height: 56,
                                        child: ElevatedButton(
                                          onPressed: _proceedToNext,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.businessIdeaColor,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Dalej: Plan marketingowy',
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

  Widget _buildPlanElement(IconData icon, String title, String description) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.businessIdeaColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            color: AppTheme.businessIdeaColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
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