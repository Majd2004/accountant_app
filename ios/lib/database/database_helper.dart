import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'accounting_app.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // الحسابات (دليل الحسابات)
    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        balance REAL DEFAULT 0,
        currency TEXT DEFAULT 'دينار',
        notes TEXT,
        created_at TEXT
      )
    ''');

    // الحركات المالية
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        from_account_id INTEGER,
        to_account_id INTEGER,
        amount REAL NOT NULL,
        currency TEXT DEFAULT 'دينار',
        exchange_rate REAL DEFAULT 1,
        notes TEXT,
        reference TEXT,
        created_at TEXT
      )
    ''');

    // المنتجات
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        code TEXT,
        category TEXT,
        unit TEXT DEFAULT 'قطعة',
        purchase_price REAL DEFAULT 0,
        sale_price REAL DEFAULT 0,
        quantity INTEGER DEFAULT 0,
        min_quantity INTEGER DEFAULT 0,
        warehouse_id INTEGER,
        notes TEXT
      )
    ''');

    // المخازن
    await db.execute('''
      CREATE TABLE warehouses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        location TEXT,
        notes TEXT
      )
    ''');

    // الفواتير
    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        account_id INTEGER,
        warehouse_id INTEGER,
        total REAL DEFAULT 0,
        discount REAL DEFAULT 0,
        tax REAL DEFAULT 0,
        final_total REAL DEFAULT 0,
        paid REAL DEFAULT 0,
        remaining REAL DEFAULT 0,
        currency TEXT DEFAULT 'دينار',
        notes TEXT
      )
    ''');

    // تفاصيل الفاتورة
    await db.execute('''
      CREATE TABLE invoice_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity REAL NOT NULL,
        unit_price REAL NOT NULL,
        total REAL NOT NULL,
        notes TEXT
      )
    ''');

    // العملات
    await db.execute('''
      CREATE TABLE currencies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        code TEXT NOT NULL,
        symbol TEXT,
        exchange_rate REAL DEFAULT 1,
        is_default INTEGER DEFAULT 0
      )
    ''');

    // الإعدادات
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT NOT NULL UNIQUE,
        value TEXT
      )
    ''');

    // إضافة بيانات افتراضية
    await _insertDefaultData(db);
  }

  Future<void> _insertDefaultData(Database db) async {
    // إضافة عملة افتراضية
    await db.insert('currencies', {
      'name': 'دينار عراقي',
      'code': 'IQD',
      'symbol': 'د.ع',
      'exchange_rate': 1,
      'is_default': 1,
    });

    // إضافة مخزن افتراضي
    await db.insert('warehouses', {
      'name': 'المخزن الرئيسي',
      'location': 'الموقع الرئيسي',
      'notes': '',
    });

    // إضافة حسابات افتراضية
    final defaultAccounts = [
      {'name': 'الصندوق', 'type': 'صندوق', 'balance': 0},
      {'name': 'العملاء', 'type': 'عميل', 'balance': 0},
      {'name': 'الموردين', 'type': 'مورد', 'balance': 0},
      {'name': 'المصروفات', 'type': 'مصروف', 'balance': 0},
      {'name': 'الموظفين', 'type': 'موظف', 'balance': 0},
      {'name': 'الديون', 'type': 'دين', 'balance': 0},
    ];

    for (var account in defaultAccounts) {
      await db.insert('accounts', {
        ...account,
        'currency': 'دينار',
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  // ==================== CRUD Operations ====================

  // الحسابات
  Future<List<Map<String, dynamic>>> getAccounts({String? type}) async {
    final db = await database;
    if (type != null) {
      return await db.query('accounts', where: 'type = ?', whereArgs: [type]);
    }
    return await db.query('accounts', orderBy: 'type, name');
  }

  Future<int> insertAccount(Map<String, dynamic> account) async {
    final db = await database;
    return await db.insert('accounts', {
      ...account,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> updateAccount(int id, Map<String, dynamic> account) async {
    final db = await database;
    return await db.update('accounts', account, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAccount(int id) async {
    final db = await database;
    return await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  // الحركات
  Future<List<Map<String, dynamic>>> getTransactions({String? type, String? dateFrom, String? dateTo}) async {
    final db = await database;
    String? where;
    List<dynamic>? whereArgs;

    if (type != null) {
      where = 'type = ?';
      whereArgs = [type];
    }

    if (dateFrom != null && dateTo != null) {
      where = where != null ? '$where AND date BETWEEN ? AND ?' : 'date BETWEEN ? AND ?';
      whereArgs = whereArgs != null ? [...whereArgs, dateFrom, dateTo] : [dateFrom, dateTo];
    }

    return await db.query(
      'transactions',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'date DESC, id DESC',
    );
  }

  Future<int> insertTransaction(Map<String, dynamic> transaction) async {
    final db = await database;
    final id = await db.insert('transactions', {
      ...transaction,
      'created_at': DateTime.now().toIso8601String(),
    });

    // تحديث أرصدة الحسابات
    await _updateAccountBalances(transaction);

    return id;
  }

  Future<void> _updateAccountBalances(Map<String, dynamic> transaction) async {
    final db = await database;
    final type = transaction['type'];
    final amount = transaction['amount'] as double;

    if (type == 'قبض' && transaction['to_account_id'] != null) {
      await db.rawUpdate(
        'UPDATE accounts SET balance = balance + ? WHERE id = ?',
        [amount, transaction['to_account_id']],
      );
    } else if (type == 'صرف' && transaction['from_account_id'] != null) {
      await db.rawUpdate(
        'UPDATE accounts SET balance = balance - ? WHERE id = ?',
        [amount, transaction['from_account_id']],
      );
    } else if (type == 'حوالة') {
      if (transaction['from_account_id'] != null) {
        await db.rawUpdate(
          'UPDATE accounts SET balance = balance - ? WHERE id = ?',
          [amount, transaction['from_account_id']],
        );
      }
      if (transaction['to_account_id'] != null) {
        await db.rawUpdate(
          'UPDATE accounts SET balance = balance + ? WHERE id = ?',
          [amount, transaction['to_account_id']],
        );
      }
    }
  }

  // الفواتير
  Future<List<Map<String, dynamic>>> getInvoices({String? type}) async {
    final db = await database;
    if (type != null) {
      return await db.query('invoices', where: 'type = ?', orderBy: 'date DESC', whereArgs: [type]);
    }
    return await db.query('invoices', orderBy: 'date DESC');
  }

  Future<int> insertInvoice(Map<String, dynamic> invoice, List<Map<String, dynamic>> items) async {
    final db = await database;

    return await db.transaction((txn) async {
      final invoiceId = await txn.insert('invoices', {
        ...invoice,
      });

      for (var item in items) {
        await txn.insert('invoice_items', {
          ...item,
          'invoice_id': invoiceId,
        });

        // تحديث كمية المنتج
        if (invoice['type'] == 'بيع') {
          await txn.rawUpdate(
            'UPDATE products SET quantity = quantity - ? WHERE id = ?',
            [item['quantity'], item['product_id']],
          );
        } else if (invoice['type'] == 'شراء') {
          await txn.rawUpdate(
            'UPDATE products SET quantity = quantity + ? WHERE id = ?',
            [item['quantity'], item['product_id']],
          );
        }
      }

      return invoiceId;
    });
  }

  // المنتجات
  Future<List<Map<String, dynamic>>> getProducts({int? warehouseId}) async {
    final db = await database;
    if (warehouseId != null) {
      return await db.query('products', where: 'warehouse_id = ?', orderBy: 'name', whereArgs: [warehouseId]);
    }
    return await db.query('products', orderBy: 'name');
  }

  Future<int> insertProduct(Map<String, dynamic> product) async {
    final db = await database;
    return await db.insert('products', product);
  }

  Future<int> updateProduct(int id, Map<String, dynamic> product) async {
    final db = await database;
    return await db.update('products', product, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // المخازن
  Future<List<Map<String, dynamic>>> getWarehouses() async {
    final db = await database;
    return await db.query('warehouses', orderBy: 'name');
  }

  Future<int> insertWarehouse(Map<String, dynamic> warehouse) async {
    final db = await database;
    return await db.insert('warehouses', warehouse);
  }

  // العملات
  Future<List<Map<String, dynamic>>> getCurrencies() async {
    final db = await database;
    return await db.query('currencies', orderBy: 'name');
  }

  Future<int> insertCurrency(Map<String, dynamic> currency) async {
    final db = await database;
    return await db.insert('currencies', currency);
  }

  // الإعدادات
  Future<String?> getSetting(String key) async {
    final db = await database;
    final results = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (results.isNotEmpty) {
      return results.first['value'] as String?;
    }
    return null;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ==================== Backup & Restore ====================

  Future<String> backupDatabase() async {
    final dbPath = await getDatabasesPath();
    final dbFile = File(join(dbPath, 'accounting_app.db'));

    final externalDir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    final backupDir = Directory(join(externalDir.path, 'Accounting_Backups'));
    await backupDir.create(recursive: true);

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupFile = File(join(backupDir.path, 'backup_$timestamp.db'));

    await dbFile.copy(backupFile.path);
    return backupFile.path;
  }

  Future<void> shareBackup() async {
    final backupPath = await backupDatabase();
    await SharePlus.instance.share(ShareParams(
      files: [XFile(backupPath)],
      text: 'نسخة احتياطية من التطبيق المحاسبي',
    ));
  }

  Future<void> restoreDatabase(String filePath) async {
    final dbPath = await getDatabasesPath();
    final dbFile = File(join(dbPath, 'accounting_app.db'));

    // إغلاق قاعدة البيانات أولاً
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    // نسخ ملف الاستعادة
    await File(filePath).copy(dbFile.path);
  }

  Future<List<String>> getBackupFiles() async {
    final externalDir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    final backupDir = Directory(join(externalDir.path, 'Accounting_Backups'));

    if (!await backupDir.exists()) return [];

    final files = await backupDir.list().toList();
    return files
        .whereType<File>()
        .map((f) => f.path)
        .toList()
      ..sort((a, b) => b.compareTo(a));
  }

  // إغلاق قاعدة البيانات
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
