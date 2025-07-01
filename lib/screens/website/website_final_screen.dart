import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../providers/website_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/website_design.dart';
import '../../utils/app_theme.dart';

class WebsiteFinalScreen extends StatefulWidget {
  const WebsiteFinalScreen({super.key});

  @override
  State<WebsiteFinalScreen> createState() => _WebsiteFinalScreenState();
}

class _WebsiteFinalScreenState extends State<WebsiteFinalScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isGenerating = false;
  bool _generationComplete = false;
  bool _isCreatingPreview = false;
  String? _previewUrl;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
    _generateWebsite();
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

  Future<void> _generateWebsite() async {
    setState(() {
      _isGenerating = true;
    });

    final websiteProvider = Provider.of<WebsiteProvider>(context, listen: false);
    
    final success = await websiteProvider.generateWebsite();
    
    setState(() {
      _isGenerating = false;
      _generationComplete = success;
    });

    if (!success && mounted) {
      _showErrorSnackBar(websiteProvider.errorMessage ?? 'Błąd generowania strony');
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _copyToClipboard(String text, String type) async {
    await Clipboard.setData(ClipboardData(text: text));
    _showSuccessSnackBar('$type skopiowany do schowka');
  }

  void _goToHome() {
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }

  void _createNewWebsite() {
    Navigator.of(context).pushNamedAndRemoveUntil('/website-intro', (route) => route.settings.name == '/home');
  }

  Future<void> _createPreview() async {
    final websiteProvider = Provider.of<WebsiteProvider>(context, listen: false);
    final websiteDesign = websiteProvider.currentWebsiteDesign;
    
    if (websiteDesign?.htmlCode == null) {
      _showErrorSnackBar('Brak kodu HTML do podglądu');
      return;
    }

    setState(() {
      _isCreatingPreview = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorSnackBar('Musisz być zalogowany aby utworzyć podgląd');
        return;
      }

      final previewUrl = await _firestoreService.uploadWebsitePreview(
        websiteDesign!.htmlCode!,
        user.uid,
      );

      if (previewUrl != null) {
        setState(() {
          _previewUrl = previewUrl;
        });

        _showSuccessSnackBar('Podgląd strony utworzony! Kliknij "Otwórz podgląd" lub skopiuj link.');

      } else {
        _showErrorSnackBar('Nie udało się utworzyć podglądu strony');
      }
    } catch (e) {
      _showErrorSnackBar('Błąd podczas tworzenia podglądu: $e');
    } finally {
      setState(() {
        _isCreatingPreview = false;
      });
    }
  }

  Future<void> _openPreviewInBrowser(String url) async {
    try {
      print('Próba otwarcia URL: $url');
      final uri = Uri.parse(url);

      if (uri.scheme.isEmpty || (!uri.scheme.startsWith('http'))) {
        throw Exception('Nieprawidłowy URL: $url');
      }
      
      print('Sprawdzanie czy można uruchomić URL...');
      final canLaunch = await canLaunchUrl(uri);
      print('canLaunchUrl wynik: $canLaunch');
      
      if (canLaunch) {
        print('Próba uruchomienia w trybie external...');
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        
        if (!launched) {
          print('Nie udało się uruchomić w trybie external, próba platformDefault...');
          final launchedDefault = await launchUrl(
            uri,
            mode: LaunchMode.platformDefault,
          );
          
          if (!launchedDefault) {
            print('Nie udało się uruchomić w żadnym trybie, próba inAppWebView...');
            await launchUrl(
              uri,
              mode: LaunchMode.inAppWebView,
            );
          }
        }
        
        print('URL został uruchomiony pomyślnie');
      } else {
        throw Exception('Nie można uruchomić URL - brak obsługujących aplikacji');
      }
    } catch (e) {
      print('BŁĄD podczas otwierania przeglądarki: $e');

      if (mounted) {
        _showErrorDialog(
          'Nie udało się otworzyć przeglądarki',
          'Szczegóły błędu: $e\n\n'
          'URL: $url\n\n'
          'Możesz skopiować kod HTML i otworzyć go ręcznie w przeglądarce.',
        );
      }
    }
  }

  void _showErrorDialog(String title, String message) {
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
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _openExistingPreview() async {
    if (_previewUrl != null) {
      await _openPreviewInBrowser(_previewUrl!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final websiteProvider = Provider.of<WebsiteProvider>(context);
    final websiteDesign = websiteProvider.currentWebsiteDesign;

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
                            'Twoja strona internetowa',
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          onPressed: _goToHome,
                          icon: const Icon(
                            Icons.home_outlined,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // main
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          if (_isGenerating) ...[
                            AnimationConfiguration.staggeredList(
                              position: 0,
                              child: SlideAnimation(
                                verticalOffset: 30,
                                child: FadeInAnimation(
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          color: AppTheme.websiteColor.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(30),
                                          border: Border.all(
                                            color: AppTheme.websiteColor.withOpacity(0.5),
                                            width: 2,
                                          ),
                                        ),
                                        child: Center(
                                          child: LoadingAnimationWidget.threeArchedCircle(
                                            color: AppTheme.websiteColor,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 32),
                                      Text(
                                        'Tworzę stronę internetową...',
                                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Projektuję profesjonalną stronę internetową na podstawie podanych przez Ciebie informacji. To może potrwać chwilę...',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: AppTheme.textSecondary,
                                          height: 1.4,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ] else if (_generationComplete && websiteDesign != null) ...[
                            // results
                            AnimationConfiguration.staggeredList(
                              position: 0,
                              child: SlideAnimation(
                                verticalOffset: 30,
                                child: FadeInAnimation(
                                  child: Column(
                                    children: [
                                      // icon
                                      Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(25),
                                          border: Border.all(
                                            color: Colors.green.withOpacity(0.5),
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.check_circle_outline,
                                          size: 50,
                                          color: Colors.green,
                                        ),
                                      ),
                                      const SizedBox(height: 32),
                                      Text(
                                        'Strona internetowa wygenerowana!',
                                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                          color: AppTheme.textPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Twoja profesjonalna strona internetowa dla "${websiteDesign.companyName}" jest gotowa. Możesz skopiować kod i opublikować ją na swoim serwerze.',
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: AppTheme.textSecondary,
                                          height: 1.6,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 40),

                            // summarize
                            AnimationConfiguration.staggeredList(
                              position: 1,
                              child: SlideAnimation(
                                verticalOffset: 30,
                                child: FadeInAnimation(
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: AppTheme.cardColor.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(16),
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
                                              Icons.summarize_outlined,
                                              color: AppTheme.websiteColor,
                                              size: 24,
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Podsumowanie projektu',
                                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                color: AppTheme.textPrimary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        
                                        _buildSummaryItem('Nazwa firmy', websiteDesign.companyName ?? ''),
                                        if (websiteDesign.selectedSections != null && websiteDesign.selectedSections!.isNotEmpty)
                                          _buildSummaryItem('Sekcje', websiteDesign.selectedSections!.join(', ')),
                                        if (websiteDesign.websiteStyle != null)
                                          _buildSummaryItem('Styl', websiteDesign.websiteStyle!),
                                        if (websiteDesign.textColor != null && websiteDesign.backgroundColor != null)
                                          _buildColorSummary(websiteDesign),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),

                            if (websiteDesign.htmlCode != null) ...[
                              AnimationConfiguration.staggeredList(
                                position: 2,
                                child: SlideAnimation(
                                  verticalOffset: 30,
                                  child: FadeInAnimation(
                                    child: Column(
                                      children: [
                                        // Kod HTML
                                        _buildCodeSection(
                                          'Kod HTML',
                                          websiteDesign.htmlCode!,
                                          Icons.code_outlined,
                                        ),
                                        
                                        const SizedBox(height: 20),
                                        
                                        // Kod CSS (jeśli oddzielny)
                                        if (websiteDesign.cssCode != null && websiteDesign.cssCode!.isNotEmpty)
                                          _buildCodeSection(
                                            'Kod CSS',
                                            websiteDesign.cssCode!,
                                            Icons.style_outlined,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 32),
                            ],

                            AnimationConfiguration.staggeredList(
                              position: 3,
                              child: SlideAnimation(
                                verticalOffset: 30,
                                child: FadeInAnimation(
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: AppTheme.websiteColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
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
                                              Icons.info_outline,
                                              color: AppTheme.websiteColor,
                                              size: 24,
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Jak korzystać ze strony?',
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                color: AppTheme.textPrimary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          '• Kliknij "Podgląd strony" aby zobaczyć stronę w przeglądarce\n'
                                          '• Link podglądu wygasa automatycznie po 15 minutach\n'
                                          '• Skopiuj kod HTML i zapisz jako plik index.html\n'
                                          '• Jeśli masz oddzielny CSS, zapisz go jako styles.css\n'
                                          '• Wgraj pliki na swój serwer WWW lub hosting\n'
                                          '• Twoja strona będzie dostępna pod adresem domeny',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: AppTheme.textSecondary,
                                            height: 1.6,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            AnimationConfiguration.staggeredList(
                              position: 0,
                              child: SlideAnimation(
                                verticalOffset: 30,
                                child: FadeInAnimation(
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(25),
                                          border: Border.all(
                                            color: Colors.red.withOpacity(0.5),
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.error_outline,
                                          size: 50,
                                          color: Colors.red,
                                        ),
                                      ),
                                      const SizedBox(height: 32),
                                      Text(
                                        'Wystąpił błąd',
                                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                          color: AppTheme.textPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Nie udało się wygenerować strony internetowej. Spróbuj ponownie lub skontaktuj się z obsługą.',
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: AppTheme.textSecondary,
                                          height: 1.6,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // button
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        if (_generationComplete && websiteDesign != null) ...[
                          // Przycisk podgląd strony
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: _isCreatingPreview ? null : (_previewUrl != null ? _openExistingPreview : _createPreview),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.websiteColor.withOpacity(0.9),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 6,
                              ),
                              icon: _isCreatingPreview 
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: LoadingAnimationWidget.threeArchedCircle(
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    )
                                  : Icon(
                                      _previewUrl != null ? Icons.open_in_browser : Icons.preview,
                                      color: Colors.white,
                                    ),
                              label: Text(
                                _isCreatingPreview 
                                    ? 'Tworzenie podglądu...' 
                                    : (_previewUrl != null ? 'Otwórz podgląd' : 'Podgląd strony'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          if (_previewUrl != null)
                            Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _copyToClipboard(_previewUrl!, 'Link podglądu'),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: AppTheme.websiteColor.withOpacity(0.7)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.copy,
                                      color: AppTheme.textPrimary,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'Kopiuj link podglądu',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Link wygasa za 15 minut',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textHint,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),

                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _createNewWebsite,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.websiteColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 8,
                              ),
                              child: const Text(
                                'Stwórz nową stronę',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ] else if (!_isGenerating) ...[
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _generateWebsite,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.websiteColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 8,
                              ),
                              child: const Text(
                                'Spróbuj ponownie',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton(
                            onPressed: _goToHome,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.accentColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Powrót do strony głównej',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildSummaryItem(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSummary(WebsiteDesign websiteDesign) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              'Kolory:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: websiteDesign.textColor,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.textSecondary),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: websiteDesign.backgroundColor,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.textSecondary),
                  ),
                ),
                if (websiteDesign.additionalColors != null && websiteDesign.additionalColors!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  ...websiteDesign.additionalColors!.map((color) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.textSecondary),
                      ),
                    ),
                  )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeSection(String title, String code, IconData icon) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.websiteColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _copyToClipboard(code, title),
                  icon: const Icon(
                    Icons.copy_outlined,
                    color: AppTheme.websiteColor,
                    size: 20,
                  ),
                  tooltip: 'Skopiuj kod',
                ),
              ],
            ),
          ),

          Container(
            width: double.infinity,
            height: 120,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.accentColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: SingleChildScrollView(
              child: Text(
                code.length > 500 ? '${code.substring(0, 500)}...' : code,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 