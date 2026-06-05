import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../database/database_helper.dart';

class DailyTransactionsScreen extends StatefulWidget {
  const DailyTransactionsScreen({super.key});

  @override
  State<DailyTransactionsScreen> createState() => _DailyTransactionsScreenState();
}

class _DailyTransactionsScreenState extends State<DailyTransactionsScreen> {
  final dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> transactions = [];
  bool isLoading = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => isLoading = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final data = await dbHelper.getTransactions(dateFrom: dateStr, dateTo: dateStr);
    setState(() {
      transactions = data;
      isLoading = false;
    });
  }

  Future<void> _deleteTransaction(int id) async {
    final db = await dbHelper.database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
    _loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الحركة اليومية'),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // اختيار التاريخ
            Card(
              margin: const EdgeInsets.all(12),
              child: ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.indigo),
                title: Text('تاريخ: $dateStr'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
                        _loadTransactions();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_month),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) {
                          setState(() => _selectedDate = date);
                          _loadTransactions();
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));
                        _loadTransactions();
                      },
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
                      ? const Center(child: Text('لا توجد حركات لهذا اليوم'))
                      : ListView.builder(
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            final t = transactions[index];
                            final type = t['type'] as String;
                            Color typeColor;
                            IconData typeIcon;

                            switch (type) {
                              case 'قبض':
                                typeColor = Colors.green;
                                typeIcon = Icons.arrow_downward;
                                break;
                              case 'صرف':
                                typeColor = Colors.red;
                                typeIcon = Icons.arrow_upward;
                                break;
                              case 'حوالة':
                                typeColor = Colors.blue;
                                typeIcon = Icons.swap_horiz;
                                break;
                              default:
                                typeColor = Colors.grey;
                                typeIcon = Icons.receipt;
                            }

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: typeColor,
                                  child: Icon(typeIcon, color: Colors.white),
                                ),
                                title: Text('$type - ${t['notes'] ?? ''}'),
                                subtitle: Text('المرجع: ${t['reference'] ?? '-'}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${(t['amount'] as double).toStringAsFixed(0)} د.ع',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: typeColor,
                                        fontSize: 16,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteTransaction(t['id'] as int),
                                    ),
                                  ],
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
