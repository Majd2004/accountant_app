import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final dbHelper = DatabaseHelper.instance;
  Map<String, dynamic> summary = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final accounts = await dbHelper.getAccounts();
    double suppliers = 0, customers = 0, debts = 0, employees = 0, expenses = 0, others = 0, cash = 0;

    for (var account in accounts) {
      final balance = account['balance'] ?? 0;
      switch (account['type']) {
        case 'مورد':
          suppliers += balance;
          break;
        case 'عميل':
          customers += balance;
          break;
        case 'دين':
          debts += balance;
          break;
        case 'موظف':
          employees += balance;
          break;
        case 'مصروف':
          expenses += balance;
          break;
        case 'صندوق':
          cash += balance;
          break;
        default:
          others += balance;
      }
    }

    setState(() {
      summary = {
        'suppliers': suppliers,
        'customers': customers,
        'debts': debts,
        'employees': employees,
        'expenses': expenses,
        'cash': cash,
        'others': others,
        'total': suppliers + customers + debts + employees + expenses + cash + others,
      };
      isLoading = false;
    });
  }

  Widget _buildSummaryCard(String title, double amount, Color color, IconData icon) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '${amount.toStringAsFixed(0)} د.ع',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color.withOpacity(0.6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المحاسب الشخصي'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ),
        drawer: _buildDrawer(),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadSummary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        // ملخص الحسابات
                        Card(
                          color: Colors.indigo[700],
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Text(
                                  'الملخص المالي',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: 2,
                                  childAspectRatio: 1.5,
                                  children: [
                                    _buildSummaryCard('الموردين', summary['suppliers'] ?? 0, Colors.orange, Icons.people),
                                    _buildSummaryCard('العملاء', summary['customers'] ?? 0, Colors.green, Icons.person),
                                    _buildSummaryCard('الديون', summary['debts'] ?? 0, Colors.red, Icons.money_off),
                                    _buildSummaryCard('الموظفين', summary['employees'] ?? 0, Colors.blue, Icons.badge),
                                    _buildSummaryCard('الصرفيات', summary['expenses'] ?? 0, Colors.purple, Icons.payment),
                                    _buildSummaryCard('الصناديق', summary['cash'] ?? 0, Colors.teal, Icons.account_balance_wallet),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'الإجمالي: ',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        '${(summary['total'] ?? 0).toStringAsFixed(0)} د.ع',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // الأزرار الرئيسية
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          childAspectRatio: 1.3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          children: [
                            _buildMainButton('سند جديد', Icons.receipt_long, Colors.green, () {
                              Navigator.pushNamed(context, '/voucher');
                            }),
                            _buildMainButton('حوالة جديدة', Icons.swap_horiz, Colors.blue, () {
                              Navigator.pushNamed(context, '/transfer');
                            }),
                            _buildMainButton('فاتورة جديدة', Icons.description, Colors.orange, () {
                              Navigator.pushNamed(context, '/invoice');
                            }),
                            _buildMainButton('كشف حساب', Icons.account_balance, Colors.indigo, () {
                              Navigator.pushNamed(context, '/statement');
                            }),
                            _buildMainButton('حركة يومية', Icons.calendar_today, Colors.purple, () {
                              Navigator.pushNamed(context, '/daily_transactions');
                            }),
                            _buildMainButton('المنتجات', Icons.inventory_2, Colors.teal, () {
                              Navigator.pushNamed(context, '/products');
                            }),
                            _buildMainButton('المخازن', Icons.warehouse, Colors.brown, () {
                              Navigator.pushNamed(context, '/warehouses');
                            }),
                            _buildMainButton('دليل الحسابات', Icons.menu_book, Colors.cyan, () {
                              Navigator.pushNamed(context, '/accounts');
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo[700]!, Colors.indigo[500]!],
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.account_balance, size: 48, color: Colors.white),
                  SizedBox(height: 8),
                  Text(
                    'المحاسب الشخصي',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'إدارة الحسابات والمخازن',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(Icons.home, 'الرئيسية', () {
              Navigator.pop(context);
            }),
            _buildDrawerItem(Icons.receipt_long, 'سند قبض/صرف', () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/voucher');
            }),
            _buildDrawerItem(Icons.swap_horiz, 'حوالة جديدة', () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/transfer');
            }),
            _buildDrawerItem(Icons.description, 'فاتورة جديدة', () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/invoice');
            }),
            _buildDrawerItem(Icons.calendar_today, 'الحركة اليومية', () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/daily_transactions');
            }),
            _buildDrawerItem(Icons.search, 'البحث السريع', () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/search');
            }),
            const Divider(),
            _buildDrawerItem(Icons.inventory_2, 'المنتجات', () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/products');
            }),
            _buildDrawerItem(Icons.warehouse, 'المخازن', () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/warehouses');
            }),
            _buildDrawerItem(Icons.menu_book, 'دليل الحسابات', () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/accounts');
            }),
            const Divider(),
            _buildDrawerItem(Icons.backup, 'النسخ الاحتياطي', () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/backup');
            }),
            _buildDrawerItem(Icons.settings, 'الإعدادات', () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.indigo),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      onTap: onTap,
    );
  }
}
