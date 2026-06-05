import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/models.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final dbHelper = DatabaseHelper.instance;
  List<Account> accounts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final data = await dbHelper.getAccounts();
    setState(() {
      accounts = data.map((e) => Account.fromMap(e)).toList();
      isLoading = false;
    });
  }

  Future<void> _deleteAccount(int id) async {
    await dbHelper.deleteAccount(id);
    _loadAccounts();
  }

  void _showAddAccountDialog() {
    final nameController = TextEditingController();
    String selectedType = 'عميل';
    final notesController = TextEditingController();

    final accountTypes = ['عميل', 'مورد', 'موظف', 'صندوق', 'مصروف', 'دين', 'أخرى'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة حساب جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'اسم الحساب', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'نوع الحساب', border: OutlineInputBorder()),
                  value: selectedType,
                  items: accountTypes.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (value) => setDialogState(() => selectedType = value!),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'ملاحظات', border: OutlineInputBorder()),
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
              onPressed: () async {
                await dbHelper.insertAccount({
                  'name': nameController.text,
                  'type': selectedType,
                  'notes': notesController.text,
                });
                Navigator.pop(context);
                _loadAccounts();
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // تجميع الحسابات حسب النوع
    final groupedAccounts = <String, List<Account>>{};
    for (var account in accounts) {
      groupedAccounts.putIfAbsent(account.type, () => []).add(account);
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('دليل الحسابات'),
          centerTitle: true,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddAccountDialog,
          child: const Icon(Icons.add),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : accounts.isEmpty
                ? const Center(child: Text('لا توجد حسابات'))
                : ListView.builder(
                    itemCount: groupedAccounts.keys.length,
                    itemBuilder: (context, index) {
                      final type = groupedAccounts.keys.elementAt(index);
                      final typeAccounts = groupedAccounts[type]!;

                      return ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: _getTypeColor(type),
                          child: Icon(_getTypeIcon(type), color: Colors.white),
                        ),
                        title: Text(
                          type,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('${typeAccounts.length} حساب - المجموع: ${_getTypeTotal(typeAccounts).toStringAsFixed(0)} د.ع'),
                        children: typeAccounts.map((account) {
                          return ListTile(
                            title: Text(account.name),
                            subtitle: Text(account.notes ?? ''),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${account.balance.toStringAsFixed(0)} د.ع',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: account.balance >= 0 ? Colors.green : Colors.red,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteAccount(account.id!),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
      ),
    );
  }

  double _getTypeTotal(List<Account> accounts) {
    return accounts.fold(0, (sum, a) => sum + a.balance);
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'عميل': return Colors.green;
      case 'مورد': return Colors.orange;
      case 'موظف': return Colors.blue;
      case 'صندوق': return Colors.teal;
      case 'مصروف': return Colors.purple;
      case 'دين': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'عميل': return Icons.person;
      case 'مورد': return Icons.people;
      case 'موظف': return Icons.badge;
      case 'صندوق': return Icons.account_balance_wallet;
      case 'مصروف': return Icons.payment;
      case 'دين': return Icons.money_off;
      default: return Icons.account_balance;
    }
  }
}
