import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/models.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final dbHelper = DatabaseHelper.instance;
  List<Currency> currencies = [];
  final _currencyNameController = TextEditingController();
  final _currencyCodeController = TextEditingController();
  final _currencyRateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrencies();
  }

  Future<void> _loadCurrencies() async {
    final data = await dbHelper.getCurrencies();
    setState(() {
      currencies = data.map((e) => Currency.fromMap(e)).toList();
    });
  }

  void _showAddCurrencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة عملة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _currencyNameController,
              decoration: const InputDecoration(labelText: 'اسم العملة', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _currencyCodeController,
              decoration: const InputDecoration(labelText: 'الكود (مثل USD)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _currencyRateController,
              decoration: const InputDecoration(labelText: 'سعر الصرف', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              await dbHelper.insertCurrency({
                'name': _currencyNameController.text,
                'code': _currencyCodeController.text,
                'symbol': _currencyCodeController.text,
                'exchange_rate': double.tryParse(_currencyRateController.text) ?? 1,
              });
              _currencyNameController.clear();
              _currencyCodeController.clear();
              _currencyRateController.clear();
              Navigator.pop(context);
              _loadCurrencies();
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الإعدادات'),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Card(
              child: ListTile(
                leading: Icon(Icons.info, color: Colors.blue),
                title: Text('المحاسب الشخصي'),
                subtitle: Text('الإصدار 1.0.0'),
              ),
            ),
            const SizedBox(height: 16),
            const Text('العملات:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...currencies.map((c) => Card(
              child: ListTile(
                leading: const Icon(Icons.currency_exchange, color: Colors.amber),
                title: Text(c.name),
                subtitle: Text('الكود: ${c.code} - السعر: ${c.exchangeRate}'),
                trailing: c.isDefault
                    ? const Chip(label: Text('افتراضية'), backgroundColor: Colors.green)
                    : null,
              ),
            )),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _showAddCurrencyDialog,
              icon: const Icon(Icons.add),
              label: const Text('إضافة عملة'),
            ),
            const SizedBox(height: 24),
            const Text('عام:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.backup, color: Colors.green),
              title: const Text('النسخ الاحتياطي'),
              subtitle: const Text('حفظ واستعادة البيانات'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => Navigator.pushNamed(context, '/backup'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('حذف جميع البيانات'),
              subtitle: const Text('تنبيه: لا يمكن التراجع عن هذا الإجراء'),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('تأكيد الحذف'),
                    content: const Text('هل أنت متأكد من حذف جميع البيانات؟ هذا الإجراء لا يمكن التراجع عنه.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('إلغاء'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('حذف', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  final db = await dbHelper.database;
                  await db.delete('transactions');
                  await db.delete('accounts');
                  await db.delete('products');
                  await db.delete('invoices');
                  await db.delete('invoice_items');
                  await db.delete('warehouses');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم حذف جميع البيانات')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
