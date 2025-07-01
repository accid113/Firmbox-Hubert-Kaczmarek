import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class ColorPickerWidget extends StatefulWidget {
  final String label;
  final Color? selectedColor;
  final Function(Color) onColorSelected;
  final List<Color> presetColors;

  const ColorPickerWidget({
    super.key,
    required this.label,
    this.selectedColor,
    required this.onColorSelected,
    this.presetColors = const [],
  });

  @override
  State<ColorPickerWidget> createState() => _ColorPickerWidgetState();
}

class _ColorPickerWidgetState extends State<ColorPickerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  static const List<Color> _defaultColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
    Colors.black,
    Colors.white,
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Wybierz ${widget.label}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: SizedBox(
          width: 300,
          height: 300,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _getAvailableColors().length,
            itemBuilder: (context, index) {
              final color = _getAvailableColors()[index];
              final isSelected = widget.selectedColor == color;

              return GestureDetector(
                onTap: () {
                  widget.onColorSelected(color);
                  Navigator.of(context).pop();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.logoColor
                          : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        )
                      : null,
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anuluj'),
          ),
        ],
      ),
    );
  }

  List<Color> _getAvailableColors() {
    if (widget.presetColors.isNotEmpty) {
      return widget.presetColors;
    }
    return _defaultColors;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _showColorPicker,
          onTapDown: (_) => _animationController.forward(),
          onTapUp: (_) => _animationController.reverse(),
          onTapCancel: () => _animationController.reverse(),
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: double.infinity,
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.accentColor.withOpacity(0.5),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.logoColor.withOpacity(0.1),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Podgląd koloru
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: widget.selectedColor ?? Colors.grey,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.textHint,
                            width: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Tekst
                      Expanded(
                        child: Text(
                          widget.selectedColor != null
                              ? _getColorName(widget.selectedColor!)
                              : 'Dotknij aby wybrać kolor',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: widget.selectedColor != null
                                ? AppTheme.textPrimary
                                : AppTheme.textHint,
                          ),
                        ),
                      ),
                      
                      // Ikona
                      Icon(
                        Icons.palette,
                        color: AppTheme.logoColor,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _getColorName(Color color) {
    if (color == Colors.red) return 'Czerwony';
    if (color == Colors.pink) return 'Różowy';
    if (color == Colors.purple) return 'Fioletowy';
    if (color == Colors.deepPurple) return 'Ciemnofioletowy';
    if (color == Colors.indigo) return 'Indygo';
    if (color == Colors.blue) return 'Niebieski';
    if (color == Colors.lightBlue) return 'Jasnoniebieski';
    if (color == Colors.cyan) return 'Cyjan';
    if (color == Colors.teal) return 'Morski';
    if (color == Colors.green) return 'Zielony';
    if (color == Colors.lightGreen) return 'Jasnozielony';
    if (color == Colors.lime) return 'Limonkowy';
    if (color == Colors.yellow) return 'Żółty';
    if (color == Colors.amber) return 'Bursztynowy';
    if (color == Colors.orange) return 'Pomarańczowy';
    if (color == Colors.deepOrange) return 'Ciemnopomarańczowy';
    if (color == Colors.brown) return 'Brązowy';
    if (color == Colors.grey) return 'Szary';
    if (color == Colors.blueGrey) return 'Niebieskowszary';
    if (color == Colors.black) return 'Czarny';
    if (color == Colors.white) return 'Biały';
    return 'Kolor #${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }
} 