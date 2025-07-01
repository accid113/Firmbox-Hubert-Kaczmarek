import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:universal_io/io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';

import '../../providers/logo_provider.dart';
import '../../utils/app_theme.dart';

class LogoFinalScreen extends StatefulWidget {
  const LogoFinalScreen({super.key});

  @override
  State<LogoFinalScreen> createState() => _LogoFinalScreenState();
}

class _LogoFinalScreenState extends State<LogoFinalScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();

  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
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

  Future<void> _generateLogo() async {
    setState(() {
      _isGenerating = true;
    });

    final logoProvider = Provider.of<LogoProvider>(context, listen: false);
    final success = await logoProvider.generateLogo();

    setState(() {
      _isGenerating = false;
    });

    if (!success && mounted) {
      _showErrorSnackBar(logoProvider.errorMessage ?? 'Błąd generowania logo');
    }
  }

  Future<void> _regenerateLogo() async {
    setState(() {
      _isGenerating = true;
    });

    final logoProvider = Provider.of<LogoProvider>(context, listen: false);
    final success = await logoProvider.regenerateLogo();

    setState(() {
      _isGenerating = false;
    });

    if (!success && mounted) {
      _showErrorSnackBar(logoProvider.errorMessage ?? 'Błąd regenerowania logo');
    }
  }

  Future<void> _downloadLogo() async {
    final logoProvider = Provider.of<LogoProvider>(context, listen: false);
    final logoUrl = logoProvider.currentLogoDesign?.logoUrl;
    final companyName = logoProvider.currentLogoDesign?.companyName ?? 'logo';

    if (logoUrl == null) {
      _showErrorSnackBar('Brak URL logo');
      return;
    }

    try {
      if (kIsWeb) {
        final Uri url = Uri.parse(logoUrl);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          _showSuccessSnackBar('Logo otwarte w nowej karcie. Użyj prawego przycisku aby zapisać.');
        } else {
          _showErrorSnackBar('Nie można otworzyć logo');
        }
      } else {
        _showSuccessSnackBar('Rozpoczynam pobieranie logo...');
        
        final response = await http.get(Uri.parse(logoUrl));
        if (response.statusCode == 200) {
          final bytes = response.bodyBytes;
          
          if (Platform.isAndroid || Platform.isIOS) {
            await _saveMobileFile(bytes, companyName);
          } else {
            await _saveDesktopFile(bytes, companyName);
          }
        } else {
          _showErrorSnackBar('Błąd pobierania pliku: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Download error: $e');
      _showErrorSnackBar('Błąd pobierania logo: $e');
    }
  }

  Future<void> _saveMobileFile(Uint8List bytes, String companyName) async {
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final granted = await Gal.requestAccess();
        if (!granted) {
          _showErrorSnackBar('Brak uprawnień do zapisu w galerii. Włącz je w ustawieniach aplikacji.');
          return;
        }
      }

      final fileName = '${companyName.replaceAll(' ', '-')}-logo.png';
      
      if (Platform.isIOS) {
        try {
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/$fileName');
          await file.writeAsBytes(bytes);
          await Gal.putImage(file.path, album: 'FirmBox');
          
          _showSuccessSnackBar('Logo zapisane w aplikacji Zdjęcia!');
          Future.delayed(const Duration(seconds: 2), () {
            _showSuccessSnackBar('Znajdziesz je w albumie "FirmBox"');
          });
        } catch (e) {
          print('iOS Gal save error: $e');
          _showErrorSnackBar('Nie udało się zapisać logo. Sprawdź uprawnienia w ustawieniach.');
        }
      } else {
        try {
          await Gal.putImageBytes(bytes, name: fileName);
          _showSuccessSnackBar('Logo zapisane w galerii!');
           Future.delayed(const Duration(seconds: 2), () {
            _showSuccessSnackBar('Znajdziesz je w aplikacji Galeria');
          });
        } catch (e) {
          print('Android Gal save error: $e');
          await _saveToDownloadsFallback(bytes, companyName);
        }
      }
    } catch (e) {
      print('Mobile save error: $e');
      _showErrorSnackBar('Wystąpił nieoczekiwany błąd podczas zapisu: $e');
    }
  }

  Future<void> _saveToDownloadsFallback(Uint8List bytes, String companyName) async {
    try {
      final fileName = '${companyName.replaceAll(' ', '-')}-logo.png';

      final downloadsPaths = [
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Downloads', 
        '/sdcard/Download',
        '/sdcard/Downloads',
      ];
      
      File? savedFile;
      
      for (final path in downloadsPaths) {
        try {
          final directory = Directory(path);
          if (await directory.exists()) {
            final file = File('$path/$fileName');
            await file.writeAsBytes(bytes);
            savedFile = file;
            break;
          }
        } catch (e) {
          print('Cannot save to $path: $e');
          continue;
        }
      }
      
      if (savedFile != null) {
        _showSuccessSnackBar('Logo zapisane: ${savedFile.path}');
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(bytes);
        _showSuccessSnackBar('Logo zapisane w aplikacji: ${file.path}');
      }
    } catch (e) {
      print('Fallback save error: $e');
      _showErrorSnackBar('Błąd zapisywania w trybie fallback: $e');
    }
  }

  Future<void> _saveDesktopFile(Uint8List bytes, String companyName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${companyName.replaceAll(' ', '-')}-logo.png';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsBytes(bytes);
      _showSuccessSnackBar('Logo zapisane w: ${file.path}');

      try {
        if (Platform.isMacOS) {
          await Process.run('open', [directory.path]);
        } else if (Platform.isWindows) {
          await Process.run('explorer', [directory.path]);
        } else if (Platform.isLinux) {
          await Process.run('xdg-open', [directory.path]);
        }
      } catch (e) {
        print('Cannot open file directory: $e');
      }
    } catch (e) {
      print('Desktop save error: $e');
      _showErrorSnackBar('Błąd zapisywania na pulpicie: $e');
    }
  }

  Future<void> _openLogoInNewTab() async {
    final logoProvider = Provider.of<LogoProvider>(context, listen: false);
    final logoUrl = logoProvider.currentLogoDesign?.logoUrl;

    if (logoUrl != null) {
      try {
        final Uri url = Uri.parse(logoUrl);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          _showSuccessSnackBar('Logo otwarte w nowej karcie');
        } else {
          _showErrorSnackBar('Nie można otworzyć logo');
        }
      } catch (e) {
        _showErrorSnackBar('Błąd otwierania logo: $e');
      }
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

  void _goBackToHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final logoProvider = Provider.of<LogoProvider>(context);
    final logoDesign = logoProvider.currentLogoDesign;

    if (logoDesign != null && logoDesign.logoUrl == null && !_isGenerating && !logoProvider.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _generateLogo();
      });
    }

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
                          onPressed: _goBackToHome,
                          icon: const Icon(
                            Icons.home,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Twoje logo',
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),

                  // main
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const SizedBox(height: 40),

                          if (_isGenerating) ...[
                            // loading state
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
                                          color: AppTheme.logoColor.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(30),
                                          border: Border.all(
                                            color: AppTheme.logoColor.withOpacity(0.5),
                                            width: 2,
                                          ),
                                        ),
                                        child: LoadingAnimationWidget.threeArchedCircle(
                                          color: AppTheme.logoColor,
                                          size: 40,
                                        ),
                                      ),
                                      const SizedBox(height: 32),
                                      Text(
                                        'Tworzę unikalne logo...',
                                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          color: AppTheme.textPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Sztuczna inteligencja tworzy unikalne logo na podstawie Twoich preferencji.',
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: AppTheme.textSecondary,
                                          height: 1.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ] else if (logoDesign?.logoUrl != null) ...[
                            // logo generated successfully
                            AnimationConfiguration.staggeredList(
                              position: 0,
                              child: SlideAnimation(
                                verticalOffset: 30,
                                child: FadeInAnimation(
                                  child: Column(
                                    children: [
                                      // logo container
                                      Container(
                                        width: double.infinity,
                                        constraints: const BoxConstraints(
                                          maxWidth: 400,
                                          maxHeight: 400,
                                        ),
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppTheme.logoColor.withOpacity(0.3),
                                              blurRadius: 20,
                                              spreadRadius: 4,
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                                          child: kIsWeb 
                                            ? _buildWebImage(logoDesign!.logoUrl!)
                                            : _buildMobileImage(logoDesign!.logoUrl!),
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 32),
                                      
                                      Text(
                                        'Gratulacje!',
                                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          color: AppTheme.textPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      
                                      const SizedBox(height: 16),
                                      
                                      Text(
                                        'Twoje logo zostało wygenerowane dla firmy "${logoDesign.companyName}". Możesz je pobrać lub wygenerować nową wersję.',
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: AppTheme.textSecondary,
                                          height: 1.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            // Error state
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
                                          color: Colors.red.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(30),
                                          border: Border.all(
                                            color: Colors.red.withOpacity(0.5),
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.error_outline,
                                          size: 60,
                                          color: Colors.red,
                                        ),
                                      ),
                                      const SizedBox(height: 32),
                                      Text(
                                        'Wystąpił błąd',
                                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          color: AppTheme.textPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        logoProvider.errorMessage ?? 'Nie udało się wygenerować logo.',
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: AppTheme.textSecondary,
                                          height: 1.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 50),
                        ],
                      ),
                    ),
                  ),

                  // action buttons
                  if (!_isGenerating)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          if (logoDesign?.logoUrl != null) ...[
                            // download button
                            AnimationConfiguration.staggeredList(
                              position: 1,
                              child: SlideAnimation(
                                verticalOffset: 30,
                                child: FadeInAnimation(
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _downloadLogo,
                                      icon: const Icon(Icons.download),
                                      label: const Text(
                                        'Pobierz logo',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.logoColor,
                                        foregroundColor: AppTheme.textPrimary,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 4,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // regenerate button
                            AnimationConfiguration.staggeredList(
                              position: 2,
                              child: SlideAnimation(
                                verticalOffset: 30,
                                child: FadeInAnimation(
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: _regenerateLogo,
                                      icon: const Icon(Icons.refresh),
                                      label: const Text(
                                        'Wygeneruj ponownie',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.logoColor,
                                        side: BorderSide(color: AppTheme.logoColor, width: 2),
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),
                          ] else ...[
                            // retry button for error state
                            AnimationConfiguration.staggeredList(
                              position: 1,
                              child: SlideAnimation(
                                verticalOffset: 30,
                                child: FadeInAnimation(
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _generateLogo,
                                      icon: const Icon(Icons.refresh),
                                      label: const Text(
                                        'Spróbuj ponownie',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.logoColor,
                                        foregroundColor: AppTheme.textPrimary,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 4,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),
                          ],

                          // back to home button
                          AnimationConfiguration.staggeredList(
                            position: 3,
                            child: SlideAnimation(
                              verticalOffset: 30,
                              child: FadeInAnimation(
                                child: SizedBox(
                                  width: double.infinity,
                                  child: TextButton.icon(
                                    onPressed: _goBackToHome,
                                    icon: const Icon(Icons.home),
                                    label: const Text(
                                      'Powrót do menu',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppTheme.textSecondary,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                  ),
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

  Widget _buildWebImage(String logoUrl) {
    final proxyUrl = kIsWeb ? 'https://corsproxy.io/?${Uri.encodeComponent(logoUrl)}' : logoUrl;
    
    return FutureBuilder<http.Response>(
      future: http.get(Uri.parse(proxyUrl)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LoadingAnimationWidget.threeArchedCircle(
                    color: AppTheme.logoColor,
                    size: 40,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pobieram logo...',
                    style: TextStyle(
                      color: AppTheme.textHint,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.statusCode != 200) {
          print('Error loading image via proxy: ${snapshot.error}');
          return Image.network(
            logoUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.image_outlined,
                      size: 48,
                      color: AppTheme.textHint,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Logo wygenerowane!',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Kliknij "Pobierz logo" aby zobaczyć',
                      style: TextStyle(
                        color: AppTheme.textHint,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _openLogoInNewTab(),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text(
                        'Otwórz logo',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.logoColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }
        
        final imageBytes = snapshot.data!.bodyBytes;
        return Image.memory(
          imageBytes,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.image_outlined,
                    size: 48,
                    color: AppTheme.textHint,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Logo wygenerowane!',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Używaj "Pobierz logo" aby otworzyć w nowej karcie',
                    style: TextStyle(
                      color: AppTheme.textHint,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMobileImage(String logoUrl) {
    return Image.network(
      logoUrl,
      fit: BoxFit.contain,
      headers: const {
        'Access-Control-Allow-Origin': '*',
      },
      errorBuilder: (context, error, stackTrace) {
        print('Error loading logo image: $error');
        print('Logo URL: $logoUrl');
        return Container(
          height: 200,
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.image_outlined,
                size: 48,
                color: AppTheme.textHint,
              ),
              const SizedBox(height: 16),
              const Text(
                'Logo wygenerowane!',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Kliknij "Pobierz logo" aby zobaczyć',
                style: TextStyle(
                  color: AppTheme.textHint,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _openLogoInNewTab(),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text(
                  'Otwórz logo',
                  style: TextStyle(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.logoColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                ),
              ),
            ],
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LoadingAnimationWidget.threeArchedCircle(
                  color: AppTheme.logoColor,
                  size: 40,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pobieram logo...',
                  style: TextStyle(
                    color: AppTheme.textHint,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 