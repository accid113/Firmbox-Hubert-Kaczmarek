import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:printing/printing.dart';
import 'package:universal_io/io.dart';

import '../../providers/business_idea_provider.dart';
import '../../utils/app_theme.dart';

class FinalScreen extends StatefulWidget {
  const FinalScreen({super.key});

  @override
  State<FinalScreen> createState() => _FinalScreenState();
}

class _FinalScreenState extends State<FinalScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _animationController;
  late AnimationController _successController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

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

    _successController = AnimationController(
      duration: const Duration(milliseconds: 2000),
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

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    ));
  }

  void _startAnimations() {
    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _successController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _successController.dispose();
    super.dispose();
  }

  Future<void> _downloadPdf() async {
    final provider = Provider.of<BusinessIdeaProvider>(context, listen: false);
    
    if (!provider.isBusinessIdeaComplete || provider.currentBusinessIdea == null) {
      _showErrorSnackBar('Brakuje wymaganych danych do generowania PDF');
      return;
    }

    try {
      final businessIdea = provider.currentBusinessIdea!;
      
      print('Pobieranie PDF dla biznesplanu: ${businessIdea.companyName}');
      
      if (businessIdea.pdfUrl != null && businessIdea.pdfUrl!.isNotEmpty) {
        print('PDF już istnieje: ${businessIdea.pdfUrl}');
        
        // Na web - regeneruj i wyświetl
        if (!Platform.isAndroid && !Platform.isIOS) {
          await provider.downloadPDF();
          if (mounted) {
            _showSuccessSnackBar('PDF wyświetlony w przeglądarce');
          }
          return;
        }

        if (businessIdea.pdfUrl!.startsWith('PDF zapisany w: ')) {
          final path = businessIdea.pdfUrl!.replaceFirst('PDF zapisany w: ', '');
          final file = File(path);
          
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            await Printing.layoutPdf(
              onLayout: (format) async => bytes,
              name: 'Biznesplan-${businessIdea.companyName?.replaceAll(' ', '-')}.pdf',
            );
            if (mounted) {
              _showSuccessSnackBar('PDF otwarty');
            }
            return;
          }
        }
      }
      
      print('Generowanie nowego PDF...');
      await provider.downloadPDF();
      
      if (mounted) {
        _showSuccessSnackBar('PDF wygenerowany i otwarty');
      }
      
    } catch (e) {
      print('Błąd pobierania PDF: $e');
      if (mounted) {
        _showErrorSnackBar('Błąd podczas generowania PDF: $e');
      }
    }
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

  void _goToHome() {
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BusinessIdeaProvider>(context);
    final businessIdea = provider.currentBusinessIdea?.idea ?? '';
    final companyName = provider.currentBusinessIdea?.companyName ?? '';

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
                            'Gotowe!',
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
                    child: AnimationLimiter(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),

                            AnimationConfiguration.staggeredList(
                              position: 0,
                              child: SlideAnimation(
                                verticalOffset: 30,
                                child: FadeInAnimation(
                                  child: Column(
                                    children: [
                                      // icon
                                      AnimatedBuilder(
                                        animation: _scaleAnimation,
                                        builder: (context, child) {
                                          return Transform.scale(
                                            scale: _scaleAnimation.value,
                                            child: Container(
                                              width: 100,
                                              height: 100,
                                              decoration: BoxDecoration(
                                                color: AppTheme.businessIdeaColor.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(25),
                                                border: Border.all(
                                                  color: AppTheme.businessIdeaColor.withOpacity(0.5),
                                                  width: 2,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.check_circle_outline,
                                                size: 50,
                                                color: AppTheme.businessIdeaColor,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      
                                      const SizedBox(height: 24),
                                      
                                      Text(
                                        'Gratulacje!',
                                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 12),
                                      
                                      Text(
                                        'Twój kompletny biznesplan jest gotowy',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: AppTheme.textSecondary,
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
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: AppTheme.cardColor.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.green.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.business_outlined,
                                              color: AppTheme.businessCardColor,
                                              size: 24,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                companyName,
                                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                  color: AppTheme.textPrimary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        
                                        const SizedBox(height: 16),
                                        
                                        Column(
                                          children: [
                                            _buildCompletedItem(
                                              Icons.lightbulb,
                                              'Pomysł na biznes',
                                              businessIdea.length > 50 
                                                ? '${businessIdea.substring(0, 50)}...'
                                                : businessIdea,
                                            ),
                                            const SizedBox(height: 12),
                                            _buildCompletedItem(
                                              Icons.business,
                                              'Nazwa firmy',
                                              companyName,
                                            ),
                                            const SizedBox(height: 12),
                                            _buildCompletedItem(
                                              Icons.analytics,
                                              'Analiza konkurencji',
                                              'Przegląd głównych konkurentów i możliwości',
                                            ),
                                            const SizedBox(height: 12),
                                            _buildCompletedItem(
                                              Icons.description,
                                              'Biznesplan',
                                              'Kompletny plan rozwoju firmy',
                                            ),
                                            const SizedBox(height: 12),
                                            _buildCompletedItem(
                                              Icons.campaign,
                                              'Plan marketingowy',
                                              'Strategia promocji i dotarcia do klientów',
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),

                            // pdf
                            AnimationConfiguration.staggeredList(
                              position: 2,
                              child: SlideAnimation(
                                verticalOffset: 30,
                                child: FadeInAnimation(
                                  child: Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          AppTheme.logoColor.withOpacity(0.2),
                                          AppTheme.logoColor.withOpacity(0.1),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: AppTheme.logoColor.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.picture_as_pdf,
                                              color: AppTheme.logoColor,
                                              size: 32,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Raport PDF',
                                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                      color: AppTheme.textPrimary,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Pobierz kompletny biznesplan w formacie PDF',
                                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                      color: AppTheme.textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        
                                        const SizedBox(height: 24),
                                        
                                        Text(
                                          'Wygeneruj i pobierz profesjonalny raport PDF zawierający wszystkie elementy Twojego biznesplanu.',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: AppTheme.textSecondary,
                                            height: 1.4,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        
                                        const SizedBox(height: 20),
                                        
                                        Consumer<BusinessIdeaProvider>(
                                          builder: (context, provider, child) {
                                            return SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton.icon(
                                                onPressed: provider.isLoading ? null : _downloadPdf,
                                                icon: provider.isLoading
                                                  ? LoadingAnimationWidget.threeArchedCircle(
                                                      color: AppTheme.textPrimary,
                                                      size: 24,
                                                    )
                                                  : Icon(
                                                      Icons.picture_as_pdf,
                                                      color: AppTheme.textPrimary,
                                                    ),
                                                label: Text(
                                                  provider.isLoading ? 'Generowanie PDF...' : 'Wygeneruj i pobierz PDF',
                                                  style: TextStyle(color: AppTheme.textPrimary),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppTheme.businessIdeaColor,
                                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                                ),
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

                            const SizedBox(height: 40),
                            
                            AnimationConfiguration.staggeredList(
                              position: 3,
                              child: SlideAnimation(
                                verticalOffset: 50,
                                child: FadeInAnimation(
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        width: double.infinity,
                                        height: 56,
                                        child: ElevatedButton.icon(
                                          onPressed: _goToHome,
                                          icon: const Icon(
                                            Icons.home,
                                            color: AppTheme.textPrimary,
                                          ),
                                          label: Text(
                                            'Powrót do głównej',
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              color: AppTheme.textPrimary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.businessIdeaColor,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                          ),
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 12),
                                      
                                      Text(
                                        'Pamiętaj, że niepobrane pliki się niezapisują',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 24), // Bottom padding
                          ],
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

  Widget _buildCompletedItem(IconData icon, String title, String description) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            color: Colors.green,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 20,
        ),
      ],
    );
  }
} 