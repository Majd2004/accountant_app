import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/models.dart';

class WarehousesScreen extends StatefulWidget {
  const WarehousesScreen({super.key});

  @override
  State<WarehousesScreen> createState() => _WarehousesScreenState();
}

class _WarehousesScreenState extends State<WarehousesScreen> {
  final dbHelper = DatabaseHelper.instance;
  List<Warehouse> warehouses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWarehouses();
  }

  Future<void> _loadWarehouses() async {
    final data = await dbHelper.getWarehouses();
    setState(() {
      warehouses = data.map((e) => Warehouse.fromMap(e)).toList();
      isLoading = false;
    });
  }

  void _showAddWarehouseDialog() {
    final nameController = TextEditingController();
    final locationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة مخزن جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'اسم المخزن', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(labelText: 'الموقع', border: OutlineInputBorder()),
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
              await dbHelper.insertWarehouse({
                'name': nameController.text,
                'location': locationController.text,
                'notes': '',
              });
              Navigator.pop(context);
              _loadWarehouses();
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
          title: const Text('المخازن'),
          centerTitle: true,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddWarehouseDialog,
          child: const Icon(Icons.add),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : warehouses.isEmpty
                ? const Center(child: Text('لا توجد مخازن'))
                : ListView.builder(
                    itemCount: warehouses.length,
                    itemBuilder: (context, index) {
                      final warehouse = warehouses[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.brown,
                            child: Icon(Icons.warehouse, color: Colors.white),
                          ),
                          title: Text(warehouse.name),
                          subtitle: Text('الموقع: ${warehouse.location ?? '-'}'),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
