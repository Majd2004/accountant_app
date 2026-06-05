class Account {
  final int? id;
  final String name;
  final String type;
  double balance;
  final String currency;
  final String? notes;

  Account({
    this.id,
    required this.name,
    required this.type,
    this.balance = 0,
    this.currency = 'دينار',
    this.notes,
  });

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      balance: map['balance'] ?? 0,
      currency: map['currency'] ?? 'دينار',
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'balance': balance,
      'currency': currency,
      'notes': notes,
    };
  }
}

class Transaction {
  final int? id;
  final String date;
  final String type;
  final int? fromAccountId;
  final int? toAccountId;
  final double amount;
  final String currency;
  final double exchangeRate;
  final String? notes;
  final String? reference;

  Transaction({
    this.id,
    required this.date,
    required this.type,
    this.fromAccountId,
    this.toAccountId,
    required this.amount,
    this.currency = 'دينار',
    this.exchangeRate = 1,
    this.notes,
    this.reference,
  });

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      date: map['date'],
      type: map['type'],
      fromAccountId: map['from_account_id'],
      toAccountId: map['to_account_id'],
      amount: map['amount'] ?? 0,
      currency: map['currency'] ?? 'دينار',
      exchangeRate: map['exchange_rate'] ?? 1,
      notes: map['notes'],
      reference: map['reference'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'type': type,
      'from_account_id': fromAccountId,
      'to_account_id': toAccountId,
      'amount': amount,
      'currency': currency,
      'exchange_rate': exchangeRate,
      'notes': notes,
      'reference': reference,
    };
  }
}

class Product {
  final int? id;
  final String name;
  final String? code;
  final String? category;
  final String unit;
  final double purchasePrice;
  final double salePrice;
  int quantity;
  final int minQuantity;
  final int? warehouseId;
  final String? notes;

  Product({
    this.id,
    required this.name,
    this.code,
    this.category,
    this.unit = 'قطعة',
    this.purchasePrice = 0,
    this.salePrice = 0,
    this.quantity = 0,
    this.minQuantity = 0,
    this.warehouseId,
    this.notes,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      code: map['code'],
      category: map['category'],
      unit: map['unit'] ?? 'قطعة',
      purchasePrice: map['purchase_price'] ?? 0,
      salePrice: map['sale_price'] ?? 0,
      quantity: map['quantity'] ?? 0,
      minQuantity: map['min_quantity'] ?? 0,
      warehouseId: map['warehouse_id'],
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'category': category,
      'unit': unit,
      'purchase_price': purchasePrice,
      'sale_price': salePrice,
      'quantity': quantity,
      'min_quantity': minQuantity,
      'warehouse_id': warehouseId,
      'notes': notes,
    };
  }
}

class Invoice {
  final int? id;
  final String invoiceNumber;
  final String date;
  final String type;
  final int? accountId;
  final int? warehouseId;
  final double total;
  final double discount;
  final double tax;
  final double finalTotal;
  final double paid;
  final double remaining;
  final String currency;
  final String? notes;

  Invoice({
    this.id,
    required this.invoiceNumber,
    required this.date,
    required this.type,
    this.accountId,
    this.warehouseId,
    this.total = 0,
    this.discount = 0,
    this.tax = 0,
    this.finalTotal = 0,
    this.paid = 0,
    this.remaining = 0,
    this.currency = 'دينار',
    this.notes,
  });

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'],
      invoiceNumber: map['invoice_number'],
      date: map['date'],
      type: map['type'],
      accountId: map['account_id'],
      warehouseId: map['warehouse_id'],
      total: map['total'] ?? 0,
      discount: map['discount'] ?? 0,
      tax: map['tax'] ?? 0,
      finalTotal: map['final_total'] ?? 0,
      paid: map['paid'] ?? 0,
      remaining: map['remaining'] ?? 0,
      currency: map['currency'] ?? 'دينار',
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'date': date,
      'type': type,
      'account_id': accountId,
      'warehouse_id': warehouseId,
      'total': total,
      'discount': discount,
      'tax': tax,
      'final_total': finalTotal,
      'paid': paid,
      'remaining': remaining,
      'currency': currency,
      'notes': notes,
    };
  }
}

class Warehouse {
  final int? id;
  final String name;
  final String? location;
  final String? notes;

  Warehouse({
    this.id,
    required this.name,
    this.location,
    this.notes,
  });

  factory Warehouse.fromMap(Map<String, dynamic> map) {
    return Warehouse(
      id: map['id'],
      name: map['name'],
      location: map['location'],
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'notes': notes,
    };
  }
}

class Currency {
  final int? id;
  final String name;
  final String code;
  final String? symbol;
  final double exchangeRate;
  final bool isDefault;

  Currency({
    this.id,
    required this.name,
    required this.code,
    this.symbol,
    this.exchangeRate = 1,
    this.isDefault = false,
  });

  factory Currency.fromMap(Map<String, dynamic> map) {
    return Currency(
      id: map['id'],
      name: map['name'],
      code: map['code'],
      symbol: map['symbol'],
      exchangeRate: map['exchange_rate'] ?? 1,
      isDefault: map['is_default'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'symbol': symbol,
      'exchange_rate': exchangeRate,
      'is_default': isDefault ? 1 : 0,
    };
  }
}
