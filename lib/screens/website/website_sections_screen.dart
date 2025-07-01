import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../providers/website_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/step_progress_indicator.dart';

class WebsiteSectionsScreen extends StatefulWidget {
  const WebsiteSectionsScreen({super.key});

  @override
  State<WebsiteSectionsScreen> createState() => _WebsiteSectionsScreenState();
}

class _WebsiteSectionsScreenState extends State<WebsiteSectionsScreen>
    with TickerProviderStateMixin {
  final Set<String> _selectedSections = {};
  final _customSectionController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
    
    _customSectionController.addListener(() => setState(() {}));
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
    _customSectionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _proceedToNext() async {
    if (_selectedSections.isEmpty) {
      _showErrorSnackBar('Wybierz co najmniej jedną sekcję');
      return;
    }

    final websiteProvider = Provider.of<WebsiteProvider>(context, listen: false);
    
    final success = await websiteProvider.setSelectedSections(
      _selectedSections.toList(),
      _customSectionController.text.trim().isNotEmpty ? _customSectionController.text.trim() : null,
    );
    
    if (success && mounted) {
      Navigator.of(context).pushNamed('/website-style');
    } else if (mounted) {
      _showErrorSnackBar(websiteProvider.errorMessage ?? 'Błąd zapisywania sekcji');
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

  void _toggleSection(String section) {
    setState(() {
      if (_selectedSections.contains(section)) {
        _selectedSections.remove(section);
      } else {
        _selectedSections.add(section);
      }
    });
  }

  bool get _canProceed => _selectedSections.isNotEmpty;

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
                            'Sekcje strony',
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
                    totalSteps: 4,
                    currentStep: 2,
                    activeColor: AppTheme.websiteColor,
                  ),

                  // main
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
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
                                      Icons.widgets_outlined,
                                      size: 40,
                                      color: AppTheme.websiteColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // ttle
                          AnimationConfiguration.staggeredList(
                            position: 1,
                            child: SlideAnimation(
                              verticalOffset: 20,
                              child: FadeInAnimation(
                                child: Text(
                                  'Wybierz sekcje, które mają znaleźć się na Twojej stronie',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // description
                          AnimationConfiguration.staggeredList(
                            position: 2,
                            child: SlideAnimation(
                              verticalOffset: 20,
                              child: FadeInAnimation(
                                child: Text(
                                  'Możesz wybrać dowolną ilość sekcji. Wybrane sekcje zostaną automatycznie wygenerowane z odpowiednią treścią.',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          AnimationConfiguration.staggeredList(
                            position: 3,
                            child: SlideAnimation(
                              verticalOffset: 20,
                              child: FadeInAnimation(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dostępne sekcje:',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    // grid
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                        childAspectRatio: 3.2,
                                      ),
                                      itemCount: WebsiteProvider.availableSections.length,
                                      itemBuilder: (context, index) {
                                        final section = WebsiteProvider.availableSections[index];
                                        final isSelected = _selectedSections.contains(section);
                                        
                                        return AnimationConfiguration.staggeredGrid(
                                          position: index,
                                          duration: const Duration(milliseconds: 375),
                                          columnCount: 2,
                                          child: SlideAnimation(
                                            verticalOffset: 50.0,
                                            child: FadeInAnimation(
                                              child: _buildSectionCard(section, isSelected),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          AnimationConfiguration.staggeredList(
                            position: 4,
                            child: SlideAnimation(
                              verticalOffset: 20,
                              child: FadeInAnimation(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Własna sekcja (opcjonalnie):',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Jeśli potrzebujesz dodatkowej sekcji, która nie znajduje się na liście, opisz ją poniżej.',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    CustomTextField(
                                      controller: _customSectionController,
                                      label: 'Własna sekcja',
                                      hint: 'np. Historia firmy, Nasze osiągnięcia, FAQ...',
                                      prefixIcon: Icons.add_circle_outline,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // sumarize
                          if (_selectedSections.isNotEmpty) ...[
                            AnimationConfiguration.staggeredList(
                              position: 5,
                              child: SlideAnimation(
                                verticalOffset: 20,
                                child: FadeInAnimation(
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppTheme.websiteColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppTheme.websiteColor.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.check_circle_outline,
                                              color: AppTheme.websiteColor,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Wybrane sekcje (${_selectedSections.length}):',
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                color: AppTheme.textPrimary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: _selectedSections.map((section) {
                                            return Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: AppTheme.websiteColor.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                section,
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: AppTheme.textPrimary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                        if (_customSectionController.text.trim().isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: AppTheme.accentColor.withOpacity(0.3),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              _customSectionController.text.trim(),
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: AppTheme.textPrimary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // button
                  AnimationConfiguration.staggeredList(
                    position: 6,
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

  Widget _buildSectionCard(String section, bool isSelected) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _toggleSection(section),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected 
                ? AppTheme.websiteColor.withOpacity(0.2)
                : AppTheme.cardColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                  ? AppTheme.websiteColor
                  : AppTheme.accentColor.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? AppTheme.websiteColor : AppTheme.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    section,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 