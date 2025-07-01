import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLogin = true;
  bool _obscurePassword = true;
  
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
      begin: const Offset(0, 0.5),
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
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success = false;

    if (_isLogin) {
      success = await authProvider.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } else {
      success = await authProvider.registerWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }

    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else if (mounted) {
      _showErrorSnackBar(authProvider.errorMessage ?? 
        (_isLogin ? 'Nie udało się zalogować. Sprawdź swoje dane.' : 'Nie udało się utworzyć konta.'));
    }
  }

  Future<void> _signInWithGoogle() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await authProvider.signInWithGoogle();
    
    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else if (mounted && authProvider.errorMessage != null) {
      _showErrorSnackBar(authProvider.errorMessage!);
    }
  }

  Future<void> _signInWithApple() async {
    if (kIsWeb || !Platform.isIOS) {
      _showErrorSnackBar('Logowanie przez Apple ID jest dostępne tylko na urządzeniach iOS');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await authProvider.signInWithApple();
    
    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else if (mounted && authProvider.errorMessage != null) {
      _showErrorSnackBar(authProvider.errorMessage!);
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final TextEditingController emailController = TextEditingController();
    
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Reset hasła',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.textPrimary,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Wprowadź adres email, a wyślemy Ci link do resetowania hasła.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Wprowadź swój adres email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.businessIdeaColor),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Anuluj',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return ElevatedButton(
                  onPressed: authProvider.isLoading ? null : () async {
                    if (emailController.text.trim().isEmpty) {
                      _showErrorSnackBar('Wprowadź adres email');
                      return;
                    }
                    
                    final success = await authProvider.resetPassword(emailController.text.trim());
                    
                    if (mounted) {
                      Navigator.of(context).pop();
                      if (success) {
                        _showSuccessSnackBar('Link do resetowania hasła został wysłany na Twój email');
                      } else {
                        _showErrorSnackBar(authProvider.errorMessage ?? 'Nie udało się wysłać emaila');
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.businessIdeaColor,
                  ),
                  child: authProvider.isLoading
                    ? LoadingAnimationWidget.threeArchedCircle(
                        color: AppTheme.textPrimary,
                        size: 16,
                      )
                    : Text(
                        'Wyślij',
                        style: TextStyle(color: AppTheme.textPrimary),
                      ),
                );
              },
            ),
          ],
        );
      },
    );
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Wprowadź adres email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Wprowadź prawidłowy adres email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Wprowadź hasło';
    }
    if (value.length < 6) {
      return 'Hasło musi mieć co najmniej 6 znaków';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: AnimationLimiter(
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          
                          // Logo
                          AnimationConfiguration.staggeredList(
                            position: 0,
                            child: SlideAnimation(
                              verticalOffset: 30,
                              child: FadeInAnimation(
                                child: Column(
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppTheme.businessIdeaColor,
                                            AppTheme.businessCardColor,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Icon(
                                        Icons.business_center,
                                        size: 40,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      _isLogin ? 'Witaj ponownie!' : 'Dołącz do nas!',
                                      style: Theme.of(context).textTheme.headlineMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _isLogin 
                                        ? 'Zaloguj się do swojego konta'
                                        : 'Stwórz nowe konto',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 48),
                          
                          // login/register form
                          AnimationConfiguration.staggeredList(
                            position: 1,
                            child: SlideAnimation(
                              verticalOffset: 30,
                              child: FadeInAnimation(
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      CustomTextField(
                                        controller: _emailController,
                                        label: 'Adres email',
                                        hint: 'Wprowadź swój email',
                                        prefixIcon: Icons.email_outlined,
                                        keyboardType: TextInputType.emailAddress,
                                        validator: _validateEmail,
                                      ),
                                      
                                      const SizedBox(height: 16),
                                      
                                      CustomTextField(
                                        controller: _passwordController,
                                        label: 'Hasło',
                                        hint: 'Wprowadź swoje hasło',
                                        prefixIcon: Icons.lock_outline,
                                        obscureText: _obscurePassword,
                                        validator: _validatePassword,
                                        suffixIcon: IconButton(
                                          onPressed: _togglePasswordVisibility,
                                          icon: Icon(
                                            _obscurePassword 
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ),

                                      if (_isLogin) ...[
                                        const SizedBox(height: 8),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            onPressed: _showForgotPasswordDialog,
                                            child: Text(
                                              'Zapomniałeś hasła?',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: AppTheme.businessIdeaColor,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                      
                                      const SizedBox(height: 32),
                                      
                                      // login button
                                      Consumer<AuthProvider>(
                                        builder: (context, authProvider, child) {
                                          return SizedBox(
                                            width: double.infinity,
                                            height: 56,
                                            child: ElevatedButton(
                                              onPressed: authProvider.isLoading ? null : _submitForm,
                                              child: authProvider.isLoading
                                                ? LoadingAnimationWidget.threeArchedCircle(
                                                    color: AppTheme.textPrimary,
                                                    size: 24,
                                                  )
                                                : Text(_isLogin ? 'Zaloguj się' : 'Załóż konto'),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),

                          AnimationConfiguration.staggeredList(
                            position: 2,
                            child: SlideAnimation(
                              verticalOffset: 30,
                              child: FadeInAnimation(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _isLogin 
                                        ? 'Nie masz konta? '
                                        : 'Masz już konto? ',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                    TextButton(
                                      onPressed: _toggleAuthMode,
                                      child: Text(
                                        _isLogin ? 'Załóż konto' : 'Zaloguj się',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 32),

                          AnimationConfiguration.staggeredList(
                            position: 3,
                            child: SlideAnimation(
                              verticalOffset: 30,
                              child: FadeInAnimation(
                                child: Row(
                                  children: [
                                    const Expanded(child: Divider()),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        'lub',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ),
                                    const Expanded(child: Divider()),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // social media button
                          AnimationConfiguration.staggeredList(
                            position: 4,
                            child: SlideAnimation(
                              verticalOffset: 30,
                              child: FadeInAnimation(
                                child: Column(
                                  children: [
                                    const SizedBox(height: 32),
                                    Text(
                                      'zaloguj się przez',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                    const SizedBox(height: 24),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        _buildSocialButton(
                                          icon: Icons.android,
                                          onTap: _signInWithGoogle,
                                          label: 'Google',
                                          backgroundColor: Colors.white,
                                          textColor: Colors.black87,
                                        ),
                                        if (!kIsWeb && Platform.isIOS)
                                          const SizedBox(width: 24),
                                        if (!kIsWeb && Platform.isIOS)
                                          _buildSocialButton(
                                            icon: Icons.apple,
                                            onTap: _signInWithApple,
                                            label: 'Apple',
                                            backgroundColor: Colors.black,
                                            textColor: Colors.white,
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required VoidCallback onTap,
    required String label,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.accentColor,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: textColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 