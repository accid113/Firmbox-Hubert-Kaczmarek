class InvoiceItem {
  final String name;
  final double quantity;
  final String unit;
  final double netPrice;
  final double vatRate;
  
  InvoiceItem({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.netPrice,
    required this.vatRate,
  });

  double get netValue => quantity * netPrice;
  double get vatValue => netValue * vatRate;
  double get grossValue => netValue + vatValue;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'netPrice': netPrice,
      'vatRate': vatRate,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      name: map['name'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      unit: map['unit'] ?? '',
      netPrice: (map['netPrice'] ?? 0).toDouble(),
      vatRate: (map['vatRate'] ?? 0).toDouble(),
    );
  }

  InvoiceItem copyWith({
    String? name,
    double? quantity,
    String? unit,
    double? netPrice,
    double? vatRate,
  }) {
    return InvoiceItem(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      netPrice: netPrice ?? this.netPrice,
      vatRate: vatRate ?? this.vatRate,
    );
  }
}

class Invoice {
  final String id;
  final String userId;
  final String invoiceNumber;
  final DateTime issueDate;
  final DateTime saleDate;
  final DateTime? paymentDate;
  
  // Seller data
  final String sellerName;
  final String sellerAddress;
  final String sellerNip;
  final String? sellerLogoUrl;
  
  // Buyer data
  final String buyerName;
  final String buyerAddress;
  final String buyerNip;
  
  // Items and totals
  final List<InvoiceItem> items;
  final String? notes;
  final String? paymentMethod;
  
  final String? pdfUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Invoice({
    required this.id,
    required this.userId,
    required this.invoiceNumber,
    required this.issueDate,
    required this.saleDate,
    this.paymentDate,
    required this.sellerName,
    required this.sellerAddress,
    required this.sellerNip,
    this.sellerLogoUrl,
    required this.buyerName,
    required this.buyerAddress,
    required this.buyerNip,
    required this.items,
    this.notes,
    this.paymentMethod,
    this.pdfUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  double get totalNet => items.fold(0, (sum, item) => sum + item.netValue);
  double get totalVat => items.fold(0, (sum, item) => sum + item.vatValue);
  double get totalGross => totalNet + totalVat;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'invoiceNumber': invoiceNumber,
      'issueDate': issueDate.toIso8601String(),
      'saleDate': saleDate.toIso8601String(),
      'paymentDate': paymentDate?.toIso8601String(),
      'sellerName': sellerName,
      'sellerAddress': sellerAddress,
      'sellerNip': sellerNip,
      'sellerLogoUrl': sellerLogoUrl,
      'buyerName': buyerName,
      'buyerAddress': buyerAddress,
      'buyerNip': buyerNip,
      'items': items.map((item) => item.toMap()).toList(),
      'notes': notes,
      'paymentMethod': paymentMethod,
      'pdfUrl': pdfUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      invoiceNumber: map['invoiceNumber'] ?? '',
      issueDate: DateTime.parse(map['issueDate']),
      saleDate: DateTime.parse(map['saleDate']),
      paymentDate: map['paymentDate'] != null ? DateTime.parse(map['paymentDate']) : null,
      sellerName: map['sellerName'] ?? '',
      sellerAddress: map['sellerAddress'] ?? '',
      sellerNip: map['sellerNip'] ?? '',
      sellerLogoUrl: map['sellerLogoUrl'],
      buyerName: map['buyerName'] ?? '',
      buyerAddress: map['buyerAddress'] ?? '',
      buyerNip: map['buyerNip'] ?? '',
      items: (map['items'] as List<dynamic>?)
          ?.map((item) => InvoiceItem.fromMap(item as Map<String, dynamic>))
          .toList() ?? [],
      notes: map['notes'],
      paymentMethod: map['paymentMethod'],
      pdfUrl: map['pdfUrl'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Invoice copyWith({
    String? id,
    String? userId,
    String? invoiceNumber,
    DateTime? issueDate,
    DateTime? saleDate,
    DateTime? paymentDate,
    String? sellerName,
    String? sellerAddress,
    String? sellerNip,
    String? sellerLogoUrl,
    String? buyerName,
    String? buyerAddress,
    String? buyerNip,
    List<InvoiceItem>? items,
    String? notes,
    String? paymentMethod,
    String? pdfUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      issueDate: issueDate ?? this.issueDate,
      saleDate: saleDate ?? this.saleDate,
      paymentDate: paymentDate ?? this.paymentDate,
      sellerName: sellerName ?? this.sellerName,
      sellerAddress: sellerAddress ?? this.sellerAddress,
      sellerNip: sellerNip ?? this.sellerNip,
      sellerLogoUrl: sellerLogoUrl ?? this.sellerLogoUrl,
      buyerName: buyerName ?? this.buyerName,
      buyerAddress: buyerAddress ?? this.buyerAddress,
      buyerNip: buyerNip ?? this.buyerNip,
      items: items ?? this.items,
      notes: notes ?? this.notes,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 