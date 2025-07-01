import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../providers/logo_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/step_progress_indicator.dart';

class LogoColorsScreen extends StatefulWidget {
  const LogoColorsScreen({super.key});

  @override
  State<LogoColorsScreen> createState() => _LogoColorsScreenState();
}

class _LogoColorsScreenState extends State<LogoColorsScreen>
    with TickerProviderStateMixin {
  Color? _textColor;
  Color? _backgroundColor;
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
    final logoProvider = Provider.of<LogoProvider>(context, listen: false);
    
    final success = await logoProvider.setColors(
      textColor: _textColor,
      backgroundColor: _backgroundColor,
      additionalColors: _additionalColors.isNotEmpty ? _additionalColors : null,
    );
    
    if (success && mounted) {
      Navigator.of(context).pushNamed('/logo-style');
    } else if (mounted) {
      _showErrorSnackBar(logoProvider.errorMessage ?? 'Błąd zapisywania kolorów');
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
              backgroundColor: AppTheme.logoColor,
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
      currentColor: AppTheme.logoColor,
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
                            'Kolory logo',
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
                    currentStep: 3,
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
                                      Icons.palette,
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
                                  'Wybierz kolory dla swojego logo',
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
                                  'Wybierz kolory, które najlepiej reprezentują Twoją markę. Wszystkie kolory są opcjonalne.',
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

                          // text color
                          AnimationConfiguration.staggeredList(
                            position: 3,
                            child: SlideAnimation(
                              verticalOffset: 20,
                              child: FadeInAnimation(
                                child: _buildColorSection(
                                  title: 'Kolor tekstu',
                                  isRequired: false,
                                  color: _textColor,
                                  onTap: () => _showColorPicker(
                                    title: 'Wybierz kolor tekstu',
                                    currentColor: _textColor ?? Colors.black,
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
                                  isRequired: false,
                                  color: _backgroundColor,
                                  onTap: () => _showColorPicker(
                                    title: 'Wybierz kolor tła',
                                    currentColor: _backgroundColor ?? Colors.white,
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
                                      'Dodaj do 3 kolorów dodatkowych, które będą używane jako akcenty w logo.',
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

                          if (_textColor != null || _backgroundColor != null || _additionalColors.isNotEmpty)
                            AnimationConfiguration.staggeredList(
                              position: 6,
                              child: SlideAnimation(
                                verticalOffset: 20,
                                child: FadeInAnimation(
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: _backgroundColor ?? Colors.transparent,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: AppTheme.accentColor.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          'Podgląd kolorów logo',
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            color: _textColor ?? AppTheme.textPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Przykładowy tekst w wybranych kolorach',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: _textColor ?? AppTheme.textPrimary,
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
                                                  color: (_textColor ?? AppTheme.textPrimary).withOpacity(0.7),
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
                                                    color: (_textColor ?? AppTheme.textPrimary).withOpacity(0.3),
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

                          const SizedBox(height: 50),
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: AnimationConfiguration.staggeredList(
                      position: 7,
                      child: SlideAnimation(
                        verticalOffset: 30,
                        child: FadeInAnimation(
                          child: Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: logoProvider.isLoading ? null : _proceedToNext,
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
                              const SizedBox(height: 8),
                              Text(
                                'Wszystkie kolory są opcjonalne',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textHint,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Krok 3 z 4',
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

  Widget _buildColorSection({
    required String title,
    required bool isRequired,
    required Color? color,
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
                      color: color ?? Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.textSecondary,
                        width: 1,
                      ),
                    ),
                    child: color == null 
                        ? Icon(
                            Icons.add,
                            color: AppTheme.textSecondary,
                            size: 20,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          color == null ? 'Kliknij aby wybrać' : 'Kliknij aby zmienić',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (color != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.color_lens_outlined,
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
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _removeAdditionalColor(index),
            child: Icon(
              Icons.close,
              size: 16,
              color: AppTheme.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddColorButton() {
    return GestureDetector(
      onTap: _addAdditionalColor,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.logoColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.logoColor,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add,
              size: 16,
              color: AppTheme.logoColor,
            ),
            const SizedBox(width: 4),
            Text(
              'Dodaj',
              style: TextStyle(
                color: AppTheme.logoColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 