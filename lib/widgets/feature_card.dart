import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../utils/app_theme.dart';

class FeatureCard extends StatefulWidget {
  final FeatureCardData data;
  final VoidCallback onTap;

  const FeatureCard({
    super.key,
    required this.data,
    required this.onTap,
  });

  @override
  State<FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<FeatureCard>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _hoverController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _borderAnimation;

  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startPulseAnimation();
  }

  void _initAnimations() {
    // Animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Animation hover
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));

    _borderAnimation = Tween<double>(
      begin: 2.0,
      end: 4.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));
  }

  void _startPulseAnimation() {
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _hoverController.dispose();
    super.dispose();
  }

  void _onHover(bool hover) {
    setState(() {
      _isHovered = hover;
    });

    if (hover) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: GestureDetector(
        onTap: () {
          print('DEBUG: FeatureCard onTap called for ${widget.data.title}');
          widget.onTap();
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([_pulseController, _hoverController]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: widget.data.color.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: _isHovered ? 2 : 0,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.data.color.withOpacity(0.8),
                        widget.data.color.withOpacity(0.6),
                        AppTheme.cardColor.withOpacity(0.9),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: widget.data.color.withOpacity(
                        0.3 + (_pulseAnimation.value * 0.4),
                      ),
                      width: _borderAnimation.value,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(
                      children: [
                        // Gradient overlay
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.3),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // main
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  widget.data.icon,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),

                              const SizedBox(height: 24),

                              // title
                              Text(
                                widget.data.title,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 8),

                              Text(
                                widget.data.subtitle,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: widget.data.color.withOpacity(0.8),
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 16),

                              // description
                              Expanded(
                                child: Text(
                                  widget.data.description,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                              const SizedBox(height: 16),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: widget.data.isImplemented
                                      ? Colors.green.withOpacity(0.2)
                                      : Colors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: widget.data.isImplemented
                                        ? Colors.green.withOpacity(0.5)
                                        : Colors.orange.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      widget.data.isImplemented
                                          ? Icons.check_circle_outline
                                          : Icons.access_time,
                                      size: 16,
                                      color: widget.data.isImplemented
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      widget.data.isImplemented
                                          ? 'Dostępne'
                                          : 'Wkrótce',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: widget.data.isImplemented
                                            ? Colors.green
                                            : Colors.orange,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: widget.onTap,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: widget.data.isImplemented
                                        ? widget.data.color
                                        : AppTheme.textHint,
                                    foregroundColor: AppTheme.textPrimary,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: _isHovered ? 8 : 4,
                                  ),
                                  child: Text(
                                    widget.data.isImplemented ? 'Rozpocznij' : 'Wkrótce',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (widget.data.isImplemented)
                          Positioned(
                            top: 20,
                            right: 20,
                            child: AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(
                                      0.3 + (_pulseAnimation.value * 0.7),
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(
                                          _pulseAnimation.value * 0.5,
                                        ),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
} 