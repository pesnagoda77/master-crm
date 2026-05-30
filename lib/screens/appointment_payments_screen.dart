import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../utils/constants.dart';

class AppointmentPaymentsScreen extends StatefulWidget {
  final int appointmentId;
  final double totalPrice;
  final AppointmentStatus status;

  const AppointmentPaymentsScreen({
    super.key,
    required this.appointmentId,
    required this.totalPrice,
    required this.status,
  });

  @override
  State<AppointmentPaymentsScreen> createState() => _AppointmentPaymentsScreenState();
}

class _AppointmentPaymentsScreenState extends State<AppointmentPaymentsScreen> {
  List<Map<String, dynamic>> _payments = [];
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    final payments = await DatabaseHelper.instance.getPaymentsForAppointment(widget.appointmentId);
    setState(() => _payments = payments);
  }

  double get _totalPaid {
    return _payments.fold(0.0, (sum, p) => sum + (p['amount'] as num).toDouble());
  }

  double get _remaining {
    return widget.totalPrice - _totalPaid;
  }

  Future<void> _addPayment() async {
    if (_amountController.text.isEmpty) return;

    final amount = double.parse(_amountController.text.trim());
    if (amount <= 0 || amount > _remaining) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Сумма не может превышать ${_remaining.toStringAsFixed(0)} ₽')),
      );
      return;
    }

    await DatabaseHelper.instance.createPayment(
      widget.appointmentId,
      amount,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    _amountController.clear();
    _notesController.clear();
    await _loadPayments();

    // Auto-update status if fully paid
    if (_remaining <= 0.01) {
      // Need to update appointment status - this would require passing the appointment object
      // For now, just show a message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Запись полностью оплачена!')),
      );
    }
  }

  Future<void> _deletePayment(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('payments', where: 'id = ?', whereArgs: [id]);
    await _loadPayments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Оплаты', style: TextStyle(color: AppColors.textPrimary)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Сводка
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Сумма записи', widget.totalPrice, AppColors.textPrimary),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Оплачено', _totalPaid, AppColors.income),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Осталось', _remaining, _remaining > 0 ? AppColors.expense : AppColors.income),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Добавление
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Сумма оплаты',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.currency_ruble, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Примечание',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _remaining > 0 ? _addPayment : null,
                icon: const Icon(Icons.add),
                label: const Text('Добавить оплату'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navActive,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Список
            Expanded(
              child: _payments.isEmpty
                  ? Center(
                      child: Text(
                        'Нет оплат',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _payments.length,
                      itemBuilder: (context, index) {
                        final p = _payments[index];
                        final date = DateTime.parse(p['date']);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.income.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.currency_ruble, color: AppColors.income, size: 16),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${p['amount'].toStringAsFixed(0)} ₽',
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('dd.MM.yyyy HH:mm').format(date),
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (p['notes'] != null)
                                      Text(
                                        p['notes'],
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => _deletePayment(p['id']),
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppColors.textSecondary)),
        Text(
          '${value.toStringAsFixed(0)} ₽',
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
