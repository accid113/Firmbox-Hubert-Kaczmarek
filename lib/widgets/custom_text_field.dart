import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final bool enabled;
  final VoidCallback? onTap;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.maxLines = 1,
    this.enabled = true,
    this.onTap,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _focusAnimation;
  
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _focusAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
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

  void _onFocusChange(bool focused) {
    setState(() {
      _isFocused = focused;
    });
    
    if (focused) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _focusAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              if (_isFocused)
                BoxShadow(
                  color: AppTheme.businessIdeaColor.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Focus(
            onFocusChange: _onFocusChange,
            child: TextFormField(
              controller: widget.controller,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              validator: widget.validator,
              maxLines: widget.maxLines,
              enabled: widget.enabled,
              onTap: widget.onTap,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: InputDecoration(
                labelText: widget.label,
                hintText: widget.hint,
                prefixIcon: widget.prefixIcon != null
                    ? Icon(
                        widget.prefixIcon,
                        color: _isFocused 
                          ? AppTheme.businessIdeaColor 
                          : AppTheme.textSecondary,
                      )
                    : null,
                suffixIcon: widget.suffixIcon,
                filled: true,
                fillColor: AppTheme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.accentColor.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.businessIdeaColor,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.red,
                    width: 1,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.red,
                    width: 2,
                  ),
                ),
                labelStyle: TextStyle(
                  color: _isFocused 
                    ? AppTheme.businessIdeaColor 
                    : AppTheme.textSecondary,
                ),
                hintStyle: const TextStyle(
                  color: AppTheme.textHint,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: widget.prefixIcon != null ? 12 : 16,
                  vertical: widget.maxLines > 1 ? 16 : 16,
                ),
                errorStyle: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
} 