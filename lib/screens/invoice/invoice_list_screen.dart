import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:printing/printing.dart';
import 'package:universal_io/io.dart';

import '../../providers/invoice_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/invoice.dart';
import '../../utils/app_theme.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInvoices();
    });
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

  void _loadInvoices() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final invoiceProvider = Provider.of<InvoiceProvider>(context, listen: false);
    
    print('Ładowanie faktur w InvoiceListScreen');
    if (authProvider.user?.uid != null) {
      print('User ID: ${authProvider.user!.uid}');
      invoiceProvider.loadUserInvoices(authProvider.user!.uid);
    } else {
      print('Brak zalogowanego użytkownika');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  void _showInvoiceDetails(Invoice invoice) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: AppTheme.invoiceColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    invoice.invoiceNumber,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: AppTheme.textSecondary),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            _buildDetailRow('Sprzedawca:', invoice.sellerName),
            _buildDetailRow('Nabywca:', invoice.buyerName),
            _buildDetailRow('Data wystawienia:', _formatDate(invoice.issueDate)),
            _buildDetailRow('Data sprzedaży:', _formatDate(invoice.saleDate)),
            _buildDetailRow('Pozycji:', '${invoice.items.length}'),
            
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
            
            const SizedBox(height: 24),
            
            if (invoice.pdfUrl != null) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _downloadInvoicePdf(invoice);
                  },
                  icon: Icon(Icons.download),
                  label: Text('Pobierz PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.invoiceColor,
                    foregroundColor: AppTheme.textPrimary,
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _downloadInvoicePdf(invoice);
                  },
                  icon: Icon(Icons.picture_as_pdf),
                  label: Text('Wygeneruj PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.invoiceColor,
                    foregroundColor: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadInvoicePdf(Invoice invoice) async {
    try {
      final invoiceProvider = Provider.of<InvoiceProvider>(context, listen: false);
      
      print('Pobieranie PDF dla faktury: ${invoice.invoiceNumber}');
      
      await invoiceProvider.loadInvoice(invoice.id);
      
      if (invoice.pdfUrl != null && invoice.pdfUrl!.isNotEmpty) {
        print('PDF już istnieje: ${invoice.pdfUrl}');
        
        if (!Platform.isAndroid && !Platform.isIOS) {
          await invoiceProvider.generateInvoicePDF();
          _showSuccessSnackBar('PDF wyświetlony w przeglądarce');
          return;
        }

        if (invoice.pdfUrl!.startsWith('PDF zapisany w: ')) {
          final path = invoice.pdfUrl!.replaceFirst('PDF zapisany w: ', '');
          final file = File(path);
          
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            await Printing.layoutPdf(
              onLayout: (format) async => bytes,
              name: 'Faktura-${invoice.invoiceNumber.replaceAll('/', '-')}.pdf',
            );
            _showSuccessSnackBar('PDF otwarty');
            return;
          }
        }
      }
      
      print('Generowanie nowego PDF...');
      final success = await invoiceProvider.generateInvoicePDF();
      
      if (success) {
        _showSuccessSnackBar('PDF wygenerowany i otwarty');
      } else {
        _showErrorSnackBar(invoiceProvider.errorMessage ?? 'Błąd generowania PDF');
      }
      
    } catch (e) {
      print('Błąd pobierania PDF: $e');
      _showErrorSnackBar('Błąd pobierania PDF: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.invoiceColor,
        behavior: SnackBarBehavior.floating,
      ),
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
                            'Wszystkie faktury',
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),

                  // Główna zawartość
                  Expanded(
                    child: Consumer<InvoiceProvider>(
                      builder: (context, invoiceProvider, child) {
                        if (invoiceProvider.isLoading) {
                          return Center(
                            child: LoadingAnimationWidget.threeArchedCircle(
                              color: AppTheme.invoiceColor,
                              size: 32,
                            ),
                          );
                        }

                        final invoices = invoiceProvider.userInvoices;

                        if (invoices.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: AppTheme.invoiceColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.receipt_long_outlined,
                                    size: 40,
                                    color: AppTheme.invoiceColor,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Brak faktur',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Nie masz jeszcze żadnych wystawionych faktur',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 32),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).pushNamedAndRemoveUntil(
                                      '/invoice-intro',
                                      (route) => route.settings.name == '/home',
                                    );
                                  },
                                  icon: const Icon(Icons.add, color: AppTheme.textPrimary),
                                  label: const Text(
                                    'Wystaw pierwszą fakturę',
                                    style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.invoiceColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return AnimationLimiter(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(24),
                            itemCount: invoices.length,
                            itemBuilder: (context, index) {
                              final invoice = invoices[index];
                              return AnimationConfiguration.staggeredList(
                                position: index,
                                child: SlideAnimation(
                                  verticalOffset: 30,
                                  child: FadeInAnimation(
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: AppTheme.cardColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: AppTheme.invoiceColor.withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: InkWell(
                                        onTap: () => _showInvoiceDetails(invoice),
                                        borderRadius: BorderRadius.circular(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.invoiceColor.withOpacity(0.2),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Icon(
                                                    Icons.receipt_long,
                                                    color: AppTheme.invoiceColor,
                                                    size: 20,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    invoice.invoiceNumber,
                                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                      color: AppTheme.textPrimary,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                if (invoice.pdfUrl != null)
                                                  Icon(
                                                    Icons.picture_as_pdf,
                                                    color: AppTheme.invoiceColor,
                                                    size: 20,
                                                  ),
                                              ],
                                            ),
                                            
                                            const SizedBox(height: 16),
                                            
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        'Nabywca:',
                                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                          color: AppTheme.textSecondary,
                                                        ),
                                                      ),
                                                      Text(
                                                        invoice.buyerName.isNotEmpty 
                                                          ? invoice.buyerName 
                                                          : 'Nie podano',
                                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                          color: AppTheme.textPrimary,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      'Data:',
                                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                        color: AppTheme.textSecondary,
                                                      ),
                                                    ),
                                                    Text(
                                                      _formatDate(invoice.issueDate),
                                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                        color: AppTheme.textPrimary,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            
                                            const SizedBox(height: 12),
                                            
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'Pozycji: ${invoice.items.length}',
                                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                    color: AppTheme.textSecondary,
                                                  ),
                                                ),
                                                Text(
                                                  '${invoice.totalGross.toStringAsFixed(2)} zł',
                                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/invoice-intro',
                            (route) => route.settings.name == '/home',
                          );
                        },
                        icon: const Icon(
                          Icons.add,
                          color: AppTheme.textPrimary,
                        ),
                        label: Text(
                          'Wystaw nową fakturę',
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 