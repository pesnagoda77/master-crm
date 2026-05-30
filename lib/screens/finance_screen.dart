import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'add_expense_screen.dart';
import '../database/database_helper.dart';
import '../models/expense.dart';
import '../utils/constants.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});
  
  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Expense> _expenses = [];
  Map<String, dynamic>? _stats;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    final expenses = await DatabaseHelper.instance.getExpensesForDate(_selectedDate);
    final stats = await DatabaseHelper.instance.getFinanceSummary(_selectedDate);
    setState(() {
      _expenses = expenses;
      _stats = stats;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final income = (_stats?['income'] ?? 0).toDouble();
    final totalExpenses = (_stats?['expenses'] ?? 0).toDouble();
    final net = income - totalExpenses;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Финансы',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('dd.MM.yyyy').format(_selectedDate),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Сегодня',
              style: AppStyles.header,
            ),
            const SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(
                  child: _buildFinanceCard(
                    'Доход',
                    income,
                    AppColors.income,
                    Icons.arrow_upward,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFinanceCard(
                    'Расход',
                    totalExpenses,
                    AppColors.expense,
                    Icons.arrow_downward,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildNetCard(net),
            const SizedBox(height: 24),
            
            const Text(
              'Расходы',
              style: AppStyles.cardTitle,
            ),
            const SizedBox(height: 12),
            
            if (_expenses.isEmpty)
              _buildEmptyExpenses()
            else
              ..._expenses.map((e) => _buildExpenseCard(e)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
          );
          if (result == true) {
            _loadData();
          }
        },
        backgroundColor: AppColors.expense,
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildFinanceCard(String title, double amount, Color color, IconData icon) {
    return Container(
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${NumberFormat('#,###').format(amount.toInt())} ₽',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNetCard(double net) {
    final isPositive = net >= 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPositive ? AppColors.income.withOpacity(0.1) : AppColors.expense.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPositive ? AppColors.income.withOpacity(0.3) : AppColors.expense.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Чистыми',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            '${NumberFormat('#,###').format(net.toInt())} ₽',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isPositive ? AppColors.income : AppColors.expense,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildExpenseCard(Expense expense) {
    final categoryLabels = {
      'materials': 'Материалы',
      'fuel': 'ГСМ',
      'rent': 'Аренда',
      'ads': 'Реклама',
      'other': 'Прочее',
    };
    
    final categoryColors = {
      'materials': Colors.orange,
      'fuel': Colors.blue,
      'rent': Colors.purple,
      'ads': Colors.pink,
      'other': Colors.grey,
    };
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (categoryColors[expense.category] ?? Colors.grey).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
              image: expense.receiptPhoto != null
                  ? DecorationImage(
                      image: FileImage(File(expense.receiptPhoto!)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: expense.receiptPhoto == null
                ? Center(
                    child: Icon(
                      Icons.receipt_long,
                      color: categoryColors[expense.category] ?? Colors.grey,
                      size: 20,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryLabels[expense.category] ?? expense.category,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (expense.notes != null)
                  Text(
                    expense.notes!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${NumberFormat('#,###').format(expense.amount.toInt())} ₽',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.expense,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyExpenses() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: AppColors.textSecondary.withOpacity(0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'Нет расходов',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}