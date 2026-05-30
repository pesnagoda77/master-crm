import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/client.dart';
import '../utils/constants.dart';

class RecurringScreen extends StatefulWidget {
  const RecurringScreen({super.key});

  @override
  State<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends State<RecurringScreen> {
  List<Map<String, dynamic>> _recurring = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await DatabaseHelper.instance.getAllRecurring();
    setState(() {
      _recurring = data;
      _isLoading = false;
    });
  }

  Future<void> _deleteRecurring(int id) async {
    await DatabaseHelper.instance.deleteRecurring(id);
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Повторяющиеся', style: TextStyle(color: AppColors.textPrimary)),
        centerTitle: true,
      ),
      body: _recurring.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.repeat, color: AppColors.textSecondary, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Нет повторяющихся записей',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _recurring.length,
              itemBuilder: (context, index) {
                final r = _recurring[index];
                final startDate = DateTime.parse(r['startDate']);
                final endDate = r['endDate'] != null ? DateTime.parse(r['endDate']) : null;
                
                String repeatText;
                switch (r['repeatType']) {
                  case 'daily':
                    repeatText = 'Каждый ${r['repeatInterval']} день';
                    break;
                  case 'weekly':
                    repeatText = 'Каждую ${r['repeatInterval']} неделю';
                    break;
                  case 'monthly':
                    repeatText = 'Каждый ${r['repeatInterval']} месяц';
                    break;
                  default:
                    repeatText = 'Повтор';
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.navActive.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                (r['clientName'] as String)[0].toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.navActive,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r['clientName'],
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  r['service'],
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _deleteRecurring(r['id']),
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.repeat, color: AppColors.navActive, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            repeatText,
                            style: TextStyle(color: AppColors.navActive),
                          ),
                          const Spacer(),
                          Text(
                            '${r['price'].toStringAsFixed(0)} ₽',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'С ${DateFormat('dd.MM.yyyy').format(startDate)}${endDate != null ? ' до ${DateFormat('dd.MM.yyyy').format(endDate)}' : ''}',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
