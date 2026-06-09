import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/voucher_screen.dart';
import 'screens/transfer_screen.dart';
import 'screens/invoice_screen.dart';
import 'screens/statement_screen.dart';
import 'screens/daily_transactions_screen.dart';
import 'screens/products_screen.dart';
import 'screens/warehouses_screen.dart';
import 'screens/accounts_screen.dart';
import 'screens/search_screen.dart';
import 'screens/backup_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'المحاسب الشخصي',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Cairo',
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
      locale: const Locale('ar', 'IQ'),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/voucher': (context) => const VoucherScreen(),
        '/transfer': (context) => const TransferScreen(),
        '/invoice': (context) => const InvoiceScreen(),
        '/statement': (context) => const StatementScreen(),
        '/daily_transactions': (context) => const DailyTransactionsScreen(),
        '/products': (context) => const ProductsScreen(),
        '/warehouses': (context) => const WarehousesScreen(),
        '/accounts': (context) => const AccountsScreen(),
        '/search': (context) => const SearchScreen(),
        '/backup': (context) => const BackupScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
