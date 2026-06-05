import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import '../database/database_helper.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final dbHelper = DatabaseHelper.instance;
  List<String> backupFiles = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBackupFiles();
  }

  Future<void> _loadBackupFiles() async {
    final files = await dbHelper.getBackupFiles();
    setState(() => backupFiles = files);
  }

  Future<void> _createBackup() async {
    setState(() => isLoading = true);
    try {
      final backupPath = await dbHelper.backupDatabase();
      await _loadBackupFiles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم إنشاء النسخة الاحتياطية بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
    setState(() => isLoading = false);
  }

  Future<void> _shareBackup() async {
    setState(() => isLoading = true);
    try {
      await dbHelper.shareBackup();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
    setState(() => isLoading = false);
  }

  Future<void> _restoreBackup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الاستعادة'),
        content: const Text('سيتم استبدال جميع البيانات الحالية بالبيانات من ملف النسخة الاحتياطية. هل أنت متأكد؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('استعادة', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => isLoading = true);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty || result.files.first.path == null) {
        setState(() => isLoading = false);
        return;
      }

      await dbHelper.restoreDatabase(result.files.first.path!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم استعادة النسخة الاحتياطية بنجاح. يرجى إعادة تشغيل التطبيق.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الاستعادة: $e')),
        );
      }
    }
    setState(() => isLoading = false);
  }

  Future<void> _restoreFromFile(String filePath) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الاستعادة'),
        content: Text('سيتم استبدال جميع البيانات الحالية ببيانات من: ${path.basename(filePath)}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('استعادة', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => isLoading = true);
    try {
      final dbPath = await getDatabasesPath();
      final dbFile = File(path.join(dbPath, 'accounting_app.db'));
      await File(filePath).copy(dbFile.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم استعادة النسخة الاحتياطية بنجاح. يرجى إعادة تشغيل التطبيق.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
    setState(() => isLoading = false);
  }

  Future<void> _deleteBackup(String filePath) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذه النسخة الاحتياطية؟'),
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

    if (confirmed != true) return;

    try {
      await File(filePath).delete();
      await _loadBackupFiles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف النسخة الاحتياطية')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('النسخ الاحتياطي'),
          centerTitle: true,
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // معلومات
                    Card(
                      color: Colors.blue[50],
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(Icons.info, color: Colors.blue, size: 32),
                            SizedBox(height: 8),
                            Text(
                              'يتم حفظ النسخ الاحتياطية في مجلد Accounting_Backups على الجهاز. يمكنك مشاركة الملف أو استعادته لاحقاً.',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // أزرار النسخ والاستعادة
                    ElevatedButton.icon(
                      onPressed: _createBackup,
                      icon: const Icon(Icons.backup),
                      label: const Text('إنشاء نسخة احتياطية جديدة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _shareBackup,
                      icon: const Icon(Icons.share),
                      label: const Text('مشاركة النسخة الاحتياطية'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _restoreBackup,
                      icon: const Icon(Icons.restore),
                      label: const Text('استعادة من ملف خارجي'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'النسخ الاحتياطية المحفوظة:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    // قائمة النسخ
                    backupFiles.isEmpty
                        ? const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('لا توجد نسخ احتياطية محفوظة'),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: backupFiles.length,
                            itemBuilder: (context, index) {
                              final file = backupFiles[index];
                              final fileName = path.basename(file);
                              final fileStat = File(file).statSync();
                              final fileSize = (fileStat.size / 1024).toStringAsFixed(1);

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  leading: const Icon(Icons.backup, color: Colors.green),
                                  title: Text(fileName),
                                  subtitle: Text('الحجم: $fileSize كيلوبايت'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.restore, color: Colors.blue),
                                        onPressed: () => _restoreFromFile(file),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.share, color: Colors.indigo),
                                        onPressed: () => SharePlus.instance.share(ShareParams(files: [XFile(file)])),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _deleteBackup(file),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
      ),
    );
  }
}
