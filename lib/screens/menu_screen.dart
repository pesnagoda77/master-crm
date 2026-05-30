import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../database/database_helper.dart';
import '../utils/constants.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _taxSystem = 'usn6';
  double _monthlyGoal = 150000;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Настройки',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Налоги'),
            _buildTaxSelector(),
            const SizedBox(height: 24),

            _buildSectionTitle('Цель месяца'),
            _buildGoalSlider(),
            const SizedBox(height: 24),

            _buildSectionTitle('Данные'),
            _buildMenuItem(
              Icons.backup,
              'Экспорт данных',
              'Сохранить бэкап',
              () => _exportData(),
            ),
            _buildMenuItem(
              Icons.restore,
              'Импорт данных',
              'Восстановить из бэкапа',
              () => _importData(),
            ),
            _buildMenuItem(
              Icons.delete_outline,
              'Очистить все данные',
              'Удалить клиентов, записи, расходы',
              () => _showClearDataDialog(),
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('О приложении'),
            _buildMenuItem(
              Icons.info_outline,
              'Версия',
              '1.0.0 MVP',
              null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildTaxSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildTaxOption('usn6', 'УСН 6%', 'Доход × 6%'),
          const Divider(height: 16, color: AppColors.surface),
          _buildTaxOption('usn15', 'УСН 15%', '(Доход − Расход) × 15%'),
        ],
      ),
    );
  }

  Widget _buildTaxOption(String value, String title, String subtitle) {
    final isSelected = _taxSystem == value;
    return GestureDetector(
      onTap: () => setState(() => _taxSystem = value),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.navActive : AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.navActive : Colors.transparent,
              border: Border.all(
                color: isSelected ? AppColors.navActive : AppColors.textSecondary,
                width: 2,
              ),
              shape: BoxShape.circle,
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildGoalSlider() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${NumberFormat('#,###').format(_monthlyGoal.toInt())} ₽',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.navActive,
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _monthlyGoal,
            min: 50000,
            max: 500000,
            divisions: 45,
            activeColor: AppColors.navActive,
            inactiveColor: AppColors.surface,
            onChanged: (value) => setState(() => _monthlyGoal = value),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '50 000 ₽',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '500 000 ₽',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.navActive.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.navActive, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      final clients = await db.query('clients');
      final appointments = await db.query('appointments');
      final expenses = await db.query('expenses');
      
      final exportData = {
        'exportDate': DateTime.now().toIso8601String(),
        'clients': clients,
        'appointments': appointments,
        'expenses': expenses,
      };
      
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/master_crm_backup.json');
      await file.writeAsString(jsonEncode(exportData));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Бэкап сохранён: ${file.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка экспорта: $e')),
        );
      }
    }
  }

  Future<void> _importData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/master_crm_backup.json');
      
      if (!await file.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Файл бэкапа не найден')),
          );
        }
        return;
      }
      
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString);
      
      final db = await DatabaseHelper.instance.database;
      
      await db.delete('clients');
      await db.delete('appointments');
      await db.delete('expenses');
      
      for (final client in data['clients']) {
        await db.insert('clients', client);
      }
      for (final appointment in data['appointments']) {
        await db.insert('appointments', appointment);
      }
      for (final expense in data['expenses']) {
        await db.insert('expenses', expense);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Данные восстановлены')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка импорта: $e')),
        );
      }
    }
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Очистить все данные?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Это удалит всех клиентов, записи и расходы. Действие нельзя отменить.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              final db = await DatabaseHelper.instance.database;
              await db.delete('clients');
              await db.delete('appointments');
              await db.delete('expenses');
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Данные очищены')),
              );
            },
            child: const Text(
              'Удалить',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}