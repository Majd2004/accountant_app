import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:intl/intl.dart' hide TextDirection;
import '../database/database_helper.dart';
import '../models/models.dart';

class VoucherScreen extends StatefulWidget {
  const VoucherScreen({super.key});

  @override
  State<VoucherScreen> createState() => _VoucherScreenState();
}

class _VoucherScreenState extends State<VoucherScreen> {
  final dbHelper = DatabaseHelper.instance;
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _referenceController = TextEditingController();

  String _selectedType = 'قبض';
  Account? _selectedAccount;
  List<Account> accounts = [];
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final data = await dbHelper.getAccounts();
    setState(() {
      accounts = data.map((e) => Account.fromMap(e)).toList();
    });
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار الحساب')),
      );
      return;
    }

    final transaction = Transaction(
      date: DateFormat('yyyy-MM-dd').format(_selectedDate),
      type: _selectedType,
      fromAccountId: _selectedType == 'صرف' ? _selectedAccount!.id : null,
      toAccountId: _selectedType == 'قبض' ? _selectedAccount!.id : null,
      amount: double.parse(_amountController.text),
      notes: _notesController.text,
      reference: _referenceController.text,
    );

    await dbHelper.insertTransaction(transaction.toMap());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حفظ سند $_selectedType بنجاح')),
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
          title: const Text('سند قبض / صرف'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                // نوع السند
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('قبض'),
                        value: 'قبض',
                        groupValue: _selectedType,
                        onChanged: (value) => setState(() => _selectedType = value!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('صرف'),
                        value: 'صرف',
                        groupValue: _selectedType,
                        onChanged: (value) => setState(() => _selectedType = value!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // اختيار الحساب
                DropdownButtonFormField<Account>(
                  decoration: const InputDecoration(
                    labelText: 'الحساب',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.account_balance_wallet),
                  ),
                  value: _selectedAccount,
                  items: accounts.map((account) {
                    return DropdownMenuItem(
                      value: account,
                      child: Text('${account.name} (${account.type}) - ${account.balance.toStringAsFixed(0)} د.ع'),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedAccount = value),
                  validator: (value) => value == null ? 'الرجاء اختيار الحساب' : null,
                ),
                const SizedBox(height: 16),
                // المبلغ
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'المبلغ',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'الرجاء إدخال المبلغ';
                    if (double.tryParse(value) == null) return 'المبلغ غير صالح';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
                // المرجع
                TextFormField(
                  controller: _referenceController,
                  decoration: const InputDecoration(
                    labelText: 'المرجع / رقم السند',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.numbers),
                  ),
                ),
                const SizedBox(height: 16),
                // الملاحظات
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                // زر الحفظ
                ElevatedButton.icon(
                  onPressed: _saveTransaction,
                  icon: const Icon(Icons.save),
                  label: const Text('حفظ السند', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
