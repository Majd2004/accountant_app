import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../database/database_helper.dart';
import '../models/models.dart';

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  final dbHelper = DatabaseHelper.instance;
  final _formKey = GlobalKey<FormState>();

  String _invoiceType = 'بيع';
  Account? _selectedAccount;
  Warehouse? _selectedWarehouse;
  DateTime _selectedDate = DateTime.now();
  final _invoiceNumberController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _taxController = TextEditingController(text: '0');
  final _paidController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  List<Account> accounts = [];
  List<Warehouse> warehouses = [];
  List<Product> products = [];
  List<Map<String, dynamic>> invoiceItems = [];

  double get subtotal => invoiceItems.fold(0, (sum, item) => sum + (item['total'] as double));
  double get discount => double.tryParse(_discountController.text) ?? 0;
  double get tax => double.tryParse(_taxController.text) ?? 0;
  double get total => subtotal - discount + tax;
  double get paid => double.tryParse(_paidController.text) ?? 0;
  double get remaining => total - paid;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final accountData = await dbHelper.getAccounts();
    final warehouseData = await dbHelper.getWarehouses();
    final productData = await dbHelper.getProducts();

    setState(() {
      accounts = accountData.map((e) => Account.fromMap(e)).toList();
      warehouses = warehouseData.map((e) => Warehouse.fromMap(e)).toList();
      products = productData.map((e) => Product.fromMap(e)).toList();
    });
  }

  void _addItem() {
    Product? selectedProduct;
    final quantityController = TextEditingController(text: '1');
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة صنف'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Product>(
                  decoration: const InputDecoration(labelText: 'المنتج', border: OutlineInputBorder()),
                  value: selectedProduct,
                  items: products.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Text('${p.name} (متوفر: ${p.quantity})'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedProduct = value;
                      priceController.text = _invoiceType == 'بيع'
                          ? value!.salePrice.toStringAsFixed(0)
                          : value!.purchasePrice.toStringAsFixed(0);
                    });
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: quantityController,
                  decoration: const InputDecoration(labelText: 'الكمية', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'السعر', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedProduct == null) return;
                final qty = double.tryParse(quantityController.text) ?? 1;
                final price = double.tryParse(priceController.text) ?? 0;
                setState(() {
                  invoiceItems.add({
                    'product_id': selectedProduct!.id,
                    'product_name': selectedProduct!.name,
                    'quantity': qty,
                    'unit_price': price,
                    'total': qty * price,
                  });
                });
                Navigator.pop(context);
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveInvoice() async {
    if (!_formKey.currentState!.validate()) return;
    if (invoiceItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إضافة أصناف للفاتورة')),
      );
      return;
    }

    final invoice = Invoice(
      invoiceNumber: _invoiceNumberController.text,
      date: DateFormat('yyyy-MM-dd').format(_selectedDate),
      type: _invoiceType,
      accountId: _selectedAccount?.id,
      warehouseId: _selectedWarehouse?.id,
      total: subtotal,
      discount: discount,
      tax: tax,
      finalTotal: total,
      paid: paid,
      remaining: remaining,
      notes: _notesController.text,
    );

    await dbHelper.insertInvoice(
      invoice.toMap(),
      invoiceItems.map((item) => {
        'product_id': item['product_id'],
        'quantity': item['quantity'],
        'unit_price': item['unit_price'],
        'total': item['total'],
      }).toList(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الفاتورة بنجاح')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('فاتورة جديدة'),
          centerTitle: true,
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // نوع الفاتورة
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('بيع'),
                      value: 'بيع',
                      groupValue: _invoiceType,
                      onChanged: (value) => setState(() => _invoiceType = value!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('شراء'),
                      value: 'شراء',
                      groupValue: _invoiceType,
                      onChanged: (value) => setState(() => _invoiceType = value!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // رقم الفاتورة
              TextFormField(
                controller: _invoiceNumberController,
                decoration: const InputDecoration(
                  labelText: 'رقم الفاتورة',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
                validator: (value) => value == null || value.isEmpty ? 'الرجاء إدخال رقم الفاتورة' : null,
              ),
              const SizedBox(height: 8),
              // التاريخ
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
                leading: const Icon(Icons.calendar_today),
                title: Text('التاريخ: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}'),
                trailing: const Icon(Icons.edit),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) setState(() => _selectedDate = date);
                },
              ),
              const SizedBox(height: 8),
              // الحساب
              DropdownButtonFormField<Account>(
                decoration: const InputDecoration(
                  labelText: 'الحساب',
                  border: OutlineInputBorder(),
                ),
                value: _selectedAccount,
                items: accounts.map((a) {
                  return DropdownMenuItem(value: a, child: Text('${a.name} (${a.type})'));
                }).toList(),
                onChanged: (value) => setState(() => _selectedAccount = value),
              ),
              const SizedBox(height: 8),
              // المخزن
              DropdownButtonFormField<Warehouse>(
                decoration: const InputDecoration(
                  labelText: 'المخزن',
                  border: OutlineInputBorder(),
                ),
                value: _selectedWarehouse,
                items: warehouses.map((w) {
                  return DropdownMenuItem(value: w, child: Text(w.name));
                }).toList(),
                onChanged: (value) => setState(() => _selectedWarehouse = value),
              ),
              const SizedBox(height: 16),
              // أصناف الفاتورة
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('الأصناف:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة صنف'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...invoiceItems.map((item) => Card(
                child: ListTile(
                  title: Text(item['product_name']),
                  subtitle: Text('${item['quantity']} × ${item['unit_price']} = ${item['total']} د.ع'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => setState(() => invoiceItems.remove(item)),
                  ),
                ),
              )),
              const Divider(),
              // ملخص الفاتورة
              Card(
                color: Colors.indigo[50],
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      _buildSummaryRow('المجموع:', subtotal),
                      _buildSummaryRow('الخصم:', discount, isNegative: true),
                      _buildSummaryRow('الضريبة:', tax),
                      const Divider(),
                      _buildSummaryRow('الإجمالي:', total, isBold: true),
                      _buildSummaryRow('المدفوع:', paid, color: Colors.green),
                      _buildSummaryRow('المتبقي:', remaining, color: Colors.red),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // الخصم والضريبة والمدفوع
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _discountController,
                      decoration: const InputDecoration(labelText: 'الخصم', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _taxController,
                      decoration: const InputDecoration(labelText: 'الضريبة', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _paidController,
                      decoration: const InputDecoration(labelText: 'المدفوع', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // ملاحظات
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _saveInvoice,
                icon: const Icon(Icons.save),
                label: const Text('حفظ الفاتورة', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, {bool isBold = false, bool isNegative = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            '${value.toStringAsFixed(0)} د.ع',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? (isNegative ? Colors.red : null),
            ),
          ),
        ],
      ),
    );
  }
}
