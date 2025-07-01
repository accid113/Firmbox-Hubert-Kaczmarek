import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../providers/invoice_provider.dart';
import '../../models/invoice.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_text_field.dart';

class InvoiceItemsScreen extends StatefulWidget {
  const InvoiceItemsScreen({super.key});

  @override
  State<InvoiceItemsScreen> createState() => _InvoiceItemsScreenState();
}

class _InvoiceItemsScreenState extends State<InvoiceItemsScreen>
    with TickerProviderStateMixin {
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

  void _addItem() {
    _showItemDialog();
  }

  void _editItem(int index, InvoiceItem item) {
    _showItemDialog(index: index, item: item);
  }

  void _deleteItem(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Usuń pozycję'),
        content: const Text('Czy na pewno chcesz usunąć tę pozycję z faktury?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final invoiceProvider = Provider.of<InvoiceProvider>(context, listen: false);
              await invoiceProvider.removeItem(index);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
  }

  void _showItemDialog({int? index, InvoiceItem? item}) {
    showDialog(
      context: context,
      builder: (context) => AddItemDialog(
        item: item,
        onSave: (newItem) async {
          final invoiceProvider = Provider.of<InvoiceProvider>(context, listen: false);
          
          if (index != null) {
            await invoiceProvider.updateItem(index, newItem);
          } else {
            await invoiceProvider.addItem(newItem);
          }
        },
      ),
    );
  }

  void _proceedToNext() {
    final invoiceProvider = Provider.of<InvoiceProvider>(context, listen: false);
    
    if (invoiceProvider.currentInvoice?.items.isEmpty ?? true) {
      _showErrorSnackBar('Dodaj co najmniej jedną pozycję do faktury');
      return;
    }
    
    Navigator.of(context).pushNamed('/invoice-summary');
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
                            'Pozycje faktury',
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
                              color: AppTheme.accentColor,
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

                  const SizedBox(height: 32),

                  // main
                  Expanded(
                    child: Consumer<InvoiceProvider>(
                      builder: (context, invoiceProvider, child) {
                        final invoice = invoiceProvider.currentInvoice;
                        final items = invoice?.items ?? [];

                        return Column(
                          children: [
                            // header
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    color: AppTheme.invoiceColor,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Dodane pozycje (${items.length})',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    onPressed: _addItem,
                                    icon: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.invoiceColor,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.add,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            Expanded(
                              child: items.isEmpty
                                  ? _buildEmptyState()
                                  : AnimationLimiter(
                                      child: ListView.builder(
                                        padding: const EdgeInsets.symmetric(horizontal: 24),
                                        itemCount: items.length,
                                        itemBuilder: (context, index) {
                                          return AnimationConfiguration.staggeredList(
                                            position: index,
                                            child: SlideAnimation(
                                              verticalOffset: 30,
                                              child: FadeInAnimation(
                                                child: _buildItemCard(items[index], index),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                            ),

                            // Podsumowanie
                            if (items.isNotEmpty) _buildSummary(invoice!),
                          ],
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
                        onPressed: _proceedToNext,
                        icon: const Icon(
                          Icons.arrow_forward_rounded,
                          color: AppTheme.textPrimary,
                        ),
                        label: Text(
                          'Dalej',
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

  Widget _buildEmptyState() {
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
              Icons.inventory_2_outlined,
              size: 40,
              color: AppTheme.invoiceColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Brak pozycji',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Dodaj pierwszą pozycję do faktury',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _addItem,
            icon: const Icon(Icons.add, color: AppTheme.textPrimary),
            label: const Text(
              'Dodaj pozycję',
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

  Widget _buildItemCard(InvoiceItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
              Expanded(
                child: Text(
                  item.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _editItem(index, item),
                icon: const Icon(Icons.edit, color: AppTheme.invoiceColor, size: 20),
              ),
              IconButton(
                onPressed: () => _deleteItem(index),
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ilość: ${item.quantity.toStringAsFixed(2)} ${item.unit}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              Text(
                'Cena: ${item.netPrice.toStringAsFixed(2)} zł',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'VAT: ${(item.vatRate * 100).toInt()}%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              Text(
                'Wartość: ${item.grossValue.toStringAsFixed(2)} zł',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.invoiceColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(Invoice invoice) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(24),
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
                'RAZEM:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
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
    );
  }
}

class AddItemDialog extends StatefulWidget {
  final InvoiceItem? item;
  final Function(InvoiceItem) onSave;

  const AddItemDialog({
    super.key,
    this.item,
    required this.onSave,
  });

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();
  final _priceController = TextEditingController();
  double _vatRate = 0.23;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _nameController.text = widget.item!.name;
      _quantityController.text = widget.item!.quantity.toString();
      _unitController.text = widget.item!.unit;
      _priceController.text = widget.item!.netPrice.toString();
      _vatRate = widget.item!.vatRate;
    } else {
      _unitController.text = 'szt.';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final item = InvoiceItem(
      name: _nameController.text.trim(),
      quantity: double.parse(_quantityController.text),
      unit: _unitController.text.trim(),
      netPrice: double.parse(_priceController.text),
      vatRate: _vatRate,
    );

    widget.onSave(item);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(widget.item != null ? 'Edytuj pozycję' : 'Dodaj pozycję'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: _nameController,
                label: 'Nazwa towaru/usługi',
                hint: 'np. Programowanie aplikacji',
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return 'Wprowadź nazwę';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _quantityController,
                      label: 'Ilość',
                      hint: '1',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.trim().isEmpty ?? true) {
                          return 'Wprowadź ilość';
                        }
                        if (double.tryParse(value!) == null) {
                          return 'Nieprawidłowa wartość';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _unitController,
                      label: 'Jednostka',
                      hint: 'szt.',
                      validator: (value) {
                        if (value?.trim().isEmpty ?? true) {
                          return 'Wprowadź jednostkę';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _priceController,
                label: 'Cena netto (zł)',
                hint: '100.00',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return 'Wprowadź cenę';
                  }
                  if (double.tryParse(value!) == null) {
                    return 'Nieprawidłowa wartość';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<double>(
                value: _vatRate,
                decoration: const InputDecoration(
                  labelText: 'Stawka VAT',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 0.0, child: Text('0%')),
                  DropdownMenuItem(value: 0.05, child: Text('5%')),
                  DropdownMenuItem(value: 0.08, child: Text('8%')),
                  DropdownMenuItem(value: 0.23, child: Text('23%')),
                ],
                onChanged: (value) {
                  setState(() {
                    _vatRate = value!;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Anuluj'),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.invoiceColor,
          ),
          child: Text(
            widget.item != null ? 'Zapisz' : 'Dodaj',
            style: const TextStyle(color: AppTheme.textPrimary),
          ),
        ),
      ],
    );
  }
} 