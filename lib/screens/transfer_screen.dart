import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../database/database_helper.dart';
import '../models/models.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final dbHelper = DatabaseHelper.instance;
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  Account? _fromAccount;
  Account? _toAccount;
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

  Future<void> _saveTransfer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fromAccount == null || _toAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار الحسابين')),
      );
      return;
    }
    if (_fromAccount!.id == _toAccount!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن التحويل لنفس الحساب')),
      );
      return;
    }

    final transaction = Transaction(
      date: DateFormat('yyyy-MM-dd').format(_selectedDate),
      type: 'حوالة',
      fromAccountId: _fromAccount!.id,
      toAccountId: _toAccount!.id,
      amount: double.parse(_amountController.text),
      notes: _notesController.text,
    );

    await dbHelper.insertTransaction(transaction.toMap());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الحوالة بنجاح')),
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
          title: const Text('حوالة جديدة'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const Icon(Icons.swap_horiz, size: 64, color: Colors.blue),
                const SizedBox(height: 16),
                // من حساب
                DropdownButtonFormField<Account>(
                  decoration: const InputDecoration(
                    labelText: 'من حساب',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.account_balance),
                  ),
                  value: _fromAccount,
                  items: accounts.map((account) {
                    return DropdownMenuItem(
                      value: account,
                      child: Text('${account.name} - ${account.balance.toStringAsFixed(0)} د.ع'),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _fromAccount = value),
                  validator: (value) => value == null ? 'الرجاء اختيار الحساب' : null,
                ),
                const SizedBox(height: 16),
                // إلى حساب
                DropdownButtonFormField<Account>(
                  decoration: const InputDecoration(
                    labelText: 'إلى حساب',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.account_balance_wallet),
                  ),
                  value: _toAccount,
                  items: accounts.map((account) {
                    return DropdownMenuItem(
                      value: account,
                      child: Text('${account.name} - ${account.balance.toStringAsFixed(0)} د.ع'),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _toAccount = value),
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
                ElevatedButton.icon(
                  onPressed: _saveTransfer,
                  icon: const Icon(Icons.save),
                  label: const Text('حفظ الحوالة', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
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
