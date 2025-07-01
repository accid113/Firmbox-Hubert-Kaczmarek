import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../providers/website_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/step_progress_indicator.dart';

class WebsiteStyleScreen extends StatefulWidget {
  const WebsiteStyleScreen({super.key});

  @override
  State<WebsiteStyleScreen> createState() => _WebsiteStyleScreenState();
}

class _WebsiteStyleScreenState extends State<WebsiteStyleScreen>
    with TickerProviderStateMixin {
  String? _selectedStyle;
  final _customStyleController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
    
    _customStyleController.addListener(() => setState(() {}));
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
    _customStyleController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _proceedToNext() async {
    final selectedStyle = _selectedStyle ?? _customStyleController.text.trim();
    
    if (selectedStyle.isEmpty) {
      _showErrorSnackBar('Wybierz styl lub wprowadź własny');
      return;
    }

    final websiteProvider = Provider.of<WebsiteProvider>(context, listen: false);
    
    final success = await websiteProvider.setWebsiteStyle(selectedStyle);
    
    if (success && mounted) {
      Navigator.of(context).pushNamed('/website-colors');
    } else if (mounted) {
      _showErrorSnackBar(websiteProvider.errorMessage ?? 'Błąd zapisywania stylu');
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

  void _selectStyle(String style) {
    setState(() {
      _selectedStyle = style;
      _customStyleController.clear();
    });
  }

  void _selectCustomStyle() {
    setState(() {
      _selectedStyle = null;
    });
  }

  bool get _canProceed {
    return _selectedStyle != null || _customStyleController.text.trim().isNotEmpty;
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
                            'Styl strony',
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
                    currentStep: 3,
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
                                      Icons.palette_outlined,
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
                                  'Wybierz styl Twojej strony internetowej',
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
                                  'Wybierz styl, który najlepiej oddaje charakter Twojej firmy. Możesz także wprowadzić własny opis stylu.',
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
                                      'Dostępne style:',
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
                                        childAspectRatio: 2.5,
                                      ),
                                      itemCount: WebsiteProvider.availableStyles.length,
                                      itemBuilder: (context, index) {
                                        final style = WebsiteProvider.availableStyles[index];
                                        final isSelected = _selectedStyle == style;
                                        
                                        return AnimationConfiguration.staggeredGrid(
                                          position: index,
                                          duration: const Duration(milliseconds: 375),
                                          columnCount: 2,
                                          child: SlideAnimation(
                                            verticalOffset: 50.0,
                                            child: FadeInAnimation(
                                              child: _buildStyleCard(style, isSelected, _getStyleIcon(style)),
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
                                      'Lub opisz własny styl:',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Opisz jaki styl chcesz osiągnąć na swojej stronie.',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    TextField(
                                      controller: _customStyleController,
                                      onTap: _selectCustomStyle,
                                      decoration: InputDecoration(
                                        hintText: 'np. Futurystyczny z animacjami, Rustykalny i ciepły...',
                                        prefixIcon: const Icon(Icons.edit_outlined),
                                        filled: true,
                                        fillColor: AppTheme.cardColor.withOpacity(0.5),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: _selectedStyle == null && _customStyleController.text.isNotEmpty
                                                ? AppTheme.websiteColor
                                                : AppTheme.accentColor.withOpacity(0.3),
                                            width: _selectedStyle == null && _customStyleController.text.isNotEmpty ? 2 : 1,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                            color: AppTheme.websiteColor,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      maxLines: 2,
                                      maxLength: 200,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // sumarize
                          if (_canProceed) ...[
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
                                              Icons.style_outlined,
                                              color: AppTheme.websiteColor,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Wybrany styl:',
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                color: AppTheme.textPrimary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _selectedStyle ?? _customStyleController.text.trim(),
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: AppTheme.textPrimary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
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

  Widget _buildStyleCard(String style, bool isSelected, IconData icon) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectStyle(style),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected 
                ? AppTheme.websiteColor.withOpacity(0.2)
                : AppTheme.cardColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected 
                  ? AppTheme.websiteColor
                  : AppTheme.accentColor.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Icon(
                    icon,
                    color: isSelected ? AppTheme.websiteColor : AppTheme.textSecondary,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 6),
                Flexible(
                  child: Text(
                    style,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
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

  IconData _getStyleIcon(String style) {
    switch (style) {
      case 'Nowoczesny':
        return Icons.auto_awesome_outlined;
      case 'Minimalistyczny':
        return Icons.minimize_outlined;
      case 'Klasyczny':
        return Icons.account_balance_outlined;
      case 'Firmowy':
        return Icons.business_center_outlined;
      case 'Kreatywny':
        return Icons.brush_outlined;
      case 'Elegancki':
        return Icons.diamond_outlined;
      case 'Technologiczny':
        return Icons.memory_outlined;
      case 'Artystyczny':
        return Icons.palette_outlined;
      default:
        return Icons.style_outlined;
    }
  }
} 