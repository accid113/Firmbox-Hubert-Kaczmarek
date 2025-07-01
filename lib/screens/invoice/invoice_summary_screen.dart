import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../providers/invoice_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_text_field.dart';

class InvoiceSummaryScreen extends StatefulWidget {
  const InvoiceSummaryScreen({super.key});

  @override
  State<InvoiceSummaryScreen> createState() => _InvoiceSummaryScreenState();
}

class _InvoiceSummaryScreenState extends State<InvoiceSummaryScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  DateTime _issueDate = DateTime.now();
  DateTime _saleDate = DateTime.now();
  DateTime? _paymentDate;
  String _paymentMethod = 'Przelew';

  final List<String> _paymentMethods = [
    'Przelew',
    'Gotówka',
    'Karta płatnicza',
    'BLIK',
    'Czek',
    'Potrącenie',
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
    _loadExistingData();
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

  void _loadExistingData() {
    final invoiceProvider = Provider.of<InvoiceProvider>(context, listen: false);
    final invoice = invoiceProvider.currentInvoice;
    
    if (invoice != null) {
      _issueDate = invoice.issueDate;
      _saleDate = invoice.saleDate;
      _paymentDate = invoice.paymentDate;
      _notesController.text = invoice.notes ?? '';
      _paymentMethod = invoice.paymentMethod ?? 'Przelew';
    }
    
    _paymentDate ??= _issueDate.add(const Duration(days: 14));
  }

  @override
  void dispose() {
    _notesController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, String type) async {
    DateTime initialDate = DateTime.now();
    
    switch (type) {
      case 'issue':
        initialDate = _issueDate;
        break;
      case 'sale':
        initialDate = _saleDate;
        break;
      case 'payment':
        initialDate = _paymentDate ?? DateTime.now().add(const Duration(days: 14));
        break;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.invoiceColor,
              onPrimary: Colors.white,
              surface: AppTheme.cardColor,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        switch (type) {
          case 'issue':
            _issueDate = picked;
            break;
          case 'sale':
            _saleDate = picked;
            break;
          case 'payment':
            _paymentDate = picked;
            break;
        }
      });
    }
  }

  Future<void> _proceedToNext() async {
    if (!_formKey.currentState!.validate()) return;

    final invoiceProvider = Provider.of<InvoiceProvider>(context, listen: false);
    
    try {
      bool datesSuccess = await invoiceProvider.setDates(
        issueDate: _issueDate,
        saleDate: _saleDate,
        paymentDate: _paymentDate,
      );
      
      if (!datesSuccess) {
        _showErrorSnackBar('Błąd zapisywania dat');
        return;
      }
      
      bool notesSuccess = await invoiceProvider.setNotesAndPayment(
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        paymentMethod: _paymentMethod,
      );
      
      if (!notesSuccess) {
        _showErrorSnackBar(invoiceProvider.errorMessage ?? 'Błąd zapisywania uwag');
        return;
      }

      print('Finalizowanie faktury...');
      final invoiceId = await invoiceProvider.finalizeInvoice();
      print('Faktura sfinalizowana z ID: $invoiceId');
      
      if (mounted) {
        Navigator.of(context).pushNamed('/invoice-final');
      }
      
    } catch (e) {
      print('Błąd finalizacji faktury: $e');
      _showErrorSnackBar('Błąd finalizacji faktury: $e');
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
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
                            'Podsumowanie',
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
                              color: AppTheme.accentColor,
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
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              const SizedBox(height: 20),

                              // icon
                              AnimationConfiguration.staggeredList(
                                position: 0,
                                child: SlideAnimation(
                                  verticalOffset: 30,
                                  child: FadeInAnimation(
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: AppTheme.invoiceColor.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Icon(
                                        Icons.summarize_outlined,
                                        size: 40,
                                        color: AppTheme.invoiceColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 32),

                              // title
                              AnimationConfiguration.staggeredList(
                                position: 1,
                                child: SlideAnimation(
                                  verticalOffset: 30,
                                  child: FadeInAnimation(
                                    child: Column(
                                      children: [
                                        Text(
                                          'Ostatnie szczegóły',
                                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                            color: AppTheme.textPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        
                                        const SizedBox(height: 12),
                                        
                                        Text(
                                          'Ustaw daty, metodę płatności i dodaj uwagi',
                                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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

                              const SizedBox(height: 40),

                              // date
                              AnimationConfiguration.staggeredList(
                                position: 2,
                                child: SlideAnimation(
                                  verticalOffset: 30,
                                  child: FadeInAnimation(
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: AppTheme.cardColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: AppTheme.invoiceColor.withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.calendar_today,
                                                color: AppTheme.invoiceColor,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Daty faktury',
                                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  color: AppTheme.textPrimary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          
                                          ListTile(
                                            title: const Text('Data wystawienia'),
                                            subtitle: Text(_formatDate(_issueDate)),
                                            trailing: const Icon(Icons.edit),
                                            onTap: () => _selectDate(context, 'issue'),
                                          ),
                                          
                                          ListTile(
                                            title: const Text('Data sprzedaży'),
                                            subtitle: Text(_formatDate(_saleDate)),
                                            trailing: const Icon(Icons.edit),
                                            onTap: () => _selectDate(context, 'sale'),
                                          ),
                                          
                                          ListTile(
                                            title: const Text('Termin płatności'),
                                            subtitle: Text(_paymentDate != null 
                                              ? _formatDate(_paymentDate!) 
                                              : 'Nie ustawiono'),
                                            trailing: const Icon(Icons.edit),
                                            onTap: () => _selectDate(context, 'payment'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              AnimationConfiguration.staggeredList(
                                position: 3,
                                child: SlideAnimation(
                                  verticalOffset: 30,
                                  child: FadeInAnimation(
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: AppTheme.cardColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: AppTheme.invoiceColor.withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.payment,
                                                color: AppTheme.invoiceColor,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Metoda płatności',
                                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  color: AppTheme.textPrimary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          
                                          DropdownButtonFormField<String>(
                                            value: _paymentMethod,
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                              filled: true,
                                            ),
                                            items: _paymentMethods.map((method) {
                                              return DropdownMenuItem(
                                                value: method,
                                                child: Text(method),
                                              );
                                            }).toList(),
                                            onChanged: (value) {
                                              setState(() {
                                                _paymentMethod = value!;
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              AnimationConfiguration.staggeredList(
                                position: 4,
                                child: SlideAnimation(
                                  verticalOffset: 30,
                                  child: FadeInAnimation(
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: AppTheme.cardColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: AppTheme.invoiceColor.withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.note_outlined,
                                                color: AppTheme.invoiceColor,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Uwagi (opcjonalne)',
                                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  color: AppTheme.textPrimary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          
                                          CustomTextField(
                                            controller: _notesController,
                                            label: 'Uwagi',
                                            hint: 'Dodatkowe informacje dla klienta...',
                                            maxLines: 3,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // summarize
                              const SizedBox(height: 20),
                              
                              Consumer<InvoiceProvider>(
                                builder: (context, invoiceProvider, child) {
                                  final invoice = invoiceProvider.currentInvoice;
                                  if (invoice == null) return const SizedBox.shrink();
                                  
                                  return AnimationConfiguration.staggeredList(
                                    position: 5,
                                    child: SlideAnimation(
                                      verticalOffset: 30,
                                      child: FadeInAnimation(
                                        child: Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: AppTheme.invoiceColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: AppTheme.invoiceColor.withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    'Wartość netto:',
                                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                      color: AppTheme.textSecondary,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${invoice.totalNet.toStringAsFixed(2)} zł',
                                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                      color: AppTheme.textPrimary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    'VAT:',
                                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                      color: AppTheme.textSecondary,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${invoice.totalVat.toStringAsFixed(2)} zł',
                                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                      color: AppTheme.textPrimary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const Divider(height: 24),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    'RAZEM DO ZAPŁATY:',
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
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: AnimationConfiguration.staggeredList(
                      position: 6,
                      child: SlideAnimation(
                        verticalOffset: 50,
                        child: FadeInAnimation(
                          child: Consumer<InvoiceProvider>(
                            builder: (context, invoiceProvider, child) {
                              return SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton.icon(
                                  onPressed: invoiceProvider.isLoading ? null : _proceedToNext,
                                  icon: invoiceProvider.isLoading
                                    ? LoadingAnimationWidget.threeArchedCircle(
                                        color: AppTheme.textPrimary,
                                        size: 20,
                                      )
                                    : const Icon(
                                        Icons.picture_as_pdf,
                                        color: AppTheme.textPrimary,
                                      ),
                                  label: Text(
                                    invoiceProvider.isLoading ? 'Zapisywanie...' : 'Generuj fakturę',
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
                              );
                            },
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