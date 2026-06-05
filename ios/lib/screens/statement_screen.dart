import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../database/database_helper.dart';
import '../models/models.dart';

class StatementScreen extends StatefulWidget {
  const StatementScreen({super.key});

  @override
  State<StatementScreen> createState() => _StatementScreenState();
}

class _StatementScreenState extends State<StatementScreen> {
  final dbHelper = DatabaseHelper.instance;
  Account? _selectedAccount;
  List<Account> accounts = [];
  List<Map<String, dynamic>> transactions = [];
  bool isLoading = false;
  double totalDebit = 0;
  double totalCredit = 0;

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

  Future<void> _loadStatement() async {
    if (_selectedAccount == null) return;
    setState(() => isLoading = true);

    final allTransactions = await dbHelper.getTransactions();
    final filtered = allTransactions.where((t) {
      return t['from_account_id'] == _selectedAccount!.id ||
          t['to_account_id'] == _selectedAccount!.id;
    }).toList();

    double debit = 0;
    double credit = 0;

    for (var t in filtered) {
      if (t['to_account_id'] == _selectedAccount!.id) {
        debit += t['amount'] as double;
      }
      if (t['from_account_id'] == _selectedAccount!.id) {
        credit += t['amount'] as double;
      }
    }

    setState(() {
      transactions = filtered;
      totalDebit = debit;
      totalCredit = credit;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('كشف حساب'),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // اختيار الحساب
            Padding(
              padding: const EdgeInsets.all(12),
              child: DropdownButtonFormField<Account>(
                decoration: const InputDecoration(
                  labelText: 'اختر الحساب',
                  border: OutlineInputBorder(),
                ),
                value: _selectedAccount,
                items: accounts.map((account) {
                  return DropdownMenuItem(
                    value: account,
                    child: Text('${account.name} (${account.type})'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedAccount = value);
                  _loadStatement();
                },
              ),
            ),
            // الملخص
            if (_selectedAccount != null)
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                color: Colors.indigo[50],
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('مدين', style: TextStyle(color: Colors.green)),
                          Text('${totalDebit.toStringAsFixed(0)} د.ع', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('دائن', style: TextStyle(color: Colors.red)),
                          Text('${totalCredit.toStringAsFixed(0)} د.ع', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('الرصيد', style: TextStyle(color: Colors.indigo)),
                          Text('${_selectedAccount!.balance.toStringAsFixed(0)} د.ع', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            // قائمة الحركات
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : transactions.isEmpty
                      ? const Center(child: Text('لا توجد حركات لهذا الحساب'))
                      : ListView.builder(
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            final t = transactions[index];
                            final isDebit = t['to_account_id'] == _selectedAccount!.id;
                            final amount = t['amount'] as double;
                            final date = t['date'] as String;

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isDebit ? Colors.green : Colors.red,
                                  child: Icon(
                                    isDebit ? Icons.arrow_downward : Icons.arrow_upward,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text('${t['type']} - ${t['notes'] ?? ''}'),
                                subtitle: Text('التاريخ: $date'),
                                trailing: Text(
                                  '${amount.toStringAsFixed(0)} د.ع',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDebit ? Colors.green : Colors.red,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
