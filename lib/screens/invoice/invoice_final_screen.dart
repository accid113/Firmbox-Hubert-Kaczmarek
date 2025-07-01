import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:universal_io/io.dart';
import 'package:printing/printing.dart';

import '../../providers/invoice_provider.dart';
import '../../utils/app_theme.dart';

class InvoiceFinalScreen extends StatefulWidget {
  const InvoiceFinalScreen({super.key});

  @override
  State<InvoiceFinalScreen> createState() => _InvoiceFinalScreenState();
}

class _InvoiceFinalScreenState extends State<InvoiceFinalScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  bool _isGenerating = false;
  String? _pdfUrl;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateInvoicePDF();
    });
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
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

  Future<void> _generateInvoicePDF() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final invoiceProvider = Provider.of<InvoiceProvider>(context, listen: false);
      final success = await invoiceProvider.generateInvoicePDF();
      
      if (success && mounted) {
        setState(() {
          _pdfUrl = invoiceProvider.currentInvoice?.pdfUrl;
          _isGenerating = false;
        });
      } else if (mounted) {
        setState(() {
          _isGenerating = false;
        });
        _showErrorSnackBar(invoiceProvider.errorMessage ?? 'Błąd generowania PDF');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
        _showErrorSnackBar('Błąd generowania PDF: $e');
      }
    }
  }

  Future<void> _downloadPdf() async {
    if (_pdfUrl == null) {
      _showErrorSnackBar('Brak PDF do pobrania');
      return;
    }

    try {
      // Na web - otwórz w przeglądarce
      if (!Platform.isAndroid && !Platform.isIOS) {
        // Regeneruj PDF i wyświetl w przeglądarce
        await _generateInvoicePDF();
        return;
      }

      // Na mobile - parsuj ścieżkę i otwórz przez Printing
      if (_pdfUrl!.startsWith('PDF zapisany w: ')) {
        final path = _pdfUrl!.replaceFirst('PDF zapisany w: ', '');
        final file = File(path);
        
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          await Printing.layoutPdf(
            onLayout: (format) async => bytes,
            name: 'Faktura.pdf',
          );
        } else {
          _showErrorSnackBar('Plik PDF nie został znaleziony');
        }
      } else {
        _showErrorSnackBar('Nieprawidłowy format URL PDF');
      }
    } catch (e) {
      _showErrorSnackBar('Błąd otwierania PDF: $e');
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

  void _goToHome() {
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }

  void _createNewInvoice() {
    Navigator.of(context).pushNamedAndRemoveUntil('/invoice-intro', (route) => route.settings.name == '/home');
  }

  @override
  Widget build(BuildContext context) {
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
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: _goToHome,
                            icon: const Icon(
                              Icons.close,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Faktura gotowa!',
                              style: Theme.of(context).textTheme.titleLarge,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),

                    // progress indicator
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppTheme.invoiceColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppTheme.invoiceColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppTheme.invoiceColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppTheme.invoiceColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppTheme.invoiceColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // main
                    Expanded(
                      child: AnimationLimiter(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              const SizedBox(height: 40),

                              // Ikona sukcesu lub loading
                              AnimationConfiguration.staggeredList(
                                position: 0,
                                child: SlideAnimation(
                                  verticalOffset: 30,
                                  child: FadeInAnimation(
                                    child: Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: _isGenerating
                                            ? [
                                                AppTheme.invoiceColor.withOpacity(0.3),
                                                AppTheme.invoiceColor.withOpacity(0.1),
                                              ]
                                            : [
                                                AppTheme.invoiceColor,
                                                AppTheme.invoiceColor.withOpacity(0.7),
                                              ],
                                        ),
                                        borderRadius: BorderRadius.circular(30),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.invoiceColor.withOpacity(0.4),
                                            blurRadius: 20,
                                            spreadRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: _isGenerating
                                        ? LoadingAnimationWidget.threeArchedCircle(
                                            color: AppTheme.invoiceColor,
                                            size: 40,
                                          )
                                        : const Icon(
                                            Icons.check_circle,
                                            size: 60,
                                            color: Colors.white,
                                          ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 40),

                              // title
                              AnimationConfiguration.staggeredList(
                                position: 1,
                                child: SlideAnimation(
                                  verticalOffset: 30,
                                  child: FadeInAnimation(
                                    child: Column(
                                      children: [
                                        Text(
                                          _isGenerating ? 'Tworzę fakturę...' : 'Faktura została utworzona!',
                                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textPrimary,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        
                                        const SizedBox(height: 16),
                                        
                                        Text(
                                          _isGenerating 
                                            ? 'Generuję profesjonalną fakturę w formacie PDF...'
                                            : 'Twoja faktura została pomyślnie wygenerowana i jest gotowa do pobrania',
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

                              const SizedBox(height: 50),

                              // summarize
                              if (!_isGenerating)
                                Consumer<InvoiceProvider>(
                                  builder: (context, invoiceProvider, child) {
                                    final invoice = invoiceProvider.currentInvoice;
                                    if (invoice == null) return const SizedBox.shrink();
                                    
                                    return AnimationConfiguration.staggeredList(
                                      position: 2,
                                      child: SlideAnimation(
                                        verticalOffset: 30,
                                        child: FadeInAnimation(
                                          child: Container(
                                            padding: const EdgeInsets.all(24),
                                            decoration: BoxDecoration(
                                              color: AppTheme.cardColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: AppTheme.invoiceColor.withOpacity(0.2),
                                                width: 1,
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                Text(
                                                  'Nr faktury: ${invoice.invoiceNumber}',
                                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                    color: AppTheme.invoiceColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                
                                                const SizedBox(height: 20),
                                                
                                                _buildSummaryRow('Sprzedawca:', invoice.sellerName),
                                                const SizedBox(height: 12),
                                                _buildSummaryRow('Nabywca:', invoice.buyerName),
                                                const SizedBox(height: 12),
                                                _buildSummaryRow('Pozycji:', '${invoice.items.length}'),
                                                
                                                const Divider(height: 32),
                                                
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      'WARTOŚĆ FAKTURY:',
                                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                        color: AppTheme.textPrimary,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                      '${invoice.totalGross.toStringAsFixed(2)} zł',
                                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                        color: AppTheme.invoiceColor,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),

                              const SizedBox(height: 60),

                              if (!_isGenerating) ...[
                                AnimationConfiguration.staggeredList(
                                  position: 3,
                                  child: SlideAnimation(
                                    verticalOffset: 50,
                                    child: FadeInAnimation(
                                      child: Column(
                                        children: [
                                          // donload pdf
                                          SizedBox(
                                            width: double.infinity,
                                            height: 56,
                                            child: ElevatedButton.icon(
                                              onPressed: _downloadPdf,
                                              icon: const Icon(
                                                Icons.download,
                                                color: AppTheme.textPrimary,
                                              ),
                                              label: Text(
                                                'Pobierz fakturę PDF',
                                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  color: AppTheme.textPrimary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppTheme.invoiceColor,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                              ),
                                            ),
                                          ),
                                          
                                          const SizedBox(height: 16),
                                          
                                          // new invoice
                                          SizedBox(
                                            width: double.infinity,
                                            height: 56,
                                            child: OutlinedButton.icon(
                                              onPressed: _createNewInvoice,
                                              icon: const Icon(
                                                Icons.add,
                                                color: AppTheme.invoiceColor,
                                              ),
                                              label: Text(
                                                'Wystaw nową fakturę',
                                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  color: AppTheme.invoiceColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                side: const BorderSide(color: AppTheme.invoiceColor),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                              ),
                                            ),
                                          ),
                                          
                                          const SizedBox(height: 16),
                                          
                                          TextButton.icon(
                                            onPressed: _goToHome,
                                            icon: const Icon(Icons.home, color: AppTheme.textSecondary),
                                            label: Text(
                                              'Powrót do menu głównego',
                                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
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
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
} 