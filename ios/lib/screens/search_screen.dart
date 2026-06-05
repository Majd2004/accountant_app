import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../database/database_helper.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final dbHelper = DatabaseHelper.instance;
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> results = [];
  bool isSearching = false;

  Future<void> _search() async {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return;

    setState(() => isSearching = true);

    // البحث في الحركات
    final transactions = await dbHelper.getTransactions();
    final filtered = transactions.where((t) {
      final notes = (t['notes'] ?? '').toString().toLowerCase();
      final reference = (t['reference'] ?? '').toString().toLowerCase();
      final type = (t['type'] ?? '').toString().toLowerCase();
      final amount = (t['amount'] ?? 0).toString();
      return notes.contains(query) || reference.contains(query) || type.contains(query) || amount.contains(query);
    }).toList();

    setState(() {
      results = filtered;
      isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('البحث السريع'),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'ابحث في الحركات...',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => results = []);
                    },
                  ),
                ),
                onSubmitted: (_) => _search(),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _search,
              icon: const Icon(Icons.search),
              label: const Text('بحث'),
            ),
            const SizedBox(height: 8),
            if (isSearching)
              const CircularProgressIndicator()
            else if (results.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final t = results[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getTypeColor(t['type'] as String),
                          child: Icon(_getTypeIcon(t['type'] as String), color: Colors.white),
                        ),
                        title: Text('${t['type']} - ${t['notes'] ?? ''}'),
                        subtitle: Text('التاريخ: ${t['date']}'),
                        trailing: Text(
                          '${(t['amount'] as double).toStringAsFixed(0)} د.ع',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
              )
            else if (_searchController.text.isNotEmpty)
              const Expanded(
                child: Center(child: Text('لا توجد نتائج')),
              ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'قبض': return Colors.green;
      case 'صرف': return Colors.red;
      case 'حوالة': return Colors.blue;
      default: return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'قبض': return Icons.arrow_downward;
      case 'صرف': return Icons.arrow_upward;
      case 'حوالة': return Icons.swap_horiz;
      default: return Icons.receipt;
    }
  }
}
