import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:particles_flutter/particles_flutter.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late AnimationController _buttonAnimationController;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _buttonSlideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
    _checkAuthStatus();
  }

  void _initAnimations() {
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _logoFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _logoScaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
    ));

    _buttonSlideAnimation = Tween<double>(
      begin: 100.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeOutBack,
    ));
  }

  void _startAnimations() async {
    await _logoAnimationController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _buttonAnimationController.forward();
  }

  void _checkAuthStatus() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authProvider.isLoggedIn) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        });
      }
    });
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: Stack(
          children: [
            // particle
            Positioned.fill(
              child: CircularParticle(
                awayRadius: 80,
                numberOfParticles: 150,
                speedOfParticles: 1,
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                onTapAnimation: true,
                particleColor: AppTheme.businessIdeaColor.withOpacity(0.6),
                awayAnimationDuration: const Duration(seconds: 2),
                maxParticleSize: 8,
                isRandSize: true,
                isRandomColor: true,
                randColorList: [
                  AppTheme.businessIdeaColor.withOpacity(0.4),
                  AppTheme.businessCardColor.withOpacity(0.4),
                  AppTheme.logoColor.withOpacity(0.4),
                  AppTheme.websiteColor.withOpacity(0.4),
                  AppTheme.invoiceColor.withOpacity(0.4),
                ],
                awayAnimationCurve: Curves.easeInOutBack,
                enableHover: true,
                hoverRadius: 90,
                connectDots: false,
              ),
            ),
            
            // main
            SafeArea(
              child: AnimationLimiter(
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    
                    // logo
                    AnimatedBuilder(
                      animation: _logoAnimationController,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: _logoFadeAnimation,
                          child: ScaleTransition(
                            scale: _logoScaleAnimation,
                            child: Column(
                              children: [
                                // Logo placeholder
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppTheme.businessIdeaColor,
                                        AppTheme.businessCardColor,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.businessIdeaColor.withOpacity(0.4),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.business_center,
                                    size: 60,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                
                                const SizedBox(height: 24),
                                
                                // app name
                                Text(
                                  'FirmBox',
                                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                                
                                const SizedBox(height: 16),

                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 32),
                                  child: Text(
                                    'Twoja firma od pomysłu do realizacji',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: AppTheme.textSecondary,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const Spacer(flex: 3),
                    
                    // button
                    AnimatedBuilder(
                      animation: _buttonAnimationController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _buttonSlideAnimation.value),
                          child: FadeTransition(
                            opacity: _buttonAnimationController,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 48),
                              child: SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _navigateToLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.businessIdeaColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                    elevation: 8,
                                    shadowColor: AppTheme.businessIdeaColor.withOpacity(0.4),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Zaczynamy!',
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                        );
                      },
                    ),
                    
                    const Spacer(),
                    
                    // Copyright
                    AnimationConfiguration.staggeredList(
                      position: 0,
                      delay: const Duration(milliseconds: 2000),
                      child: SlideAnimation(
                        verticalOffset: 20,
                        child: FadeInAnimation(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 32),
                            child: Text(
                              '© 2025 FirmBox. Wszystkie prawa zastrzeżone.',
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 