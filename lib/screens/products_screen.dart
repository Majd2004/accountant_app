import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/models.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final dbHelper = DatabaseHelper.instance;
  List<Product> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final data = await dbHelper.getProducts();
    setState(() {
      products = data.map((e) => Product.fromMap(e)).toList();
      isLoading = false;
    });
  }

  Future<void> _deleteProduct(int id) async {
    await dbHelper.deleteProduct(id);
    _loadProducts();
  }

  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final purchasePriceController = TextEditingController();
    final salePriceController = TextEditingController();
    final quantityController = TextEditingController();
    final minQuantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة منتج جديد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'اسم المنتج', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(labelText: 'الكود', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: purchasePriceController,
                decoration: const InputDecoration(labelText: 'سعر الشراء', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: salePriceController,
                decoration: const InputDecoration(labelText: 'سعر البيع', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(labelText: 'الكمية', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: minQuantityController,
                decoration: const InputDecoration(labelText: 'الحد الأدنى', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
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
              final product = Product(
                name: nameController.text,
                code: codeController.text,
                purchasePrice: double.tryParse(purchasePriceController.text) ?? 0,
                salePrice: double.tryParse(salePriceController.text) ?? 0,
                quantity: int.tryParse(quantityController.text) ?? 0,
                minQuantity: int.tryParse(minQuantityController.text) ?? 0,
              );
              await dbHelper.insertProduct(product.toMap());
              Navigator.pop(context);
              _loadProducts();
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
          title: const Text('المنتجات'),
          centerTitle: true,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddProductDialog,
          child: const Icon(Icons.add),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : products.isEmpty
                ? const Center(child: Text('لا توجد منتجات'))
                : ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final isLowStock = product.quantity <= product.minQuantity;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isLowStock ? Colors.red : Colors.teal,
                            child: Icon(
                              isLowStock ? Icons.warning : Icons.inventory_2,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(product.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('الكود: ${product.code ?? '-'}'),
                              Text('الكمية: ${product.quantity} ${product.unit}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('شراء: ${product.purchasePrice.toStringAsFixed(0)} د.ع'),
                                  Text('بيع: ${product.salePrice.toStringAsFixed(0)} د.ع'),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteProduct(product.id!),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
