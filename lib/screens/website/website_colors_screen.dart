import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../providers/website_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/step_progress_indicator.dart';

class WebsiteColorsScreen extends StatefulWidget {
  const WebsiteColorsScreen({super.key});

  @override
  State<WebsiteColorsScreen> createState() => _WebsiteColorsScreenState();
}

class _WebsiteColorsScreenState extends State<WebsiteColorsScreen>
    with TickerProviderStateMixin {
  Color _textColor = Colors.black;
  Color _backgroundColor = Colors.white;
  List<Color> _additionalColors = [];
  
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

  Future<void> _proceedToNext() async {
    final websiteProvider = Provider.of<WebsiteProvider>(context, listen: false);
    
    final success = await websiteProvider.setColors(
      textColor: _textColor,
      backgroundColor: _backgroundColor,
      additionalColors: _additionalColors.isNotEmpty ? _additionalColors : null,
    );
    
    if (success && mounted) {
      Navigator.of(context).pushNamed('/website-final');
    } else if (mounted) {
      _showErrorSnackBar(websiteProvider.errorMessage ?? 'Błąd zapisywania kolorów');
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

  void _showColorPicker({
    required String title,
    required Color currentColor,
    required Function(Color) onColorChanged,
  }) {
    Color selectedColor = currentColor;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.textPrimary,
          ),
        ),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: currentColor,
            onColorChanged: (color) => selectedColor = color,
            labelTypes: const [],
            pickerAreaHeightPercent: 0.8,
            displayThumbColor: true,
            portraitOnly: true,
            colorPickerWidth: 300,
            enableAlpha: false,
            hexInputBar: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () {
              onColorChanged(selectedColor);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.websiteColor,
            ),
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _addAdditionalColor() {
    if (_additionalColors.length >= 3) {
      _showErrorSnackBar('Możesz dodać maksymalnie 3 dodatkowe kolory');
      return;
    }

    _showColorPicker(
      title: 'Wybierz dodatkowy kolor',
      currentColor: AppTheme.websiteColor,
      onColorChanged: (color) {
        setState(() {
          _additionalColors.add(color);
        });
      },
    );
  }

  void _removeAdditionalColor(int index) {
    setState(() {
      _additionalColors.removeAt(index);
    });
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
                            'Kolory strony',
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
                                      Icons.color_lens_outlined,
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
                                  'Wybierz kolorystykę Twojej strony',
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
                                  'Wybierz kolory, które będą reprezentować Twoją markę na stronie internetowej.',
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

                          // txt color
                          AnimationConfiguration.staggeredList(
                            position: 3,
                            child: SlideAnimation(
                              verticalOffset: 20,
                              child: FadeInAnimation(
                                child: _buildColorSection(
                                  title: 'Kolor napisów',
                                  isRequired: true,
                                  color: _textColor,
                                  onTap: () => _showColorPicker(
                                    title: 'Wybierz kolor napisów',
                                    currentColor: _textColor,
                                    onColorChanged: (color) => setState(() => _textColor = color),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          AnimationConfiguration.staggeredList(
                            position: 4,
                            child: SlideAnimation(
                              verticalOffset: 20,
                              child: FadeInAnimation(
                                child: _buildColorSection(
                                  title: 'Kolor tła',
                                  isRequired: true,
                                  color: _backgroundColor,
                                  onTap: () => _showColorPicker(
                                    title: 'Wybierz kolor tła',
                                    currentColor: _backgroundColor,
                                    onColorChanged: (color) => setState(() => _backgroundColor = color),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          AnimationConfiguration.staggeredList(
                            position: 5,
                            child: SlideAnimation(
                              verticalOffset: 20,
                              child: FadeInAnimation(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Kolory dodatkowe',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: AppTheme.textPrimary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '(opcjonalnie)',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Dodaj do 3 kolorów dodatkowych, które będą używane jako akcenty na stronie.',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      children: [
                                        ..._additionalColors.asMap().entries.map((entry) {
                                          return _buildAdditionalColorChip(entry.value, entry.key);
                                        }),
                                        if (_additionalColors.length < 3)
                                          _buildAddColorButton(),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          AnimationConfiguration.staggeredList(
                            position: 6,
                            child: SlideAnimation(
                              verticalOffset: 20,
                              child: FadeInAnimation(
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: _backgroundColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppTheme.accentColor.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Podgląd kolorów',
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          color: _textColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'To jest przykład tekstu w wybranych kolorach. Tak będzie wyglądać treść na Twojej stronie internetowej.',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: _textColor,
                                          height: 1.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      if (_additionalColors.isNotEmpty) ...[
                                        const SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Kolory akcentów: ',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: _textColor.withOpacity(0.7),
                                              ),
                                            ),
                                            ..._additionalColors.map((color) => Container(
                                              width: 16,
                                              height: 16,
                                              margin: const EdgeInsets.only(left: 4),
                                              decoration: BoxDecoration(
                                                color: color,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: _textColor.withOpacity(0.3),
                                                  width: 1,
                                                ),
                                              ),
                                            )),
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
                        ],
                      ),
                    ),
                  ),

                  AnimationConfiguration.staggeredList(
                    position: 7,
                    child: SlideAnimation(
                      verticalOffset: 30,
                      child: FadeInAnimation(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: websiteProvider.isLoading ? null : _proceedToNext,
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
                                      'Wygeneruj stronę',
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

  Widget _buildColorSection({
    required String title,
    required bool isRequired,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
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
        const SizedBox(height: 12),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.accentColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.textSecondary,
                        width: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kliknij aby zmienić',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '#${color.value.toRadixString(16).substring(2).toUpperCase()}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.edit_outlined,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalColorChip(Color color, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.textSecondary,
                width: 1,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '#${color.value.toRadixString(16).substring(2).toUpperCase()}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _removeAdditionalColor(index),
            child: const Icon(
              Icons.close,
              size: 16,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddColorButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _addAdditionalColor,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.websiteColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.websiteColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add,
                size: 20,
                color: AppTheme.websiteColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Dodaj kolor',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.websiteColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 