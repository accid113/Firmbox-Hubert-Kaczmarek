import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../providers/business_idea_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/step_progress_indicator.dart';

class CompanyNameScreen extends StatefulWidget {
  const CompanyNameScreen({super.key});

  @override
  State<CompanyNameScreen> createState() => _CompanyNameScreenState();
}

class _CompanyNameScreenState extends State<CompanyNameScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  String? _generatedName;
  bool _hasCustomName = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
    _loadBusinessIdea();
    
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

  void _loadBusinessIdea() {
    final provider = Provider.of<BusinessIdeaProvider>(context, listen: false);
    if (provider.currentBusinessIdea?.companyName != null) {
      setState(() {
        _generatedName = provider.currentBusinessIdea!.companyName;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _generateCompanyName() async {
    final provider = Provider.of<BusinessIdeaProvider>(context, listen: false);
    
    final success = await provider.generateCompanyName();
    
    if (success && mounted) {
      setState(() {
        _generatedName = provider.currentBusinessIdea?.companyName;
        _hasCustomName = false;
      });
    } else if (mounted) {
      _showErrorSnackBar(provider.errorMessage ?? 'Błąd generowania nazwy');
    }
  }

  Future<void> _proceedToNext() async {
    final provider = Provider.of<BusinessIdeaProvider>(context, listen: false);
    
    String nameToSave;
    
    if (_hasCustomName) {
      if (!_formKey.currentState!.validate()) return;
      nameToSave = _nameController.text.trim();
      
      final success = await provider.setCustomCompanyName(nameToSave);
      if (!success && mounted) {
        _showErrorSnackBar(provider.errorMessage ?? 'Błąd zapisywania nazwy');
        return;
      }
    } else {
      if (_generatedName == null) {
        _showErrorSnackBar('Najpierw wygeneruj nazwę firmy lub wprowadź własną');
        return;
      }
      nameToSave = _generatedName!;
    }
    
    if (mounted) {
      Navigator.of(context).pushNamed('/competitor-analysis');
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

  void _setCustomName(bool value) {
    setState(() {
      _hasCustomName = value;
      if (value) {
        _nameController.text = _generatedName ?? '';
      }
    });
  }

  String? _validateCompanyName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Wprowadź nazwę firmy';
    }
    if (value.trim().length < 2) {
      return 'Nazwa musi mieć co najmniej 2 znaki';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BusinessIdeaProvider>(context);
    final businessIdea = provider.currentBusinessIdea?.idea ?? '';

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
                    totalSteps: 5,
                    currentStep: 2,
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
                                      color: AppTheme.businessIdeaColor.withOpacity(0.1),
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
                                              Icons.lightbulb_outlined,
                                              color: AppTheme.businessIdeaColor,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Twój pomysł na biznes:',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: AppTheme.businessIdeaColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          businessIdea,
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
                                        color: AppTheme.businessCardColor.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.business_outlined,
                                              color: AppTheme.businessCardColor,
                                              size: 32,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Nazwa firmy',
                                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                      color: AppTheme.textPrimary,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Znajdź idealną nazwę dla swojego biznesu',
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
                                        
                                        if (_generatedName != null && !_hasCustomName) ...[
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(20),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  AppTheme.businessCardColor.withOpacity(0.2),
                                                  AppTheme.businessCardColor.withOpacity(0.1),
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: AppTheme.businessCardColor.withOpacity(0.5),
                                                width: 2,
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.auto_awesome,
                                                      color: AppTheme.businessCardColor,
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Wygenerowana nazwa:',
                                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                        color: AppTheme.businessCardColor,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  _generatedName!,
                                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                                    color: AppTheme.textPrimary,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          ),
                                          
                                          const SizedBox(height: 16),
                                          
                                          Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  onPressed: provider.isLoading ? null : _generateCompanyName,
                                                  icon: Icon(
                                                    Icons.refresh,
                                                    color: AppTheme.businessCardColor,
                                                  ),
                                                  label: Text(
                                                    'Wygeneruj inną',
                                                    style: TextStyle(color: AppTheme.businessCardColor),
                                                  ),
                                                  style: OutlinedButton.styleFrom(
                                                    side: BorderSide(color: AppTheme.businessCardColor),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  onPressed: () => _setCustomName(true),
                                                  icon: Icon(
                                                    Icons.edit,
                                                    color: AppTheme.textSecondary,
                                                  ),
                                                  label: Text(
                                                    'Edytuj',
                                                    style: TextStyle(color: AppTheme.textSecondary),
                                                  ),
                                                  style: OutlinedButton.styleFrom(
                                                    side: BorderSide(color: AppTheme.textSecondary),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ] else if (_hasCustomName) ...[
                                          Form(
                                            key: _formKey,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                CustomTextField(
                                                  controller: _nameController,
                                                  label: 'Nazwa firmy',
                                                  hint: 'Wprowadź nazwę swojej firmy...',
                                                  prefixIcon: Icons.business,
                                                  validator: _validateCompanyName,
                                                ),
                                                const SizedBox(height: 16),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: TextButton.icon(
                                                        onPressed: () => _setCustomName(false),
                                                        icon: const Icon(Icons.arrow_back),
                                                        label: const Text('Powrót'),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ] else ...[
                                          Text(
                                            'Wygeneruj nazwę firmy na podstawie Twojego pomysłu lub wprowadź własną.',
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: AppTheme.textSecondary,
                                              height: 1.4,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          
                                          const SizedBox(height: 24),
                                          
                                          Column(
                                            children: [
                                              SizedBox(
                                                width: double.infinity,
                                                child: ElevatedButton.icon(
                                                  onPressed: provider.isLoading ? null : _generateCompanyName,
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
                                                    provider.isLoading ? 'Generuję nazwę...' : 'Wygeneruj nazwę',
                                                    style: TextStyle(color: AppTheme.textPrimary),
                                                  ),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppTheme.businessCardColor,
                                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                                  ),
                                                ),
                                              ),
                                              
                                              const SizedBox(height: 12),
                                              
                                              SizedBox(
                                                width: double.infinity,
                                                child: OutlinedButton.icon(
                                                  onPressed: () => _setCustomName(true),
                                                  icon: Icon(
                                                    Icons.edit_outlined,
                                                    color: AppTheme.textSecondary,
                                                  ),
                                                  label: Text(
                                                    'Wprowadź własną nazwę',
                                                    style: TextStyle(color: AppTheme.textSecondary),
                                                  ),
                                                  style: OutlinedButton.styleFrom(
                                                    side: BorderSide(color: AppTheme.textSecondary),
                                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),
                            
                            AnimationConfiguration.staggeredList(
                              position: 2,
                              child: SlideAnimation(
                                verticalOffset: 50,
                                child: FadeInAnimation(
                                  child: Consumer<BusinessIdeaProvider>(
                                    builder: (context, provider, child) {
                                      bool canProceed = _hasCustomName 
                                        ? _nameController.text.trim().isNotEmpty
                                        : _generatedName != null;

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
                                              backgroundColor: AppTheme.businessCardColor,
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
                                                      'Dalej: Analiza konkurencji',
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
} 