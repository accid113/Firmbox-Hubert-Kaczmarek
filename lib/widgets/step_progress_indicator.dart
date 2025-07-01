import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class StepProgressIndicator extends StatelessWidget {
  final int totalSteps;
  final int currentStep;
  final Color activeColor;
  final Color inactiveColor;
  final double height;
  final double spacing;

  const StepProgressIndicator({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    required this.activeColor,
    this.inactiveColor = AppTheme.accentColor,
    this.height = 4.0,
    this.spacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(totalSteps, (index) {
          final isActive = index < currentStep;
          return [
            Expanded(
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  color: isActive ? activeColor : inactiveColor,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
            ),
            if (index < totalSteps - 1) SizedBox(width: spacing),
          ];
        }).expand((element) => element).toList(),
      ),
    );
  }
} 